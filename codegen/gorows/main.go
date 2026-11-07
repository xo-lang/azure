// Command gorows derives codegen/services.toml rows from Go's ARM
// modules, so no row is written by hand: each module's own pin
// (tsp-location.yaml: the spec commit and TypeSpec folder; autorest.md:
// the commit, readme and tag) and its source (the api-versions its
// clients send and each request's path, which pick the OpenAPI files;
// whether it writes date-times in UTC; a TypeSpec module's Accept and
// query encoding).
//
//	go run ./codegen/gorows <specs dir> < modules > rows.toml
//
// Each input line is "<module path> <version> <module dir>" (a module in
// the module cache). <specs dir> is codegen/.specs: a pinned commit's
// files when fetched, else its trees in the shared clone (.store).
// Problems go to stderr, one a line; the rows of every module still go
// to stdout.
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

const prefix = "github.com/Azure/azure-sdk-for-go/sdk/"

var (
	reMajor   = regexp.MustCompile(`/v\d+$`)
	reConst   = regexp.MustCompile(`(?m)^\s*(\w+)(?:\s+string)?\s*=\s*"([^"]*)"`)
	reAPI     = regexp.MustCompile(`"api-version", (?:"([^"]+)"|(\w+))\)`)
	reAPILit  = regexp.MustCompile(`"api-version", "([^"]+)"\)`)
	reURL     = regexp.MustCompile(`urlPath := "([^"]+)"`)
	reParam   = regexp.MustCompile(`\{[^}]*\}`)
	reDir     = regexp.MustCompile(`(?m)^directory: (\S+)`)
	reCommit  = regexp.MustCompile(`(?m)^commit: (\S+)`)
	reYAML    = regexp.MustCompile("(?s)``` *yaml\n(.*?)```")
	reRequire = regexp.MustCompile(`azure-rest-api-specs/blob/(\w+)/(\S+)`)
	reTag     = regexp.MustCompile(`(?m)^tag: (\S+)`)
	reFlag    = regexp.MustCompile(`(?m)^(package-[\w-]+): true`)
	reKey     = regexp.MustCompile(`(?m)^([\w-]+):`)
	reUTC     = regexp.MustCompile(`populate\w*(?:\[[^\]]*\])?\(objectMap, "[^"]*", [\w.]+, true\)`)
)

type row struct {
	Dir, Spec, ReadmeTag, OpenAPI, Commit, GoModule, GoVersion string
	OpenAPIMore                                                []string
	UTC, Seal, AcceptAll, QueryPlus                            bool
}

var specs string
var problems []string

func problem(f string, a ...any) { problems = append(problems, fmt.Sprintf(f, a...)) }

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: gorows <specs dir> < modules")
		os.Exit(2)
	}
	specs = os.Args[1]
	var rows []row
	sc := bufio.NewScanner(os.Stdin)
	for sc.Scan() {
		f := strings.Fields(sc.Text())
		if len(f) != 3 {
			continue
		}
		rows = append(rows, derive(f[0], f[1], f[2]))
	}
	sort.Slice(rows, func(i, j int) bool { return rows[i].GoModule < rows[j].GoModule })
	var out []string
	for _, r := range rows {
		out = append(out, format(r))
	}
	fmt.Print(strings.Join(out, "\n\n") + "\n")
	for _, p := range problems {
		fmt.Fprintln(os.Stderr, p)
	}
}

func read(p string) string {
	b, err := os.ReadFile(p)
	if err != nil {
		return ""
	}
	// the specs mix CRLF and LF line ends
	return strings.ReplaceAll(string(b), "\r\n", "\n")
}

func exists(p string) bool { _, err := os.Stat(p); return err == nil }

func normPath(p string) string { return strings.ToLower(reParam.ReplaceAllString(p, "{}")) }

