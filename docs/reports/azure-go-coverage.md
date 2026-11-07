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
| ai/azopenai | v0.9.0 | v0 | 284 | 3931 | missing |  |  |
| ai/azopenaiassistants | v0.4.0 | v0, deprecated | 1546 | 13412 | missing |  |  |
| ai/azopenaiextensions | v0.2.0 | v0, deprecated | 290 | 3840 | missing |  |  |
| azcore | v1.24.0 | stable | 8168 | 9190 | v1.24.0 | 2686 |  |
| azidentity | v1.15.0 | stable | 4100 | 4100 | partial | 638 |  |
| azidentity/cache | v0.4.0 | v0 | 595 | 595 | missing |  |  |
| batch/azbatch | v0.1.0 | v0 | 66 | 24575 | missing |  |  |
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
| messaging/azwebpubsub | v0.1.1 | v0 | 332 | 2071 | missing |  |  |
| messaging/eventgrid/azeventgrid | v1.0.0 | stable | 127 | 574 | v1.0.0 | 132 |  |
| messaging/eventgrid/aznamespaces | v1.0.0 | stable | 537 | 1939 | v1.0.0 | 345 |  |
| messaging/eventgrid/azsystemevents | v1.1.0 | stable | 878 | 19101 | missing |  |  |
| monitor/azingest | v0.1.2 | v0, deprecated | 95 | 208 | missing |  |  |
| monitor/azquery | v1.2.0 | stable | 255 | 2257 | missing |  |  |
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

## ARM modules we port

All ARM code is generated, in Go and here; "behind" means Go has
shipped a newer major whose spec our generator has not been run on.

| Go module | latest | kind | Go hand-written lines | Go lines | our port | our lines (hand + generated) | popularity |
|---|---|---|---:|---:|---|---|---|
| resourcemanager/authorization/armauthorization | v2.2.0 (`v2`) | stable; newer v3.0.0-beta.3 | 7 | 14114 | v2.2.0 | 0 + 3714 gen |  |
| resourcemanager/compute/armcompute | v9.0.0 (`v9`) | stable | 0 | 85961 | v9.0.0 | 0 + 31271 gen |  |
| resourcemanager/keyvault/armkeyvault | v2.1.0 (`v2`) | stable | 0 | 13812 | v2.1.0 | 0 + 4028 gen |  |
| resourcemanager/network/armnetwork | v12.1.0 (`v12`) | stable | 0 | 208724 | v12.1.0 | 0 + 62510 gen |  |
| resourcemanager/resources/armresources | v4.0.0 (`v4`) | stable | 0 | 8683 | v4.0.0 | 0 + 2566 gen |  |
| resourcemanager/storage/armstorage | v4.3.0 (`v4`) | stable | 0 | 42130 | v4.3.0 | 0 + 13442 gen |  |

## ARM modules not ported (302)

<details><summary>The list</summary>

