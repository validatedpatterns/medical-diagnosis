# Image Server

This is a flask application used to serve the images to the grafana dashboard.

#### Kubernetes Resources:

|resource|description|SyncWave|
|:--------:|-----------|------|
|image-server-dc | deployConfig - Deploys the image-server application | 10 |
|image-server-svc | creates service to expose for image-server | 15 |
|image-server-route| creates image-server route | 17 |
|image-server-is| imageStream to pull the image-generator image from quay | 1 |

### Additional Information:

The default image for the imagestream is: `quay.io/rh-data-services/xraylab-image-server:latest`

**Dependencies**
- db-secret