func derive(modPath, version, dir string) row {
	rel := reMajor.ReplaceAllString(strings.TrimPrefix(modPath, prefix), "")
	r := row{Dir: rel, GoModule: modPath, GoVersion: version}
	files, _ := filepath.Glob(filepath.Join(dir, "*.go"))
	var gofiles []string
	var src strings.Builder
	for _, f := range files {
		if strings.HasSuffix(f, "_test.go") {
			continue
		}
		gofiles = append(gofiles, f)
		src.WriteString(read(f))
	}
	s := src.String()
	r.UTC = reUTC.MatchString(read(filepath.Join(dir, "models_serde.go")))
	// a TypeSpec module whose every request sets Accept, a body or not
	// (typespec-go before about 0.8: armagricultureplatform,
	// armazurestackhcivm)
	nreq := strings.Count(s, "CreateRequest(ctx context.Context")
	r.AcceptAll = exists(filepath.Join(dir, "tsp-location.yaml")) && nreq > 0 && strings.Count(s, `.Header["Accept"] = `) >= nreq
	// typespec-go before it replaced the query's "+" with "%20"
	// (armalertsmanagement's emitter 0.10.2)
	r.QueryPlus = exists(filepath.Join(dir, "tsp-location.yaml")) && strings.Contains(s, "RawQuery = reqQP.Encode()") && !strings.Contains(s, `reqQP.Encode(), "+", "%20"`)
	consts := map[string]string{}
	for _, m := range reConst.FindAllStringSubmatch(s, -1) {
		consts[m[1]] = m[2]
	}
	apiSet := map[string]bool{}
	for _, m := range reAPI.FindAllStringSubmatch(s, -1) {
		// a literal is an operation's fixed api-version parameter, not a
		// spec version of its own
		if v, ok := consts[m[2]]; ok {
			apiSet[v] = true
		}
	}
	if len(apiSet) == 0 {
		// the older emitters write the version inline
		for _, m := range reAPILit.FindAllStringSubmatch(s, -1) {
			apiSet[m[1]] = true
		}
	}
	var apis []string
	for a := range apiSet {
		apis = append(apis, a)
	}
	sort.Strings(apis)
	if t := read(filepath.Join(dir, "tsp-location.yaml")); t != "" {
		r.Spec = first(reDir, t)
		r.Commit = first(reCommit, t)
		// Go's (url path, api-version) pairs, one per request builder
		used := map[string]map[string]bool{}
		for _, f := range gofiles {
			for _, fn := range strings.Split(read(f), "\nfunc ") {
				um := reURL.FindStringSubmatch(fn)
				vm := reAPI.FindStringSubmatch(fn)
				if um == nil || vm == nil {
					continue
				}
				v := consts[vm[2]]
				if v == "" {
					v = vm[1]
				}
				if used[v] == nil {
					used[v] = map[string]bool{}
				}
				used[v][normPath(um[1])] = true
			}
		}
		var out []string
		for i := len(apis) - 1; i >= 0; i-- {
			out = append(out, openapiFiles(rel, r.Commit, r.Spec, apis[i], i == len(apis)-1, used[apis[i]])...)
		}
		if len(out) > 0 {
			r.OpenAPI = out[0]
			r.OpenAPIMore = out[1:]
			r.Spec = projectOf(r.Commit, r.Spec, r.OpenAPI)
		}
		return r
	}
	t := read(filepath.Join(dir, "autorest.md"))
	y := first(reYAML, t)
	reqs := reRequire.FindAllStringSubmatch(y, -1)
	if len(reqs) == 0 {
		problem("%s: no tsp-location.yaml or autorest.md pin", rel)
		return r
	}
	r.Commit = reqs[0][1]
	for _, q := range reqs {
		if strings.HasSuffix(q[2], "/readme.md") {
			r.Spec = strings.TrimSuffix(q[2], "/readme.md")
		}
	}
	r.ReadmeTag = first(reTag, y)
	if r.ReadmeTag == "" {
		var flags []string
		for _, m := range reFlag.FindAllStringSubmatch(y, -1) {
			flags = append(flags, m[1])
		}
		base := filepath.Join(specs, r.Commit, r.Spec)
		r.ReadmeTag = readmeTag(read(filepath.Join(base, "readme.md")), read(filepath.Join(base, "readme.go.md")), flags)
		if r.ReadmeTag == "" {
			problem("%s: no tag (flags %v)", rel, flags)
		}
	}
	r.Seal = strings.Contains(y, "seal-single-value-enum-by-default")
	var extra []string
	for _, m := range reKey.FindAllStringSubmatch(y, -1) {
		switch k := m[1]; {
		case k == "azure-arm" || k == "require" || k == "license-header" || k == "module-version" || k == "tag" || strings.HasPrefix(k, "package-"):
		default:
			extra = append(extra, k)
		}
	}
	if len(extra) > 0 {
		problem("%s: autorest.md keys %v not read", rel, extra)
	}
	return r
}

func first(re *regexp.Regexp, s string) string {
	if m := re.FindStringSubmatch(s); m != nil {
		return m[1]
	}
	return ""
}