| Go module | latest | kind | Go lines |
|---|---|---|---:|
| resourcemanager/aad/armaad | v1.2.0 | stable | 3026 |
| resourcemanager/addons/armaddons | v0.3.0 | v0 | 1470 |
| resourcemanager/advisor/armadvisor | v1.2.0 | stable; newer v2.0.0-beta.1 | 4070 |
| resourcemanager/agricultureplatform/armagricultureplatform | v0.1.0 | v0 | 3050 |
| resourcemanager/agrifood/armagrifood | v0.9.0 | v0 | 6173 |
| resourcemanager/aigateway/armaigateway | v0.1.0 | v0 | 2342 |
| resourcemanager/aiinfraoptimization/armaiinfraoptimization | v0.1.0 | v0 | 2614 |
| resourcemanager/alertprocessingrules/armalertprocessingrules | v0.1.0 | v0 | 2201 |
| resourcemanager/alertrulerecommendations/armalertrulerecommendations | v0.1.0 | v0 | 938 |
| resourcemanager/alertsmanagement/armalertsmanagement | v0.11.0 | v0 | 5061 |
| resourcemanager/analysisservices/armanalysisservices | v1.2.0 | stable | 4034 |
| resourcemanager/apicenter/armapicenter | v1.0.0 | stable | 10258 |
| resourcemanager/apimanagement/armapimanagement | v3.0.0 | stable; newer v4.0.0-beta.1 | 138430 |
| resourcemanager/appcomplianceautomation/armappcomplianceautomation | v1.0.0 | stable | 9725 |
| resourcemanager/appconfiguration/armappconfiguration | v3.0.0 | stable | 7836 |
| resourcemanager/appcontainers/armappcontainers | v5.0.0 | stable | 46587 |
| resourcemanager/applicationinsights/armapplicationinsights | v1.2.0 | stable; newer v2.0.0-beta.4 | 14156 |
| resourcemanager/appnetwork/armappnetwork | v0.2.0 | v0 | 4836 |
| resourcemanager/appplatform/armappplatform | v2.0.1 | stable, deprecated | 41028 |
| resourcemanager/appservice/armappservice | v6.0.0 | stable | 133180 |
| resourcemanager/arizeaiobservabilityeval/armarizeaiobservabilityeval | v1.0.0 | stable | 2438 |
| resourcemanager/artifactsigning/armartifactsigning | v0.2.0 | v0 | 3574 |
| resourcemanager/attestation/armattestation | v2.0.0 | stable | 3758 |
| resourcemanager/automanage/armautomanage | v1.2.0 | stable | 7672 |
| resourcemanager/automation/armautomation | v1.0.0 | stable | 43252 |
| resourcemanager/avs/armavs | v2.3.0 | stable | 32673 |
| resourcemanager/azurearcdata/armazurearcdata | v0.7.0 | v0 | 7935 |
| resourcemanager/azuredata/armazuredata | v0.7.0 | v0 | 3448 |
| resourcemanager/azurestackhci/armazurestackhci | v3.2.0 | stable | 41810 |
| resourcemanager/azurestackhci/armazurestackhcivm | v0.1.0 | v0 | 17245 |
| resourcemanager/baremetalinfrastructure/armbaremetalinfrastructure | v1.2.0 | stable; newer v2.0.0-beta.1 | 2329 |
| resourcemanager/batch/armbatch | v4.0.0 | stable | 15328 |
| resourcemanager/billing/armbilling | v2.0.0 | stable | 48871 |
| resourcemanager/billingbenefits/armbillingbenefits | v2.1.0 | stable; newer v3.0.0-beta.1 | 5603 |
| resourcemanager/billingtrust/armbillingtrust | v0.1.0 | v0 | 3679 |
| resourcemanager/blueprint/armblueprint | v0.7.0 | v0 | 6329 |
| resourcemanager/botservice/armbotservice | v1.2.0 | stable; newer v2.0.0-beta.1 | 11291 |
| resourcemanager/carbonoptimization/armcarbonoptimization | v1.0.0 | stable | 3373 |
| resourcemanager/cdn/armcdn | v4.0.0 | stable | 37094 |
| resourcemanager/certificateregistration/armcertificateregistration | v1.0.0 | stable | 6273 |
| resourcemanager/chaos/armchaos | v2.0.0 | stable; newer v3.0.0-beta.1 | 7722 |
| resourcemanager/cloudhealth/armcloudhealth | v1.0.0 | stable | 10855 |
| resourcemanager/cognitiveservices/armcognitiveservices | v3.0.0 | stable; newer v4.0.0-beta.5 | 29917 |
| resourcemanager/commerce/armcommerce | v0.4.0 | v0 | 1546 |
| resourcemanager/communication/armcommunication | v3.0.0 | stable | 9312 |
| resourcemanager/commvaultcontentstore/armcommvaultcontentstore | v1.0.0 | stable | 9967 |
| resourcemanager/compute/armbulkactions | v0.7.0 | v0 | 17902 |
| resourcemanager/compute/armrecommender | v0.4.0 | v0 | 3135 |
| resourcemanager/compute/armworkloadmanager | v0.1.0 | v0 | 5592 |
| resourcemanager/computebulkactions/armcomputebulkactions | v0.1.0 | v0 | 9754 |
| resourcemanager/computefleet/armcomputefleet | v2.0.0 | stable | 7767 |
| resourcemanager/computelimit/armcomputelimit | v1.3.0 | stable | 6335 |
| resourcemanager/computeschedule/armcomputeschedule | v1.1.0 | stable; newer v2.0.0-beta.1 | 3753 |
| resourcemanager/confidentialledger/armconfidentialledger | v1.2.0 | stable | 2464 |
| resourcemanager/confluent/armconfluent | v1.3.0 | stable; newer v2.0.0-beta.2 | 8770 |
| resourcemanager/connectedcache/armconnectedcache | v1.0.0 | stable | 8297 |
| resourcemanager/connectedvmware/armconnectedvmware | v1.1.1 | stable | 15051 |
| resourcemanager/consumption/armconsumption | v2.1.0 | stable | 15639 |
| resourcemanager/containerinstance/armcontainerinstance | v2.4.0 | stable; newer v3.0.0-beta.1 | 6575 |
| resourcemanager/containerorchestratorruntime/armcontainerorchestratorruntime | v0.1.0 | v0 | 4969 |
| resourcemanager/containerregistry/armcontainerregistry | v3.0.0 | stable | 15726 |
| resourcemanager/containerregistry/armcontainerregistrytasks | v0.1.0 | v0 | 8803 |
| resourcemanager/containerservice/armcontainerservice | v9.7.0 | stable | 24355 |
| resourcemanager/containerservice/armdeploymentsafeguards | v0.1.0 | v0 | 1696 |
| resourcemanager/containerserviceaimanager/armcontainerserviceaimanager | v0.2.0 | v0 | 8193 |
| resourcemanager/containerservicefleet/armcontainerservicefleet | v3.0.0 | stable | 11768 |
| resourcemanager/containerservicepreparedimgspec/armcontainerservicepreparedimgspec | v0.1.0 | v0 | 2636 |
| resourcemanager/cosmos/armcosmos | v4.0.0 | stable | 59620 |
| resourcemanager/cosmosforpostgresql/armcosmosforpostgresql | v1.1.0 | stable | 8480 |
| resourcemanager/costmanagement/armcostmanagement | v3.0.0 | stable | 21160 |
| resourcemanager/customerinsights/armcustomerinsights | v1.2.0 | stable | 17628 |
| resourcemanager/customerlockbox/armcustomerlockbox | v0.7.0 | v0 | 2098 |
| resourcemanager/customproviders/armcustomproviders | v0.7.0 | v0 | 2798 |
| resourcemanager/dashboard/armdashboard | v2.0.0 | stable | 8422 |
| resourcemanager/databasewatcher/armdatabasewatcher | v0.1.0 | v0 | 6425 |
| resourcemanager/databoundaries/armdataboundaries | v1.0.0 | stable | 1406 |
| resourcemanager/databox/armdatabox | v3.0.0 | stable | 12255 |
| resourcemanager/databoxedge/armdataboxedge | v2.0.0 | stable | 24246 |
| resourcemanager/databricks/armdatabricks | v2.0.0 | stable | 7476 |
| resourcemanager/datacatalog/armdatacatalog | v1.2.0 | stable | 1606 |
| resourcemanager/datadog/armdatadog | v1.3.0 | stable; newer v2.0.0-beta.1 | 7296 |
| resourcemanager/datafactory/armdatafactory | v11.0.0 | stable | 113310 |
| resourcemanager/datalake-analytics/armdatalakeanalytics | v0.8.0 | v0 | 9341 |
| resourcemanager/datalake-store/armdatalakestore | v1.2.0 | stable | 7289 |
| resourcemanager/datamigration/armdatamigration | v2.0.0 | stable; newer v3.0.0-beta.1 | 39403 |
| resourcemanager/dataprotection/armdataprotection | v4.2.0 | stable | 24139 |
| resourcemanager/datashare/armdatashare | v1.2.0 | stable | 17615 |
| resourcemanager/datatransfer/armdatatransfer | v0.1.0 | v0 | 12480 |
| resourcemanager/delegatednetwork/armdelegatednetwork | v1.2.0 | stable | 4648 |
| resourcemanager/dell/armdellstorage | v1.0.0 | stable | 2674 |
| resourcemanager/dependencymap/armdependencymap | v0.1.0 | v0 | 4163 |
| resourcemanager/desktopvirtualization/armdesktopvirtualization | v2.3.0 | stable | 20959 |
| resourcemanager/devcenter/armdevcenter | v2.0.0 | stable; newer v3.0.0-beta.1 | 23363 |
| resourcemanager/devhub/armdevhub | v0.7.0 | v0 | 7914 |
| resourcemanager/deviceprovisioningservices/armdeviceprovisioningservices | v1.4.0 | stable | 6150 |
| resourcemanager/deviceregistry/armdeviceregistry | v2.0.0 | stable | 17963 |
| resourcemanager/deviceupdate/armdeviceupdate | v1.3.0 | stable | 7421 |
| resourcemanager/devops/armdevops | v0.7.0 | v0 | 2395 |
| resourcemanager/devopsinfrastructure/armdevopsinfrastructure | v1.0.0 | stable | 5571 |
| resourcemanager/devtestlabs/armdevtestlabs | v1.2.0 | stable | 31727 |
| resourcemanager/digitaltwins/armdigitaltwins | v1.2.0 | stable | 6613 |
| resourcemanager/disconnectedoperations/armdisconnectedoperations | v1.0.0 | stable | 4698 |
| resourcemanager/discovery/armdiscovery | v0.1.0 | v0 | 14007 |
| resourcemanager/dns/armdns | v1.2.0 | stable | 3889 |
| resourcemanager/dnsresolver/armdnsresolver | v1.3.0 | stable; newer v2.0.0-beta.1 | 13369 |
| resourcemanager/domainregistration/armdomainregistration | v1.0.0 | stable | 5217 |
| resourcemanager/domainservices/armdomainservices | v1.2.0 | stable; newer v2.0.0-beta.1 | 4483 |
| resourcemanager/durabletask/armdurabletask | v1.1.0 | stable | 5483 |
| resourcemanager/dynatrace/armdynatrace | v2.2.0 | stable | 8236 |
| resourcemanager/edgeactions/armedgeactions | v1.0.0 | stable | 4597 |
| resourcemanager/edgemarketplace/armedgemarketplace | v0.1.1 | v0 | 3279 |
| resourcemanager/edgeoperator/armedgeoperator | v0.1.0 | v0 | 1186 |
| resourcemanager/edgeorder/armedgeorder | v2.0.0 | stable | 9371 |
| resourcemanager/edgeorderpartner/armedgeorderpartner | v0.7.0 | v0 | 2408 |
| resourcemanager/edgezones/armedgezones | v1.0.0 | stable | 1611 |
| resourcemanager/education/armeducation | v0.5.0 | v0 | 5172 |
| resourcemanager/elastic/armelastic | v3.0.0 | stable | 12444 |
| resourcemanager/elasticsan/armelasticsan | v1.2.0 | stable; newer v2.0.0-beta.1 | 8383 |
| resourcemanager/enclave/armenclave | v1.0.0 | stable | 15765 |
| resourcemanager/engagementfabric/armengagementfabric | v0.3.0 | v0 | 3729 |
| resourcemanager/eventgrid/armeventgrid | v2.3.0 | stable | 42025 |
| resourcemanager/eventhub/armeventhub | v1.3.0 | stable; newer v2.0.0-beta.1 | 15366 |
| resourcemanager/extendedlocation/armextendedlocation | v1.2.0 | stable; newer v2.0.0-beta.1 | 2623 |
| resourcemanager/fabric/armfabric | v1.0.0 | stable | 3129 |
| resourcemanager/fileshares/armfileshares | v0.1.0 | v0 | 6027 |
| resourcemanager/fluidrelay/armfluidrelay | v1.2.0 | stable | 3538 |
| resourcemanager/frontdoor/armfrontdoor | v2.0.0 | stable | 13019 |
| resourcemanager/graphservices/armgraphservices | v1.1.0 | stable | 1951 |
| resourcemanager/guestconfiguration/armguestconfiguration | v2.0.0 | stable | 6226 |
| resourcemanager/hanaonazure/armhanaonazure | v0.8.0 | v0 | 2592 |
| resourcemanager/hardwaresecuritymodules/armhardwaresecuritymodules | v3.0.0 | stable | 7090 |
| resourcemanager/hdinsight/armhdinsight | v1.2.0 | stable; newer v2.0.0-beta.1 | 15033 |
| resourcemanager/healthbot/armhealthbot | v2.0.0 | stable | 2503 |
| resourcemanager/healthcareapis/armhealthcareapis | v2.1.0 | stable; newer v3.0.0-beta.1 | 12896 |
| resourcemanager/healthdataaiservices/armhealthdataaiservices | v1.0.0 | stable | 3795 |
| resourcemanager/horizondb/armhorizondb | v0.3.0 | v0 | 22844 |
| resourcemanager/hybridcompute/armhybridcompute | v3.0.0 | stable | 19145 |
| resourcemanager/hybridconnectivity/armhybridconnectivity | v1.2.0 | stable | 8271 |
| resourcemanager/hybridcontainerservice/armhybridcontainerservice | v1.0.0 | stable | 8441 |
| resourcemanager/hybridkubernetes/armhybridkubernetes | v1.2.0 | stable; newer v2.0.0-beta.2 | 2713 |
| resourcemanager/hybridnetwork/armhybridnetwork | v2.0.0 | stable | 20959 |
| resourcemanager/impactreporting/armimpactreporting | v0.2.0 | v0 | 4615 |
| resourcemanager/informaticadatamgmt/arminformaticadatamgmt | v1.0.0 | stable | 5655 |
| resourcemanager/integrationspaces/armintegrationspaces | v0.1.0 | v0 | 8651 |
| resourcemanager/internal (support module) | v3.2.0 | stable | 220 |
| resourcemanager/iotcentral/armiotcentral | v1.2.0 | stable; newer v2.0.0-beta.2 | 2567 |
| resourcemanager/iotfirmwaredefense/armiotfirmwaredefense | v2.0.0 | stable | 8190 |
| resourcemanager/iothub/armiothub | v1.3.0 | stable; newer v2.0.0-beta.3 | 11167 |
| resourcemanager/iotoperations/armiotoperations | v1.2.0 | stable | 21882 |
| resourcemanager/kubernetesconfiguration/armextensions | v1.0.0 | stable | 2755 |
| resourcemanager/kubernetesconfiguration/armextensiontypes | v0.2.0 | v0 | 2392 |
| resourcemanager/kubernetesconfiguration/armfluxconfigurations | v0.1.0 | v0 | 4414 |
| resourcemanager/kubernetesconfiguration/armprivatelinkscopes | v0.2.0 | v0 | 2901 |
| resourcemanager/kusto/armkusto | v2.4.0 | stable | 21791 |
| resourcemanager/labservices/armlabservices | v1.2.0 | stable | 11411 |
| resourcemanager/lambdatesthyperexecute/armlambdatesthyperexecute | v1.0.0 | stable | 2440 |
| resourcemanager/largeinstance/armlargeinstance | v0.1.0 | v0 | 3962 |
| resourcemanager/liftrqumulo/armqumulo | v2.1.0 | stable | 2238 |
| resourcemanager/loadtesting/armloadtesting | v1.2.0 | stable | 3477 |
| resourcemanager/logic/armlogic | v1.2.0 | stable | 31522 |
| resourcemanager/m365securityandcompliance/armm365securityandcompliance | v0.7.0 | v0 | 14913 |
| resourcemanager/machinelearning/armmachinelearning | v4.0.0 | stable; newer v5.0.0-beta.1 | 76326 |
| resourcemanager/maintenance/armmaintenance | v1.3.0 | stable; newer v2.0.0-beta.1 | 7536 |
| resourcemanager/managednetwork/armmanagednetwork | v0.3.0 | v0 | 4826 |
| resourcemanager/managednetworkfabric/armmanagednetworkfabric | v2.0.0 | stable | 55337 |
| resourcemanager/managedops/armmanagedops | v0.2.0 | v0 | 2350 |
| resourcemanager/managedservices/armmanagedservices | v0.7.0 | v0 | 4082 |
| resourcemanager/managementgroups/armmanagementgroups | v2.0.0 | stable | 5619 |
| resourcemanager/managementpartner/armmanagementpartner | v0.7.0 | v0 | 1721 |
| resourcemanager/maps/armmaps | v1.1.0 | stable; newer v2.0.0-beta.1 | 4595 |
| resourcemanager/mariadb/armmariadb | v1.2.0 | stable | 15251 |
| resourcemanager/marketplace/armmarketplace | v2.0.0 | stable | 9919 |
| resourcemanager/marketplaceordering/armmarketplaceordering | v1.2.0 | stable | 2026 |
| resourcemanager/migrate/armmigrate | v1.2.0 | stable | 12313 |
| resourcemanager/migrationassessment/armmigrationassessment | v0.1.0 | v0 | 48178 |
| resourcemanager/migrationdiscovery/armmigrationdiscoverysap | v0.1.0 | v0 | 5132 |
| resourcemanager/mongocluster/armmongocluster | v1.2.0 | stable | 7396 |
| resourcemanager/mongodbatlas/armmongodbatlas | v1.0.0 | stable | 2427 |
| resourcemanager/monitor/armmonitor | v0.14.0 | v0 | 35278 |
| resourcemanager/monitor/armmonitorworkspaces | v1.0.0 | stable | 6119 |
| resourcemanager/monitor/armslis | v0.2.0 | v0 | 2067 |
| resourcemanager/msi/armmsi | v1.3.0 | stable | 3108 |
| resourcemanager/mysql/armmysqlflexibleservers | v2.0.0 | stable | 18146 |
| resourcemanager/napsteromniagentapi/armnapsteromniagentapi | v0.1.0 | v0 | 3074 |
| resourcemanager/netapp/armnetapp | v11.0.0 | stable | 33878 |
| resourcemanager/networkcloud/armnetworkcloud | v2.0.0 | stable | 41194 |
| resourcemanager/networkfunction/armnetworkfunction | v3.0.0 | stable | 3383 |
| resourcemanager/networksecurity/armnetworksecurity | v0.1.0 | v0 | 6867 |
| resourcemanager/newrelic/armnewrelicobservability | v2.0.0 | stable | 9937 |
| resourcemanager/nginx/armnginx | v4.0.0 | stable | 8295 |
| resourcemanager/notificationhubs/armnotificationhubs | v1.2.0 | stable; newer v2.0.0-beta.2 | 6633 |
| resourcemanager/oep/armoep | v0.6.0 | v0 | 3137 |
| resourcemanager/onlineexperimentation/armonlineexperimentation | v0.1.0 | v0 | 2368 |
| resourcemanager/operationalinsights/armoperationalinsights | v3.0.0 | stable | 20877 |
| resourcemanager/operationsmanagement/armoperationsmanagement | v0.8.0 | v0 | 3312 |
| resourcemanager/oracledatabase/armoracledatabase | v3.0.0 | stable | 40551 |
| resourcemanager/orbital/armorbital | v2.1.0 | stable | 6943 |
| resourcemanager/paloaltonetworksngfw/armpanngfw | v2.0.0 | stable | 20778 |
| resourcemanager/peering/armpeering | v2.0.0 | stable | 12311 |
| resourcemanager/pineconevectordb/armpineconevectordb | v0.1.1 | v0 | 2547 |
| resourcemanager/planetarycomputer/armplanetarycomputer | v1.0.0 | stable | 1714 |
| resourcemanager/platformvalidation/armplatformvalidation | v0.1.0 | v0 | 7501 |
| resourcemanager/playwright/armplaywright | v1.0.0 | stable | 3465 |
| resourcemanager/playwrighttesting/armplaywrighttesting | v1.0.2 | stable, deprecated | 3587 |
| resourcemanager/policyinsights/armpolicyinsights | v0.10.0 | v0 | 17449 |
| resourcemanager/portal/armportal | v0.7.0 | v0 | 3208 |
| resourcemanager/portalservicescopilot/armportalservicescopilot | v0.1.0 | v0 | 1625 |
| resourcemanager/postgresql/armpostgresql | v1.2.0 | stable; newer v2.0.0-20260225001619-0cffc1715e84 | 12920 |
| resourcemanager/postgresql/armpostgresqlflexibleservers | v6.0.0 | stable | 23210 |
| resourcemanager/postgresqlhsc/armpostgresqlhsc | v0.7.0 | v0, deprecated | 9020 |
| resourcemanager/powerbidedicated/armpowerbidedicated | v2.0.0 | stable | 4241 |
| resourcemanager/powerbiembedded/armpowerbiembedded | v1.2.0 | stable | 2783 |
| resourcemanager/powerbiprivatelinks/armpowerbiprivatelinks | v2.1.0 | stable | 4270 |
| resourcemanager/powerplatform/armpowerplatform | v0.4.0 | v0 | 4744 |
| resourcemanager/previewalertrule/armpreviewalertrule | v0.1.0 | v0 | 1331 |
| resourcemanager/privatedns/armprivatedns | v2.0.0 | stable | 4414 |
| resourcemanager/programenrollment/armprogramenrollment | v0.1.0 | v0 | 2056 |
| resourcemanager/programmableconnectivity/armprogrammableconnectivity | v0.1.0 | v0 | 4172 |
| resourcemanager/prometheusrulegroups/armprometheusrulegroups | v0.1.0 | v0 | 1606 |
| resourcemanager/providerhub/armproviderhub | v4.0.0 | stable | 20985 |
| resourcemanager/purestorageblock/armpurestorageblock | v1.0.0 | stable | 9932 |
| resourcemanager/purview/armpurview | v1.2.0 | stable; newer v2.0.0-beta.1 | 5709 |
| resourcemanager/quantum/armquantum | v0.8.0 | v0 | 3713 |
| resourcemanager/quota/armquota | v2.0.0 | stable | 9830 |
| resourcemanager/recoveryservices/armrecoveryservices | v3.2.1 | stable | 9031 |
| resourcemanager/recoveryservices/armrecoveryservicesbackup | v5.2.0 | stable | 49568 |
| resourcemanager/recoveryservices/armrecoveryservicessiterecovery | v4.0.0 | stable | 70085 |
| resourcemanager/recoveryservicesdatareplication/armrecoveryservicesdatareplication | v1.0.0 | stable | 19089 |
| resourcemanager/redhatopenshift/armredhatopenshift | v2.0.0 | stable | 4367 |
| resourcemanager/redhatopenshifthcp/armredhatopenshifthcp | v1.0.0 | stable | 7987 |
| resourcemanager/redis/armredis | v4.0.0 | stable | 10738 |
| resourcemanager/redisenterprise/armredisenterprise | v4.0.0 | stable | 10920 |
| resourcemanager/relationships/armrelationships | v1.0.0 | stable | 3746 |
| resourcemanager/relay/armrelay | v2.1.0 | stable | 8445 |
| resourcemanager/reservations/armreservations | v4.0.0 | stable | 11009 |
| resourcemanager/resiliencemanagement/armresiliencemanagement | v1.0.0 | stable | 22979 |
| resourcemanager/resourceconnector/armresourceconnector | v1.1.0 | stable | 3124 |
| resourcemanager/resourcegraph/armresourcegraph | v0.10.0 | v0 | 3625 |
| resourcemanager/resourcehealth/armresourcehealth | v1.4.0 | stable; newer v2.0.0-beta.1 | 7349 |
| resourcemanager/resourcemover/armresourcemover | v1.3.0 | stable | 7424 |
| resourcemanager/resources/armbicep | v0.1.0 | v0 | 543 |
| resourcemanager/resources/armchanges | v1.2.0 | stable | 1238 |
| resourcemanager/resources/armdeployments | v3.0.0 | stable | 10993 |
| resourcemanager/resources/armdeploymentscripts | v2.1.0 | stable | 3108 |
| resourcemanager/resources/armdeploymentstacks | v2.0.0 | stable | 8054 |
| resourcemanager/resources/armfeatures | v1.2.0 | stable | 2724 |
| resourcemanager/resources/armlinks | v1.2.0 | stable | 1462 |
| resourcemanager/resources/armlocks | v1.2.0 | stable | 3336 |
| resourcemanager/resources/armmanagedapplications | v1.2.0 | stable | 4180 |
| resourcemanager/resources/armpolicy | v2.0.0 | stable | 12204 |
| resourcemanager/resources/armsubscriptions | v2.0.0 | stable | 2718 |
| resourcemanager/resources/armtemplatespecs | v1.2.0 | stable | 3370 |
| resourcemanager/saas/armsaas | v0.7.0 | v0 | 4506 |
| resourcemanager/scheduler/armscheduler | v1.2.0 | stable | 4755 |
| resourcemanager/scvmm/armscvmm | v1.0.0 | stable | 12686 |
| resourcemanager/search/armsearch | v1.4.0 | stable; newer v2.0.0-beta.3 | 8833 |
| resourcemanager/secretsstoreextension/armsecretsstoreextension | v0.1.0 | v0 | 3537 |
| resourcemanager/security/armsecurity | v0.15.0 | v0 | 72661 |
| resourcemanager/securityinsights/armsecurityinsights | v1.2.0 | stable; newer v2.0.0-beta.6 | 23218 |
| resourcemanager/selfhelp/armselfhelp | v1.1.0 | stable; newer v2.0.0-beta.5 | 2316 |
| resourcemanager/serialconsole/armserialconsole | v2.0.0 | stable | 2190 |
| resourcemanager/servicebus/armservicebus | v1.2.0 | stable; newer v2.0.0-beta.4 | 14615 |
| resourcemanager/servicefabric/armservicefabric | v2.0.0 | stable; newer v3.0.0-beta.1 | 10935 |
| resourcemanager/servicefabricmanagedclusters/armservicefabricmanagedclusters | v1.0.0 | stable | 18373 |
| resourcemanager/servicefabricmesh/armservicefabricmesh | v0.6.2 | v0, deprecated | 8266 |
| resourcemanager/servicegroups/armservicegroups | v1.0.0 | stable | 1752 |
| resourcemanager/servicelinker/armservicelinker | v1.2.0 | stable; newer v2.0.0-beta.2 | 3739 |
| resourcemanager/servicenetworking/armservicenetworking | v1.2.0 | stable | 7166 |
| resourcemanager/signalr/armsignalr | v1.2.0 | stable | 8594 |
| resourcemanager/sitemanager/armsitemanager | v1.0.0 | stable | 2941 |
| resourcemanager/solutions/armmanagedapplications | v2.1.0 | stable | 7745 |
| resourcemanager/sphere/armsphere | v1.0.0 | stable | 10814 |
| resourcemanager/springappdiscovery/armspringappdiscovery | v0.1.0 | v0 | 5780 |
| resourcemanager/sql/armsql | v1.2.0 | stable; newer v2.0.0-beta.9 | 109506 |
| resourcemanager/sqlvirtualmachine/armsqlvirtualmachine | v1.0.0 | stable | 6912 |
| resourcemanager/standbypool/armstandbypool | v2.1.0 | stable | 5418 |
| resourcemanager/storageactions/armstorageactions | v1.0.0 | stable | 3841 |
| resourcemanager/storagecache/armstoragecache | v4.3.0 | stable | 18217 |
| resourcemanager/storagediscovery/armstoragediscovery | v1.0.0 | stable | 2061 |
| resourcemanager/storageimportexport/armstorageimportexport | v0.7.0 | v0 | 3962 |
| resourcemanager/storagemover/armstoragemover | v2.5.0 | stable | 10755 |
| resourcemanager/storagepool/armstoragepool | v1.2.0 | stable | 5687 |
| resourcemanager/storagesync/armstoragesync | v2.1.0 | stable | 14390 |
| resourcemanager/streamanalytics/armstreamanalytics | v1.2.0 | stable; newer v2.0.0-beta.1 | 14898 |
| resourcemanager/subscription/armsubscription | v1.2.0 | stable; newer v2.0.0-beta.1 | 4807 |
| resourcemanager/support/armsupport | v2.0.0 | stable | 8887 |
| resourcemanager/synapse/armsynapse | v0.8.0 | v0 | 61169 |
| resourcemanager/tenantactivitylogalerts/armtenantactivitylogalerts | v0.1.0 | v0 | 1624 |
| resourcemanager/terraform/armterraform | v0.2.0 | v0 | 1893 |
| resourcemanager/testbase/armtestbase | v0.7.0 | v0 | 13474 |
| resourcemanager/timeseriesinsights/armtimeseriesinsights | v1.2.0 | stable | 8725 |
| resourcemanager/trafficmanager/armtrafficmanager | v2.0.0 | stable | 4455 |
| resourcemanager/virtualmachineimagebuilder/armvirtualmachineimagebuilder | v3.0.0 | stable | 6161 |
| resourcemanager/vmwarecloudsimple/armvmwarecloudsimple | v1.2.0 | stable | 9852 |
| resourcemanager/webpubsub/armwebpubsub | v1.3.0 | stable | 11456 |
| resourcemanager/weightsandbiases/armweightsandbiases | v1.0.0 | stable | 2373 |
| resourcemanager/windowsesu/armwindowsesu | v0.7.0 | v0 | 2070 |
| resourcemanager/windowsiot/armwindowsiot | v1.2.0 | stable | 2267 |
| resourcemanager/workloadmonitor/armworkloadmonitor | v0.5.1 | v0, deprecated | 820 |
| resourcemanager/workloadorchestration/armworkloadorchestration | v0.3.0 | v0 | 25158 |
| resourcemanager/workloads/armworkloads | v1.1.0 | stable | 16353 |
| resourcemanager/workloadssapvirtualinstance/armworkloadssapvirtualinstance | v1.0.0 | stable | 12085 |

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
armresources v4 and armkeyvault v2) are done by regenerating from the
specs. containers/azcontainerregistry v0.2.3 is done: its operations
generated from the swagger with Go's autorest.md directives as JSON
patches, and its challenge policy, chunk upload and digest helpers
written by hand, with requests checked against Go's own. azcore's SSE
streaming is done (the reader, SSEResponse, and a streamed response
body in the pipeline). Next: ai/azopenai (v0, 284) on top of it.
