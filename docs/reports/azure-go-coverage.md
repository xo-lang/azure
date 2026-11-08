# Azure Go module coverage

What Go's `github.com/Azure/azure-sdk-for-go/sdk/...` modules exist (as of
2026-11-06), the latest release of each, and what this repo ports.

## Method

- Module paths: the Go module of every `readme.go.md` and every
  `tspconfig.yaml` (`@azure-tools/typespec-go`) in
  Azure/azure-rest-api-specs, plus a probe list of hand-written module
  paths, plus every `sdk/...` module a found module's latest `go.mod`
  requires. Each major version (`/v2`, `/v3`, ...) is probed until the
  proxy answers 404.
- Versions: proxy.golang.org `@v/list`. A family's row is its highest
  major with a release without a prerelease suffix (else its highest
  major); "newer" names a later prerelease major. `v0` is a release
  below v1.0.0; "deprecated" means the go.mod says `Deprecated`.
- Lines: newline count of the latest version's proxy zip `.go` files,
  without `_test.go`, `fake/`, `testdata/`, `internal/generated/`,
  `zz_*` files and files whose header says `Code generated`. "Go lines"
  counts every non-test `.go` file. Our lines count non-test `.xo`
  files; "gen" is what codegen wrote.
- Popularity: empty. Go publishes no download counts; pkg.go.dev's
  "Imported by" is not an approved source yet (the lead is asking the
  owner).
- Limit: a hand-written data-plane module that is neither in the specs
  repo, nor in the probe list, nor required by a found module is
  missing here. A full list needs a read of the azure-sdk-for-go tree
  (not an approved source yet) or a full index.golang.org scan (about
  17,000 requests at its current rate).

Found: 40 data-plane and support families and 308 ARM families.

## Data plane and support modules

| Go module | latest | kind | Go hand-written lines | Go lines | our port | our lines (hand + generated) | popularity |
|---|---|---|---:|---:|---|---|---|
| ai/azopenai | v0.9.0 | v0 | 284 | 3931 | v0.9.0 Azure types (no openai-go) | 315 + 952 gen |  |
| ai/azopenaiassistants | v0.4.0 | v0, deprecated | 1546 | 13412 | missing |  |  |
| ai/azopenaiextensions | v0.2.0 | v0, deprecated | 290 | 3840 | missing |  |  |
| azcore | v1.24.0 | stable | 8168 | 9190 | v1.24.0 | 2686 |  |
| azidentity | v1.15.0 | stable | 4100 | 4100 | partial | 638 |  |
| azidentity/cache | v0.4.0 | v0 | 595 | 595 | missing |  |  |
| batch/azbatch | v0.1.0 | v0 | 66 | 24575 | v0.1.0 | 64 + 9385 gen |  |
| cognitiveservices/azopenai | v0.1.2 | v0, deprecated | 619 | 3309 | missing |  |  |
| containers/azcontainerregistry | v0.2.3 | v0 | 680 | 3753 | v0.2.3 | 454 + 1471 gen |  |
| data/azappconfig | v2.3.0 (`v2`) | stable | 1972 | 5620 | v2.3.0 | 875 + 1870 gen |  |
| data/azcosmos | v1.5.0 | stable | 12599 | 12687 | v1.5.0 | 3377 |  |
| data/aztables | v1.4.1 | stable | 3409 | 5762 | v1.4.1 | 1346 |  |
| internal | v1.13.0 | stable | 6041 | 6200 | n/a (support module) |  |  |
| keyvault/azcertificates | v0.9.0 | v0, deprecated | 115 | 3929 | missing |  |  |
| keyvault/azkeys | v0.10.0 | v0, deprecated | 85 | 3518 | missing |  |  |
| keyvault/azsecrets | v0.12.0 | v0, deprecated | 85 | 1699 | missing |  |  |
| keyvault/internal | v0.7.1 | v0 | 310 | 310 | n/a (support module) |  |  |
| messaging/azeventhubs | v2.0.2 (`v2`) | stable | 8706 | 10048 | v2.0.2 | 2115 |  |
| messaging/azservicebus | v1.11.0 | stable | 12824 | 14135 | v1.11.0 | 2915 |  |
| messaging/azwebpubsub | v0.1.1 | v0 | 332 | 2071 | v0.1.1 | 218 + 1058 gen |  |
| messaging/eventgrid/azeventgrid | v1.0.0 | stable | 127 | 574 | v1.0.0 | 132 |  |
| messaging/eventgrid/aznamespaces | v1.0.0 | stable | 537 | 1939 | v1.0.0 | 345 |  |
| messaging/eventgrid/azsystemevents | v1.1.0 | stable | 878 | 19101 | v1.1.0 | 243 + 5263 gen |  |
| monitor/azingest | v0.1.2 | v0, deprecated | 95 | 208 | missing |  |  |
| monitor/azquery | v1.2.0 | stable | 255 | 2257 | v1.2.0 | 918 |  |
| monitor/ingestion/azlogs | v1.1.0 | stable | 81 | 372 | v1.1.0 | 138 |  |
| monitor/query/azlogs | v1.2.0 | stable | 180 | 1328 | v1.2.0 | 570 |  |
| monitor/query/azmetrics | v1.3.0 | stable | 90 | 1258 | v1.3.0 | 232 |  |
| security/keyvault/azadmin | v1.5.0 | stable | 484 | 4314 | v1.5.0 | 151 + 1000 gen |  |
| security/keyvault/azcertificates | v1.5.0 | stable | 114 | 5411 | v1.5.0 | 79 + 1827 gen |  |
| security/keyvault/azkeys | v1.5.0 | stable | 84 | 5135 | v1.5.0 | 50 + 1574 gen |  |
| security/keyvault/azsecrets | v1.5.1 | stable | 84 | 2376 | v1.5.1 | 50 + 662 gen |  |
| security/keyvault/internal | v1.2.0 | stable | 259 | 259 | yes | 185 |  |
| storage/azblob | v1.8.3 | stable | 14774 | 30535 | v1.8.3 | 3645 |  |
| storage/azdatalake | v1.7.1 | stable | 10622 | 16543 | v1.7.1 | 2986 |  |
| storage/azfile | v1.7.2 | stable | 8078 | 18464 | v1.7.2 | 3132 |  |
| storage/azqueue | v2.1.2 (`v2`) | stable | 3277 | 6066 | v2.1.2 | 1305 |  |
| storage/internal | v0.1.0 | v0 | 989 | 989 | n/a (support module) |  |  |
| template/aztemplate | v0.6.6 | v0 | 138 | 190 | n/a (sample) |  |  |
| tracing/azotel | v0.4.0 | v0 | 123 | 123 | missing |  |  |

### Drift refresh (2026-11-07)

Every ported data-plane module's Go vector programs were run again
against its latest Go release with azcore v1.24.0, each next to the
build its vectors came from: azfile v1.7.2 (8 programs; the vectors
were from v1.7.1), azqueue v2.1.2, azcore's runtime, poller, resume
token, API version and cloud event programs, azbatch, azcontainerregistry,
azeventgrid, aznamespaces, azwebpubsub, and a sweep of 53 more over azappconfig,
azservicebus, azmonitor's azlogs and azmetrics, azblob, azdatalake,
azcosmos, aztables, azadmin, azsecrets, azsystemevents and azidentity.
No output changed. The only differences between the two builds are the
ones between two runs of the same build (dates and the signatures over
them, loopback ports, panic addresses, Cosmos DB's asynchronous account
reads after a failover). The re-run vector files say so in their
headers. azqueue/v2's newest tag is v2.2.0-beta.1, a beta, so v2.1.2
stays.