// readmeTag: a package-X flag's section in readme.go.md or readme.md,
// else readme.md's first tag.
func readmeTag(readme, gomd string, flags []string) string {
	for _, flag := range flags {
		re := regexp.MustCompile("(?s)```\\s*yaml\\s+\\$\\(" + regexp.QuoteMeta(flag) + "\\)[^\n]*\n(.*?)```")
		for _, t := range []string{gomd, readme} {
			if m := re.FindStringSubmatch(t); m != nil {
				if tag := first(reTag, m[1]); tag != "" {
					return tag
				}
			}
		}
	}
	for _, m := range reYAML.FindAllStringSubmatch(readme, -1) {
		if tag := first(reTag, m[1]); tag != "" {
			return tag
		}
	}
	return ""
}

// openapiFiles: the files of one api-version. The newest version takes
// every file of its folder (files without paths, the shared
// definitions, first); an older one the fewest files holding Go's
// request paths at that version.
func openapiFiles(rel, commit, directory, ver string, latest bool, used map[string]bool) []string {
	kind := "stable"
	if strings.Contains(ver, "preview") {
		kind = "preview"
	}
	base := filepath.Join(specs, commit)
	folder := path.Join(directory, kind, ver)
	if cand := path.Join(folder, "openapi.json"); exists(filepath.Join(base, cand)) {
		return []string{cand}
	}
	got, _ := filepath.Glob(filepath.Join(base, folder, "*.json"))
	sort.Strings(got)
	if len(got) == 0 {
		// tspconfig.yaml's autorest output elsewhere, from the trees
		if f := tspOutput(base, commit, directory, kind, ver); f != "" {
			return []string{f}
		}
		tree := lsTree(commit, directory)
		var cands []string
		for _, f := range tree {
			if !strings.Contains(f, "/examples/") && strings.HasSuffix(f, ".json") && strings.Contains(f, "/"+kind+"/"+ver+"/") {
				cands = append(cands, f)
			}
		}
		if len(cands) == 1 {
			return cands
		}
		var info []fileInfo
		for _, f := range cands {
			b, err := exec.Command("git", "-C", filepath.Join(specs, ".store"), "show", commit+":"+f).Output()
			if err != nil {
				continue
			}
			info = append(info, fileInfo{f, pathsOf(b)})
		}
		if picked, ok := cover(info, used); ok && len(picked) > 0 {
			return picked
		}
		problem("%s: no openapi for %s %s", rel, kind, ver)
		return nil
	}
	var info []fileInfo
	for _, g := range got {
		rp, _ := filepath.Rel(base, g)
		info = append(info, fileInfo{filepath.ToSlash(rp), pathsOf([]byte(read(g)))})
	}
	if latest {
		// the files with Go's requests at this version, and those with no
		// requests (definitions only); a file whose requests Go takes
		// from another version is left out (armmonitor's 2026-01-01
		// activityLogAlerts_API.json: Go's ActivityLogAlertsClient is
		// 2023-01-01-preview's)
		if picked, ok := cover(info, used); ok && len(picked) > 0 {
			keep := map[string]bool{}
			for _, f := range picked {
				keep[f] = true
			}
			var kept []fileInfo
			for _, f := range info {
				if len(f.paths) == 0 || keep[f.name] {
					kept = append(kept, f)
				}
			}
			info = kept
		}
		sort.SliceStable(info, func(i, j int) bool {
			a, b := len(info[i].paths) > 0, len(info[j].paths) > 0
			if a != b {
				return !a
			}
			return info[i].name < info[j].name
		})
		var out []string
		for _, f := range info {
			out = append(out, f.name)
		}
		return out
	}
	picked, ok := cover(info, used)
	if !ok {
		problem("%s: %s paths not in any file", rel, ver)
	}
	return picked
}

type fileInfo struct {
	name  string
	paths map[string]bool
}

func pathsOf(b []byte) map[string]bool {
	var doc struct {
		Paths map[string]json.RawMessage `json:"paths"`
	}
	_ = json.Unmarshal(b, &doc)
	out := map[string]bool{}
	for k := range doc.Paths {
		out[normPath(k)] = true
	}
	return out
}

