# xray-init 

This chart makes up the majority of the riskassessment demo application for the pattern. There are a number of services (applications) included 
in this single chart. This application is deployed this way to ensure that the syncwaves/hooks are properly ordering the deployment. 

**Application RollOut Order**:

|Application|Description|
|-----------|-----------|
|objectstore-user| radosgw (ODF) user. Required for bucket notifications|
|s3-bucket-init| Initializes s3-capable bucket in ODF and creates notification topics (SNS)|
|riskAssessment| ML trained model for detecting anomalies in xray images|
|RBAC| All role-based-access-controls required for the `xray-init` application|

In addition to syncwaves and synchooks we are using kubernetes jobs to wait for custom resources to return a specific status. Once the desired state has been met, the next item in the syncwave will begin. 

The objectstore-user secret is consumed by multiple applications. Without it, there is no notification to trigger the pipeline. 

**RBAC**
|rbac|name|roleBinding|serviceAccount|namespace|
|----|----|-----------|--------------|---------|
|clusterRole|view-odf-storageclusters|view-odf-storageclusters|xraylab-1/xraylab-1-sa|n/a(clusterRole)|
|clusterRole|view-odf-cephobjectstores|view-odf-cephobjectstores|xraylab-1/xraylab-1-sa|n/a(clusterRole)|
|clusterRole|view-odf-cephobjectstoreusers|view-odf-cephobjectstoreusers|xraylab-1/xraylab-1-sa|n/a(clusterRole)|
|clusterRole|read-objectstore-secret|read-objectstore-secret|xraylab-1/xraylab-1-sa|n/a(clusterRole)|
|role|create-pattern-secret|create-pattern-secret|xraylab-1-sa|xraylab-1|
|role|view-pattern-jobs|view-pattern-jobs|xraylab-1-sa|xraylab-1|

|binding|rbac|serviceAccount|namespace|
|----|----|--------|-----|
|grafana-mgmt|grafana-mgmt|grafana-serviceaccount|xraylab-1|
|grafana-read-secrets|grafana-read-secrets|grafana-serviceaccount|xraylab-1|
|cluster-monitoring-view|cluster-monitoring-view|grafana-serviceaccount|xraylab-1|

**Dependencies**:
- database
- db-secret
