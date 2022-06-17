# Image Generator

This application is used to `simulate` an imaging device sending an image (xray) to a rgw bucket.

#### Kubernetes Resources:

|resource|description|SyncWave|
|:--------:|-----------|------|
|image-generator-buckets-cm | ConfigMap - defines the bucket source and bucket base name | 0 |
|image-generator-dc | deployConfig - Deployes the image-generator application | 5 |
|image-generator-is| imageStream to pull the image-generator image from quay | 1 |

### Additional Information:

The default image for the imagestream is: `quay.io/rh-data-services/xraylab-image-generator:latest`

**Dependencies**
- xray-init/objectstore-user
- db-secret