// cover: the fewest files (greedy: the most of Go's paths, then the
// fewest paths, then the name) holding every path in need.
func cover(info []fileInfo, used map[string]bool) ([]string, bool) {
	need := map[string]bool{}
	for k := range used {
		need[k] = true
	}
	var picked []string
	for len(need) > 0 && len(info) > 0 {
		best, bestHit := -1, 0
		for i, f := range info {
			hit := 0
			for p := range f.paths {
				if need[p] {
					hit++
				}
			}
			if best < 0 || hit > bestHit || hit == bestHit && (len(f.paths) < len(info[best].paths) || len(f.paths) == len(info[best].paths) && f.name > info[best].name) {
				best, bestHit = i, hit
			}
		}
		if bestHit == 0 {
			return picked, false
		}
		picked = append(picked, info[best].name)
		for p := range info[best].paths {
			delete(need, p)
		}
	}
	return picked, len(need) == 0
}

var trees = map[string][]string{}

// projectOf is Go's TypeSpec folder when the commit has it; a stale
// tsp-location (the project moved in the same commit, as frontdoor's and
// networkfunction's) gives way to the nearest folder above the OpenAPI
// file with a tspconfig.yaml.
func projectOf(commit, directory, openapi string) string {
	tree := lsTree(commit, directory)
	has := map[string]bool{}
	for _, f := range tree {
		has[f] = true
		if strings.HasPrefix(f, directory+"/") {
			return directory
		}
	}
	for d := path.Dir(openapi); strings.Count(d, "/") > 1; d = path.Dir(d) {
		if has[d+"/tspconfig.yaml"] {
			return d
		}
	}
	return directory
}

func lsTree(commit, directory string) []string {
	svc := strings.Split(directory, "/")[1]
	key := commit + " " + svc
	if t, ok := trees[key]; ok {
		return t
	}
	b, _ := exec.Command("git", "-C", filepath.Join(specs, ".store"), "ls-tree", "-r", "--name-only", commit, "--", "specification/"+svc).Output()
	trees[key] = strings.Split(string(b), "\n")
	return trees[key]
}

func tspOutput(base, commit, directory, kind, ver string) string {
	text := read(filepath.Join(base, directory, "tspconfig.yaml"))
	if text == "" {
		return ""
	}
	parts := strings.Split(text, `"@azure-tools/typespec-autorest":`)
	sect := parts[len(parts)-1]
	opt := func(k string) string {
		re := regexp.MustCompile(`(?m)^\s+` + regexp.QuoteMeta(k) + `:\s*"?([^"\n]+)"?`)
		return strings.TrimSpace(first(re, sect))
	}
	outdir := opt("emitter-output-dir")
	if outdir == "" {
		outdir = "{output-dir}"
	}
	outdir = strings.ReplaceAll(outdir, "{project-root}", directory)
	of := opt("output-file")
	if of == "" {
		of = "{version-status}/{version}/openapi.json"
	}
	rp := opt("azure-resource-provider-folder")
	if rp == "" {
		rp = "resource-manager"
	}
	of = strings.NewReplacer("{azure-resource-provider-folder}", rp, "{service-name}", "*", "{version-status}", kind, "{version}", ver).Replace(of)
	pat := path.Clean(outdir + "/" + of)
	var hits []string
	for _, f := range lsTree(commit, directory) {
		if ok, _ := path.Match(pat, f); ok {
			hits = append(hits, f)
		}
	}
	if len(hits) == 1 {
		return hits[0]
	}
	return ""
}

func format(r row) string {
	q := func(k, v string) string { return fmt.Sprintf("%s = %q", k, v) }
	out := []string{"[[service]]", q("dir", r.Dir), q("spec", r.Spec)}
	if r.ReadmeTag != "" {
		out = append(out, q("readme_tag", r.ReadmeTag))
	}
	if r.OpenAPI != "" {
		out = append(out, q("openapi", r.OpenAPI))
	}
	if len(r.OpenAPIMore) > 0 {
		var qs []string
		for _, m := range r.OpenAPIMore {
			qs = append(qs, fmt.Sprintf("%q", m))
		}
		out = append(out, "openapi_more = ["+strings.Join(qs, ", ")+"]")
	}
	out = append(out, q("commit", r.Commit), q("go_module", r.GoModule), q("go_version", r.GoVersion))
	if r.UTC {
		out = append(out, "utc_date_times = true")
	}
	out = append(out, q("version", "v0.1.0"))
	if r.Seal {
		out = append(out, "seal_single_value_enums = true")
	}
	if r.AcceptAll && r.OpenAPI != "" {
		out = append(out, "accept_always = true")
	}
	if r.QueryPlus && r.OpenAPI != "" {
		out = append(out, "query_plus = true")
	}
	return strings.Join(out, "\n")
}
