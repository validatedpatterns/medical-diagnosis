# Grafana Dashboard

The grafana dashboard is used to display the status of the `data services` pipeline. There are input sources from prometheus
as well as from the xraylab database.

## Additional Information

This chart utilizes custom RBAC policies in order to properly execute the job. Additionally, in order to use prometheus as a datasource, the `cluster-viewer` clusterRole is assocated with the `grafana-serviceaccount`

## RBAC

|rbac|name|roleBinding|serviceAccount|namespace|
|----|----|-----------|--------------|---------|
|clusterRole|cluster-monitoring-view|cluster-monitoring-view|xraylab-1/grafana-serviceaccount|n/a(clusterRole)|

## Dependencies

- database
