# risk-assessment

This chart makes up the majority of the riskassessment demo application for the pattern. There are a number of services (applications) included
in this single chart. This application is deployed this way to ensure that the syncwaves/hooks are properly ordering the deployment.

## Application RollOut Order

|Application|Description|
|-----------|-----------|
|objectstore-user| radosgw (ODF) user. Required for bucket notifications|
|s3-bucket-init| Initializes s3-capable bucket in ODF and creates notification topics (SNS)|
|riskAssessment| ML trained model for detecting anomalies in xray images|

In addition to syncwaves and synchooks we are using kubernetes jobs to wait for custom resources to return a specific status. Once the desired state has been met, the next item in the syncwave will begin.

The objectstore-user secret is consumed by multiple applications. Without it, there is no notification to trigger the pipeline.
