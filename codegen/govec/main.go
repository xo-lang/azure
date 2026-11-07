// Command govec writes the Go program that records an ARM module's Go
// vectors (decision 0002): every public method of each of Go's clients,
// called by reflection with every argument and option filled, against
// a fake transport. It reads Go's module source, so no module needs Go
// written by hand:
//
//	go run ./codegen/govec <module dir> <import path> <version> <out dir>
//
// <module dir> is Go's module in the module cache; <out dir> gets
// main.go, poly.go and go.mod. Run the program there (no network) and
// feed its output to the vector writer.
package main

import (
	_ "embed"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
)

//go:embed program.go.tmpl
var program string

type client struct {
	Name string
	Sub  bool
}

type module struct {
	Pkg, Import, Version string
	Clients              []client
	Poly                 [][2]string
}

func main() {
	if len(os.Args) != 5 {
		fmt.Fprintln(os.Stderr, "usage: govec <module dir> <import path> <version> <out dir>")
		os.Exit(2)
	}
	m, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	m.Import, m.Version = os.Args[2], os.Args[3]
	if err := write(m, os.Args[4]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Printf("%s: %d clients, %d polymorphic interfaces\n", m.Pkg, len(m.Clients), len(m.Poly))
}

// read finds the module's client constructors and, for each polymorphic
// interface (XClassification with GetX() *X), its first derived type
// by name.
func read(dir string) (*module, error) {
	fs := token.NewFileSet()
	files, err := filepath.Glob(filepath.Join(dir, "*.go"))
	if err != nil {
		return nil, err
	}
	m := &module{}
	ifaces := map[string]string{}    // XClassification -> X
	getters := map[string][]string{} // X -> types with GetX() *X
	for _, f := range files {
		if strings.HasSuffix(f, "_test.go") {
			continue
		}
		af, err := parser.ParseFile(fs, f, nil, parser.SkipObjectResolution)
		if err != nil {
			return nil, err
		}
		m.Pkg = af.Name.Name
		for _, d := range af.Decls {
			switch d := d.(type) {
			case *ast.FuncDecl:
				if d.Recv == nil {
					n := d.Name.Name
					if strings.HasPrefix(n, "New") && strings.HasSuffix(n, "Client") && d.Name.IsExported() {
						ps := d.Type.Params.List
						sub := len(ps) > 0 && types(ps[0]) == "string"
						m.Clients = append(m.Clients, client{Name: strings.TrimPrefix(n, "New"), Sub: sub})
					}
					continue
				}
				if !strings.HasPrefix(d.Name.Name, "Get") || d.Type.Results == nil || len(d.Type.Results.List) != 1 {
					continue
				}
				base := strings.TrimPrefix(d.Name.Name, "Get")
				if types(d.Type.Results.List[0]) != "*"+base {
					continue
				}
				recv := strings.TrimPrefix(types(d.Recv.List[0]), "*")
				if recv != base {
					getters[base] = append(getters[base], recv)
				}
			case *ast.GenDecl:
				for _, s := range d.Specs {
					ts, ok := s.(*ast.TypeSpec)
					if !ok || !strings.HasSuffix(ts.Name.Name, "Classification") {
						continue
					}
					it, ok := ts.Type.(*ast.InterfaceType)
					if !ok {
						continue
					}
					for _, f := range it.Methods.List {
						if len(f.Names) == 1 && strings.HasPrefix(f.Names[0].Name, "Get") {
							ifaces[ts.Name.Name] = strings.TrimPrefix(f.Names[0].Name, "Get")
						}
					}
				}
			}
		}
	}
	sort.Slice(m.Clients, func(i, j int) bool { return m.Clients[i].Name < m.Clients[j].Name })
	var names []string
	for n := range ifaces {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		ds := getters[ifaces[n]]
		if len(ds) == 0 {
			continue
		}
		sort.Strings(ds)
		m.Poly = append(m.Poly, [2]string{n, ds[0]})
	}
	return m, nil
}

func types(f *ast.Field) string {
	var b strings.Builder
	var walk func(e ast.Expr)
	walk = func(e ast.Expr) {
		switch e := e.(type) {
		case *ast.Ident:
			b.WriteString(e.Name)
		case *ast.StarExpr:
			b.WriteString("*")
			walk(e.X)
		case *ast.SelectorExpr:
			walk(e.X)
			b.WriteString("." + e.Sel.Name)
		default:
			b.WriteString("?")
		}
	}
	walk(f.Type)
	return b.String()
}

func write(m *module, out string) error {
	if err := os.MkdirAll(out, 0o755); err != nil {
		return err
	}
	t := template.Must(template.New("p").Parse(program))
	f, err := os.Create(filepath.Join(out, "main.go"))
	if err != nil {
		return err
	}
	if err := t.Execute(f, m); err != nil {
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	var p strings.Builder
	p.WriteString("package main\n\nimport (\n\t\"reflect\"\n")
	if len(m.Poly) > 0 {
		fmt.Fprintf(&p, "\n\t%q\n", m.Import)
	}
	p.WriteString(")\n\n// poly: a concrete type for each polymorphic interface (the first\n// derived one by name), so the filler can set those fields.\nvar poly = map[reflect.Type]func() any{\n")
	for _, e := range m.Poly {
		fmt.Fprintf(&p, "\treflect.TypeOf((*%s.%s)(nil)).Elem(): func() any { return &%s.%s{} },\n", m.Pkg, e[0], m.Pkg, e[1])
	}
	p.WriteString("}\n")
	if err := os.WriteFile(filepath.Join(out, "poly.go"), []byte(p.String()), 0o644); err != nil {
		return err
	}
	mod := fmt.Sprintf("module govectors\n\ngo 1.25.0\n\nrequire (\n\tgithub.com/Azure/azure-sdk-for-go/sdk/azcore v1.23.3\n\t%s %s\n)\n", m.Import, m.Version)
	return os.WriteFile(filepath.Join(out, "go.mod"), []byte(mod), 0o644)
}
