# Grafana Dashboard

The grafana dashboard is used to display the status of the `data services` pipeline. There are input sources from prometheus 
as well as from the xraylab database. 

#### Kubernetes Resources:

|resource|description|SyncWave|
|:--------:|-----------|------|
|grafana | CustomResource - Creates the grafana instance on the cluster | 1 |
|job-create-prometheus-datasource | job - Pulls bearer token from serviceAccount, creates a secret, and creates the prometheus datasource | 10 |
|mysql-datasource| datasource - MySQL datasource input for dashboard | 1 |
|xraylab-dashboard| Dashboard - dashboard to display the data pipeline | 2 |
|xraylab-images-dashboard| Dashboard - dashboard to display the processed images | 2 |

### Additional Information:

This chart utilizes custom RBAC policies in order to properly execute the job. Additionally, in order to use prometheus as a datasource, the `cluster-viewer` clusterRole is assocated with the `grafana-serviceaccount`

|rbac|name|resource|verbs|namespace|
|----|----|--------|-----|---------|
|role|grafana-mgmt|grafanadatasources|get,list,patch,create,update|xraylab-1|
|role|grafana-read-secrets|secrets|get,list,watch|xraylab-1|

|binding|rbac|serviceAccount|namespace|
|----|----|--------|-----|
|grafana-mgmt|grafana-mgmt|grafana-serviceaccount|xraylab-1|
|grafana-read-secrets|grafana-serviceaccount|xraylab-1|
|cluster-monitoring-view|cluster-monitoring-view|grafana-serviceaccount|xraylab-1|


**Dependencies**
- database