## ARM modules: Go-verified (307)

All ARM code is generated, in Go and here. Generated by
codegen/cmd/coverage from the repository: a module is ported once its
Go vectors pass (every call of every client against Go's own requests
and results).

| Go module | latest | kind | Go lines | our port | our lines | status |
|---|---|---|---:|---|---:|---|
| resourcemanager/aad/armaad | v1.2.0 | stable | 3026 | v1.2.0 | 801 gen | Go-verified |
| resourcemanager/addons/armaddons | v0.3.0 | v0 | 1470 | v0.3.0 | 367 gen | Go-verified |
| resourcemanager/advisor/armadvisor | v1.2.0 | stable; newer v2.0.0-beta.1 | 4070 | v1.2.0 | 1005 gen | Go-verified |
| resourcemanager/agricultureplatform/armagricultureplatform | v0.1.0 | v0 | 3050 | v0.1.0 | 851 gen | Go-verified |
| resourcemanager/agrifood/armagrifood | v0.9.0 | v0 | 6173 | v0.9.0 | 1770 gen | Go-verified |
| resourcemanager/aigateway/armaigateway | v0.1.0 | v0 | 2342 | v0.1.0 | 607 gen | Go-verified |
| resourcemanager/aiinfraoptimization/armaiinfraoptimization | v0.1.0 | v0 | 2614 | v0.1.0 | 658 gen | Go-verified |
| resourcemanager/alertprocessingrules/armalertprocessingrules | v0.1.0 | v0 | 2201 | v0.1.0 | 734 gen | Go-verified |
| resourcemanager/alertrulerecommendations/armalertrulerecommendations | v0.1.0 | v0 | 938 | v0.1.0 | 169 gen | Go-verified |
| resourcemanager/alertsmanagement/armalertsmanagement | v0.11.0 | v0 | 5061 | v0.11.0 | 1765 gen | Go-verified |
| resourcemanager/analysisservices/armanalysisservices | v1.2.0 | stable | 4034 | v1.2.0 | 1204 gen | Go-verified |
| resourcemanager/apicenter/armapicenter | v1.0.0 | stable | 10258 | v1.0.0 | 3257 gen | Go-verified |
| resourcemanager/apimanagement/armapimanagement | v3.0.0 | stable; newer v4.0.0-beta.1 | 138430 | v3.0.0 | 42702 gen | Go-verified |
| resourcemanager/appcomplianceautomation/armappcomplianceautomation | v1.0.0 | stable | 9725 | v1.0.0 | 2995 gen | Go-verified |
| resourcemanager/appconfiguration/armappconfiguration | v3.0.0 | stable | 7836 | v3.0.0 | 2322 gen | Go-verified |
| resourcemanager/appcontainers/armappcontainers | v5.0.0 | stable | 46587 | v5.0.0 | 13762 gen | Go-verified |
| resourcemanager/applicationinsights/armapplicationinsights | v1.2.0 | stable; newer v2.0.0-beta.4 | 14156 | v1.2.0 | 4199 gen | Go-verified |
| resourcemanager/appnetwork/armappnetwork | v0.2.0 | v0 | 4836 | v0.2.0 | 1216 gen | Go-verified |
| resourcemanager/appplatform/armappplatform | v2.0.1 | stable, deprecated | 41028 | v2.0.1 | 12685 gen | Go-verified |
| resourcemanager/appservice/armappservice | v6.0.0 | stable | 133180 | v6.0.0 | 43893 gen | Go-verified |
| resourcemanager/arizeaiobservabilityeval/armarizeaiobservabilityeval | v1.0.0 | stable | 2438 | v1.0.0 | 640 gen | Go-verified |
| resourcemanager/artifactsigning/armartifactsigning | v0.2.0 | v0 | 3574 | v0.2.0 | 999 gen | Go-verified |
| resourcemanager/attestation/armattestation | v2.0.0 | stable | 3758 | v2.0.0 | 1005 gen | Go-verified |
| resourcemanager/authorization/armauthorization | v2.2.0 (`v2`) | stable; newer v3.0.0-beta.3 | 14114 | v2.2.0 | 3819 gen | Go-verified |
| resourcemanager/automanage/armautomanage | v1.2.0 | stable | 7672 | v1.2.0 | 2136 gen | Go-verified |
| resourcemanager/automation/armautomation | v1.0.0 | stable | 43252 | v1.0.0 | 13247 gen | Go-verified |
| resourcemanager/avs/armavs | v2.3.0 | stable | 32673 | v2.3.0 | 11151 gen | Go-verified |
| resourcemanager/azurearcdata/armazurearcdata | v0.7.0 | v0 | 7935 | v0.7.0 | 2614 gen | Go-verified |
| resourcemanager/azuredata/armazuredata | v0.7.0 | v0 | 3448 | v0.7.0 | 887 gen | Go-verified |
| resourcemanager/azurestackhci/armazurestackhci | v3.2.0 | stable | 41810 | v3.2.0 | 12924 gen | Go-verified |
| resourcemanager/azurestackhci/armazurestackhcivm | v0.1.0 | v0 | 17245 | v0.1.0 | 4763 gen | Go-verified |
| resourcemanager/baremetalinfrastructure/armbaremetalinfrastructure | v1.2.0 | stable; newer v2.0.0-beta.1 | 2329 | v1.2.0 | 534 gen | Go-verified |
| resourcemanager/batch/armbatch | v4.0.0 | stable | 15328 | v4.0.0 | 4352 gen | Go-verified |
| resourcemanager/billing/armbilling | v2.0.0 | stable | 48871 | v2.0.0 | 16202 gen | Go-verified |
| resourcemanager/billingbenefits/armbillingbenefits | v2.1.0 | stable; newer v3.0.0-beta.1 | 5603 | v2.1.0 | 1553 gen | Go-verified |
| resourcemanager/billingtrust/armbillingtrust | v0.1.0 | v0 | 3679 | v0.1.0 | 1114 gen | Go-verified |
| resourcemanager/blueprint/armblueprint | v0.7.0 | v0 | 6329 | v0.7.0 | 1646 gen | Go-verified |
| resourcemanager/botservice/armbotservice | v1.2.0 | stable; newer v2.0.0-beta.1 | 11291 | v1.2.0 | 3621 gen | Go-verified |
| resourcemanager/carbonoptimization/armcarbonoptimization | v1.0.0 | stable | 3373 | v1.0.0 | 1512 gen | Go-verified |
| resourcemanager/cdn/armcdn | v4.0.0 | stable | 37094 | v4.0.0 | 12176 gen | Go-verified |
| resourcemanager/certificateregistration/armcertificateregistration | v1.0.0 | stable | 6273 | v1.0.0 | 1877 gen | Go-verified |
| resourcemanager/chaos/armchaos | v2.0.0 | stable; newer v3.0.0-beta.1 | 7722 | v2.0.0 | 2317 gen | Go-verified |
| resourcemanager/cloudhealth/armcloudhealth | v1.0.0 | stable | 10855 | v1.0.0 | 3450 gen | Go-verified |
| resourcemanager/cognitiveservices/armcognitiveservices | v3.0.0 | stable; newer v4.0.0-beta.5 | 29917 | v3.0.0 | 9094 gen | Go-verified |
| resourcemanager/commerce/armcommerce | v0.4.0 | v0 | 1546 | v0.4.0 | 420 gen | Go-verified |
| resourcemanager/communication/armcommunication | v3.0.0 | stable | 9312 | v3.0.0 | 2810 gen | Go-verified |
| resourcemanager/commvaultcontentstore/armcommvaultcontentstore | v1.0.0 | stable | 9967 | v1.0.0 | 3013 gen | Go-verified |
| resourcemanager/compute/armbulkactions | v0.7.0 | v0 | 17902 | v0.7.0 | 5050 gen | Go-verified |
| resourcemanager/compute/armcompute | v9.0.0 (`v9`) | stable | 85961 | v9.0.0 | 30813 gen | Go-verified |
| resourcemanager/compute/armrecommender | v0.4.0 | v0 | 3135 | v0.4.0 | 797 gen | Go-verified |
| resourcemanager/compute/armworkloadmanager | v0.1.0 | v0 | 5592 | v0.1.0 | 1733 gen | Go-verified |
| resourcemanager/computebulkactions/armcomputebulkactions | v0.1.0 | v0 | 9754 | v0.1.0 | 2765 gen | Go-verified |
| resourcemanager/computefleet/armcomputefleet | v2.0.0 | stable | 7767 | v2.0.0 | 3555 gen | Go-verified |
| resourcemanager/computelimit/armcomputelimit | v1.3.0 | stable | 6335 | v1.3.0 | 1740 gen | Go-verified |
| resourcemanager/computeschedule/armcomputeschedule | v1.1.0 | stable; newer v2.0.0-beta.1 | 3753 | v1.1.0 | 963 gen | Go-verified |
| resourcemanager/confidentialledger/armconfidentialledger | v1.2.0 | stable | 2464 | v1.2.0 | 643 gen | Go-verified |
| resourcemanager/confluent/armconfluent | v1.3.0 | stable; newer v2.0.0-beta.2 | 8770 | v1.3.0 | 2324 gen | Go-verified |
| resourcemanager/connectedcache/armconnectedcache | v1.0.0 | stable | 8297 | v1.0.0 | 2425 gen | Go-verified |
| resourcemanager/connectedvmware/armconnectedvmware | v1.1.1 | stable | 15051 | v1.1.1 | 4469 gen | Go-verified |
| resourcemanager/consumption/armconsumption | v2.1.0 | stable | 15639 | v2.1.0 | 4707 gen | Go-verified |
| resourcemanager/containerinstance/armcontainerinstance | v2.4.0 | stable; newer v3.0.0-beta.1 | 6575 | v2.4.0 | 1677 gen | Go-verified |
| resourcemanager/containerorchestratorruntime/armcontainerorchestratorruntime | v0.1.0 | v0 | 4969 | v0.1.0 | 1425 gen | Go-verified |
| resourcemanager/containerregistry/armcontainerregistry | v3.0.0 (`v3`) | stable | 15726 | v3.0.0 | 4866 gen | Go-verified |
| resourcemanager/containerregistry/armcontainerregistrytasks | v0.1.0 | v0 | 8803 | v0.1.0 | 3016 gen | Go-verified |
| resourcemanager/containerservice/armcontainerservice | v9.7.0 (`v9`) | stable | 24355 | v9.7.0 | 6919 gen | Go-verified |
| resourcemanager/containerservice/armdeploymentsafeguards | v0.1.0 | v0 | 1696 | v0.1.0 | 379 gen | Go-verified |
| resourcemanager/containerserviceaimanager/armcontainerserviceaimanager | v0.2.0 | v0 | 8193 | v0.2.0 | 2359 gen | Go-verified |
| resourcemanager/containerservicefleet/armcontainerservicefleet | v3.0.0 | stable | 11768 | v3.0.0 | 3446 gen | Go-verified |
| resourcemanager/containerservicepreparedimgspec/armcontainerservicepreparedimgspec | v0.1.0 | v0 | 2636 | v0.1.0 | 726 gen | Go-verified |
| resourcemanager/cosmos/armcosmos | v4.0.0 (`v4`) | stable | 59620 | v4.0.0 | 18216 gen | Go-verified |
| resourcemanager/cosmosforpostgresql/armcosmosforpostgresql | v1.1.0 | stable | 8480 | v1.1.0 | 2508 gen | Go-verified |
| resourcemanager/costmanagement/armcostmanagement | v3.0.0 | stable | 21160 | v3.0.0 | 6371 gen | Go-verified |
| resourcemanager/customerinsights/armcustomerinsights | v1.2.0 | stable | 17628 | v1.2.0 | 5089 gen | Go-verified |
| resourcemanager/customerlockbox/armcustomerlockbox | v0.7.0 | v0 | 2098 | v0.7.0 | 447 gen | Go-verified |
| resourcemanager/customproviders/armcustomproviders | v0.7.0 | v0 | 2798 | v0.7.0 | 701 gen | Go-verified |
| resourcemanager/dashboard/armdashboard | v2.0.0 | stable | 8422 | v2.0.0 | 2617 gen | Go-verified |
| resourcemanager/databasewatcher/armdatabasewatcher | v0.1.0 | v0 | 6425 | v0.1.0 | 1989 gen | Go-verified |
| resourcemanager/databoundaries/armdataboundaries | v1.0.0 | stable | 1406 | v1.0.0 | 336 gen | Go-verified |
| resourcemanager/databox/armdatabox | v3.0.0 | stable | 12255 | v3.0.0 | 5040 gen | Go-verified |
| resourcemanager/databoxedge/armdataboxedge | v2.0.0 | stable | 24246 | v2.0.0 | 7289 gen | Go-verified |
| resourcemanager/databricks/armdatabricks | v2.0.0 | stable | 7476 | v2.0.0 | 2092 gen | Go-verified |
| resourcemanager/datacatalog/armdatacatalog | v1.2.0 | stable | 1606 | v1.2.0 | 398 gen | Go-verified |
| resourcemanager/datadog/armdatadog | v1.3.0 | stable; newer v2.0.0-beta.1 | 7296 | v1.3.0 | 1970 gen | Go-verified |
| resourcemanager/datafactory/armdatafactory | v11.0.0 | stable | 113310 | v11.0.0 | 50727 gen | Go-verified |
| resourcemanager/datalake-analytics/armdatalakeanalytics | v0.8.0 | v0 | 9341 | v0.8.0 | 2554 gen | Go-verified |
| resourcemanager/datalake-store/armdatalakestore | v1.2.0 | stable | 7289 | v1.2.0 | 2030 gen | Go-verified |
| resourcemanager/datamigration/armdatamigration | v2.0.0 | stable; newer v3.0.0-beta.1 | 39403 | v2.0.0 | 15292 gen | Go-verified |
| resourcemanager/dataprotection/armdataprotection | v4.2.0 | stable | 24139 | v4.2.0 | 8068 gen | Go-verified |
| resourcemanager/datashare/armdatashare | v1.2.0 | stable | 17615 | v1.2.0 | 5882 gen | Go-verified |
| resourcemanager/datatransfer/armdatatransfer | v0.1.0 | v0 | 12480 | v0.1.0 | 4132 gen | Go-verified |
| resourcemanager/delegatednetwork/armdelegatednetwork | v1.2.0 | stable | 4648 | v1.2.0 | 1253 gen | Go-verified |
| resourcemanager/dell/armdellstorage | v1.0.0 | stable | 2674 | v1.0.0 | 724 gen | Go-verified |
| resourcemanager/dependencymap/armdependencymap | v0.1.0 | v0 | 4163 | v0.1.0 | 1122 gen | Go-verified |
| resourcemanager/desktopvirtualization/armdesktopvirtualization | v2.3.0 | stable | 20959 | v2.3.0 | 6766 gen | Go-verified |
| resourcemanager/devcenter/armdevcenter | v2.0.0 | stable; newer v3.0.0-beta.1 | 23363 | v2.0.0 | 7007 gen | Go-verified |
| resourcemanager/devhub/armdevhub | v0.7.0 | v0 | 7914 | v0.7.0 | 2222 gen | Go-verified |
| resourcemanager/deviceprovisioningservices/armdeviceprovisioningservices | v1.4.0 | stable | 6150 | v1.4.0 | 1861 gen | Go-verified |
| resourcemanager/deviceregistry/armdeviceregistry | v2.0.0 | stable | 17963 | v2.0.0 | 5317 gen | Go-verified |
| resourcemanager/deviceupdate/armdeviceupdate | v1.3.0 | stable | 7421 | v1.3.0 | 2072 gen | Go-verified |
| resourcemanager/devops/armdevops | v0.7.0 | v0 | 2395 | v0.7.0 | 581 gen | Go-verified |
| resourcemanager/devopsinfrastructure/armdevopsinfrastructure | v1.0.0 | stable | 5571 | v1.0.0 | 1619 gen | Go-verified |
| resourcemanager/devtestlabs/armdevtestlabs | v1.2.0 | stable | 31727 | v1.2.0 | 9545 gen | Go-verified |
| resourcemanager/digitaltwins/armdigitaltwins | v1.2.0 | stable | 6613 | v1.2.0 | 2116 gen | Go-verified |
| resourcemanager/disconnectedoperations/armdisconnectedoperations | v1.0.0 | stable | 4698 | v1.0.0 | 1433 gen | Go-verified |
| resourcemanager/discovery/armdiscovery | v0.1.0 | v0 | 14007 | v0.1.0 | 4295 gen | Go-verified |
| resourcemanager/dns/armdns | v1.2.0 | stable | 3889 | v1.2.0 | 1033 gen | Go-verified |
| resourcemanager/dnsresolver/armdnsresolver | v1.3.0 | stable; newer v2.0.0-beta.1 | 13369 | v1.3.0 | 3914 gen | Go-verified |
| resourcemanager/domainregistration/armdomainregistration | v1.0.0 | stable | 5217 | v1.0.0 | 1584 gen | Go-verified |
| resourcemanager/domainservices/armdomainservices | v1.2.0 | stable; newer v2.0.0-beta.1 | 4483 | v1.2.0 | 1147 gen | Go-verified |
| resourcemanager/durabletask/armdurabletask | v1.1.0 | stable | 5483 | v1.1.0 | 1541 gen | Go-verified |
| resourcemanager/dynatrace/armdynatrace | v2.2.0 | stable | 8236 | v2.2.0 | 2422 gen | Go-verified |
| resourcemanager/edgeactions/armedgeactions | v1.0.0 | stable | 4597 | v1.0.0 | 1253 gen | Go-verified |
| resourcemanager/edgemarketplace/armedgemarketplace | v0.1.1 | v0 | 3279 | v0.1.1 | 770 gen | Go-verified |
| resourcemanager/edgeoperator/armedgeoperator | v0.1.0 | v0 | 1186 | v0.1.0 | 229 gen | Go-verified |
| resourcemanager/edgeorder/armedgeorder | v2.0.0 | stable | 9371 | v2.0.0 | 3086 gen | Go-verified |
| resourcemanager/edgeorderpartner/armedgeorderpartner | v0.7.0 | v0 | 2408 | v0.7.0 | 543 gen | Go-verified |
| resourcemanager/edgezones/armedgezones | v1.0.0 | stable | 1611 | v1.0.0 | 396 gen | Go-verified |
| resourcemanager/education/armeducation | v0.5.0 | v0 | 5172 | v0.5.0 | 1431 gen | Go-verified |
| resourcemanager/elastic/armelastic | v3.0.0 | stable | 12444 | v3.0.0 | 3304 gen | Go-verified |
| resourcemanager/elasticsan/armelasticsan | v1.2.0 | stable; newer v2.0.0-beta.1 | 8383 | v1.2.0 | 2512 gen | Go-verified |
| resourcemanager/enclave/armenclave | v1.0.0 | stable | 15765 | v1.0.0 | 4650 gen | Go-verified |
| resourcemanager/engagementfabric/armengagementfabric | v0.3.0 | v0 | 3729 | v0.3.0 | 976 gen | Go-verified |
| resourcemanager/eventgrid/armeventgrid | v2.3.0 | stable | 42025 | v2.3.0 | 13728 gen | Go-verified |
| resourcemanager/eventhub/armeventhub | v1.3.0 | stable; newer v2.0.0-beta.1 | 15366 | v1.3.0 | 4593 gen | Go-verified |
| resourcemanager/extendedlocation/armextendedlocation | v1.2.0 | stable; newer v2.0.0-beta.1 | 2623 | v1.2.0 | 707 gen | Go-verified |
| resourcemanager/fabric/armfabric | v1.0.0 | stable | 3129 | v1.0.0 | 850 gen | Go-verified |
| resourcemanager/fileshares/armfileshares | v0.1.0 | v0 | 6027 | v0.1.0 | 1702 gen | Go-verified |
| resourcemanager/fluidrelay/armfluidrelay | v1.2.0 | stable | 3538 | v1.2.0 | 973 gen | Go-verified |
| resourcemanager/frontdoor/armfrontdoor | v2.0.0 | stable | 13019 | v2.0.0 | 3939 gen | Go-verified |
| resourcemanager/graphservices/armgraphservices | v1.1.0 | stable | 1951 | v1.1.0 | 503 gen | Go-verified |
| resourcemanager/guestconfiguration/armguestconfiguration | v2.0.0 | stable | 6226 | v2.0.0 | 1777 gen | Go-verified |
| resourcemanager/hanaonazure/armhanaonazure | v0.8.0 | v0 | 2592 | v0.8.0 | 672 gen | Go-verified |
| resourcemanager/hardwaresecuritymodules/armhardwaresecuritymodules | v3.0.0 | stable | 7090 | v3.0.0 | 1988 gen | Go-verified |
| resourcemanager/hdinsight/armhdinsight | v1.2.0 | stable; newer v2.0.0-beta.1 | 15033 | v1.2.0 | 4166 gen | Go-verified |
| resourcemanager/healthbot/armhealthbot | v2.0.0 | stable | 2503 | v2.0.0 | 733 gen | Go-verified |
| resourcemanager/healthcareapis/armhealthcareapis | v2.1.0 | stable; newer v3.0.0-beta.1 | 12896 | v2.1.0 | 3568 gen | Go-verified |
| resourcemanager/healthdataaiservices/armhealthdataaiservices | v1.0.0 | stable | 3795 | v1.0.0 | 945 gen | Go-verified |
| resourcemanager/horizondb/armhorizondb | v0.3.0 | v0 | 22844 | v0.3.0 | 6600 gen | Go-verified |
| resourcemanager/hybridcompute/armhybridcompute | v3.0.0 | stable | 19145 | v3.0.0 | 5799 gen | Go-verified |
| resourcemanager/hybridconnectivity/armhybridconnectivity | v1.2.0 | stable | 8271 | v1.2.0 | 2167 gen | Go-verified |
| resourcemanager/hybridcontainerservice/armhybridcontainerservice | v1.0.0 | stable | 8441 | v1.0.0 | 2170 gen | Go-verified |
| resourcemanager/hybridkubernetes/armhybridkubernetes | v1.2.0 | stable; newer v2.0.0-beta.2 | 2713 | v1.2.0 | 650 gen | Go-verified |
| resourcemanager/hybridnetwork/armhybridnetwork | v2.0.0 | stable | 20959 | v2.0.0 | 6932 gen | Go-verified |
| resourcemanager/impactreporting/armimpactreporting | v0.2.0 | v0 | 4615 | v0.2.0 | 1232 gen | Go-verified |
| resourcemanager/informaticadatamgmt/arminformaticadatamgmt | v1.0.0 | stable | 5655 | v1.0.0 | 1540 gen | Go-verified |
| resourcemanager/integrationspaces/armintegrationspaces | v0.1.0 | v0 | 8651 | v0.1.0 | 2560 gen | Go-verified |
| resourcemanager/iotcentral/armiotcentral | v1.2.0 | stable; newer v2.0.0-beta.2 | 2567 | v1.2.0 | 733 gen | Go-verified |
| resourcemanager/iotfirmwaredefense/armiotfirmwaredefense | v2.0.0 | stable | 8190 | v2.0.0 | 2437 gen | Go-verified |
| resourcemanager/iothub/armiothub | v1.3.0 | stable; newer v2.0.0-beta.3 | 11167 | v1.3.0 | 3077 gen | Go-verified |
| resourcemanager/iotoperations/armiotoperations | v1.2.0 | stable | 21882 | v1.2.0 | 7033 gen | Go-verified |
| resourcemanager/keyvault/armkeyvault | v2.1.0 (`v2`) | stable | 13812 | v2.1.0 | 3964 gen | Go-verified |
| resourcemanager/kubernetesconfiguration/armextensions | v1.0.0 | stable | 2755 | v1.0.0 | 748 gen | Go-verified |
| resourcemanager/kubernetesconfiguration/armextensiontypes | v0.2.0 | v0 | 2392 | v0.2.0 | 644 gen | Go-verified |
| resourcemanager/kubernetesconfiguration/armfluxconfigurations | v0.1.0 | v0 | 4414 | v0.1.0 | 1163 gen | Go-verified |
| resourcemanager/kubernetesconfiguration/armprivatelinkscopes | v0.2.0 | v0 | 2901 | v0.2.0 | 801 gen | Go-verified |
| resourcemanager/kusto/armkusto | v2.4.0 | stable | 21791 | v2.4.0 | 7489 gen | Go-verified |
| resourcemanager/labservices/armlabservices | v1.2.0 | stable | 11411 | v1.2.0 | 3708 gen | Go-verified |
| resourcemanager/lambdatesthyperexecute/armlambdatesthyperexecute | v1.0.0 | stable | 2440 | v1.0.0 | 640 gen | Go-verified |
| resourcemanager/largeinstance/armlargeinstance | v0.1.0 | v0 | 3962 | v0.1.0 | 1111 gen | Go-verified |
| resourcemanager/liftrqumulo/armqumulo | v2.1.0 | stable | 2238 | v2.1.0 | 672 gen | Go-verified |
| resourcemanager/loadtesting/armloadtesting | v1.2.0 | stable | 3477 | v1.2.0 | 979 gen | Go-verified |
| resourcemanager/logic/armlogic | v1.2.0 | stable | 31522 | v1.2.0 | 9011 gen | Go-verified |
| resourcemanager/m365securityandcompliance/armm365securityandcompliance | v0.7.0 | v0 | 14913 | v0.7.0 | 4317 gen | Go-verified |
| resourcemanager/machinelearning/armmachinelearning | v4.0.0 | stable; newer v5.0.0-beta.1 | 76326 | v4.0.0 | 27565 gen | Go-verified |
| resourcemanager/maintenance/armmaintenance | v1.3.0 | stable; newer v2.0.0-beta.1 | 7536 | v1.3.0 | 2168 gen | Go-verified |
| resourcemanager/managednetwork/armmanagednetwork | v0.3.0 | v0 | 4826 | v0.3.0 | 1273 gen | Go-verified |
| resourcemanager/managednetworkfabric/armmanagednetworkfabric | v2.0.0 | stable | 55337 | v2.0.0 | 16132 gen | Go-verified |
| resourcemanager/managedops/armmanagedops | v0.2.0 | v0 | 2350 | v0.2.0 | 565 gen | Go-verified |
| resourcemanager/managedservices/armmanagedservices | v0.7.0 | v0 | 4082 | v0.7.0 | 953 gen | Go-verified |
| resourcemanager/managementgroups/armmanagementgroups | v2.0.0 | stable | 5619 | v2.0.0 | 1547 gen | Go-verified |
| resourcemanager/managementpartner/armmanagementpartner | v0.7.0 | v0 | 1721 | v0.7.0 | 360 gen | Go-verified |
| resourcemanager/maps/armmaps | v1.1.0 | stable; newer v2.0.0-beta.1 | 4595 | v1.1.0 | 1397 gen | Go-verified |
| resourcemanager/mariadb/armmariadb | v1.2.0 | stable | 15251 | v1.2.0 | 4391 gen | Go-verified |
| resourcemanager/marketplace/armmarketplace | v2.0.0 | stable | 9919 | v2.0.0 | 2744 gen | Go-verified |
| resourcemanager/marketplaceordering/armmarketplaceordering | v1.2.0 | stable | 2026 | v1.2.0 | 484 gen | Go-verified |
| resourcemanager/migrate/armmigrate | v1.2.0 | stable | 12313 | v1.2.0 | 3803 gen | Go-verified |
| resourcemanager/migrationassessment/armmigrationassessment | v0.1.0 | v0 | 48178 | v0.1.0 | 14317 gen | Go-verified |
| resourcemanager/migrationdiscovery/armmigrationdiscoverysap | v0.1.0 | v0 | 5132 | v0.1.0 | 1718 gen | Go-verified |
| resourcemanager/mongocluster/armmongocluster | v1.2.0 | stable | 7396 | v1.2.0 | 2360 gen | Go-verified |
| resourcemanager/mongodbatlas/armmongodbatlas | v1.0.0 | stable | 2427 | v1.0.0 | 694 gen | Go-verified |
| resourcemanager/monitor/armmonitor | v0.14.0 | v0 | 35278 | v0.14.0 | 10793 gen | Go-verified |
| resourcemanager/monitor/armmonitorworkspaces | v1.0.0 | stable | 6119 | v1.0.0 | 2028 gen | Go-verified |
| resourcemanager/monitor/armslis | v0.2.0 | v0 | 2067 | v0.2.0 | 802 gen | Go-verified |
| resourcemanager/msi/armmsi | v1.3.0 | stable | 3108 | v1.3.0 | 846 gen | Go-verified |
| resourcemanager/mysql/armmysqlflexibleservers | v2.0.0 | stable | 18146 | v2.0.0 | 5440 gen | Go-verified |
| resourcemanager/napsteromniagentapi/armnapsteromniagentapi | v0.1.0 | v0 | 3074 | v0.1.0 | 841 gen | Go-verified |
| resourcemanager/netapp/armnetapp | v11.0.0 | stable | 33878 | v11.0.0 | 10842 gen | Go-verified |
| resourcemanager/network/armnetwork | v12.1.0 (`v12`) | stable | 208724 | v12.1.0 | 61668 gen | Go-verified |
| resourcemanager/networkcloud/armnetworkcloud | v2.0.0 | stable | 41194 | v2.0.0 | 12981 gen | Go-verified |
| resourcemanager/networkfunction/armnetworkfunction | v3.0.0 | stable | 3383 | v3.0.0 | 868 gen | Go-verified |
| resourcemanager/networksecurity/armnetworksecurity | v0.1.0 | v0 | 6867 | v0.1.0 | 1919 gen | Go-verified |
| resourcemanager/newrelic/armnewrelicobservability | v2.0.0 | stable | 9937 | v2.0.0 | 3000 gen | Go-verified |
| resourcemanager/nginx/armnginx | v4.0.0 | stable | 8295 | v4.0.0 | 2365 gen | Go-verified |
| resourcemanager/notificationhubs/armnotificationhubs | v1.2.0 | stable; newer v2.0.0-beta.2 | 6633 | v1.2.0 | 2265 gen | Go-verified |
| resourcemanager/oep/armoep | v0.6.0 | v0 | 3137 | v0.6.0 | 783 gen | Go-verified |
| resourcemanager/onlineexperimentation/armonlineexperimentation | v0.1.0 | v0 | 2368 | v0.1.0 | 730 gen | Go-verified |
| resourcemanager/operationalinsights/armoperationalinsights | v3.0.0 | stable | 20877 | v3.0.0 | 6750 gen | Go-verified |
| resourcemanager/operationsmanagement/armoperationsmanagement | v0.8.0 | v0 | 3312 | v0.8.0 | 907 gen | Go-verified |
| resourcemanager/oracledatabase/armoracledatabase | v3.0.0 | stable | 40551 | v3.0.0 | 13409 gen | Go-verified |
| resourcemanager/orbital/armorbital | v2.1.0 | stable | 6943 | v2.1.0 | 1753 gen | Go-verified |
| resourcemanager/paloaltonetworksngfw/armpanngfw | v2.0.0 | stable | 20778 | v2.0.0 | 6435 gen | Go-verified |
| resourcemanager/peering/armpeering | v2.0.0 | stable | 12311 | v2.0.0 | 3341 gen | Go-verified |
| resourcemanager/pineconevectordb/armpineconevectordb | v0.1.1 | v0 | 2547 | v0.1.1 | 640 gen | Go-verified |
| resourcemanager/planetarycomputer/armplanetarycomputer | v1.0.0 | stable | 1714 | v1.0.0 | 450 gen | Go-verified |
| resourcemanager/platformvalidation/armplatformvalidation | v0.1.0 | v0 | 7501 | v0.1.0 | 2061 gen | Go-verified |
| resourcemanager/playwright/armplaywright | v1.0.0 | stable | 3465 | v1.0.0 | 878 gen | Go-verified |
| resourcemanager/playwrighttesting/armplaywrighttesting | v1.0.2 | stable, deprecated | 3587 | v1.0.2 | 974 gen | Go-verified |
| resourcemanager/policyinsights/armpolicyinsights | v0.10.0 | v0 | 17449 | v0.10.0 | 5836 gen | Go-verified |
| resourcemanager/portal/armportal | v0.7.0 | v0 | 3208 | v0.7.0 | 885 gen | Go-verified |
| resourcemanager/portalservicescopilot/armportalservicescopilot | v0.1.0 | v0 | 1625 | v0.1.0 | 333 gen | Go-verified |
| resourcemanager/postgresql/armpostgresql | v1.2.0 | stable; newer v2.0.0-20260225001619-0cffc1715e84 | 12920 | v1.2.0 | 3846 gen | Go-verified |
| resourcemanager/postgresql/armpostgresqlflexibleservers | v6.0.0 | stable | 23210 | v6.0.0 | 6968 gen | Go-verified |
| resourcemanager/postgresqlhsc/armpostgresqlhsc | v0.7.0 | v0, deprecated | 9020 | v0.7.0 | 2607 gen | Go-verified |
| resourcemanager/powerbidedicated/armpowerbidedicated | v2.0.0 | stable | 4241 | v2.0.0 | 1248 gen | Go-verified |
| resourcemanager/powerbiembedded/armpowerbiembedded | v1.2.0 | stable | 2783 | v1.2.0 | 735 gen | Go-verified |
| resourcemanager/powerbiprivatelinks/armpowerbiprivatelinks | v2.1.0 | stable | 4270 | v2.1.0 | 1085 gen | Go-verified |
| resourcemanager/powerplatform/armpowerplatform | v0.4.0 | v0 | 4744 | v0.4.0 | 1541 gen | Go-verified |
| resourcemanager/previewalertrule/armpreviewalertrule | v0.1.0 | v0 | 1331 | v0.1.0 | 327 gen | Go-verified |
| resourcemanager/privatedns/armprivatedns | v2.0.0 (`v2`) | stable | 4414 | v2.0.0 | 1245 gen | Go-verified |
| resourcemanager/programenrollment/armprogramenrollment | v0.1.0 | v0 | 2056 | v0.1.0 | 524 gen | Go-verified |
| resourcemanager/programmableconnectivity/armprogrammableconnectivity | v0.1.0 | v0 | 4172 | v0.1.0 | 1111 gen | Go-verified |
| resourcemanager/prometheusrulegroups/armprometheusrulegroups | v0.1.0 | v0 | 1606 | v0.1.0 | 391 gen | Go-verified |
| resourcemanager/providerhub/armproviderhub | v4.0.0 | stable | 20985 | v4.0.0 | 5964 gen | Go-verified |
| resourcemanager/purestorageblock/armpurestorageblock | v1.0.0 | stable | 9932 | v1.0.0 | 2925 gen | Go-verified |
| resourcemanager/purview/armpurview | v1.2.0 | stable; newer v2.0.0-beta.1 | 5709 | v1.2.0 | 1675 gen | Go-verified |
| resourcemanager/quantum/armquantum | v0.8.0 | v0 | 3713 | v0.8.0 | 956 gen | Go-verified |
| resourcemanager/quota/armquota | v2.0.0 | stable | 9830 | v2.0.0 | 2528 gen | Go-verified |
| resourcemanager/recoveryservices/armrecoveryservices | v3.2.1 | stable | 9031 | v3.2.1 | 3245 gen | Go-verified |
| resourcemanager/recoveryservices/armrecoveryservicesbackup | v5.2.0 | stable | 49568 | v5.2.0 | 19537 gen | Go-verified |
| resourcemanager/recoveryservices/armrecoveryservicessiterecovery | v4.0.0 | stable | 70085 | v4.0.0 | 26815 gen | Go-verified |
| resourcemanager/recoveryservicesdatareplication/armrecoveryservicesdatareplication | v1.0.0 | stable | 19089 | v1.0.0 | 6442 gen | Go-verified |
| resourcemanager/redhatopenshift/armredhatopenshift | v2.0.0 | stable | 4367 | v2.0.0 | 1485 gen | Go-verified |
| resourcemanager/redhatopenshifthcp/armredhatopenshifthcp | v1.0.0 | stable | 7987 | v1.0.0 | 2166 gen | Go-verified |
| resourcemanager/redis/armredis | v4.0.0 | stable | 10738 | v4.0.0 | 2787 gen | Go-verified |
| resourcemanager/redisenterprise/armredisenterprise | v4.0.0 | stable | 10920 | v4.0.0 | 3481 gen | Go-verified |
| resourcemanager/relationships/armrelationships | v1.0.0 | stable | 3746 | v1.0.0 | 921 gen | Go-verified |
| resourcemanager/relay/armrelay | v2.1.0 | stable | 8445 | v2.1.0 | 2722 gen | Go-verified |
| resourcemanager/reservations/armreservations | v4.0.0 | stable | 11009 | v4.0.0 | 3159 gen | Go-verified |
| resourcemanager/resiliencemanagement/armresiliencemanagement | v1.0.0 | stable | 22979 | v1.0.0 | 7448 gen | Go-verified |
| resourcemanager/resourceconnector/armresourceconnector | v1.1.0 | stable | 3124 | v1.1.0 | 884 gen | Go-verified |
| resourcemanager/resourcegraph/armresourcegraph | v0.10.0 | v0 | 3625 | v0.10.0 | 1068 gen | Go-verified |
| resourcemanager/resourcehealth/armresourcehealth | v1.4.0 | stable; newer v2.0.0-beta.1 | 7349 | v1.4.0 | 1967 gen | Go-verified |
| resourcemanager/resourcemover/armresourcemover | v1.3.0 | stable | 7424 | v1.3.0 | 2410 gen | Go-verified |
| resourcemanager/resources/armbicep | v0.1.0 | v0 | 543 | v0.1.0 | 88 gen | Go-verified |
| resourcemanager/resources/armchanges | v1.2.0 | stable | 1238 | v1.2.0 | 280 gen | Go-verified |
| resourcemanager/resources/armdeployments | v3.0.0 (`v3`) | stable | 10993 | v3.0.0 | 3267 gen | Go-verified |
| resourcemanager/resources/armdeploymentscripts | v2.1.0 | stable | 3108 | v2.1.0 | 847 gen | Go-verified |
| resourcemanager/resources/armdeploymentstacks | v2.0.0 | stable | 8054 | v2.0.0 | 2365 gen | Go-verified |
| resourcemanager/resources/armfeatures | v1.2.0 | stable | 2724 | v1.2.0 | 664 gen | Go-verified |
| resourcemanager/resources/armlinks | v1.2.0 | stable | 1462 | v1.2.0 | 309 gen | Go-verified |
| resourcemanager/resources/armlocks | v1.2.0 | stable | 3336 | v1.2.0 | 891 gen | Go-verified |
| resourcemanager/resources/armmanagedapplications | v1.2.0 | stable | 4180 | v1.2.0 | 1238 gen | Go-verified |
| resourcemanager/resources/armpolicy | v2.0.0 | stable | 12204 | v2.0.0 | 3535 gen | Go-verified |
| resourcemanager/resources/armresources | v4.0.0 (`v4`) | stable | 8683 | v4.0.0 | 2499 gen | Go-verified |
| resourcemanager/resources/armsubscriptions | v2.0.0 (`v2`) | stable | 2718 | v2.0.0 | 668 gen | Go-verified |
| resourcemanager/resources/armtemplatespecs | v1.2.0 | stable | 3370 | v1.2.0 | 941 gen | Go-verified |
| resourcemanager/saas/armsaas | v0.7.0 | v0 | 4506 | v0.7.0 | 1180 gen | Go-verified |
| resourcemanager/scheduler/armscheduler | v1.2.0 | stable | 4755 | v1.2.0 | 1388 gen | Go-verified |
| resourcemanager/scvmm/armscvmm | v1.0.0 | stable | 12686 | v1.0.0 | 3712 gen | Go-verified |
| resourcemanager/search/armsearch | v1.4.0 | stable; newer v2.0.0-beta.3 | 8833 | v1.4.0 | 2813 gen | Go-verified |
| resourcemanager/secretsstoreextension/armsecretsstoreextension | v0.1.0 | v0 | 3537 | v0.1.0 | 937 gen | Go-verified |
| resourcemanager/security/armsecurity | v0.15.0 | v0 | 72661 | v0.15.0 | 22742 gen | Go-verified |
| resourcemanager/securityinsights/armsecurityinsights | v1.2.0 | stable; newer v2.0.0-beta.6 | 23218 | v1.2.0 | 8160 gen | Go-verified |
| resourcemanager/selfhelp/armselfhelp | v1.1.0 | stable; newer v2.0.0-beta.5 | 2316 | v1.1.0 | 565 gen | Go-verified |
| resourcemanager/serialconsole/armserialconsole | v2.0.0 | stable | 2190 | v2.0.0 | 599 gen | Go-verified |
| resourcemanager/servicebus/armservicebus | v1.2.0 | stable; newer v2.0.0-beta.4 | 14615 | v1.2.0 | 4504 gen | Go-verified |
| resourcemanager/servicefabric/armservicefabric | v2.0.0 | stable; newer v3.0.0-beta.1 | 10935 | v2.0.0 | 3626 gen | Go-verified |
| resourcemanager/servicefabricmanagedclusters/armservicefabricmanagedclusters | v1.0.0 | stable | 18373 | v1.0.0 | 5726 gen | Go-verified |
| resourcemanager/servicefabricmesh/armservicefabricmesh | v0.6.2 | v0, deprecated | 8266 | v0.6.2 | 3221 gen | Go-verified |
| resourcemanager/servicegroups/armservicegroups | v1.0.0 | stable | 1752 | v1.0.0 | 399 gen | Go-verified |
| resourcemanager/servicelinker/armservicelinker | v1.2.0 | stable; newer v2.0.0-beta.2 | 3739 | v1.2.0 | 1308 gen | Go-verified |
| resourcemanager/servicenetworking/armservicenetworking | v1.2.0 | stable | 7166 | v1.2.0 | 2070 gen | Go-verified |
| resourcemanager/signalr/armsignalr | v1.2.0 | stable | 8594 | v1.2.0 | 2319 gen | Go-verified |
| resourcemanager/sitemanager/armsitemanager | v1.0.0 | stable | 2941 | v1.0.0 | 830 gen | Go-verified |
| resourcemanager/solutions/armmanagedapplications | v2.1.0 | stable | 7745 | v2.1.0 | 2179 gen | Go-verified |
| resourcemanager/sphere/armsphere | v1.0.0 | stable | 10814 | v1.0.0 | 3236 gen | Go-verified |
| resourcemanager/springappdiscovery/armspringappdiscovery | v0.1.0 | v0 | 5780 | v0.1.0 | 1922 gen | Go-verified |
| resourcemanager/sql/armsql | v1.2.0 | stable; newer v2.0.0-beta.9 | 109506 | v1.2.0 | 33393 gen | Go-verified |
| resourcemanager/sqlvirtualmachine/armsqlvirtualmachine | v1.0.0 | stable | 6912 | v1.0.0 | 1992 gen | Go-verified |
| resourcemanager/standbypool/armstandbypool | v2.1.0 | stable | 5418 | v2.1.0 | 1551 gen | Go-verified |
| resourcemanager/storage/armstorage | v4.3.0 (`v4`) | stable | 42130 | v4.3.0 | 13897 gen | Go-verified |
| resourcemanager/storageactions/armstorageactions | v1.0.0 | stable | 3841 | v1.0.0 | 1031 gen | Go-verified |
| resourcemanager/storagecache/armstoragecache | v4.3.0 | stable | 18217 | v4.3.0 | 5386 gen | Go-verified |
| resourcemanager/storagediscovery/armstoragediscovery | v1.0.0 | stable | 2061 | v1.0.0 | 813 gen | Go-verified |
| resourcemanager/storageimportexport/armstorageimportexport | v0.7.0 | v0 | 3962 | v0.7.0 | 1090 gen | Go-verified |
| resourcemanager/storagemover/armstoragemover | v2.5.0 | stable | 10755 | v2.5.0 | 3646 gen | Go-verified |
| resourcemanager/storagepool/armstoragepool | v1.2.0 | stable | 5687 | v1.2.0 | 1472 gen | Go-verified |
| resourcemanager/storagesync/armstoragesync | v2.1.0 | stable | 14390 | v2.1.0 | 4163 gen | Go-verified |
| resourcemanager/streamanalytics/armstreamanalytics | v1.2.0 | stable; newer v2.0.0-beta.1 | 14898 | v1.2.0 | 4890 gen | Go-verified |
| resourcemanager/subscription/armsubscription | v1.2.0 | stable; newer v2.0.0-beta.1 | 4807 | v1.2.0 | 1158 gen | Go-verified |
| resourcemanager/support/armsupport | v2.0.0 | stable | 8887 | v2.0.0 | 2374 gen | Go-verified |
| resourcemanager/synapse/armsynapse | v0.8.0 | v0 | 61169 | v0.8.0 | 19526 gen | Go-verified |
| resourcemanager/tenantactivitylogalerts/armtenantactivitylogalerts | v0.1.0 | v0 | 1624 | v0.1.0 | 373 gen | Go-verified |
| resourcemanager/terraform/armterraform | v0.2.0 | v0 | 1893 | v0.2.0 | 624 gen | Go-verified |
| resourcemanager/testbase/armtestbase | v0.7.0 | v0 | 13474 | v0.7.0 | 3951 gen | Go-verified |
| resourcemanager/timeseriesinsights/armtimeseriesinsights | v1.2.0 | stable | 8725 | v1.2.0 | 2706 gen | Go-verified |
| resourcemanager/trafficmanager/armtrafficmanager | v2.0.0 | stable | 4455 | v2.0.0 | 1238 gen | Go-verified |
| resourcemanager/virtualmachineimagebuilder/armvirtualmachineimagebuilder | v3.0.0 | stable | 6161 | v3.0.0 | 2324 gen | Go-verified |
| resourcemanager/vmwarecloudsimple/armvmwarecloudsimple | v1.2.0 | stable | 9852 | v1.2.0 | 2713 gen | Go-verified |
| resourcemanager/webpubsub/armwebpubsub | v1.3.0 | stable | 11456 | v1.3.0 | 3268 gen | Go-verified |
| resourcemanager/weightsandbiases/armweightsandbiases | v1.0.0 | stable | 2373 | v1.0.0 | 662 gen | Go-verified |
| resourcemanager/windowsesu/armwindowsesu | v0.7.0 | v0 | 2070 | v0.7.0 | 469 gen | Go-verified |
| resourcemanager/windowsiot/armwindowsiot | v1.2.0 | stable | 2267 | v1.2.0 | 518 gen | Go-verified |
| resourcemanager/workloadmonitor/armworkloadmonitor | v0.5.1 | v0, deprecated | 820 | v0.5.1 | 496 gen | Go-verified |
| resourcemanager/workloadorchestration/armworkloadorchestration | v0.3.0 | v0 | 25158 | v0.3.0 | 7299 gen | Go-verified |
| resourcemanager/workloads/armworkloads | v1.1.0 | stable | 16353 | v1.1.0 | 5345 gen | Go-verified |
| resourcemanager/workloadssapvirtualinstance/armworkloadssapvirtualinstance | v1.0.0 | stable | 12085 | v1.0.0 | 3941 gen | Go-verified |

