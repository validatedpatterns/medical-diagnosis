# xray-init 

This chart makes up the majority of the riskassessment demo application for the pattern. There are a number of services (applications) included 
in this single chart. The applications are rolled out using sync-waves and sync-hooks in order to determine the deployment order. Each application has a 
number of helm templates associated with it.

**Application Templates**:
- objectstore-user
- rbac
- riskAssessment
- s3-bucket-init



**Dependencies**:
- database
- db-secret