## ARM modules: compiled, not yet Go-verified (0)

Generated from Go's pinned spec and built and tested by the gate; not
counted as ported until their Go vectors pass.

| Go module | latest | kind | Go lines | our port | our lines | status |
|---|---|---|---:|---|---:|---|

## ARM modules not generated yet (0)

<details><summary>The list</summary>

| Go module | latest | kind | Go lines | our port | our lines | status |
|---|---|---|---:|---|---:|---|

</details>

## Proposed next three

Status (2026-11-07): (1) is under way. azcore v1.24.0 is ported,
its SSE stream reader (`streaming/sse.go`) included since 2026-11-07:
a request can leave its response body on a stream
(`runtime.streamed`), read as it arrives.
azfile v1.7.2, azqueue v2.1.2 and azsecrets v1.5.1 are done; azidentity
v1.15.0 (2) is next.
Our line counts above are from before these catch-ups.

1. **Catch the ported modules up**: azcore v1.24.0 (query-redacted
   URLs in retry logs and tracing spans, SSE streaming, `ResourceID.ValidateResourceTypeChain`;
   v1.23.3's case-insensitive `locations`), azfile v1.7.2 and the
   azqueue v2 line (v2.1.2: SAS start and expiry converted to UTC
   before signing, no doubled `?` in `GetSASURL`), azsecrets v1.5.1
   (API version 2026-04-01). Why first: every module sits on azcore,
   and the SAS fixes are signing correctness. Each has Go vectors from
   the released code.
2. **azidentity to v1.15.0**: Go has 4100 hand-written lines and our
   port is a 638-line subset with no version mark. Every client
   authenticates through it, and v1.15.0 adds Arc user-assigned
   managed identity, workload identity's Azure proxy mode and Service
   Fabric certificate pinning. A gap list against Go v1.15.0 comes
   first, then slices, each with vectors from Go's own code and fakes
   only (no real Azure).
3. **messaging/eventgrid/aznamespaces v1.0.0**: done, hand written
   over the CloudEvent, KeyCredential and policies that azeventgrid
   added (Go rewrites its generated clients after generation, so the
   port follows the released package); requests checked against Go's
   own.

The ARM majors (armstorage v4, armcompute v9, armnetwork v12,
armresources v4 and armkeyvault v2), armsubscriptions v2 and
armcontainerservice v9 are done by
generating from the
specs. containers/azcontainerregistry v0.2.3 is done: its operations
generated from the swagger with Go's autorest.md directives as JSON
patches, and its challenge policy, chunk upload and digest helpers
written by hand, with requests checked against Go's own. azcore's SSE
streaming is done (the reader, SSEResponse, and a streamed response
body in the pipeline). ai/azopenai v0.9.0 has no client (it extends
openai-go v3, which is not an Azure module): its Azure models are
generated and its MongoDB embedding dependency, request options,
response accessors and ExtractContentFilterError written by hand over
JSON, every case checked against Go's own. messaging/eventgrid/
azsystemevents v1.1.0 is done: its models and event type constants
generated from the TypeSpec's OpenAPI file, its Event Grid event and
error written by hand, every spec example checked against Go's own.
messaging/azwebpubsub v0.1.1 is done: its operations generated from
the 2023-07-01 OpenAPI file, its constructors, access key policy and
client access URL written by hand, every public call checked against
Go's own. batch/azbatch v0.1.0 is done: generated from the TypeSpec's
2024-07-01.20.0 OpenAPI file but for its constructor, every public call
checked against Go's own.
