# Medical Diagnosis Validated Pattern — On-Prem Ceph Deployment

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

This is a fork of the [Medical Diagnosis Validated Pattern](https://github.com/validatedpatterns/medical-diagnosis) adapted for **on-premise OpenShift clusters using Ceph object storage** (via OpenShift Data Foundation) instead of AWS S3.

The pattern deploys an automated AI/ML pipeline for chest X-ray analysis that identifies signs of pneumonia. It uses GitOps (ArgoCD) to deploy and manage all components.

### Pipeline Architecture

1. X-ray images are stored in a Ceph S3-compatible bucket (`xray-source`)
2. The `image-generator` reads source images and writes them to the processing bucket, triggering Kafka notifications
3. A KNative Serving function (`risk-assessment`) runs an ML model to assess pneumonia risk
4. A **Grafana dashboard** displays the pipeline in real time — incoming images, processed results, anonymized images, and risk distribution metrics

![Pipeline dashboard](doc/dashboard.png)

### Source Image Dataset

The upstream pattern uses the [Chest X-Ray Images (Pneumonia)](https://www.kaggle.com/datasets/paultimothymooney/chest-xray-pneumonia) dataset hosted in a public AWS S3 bucket (`validated-patterns-md-xray`). The bucket contains two folders that must both be copied to your local Ceph bucket:

| Folder | Description | Approx. Count |
|--------|-------------|---------------|
| `PNEUMONIA/` | X-ray images showing signs of pneumonia | ~390 images (28.6 MB) |
| `NORMAL/` | X-ray images with no abnormalities | ~234 images (17.2 MB) |

Since we are deploying on-prem without AWS, Step 9 of this guide walks you through copying **both folders** into your local Ceph bucket.

---

## Prerequisites

- OpenShift Container Platform 4.14+ with cluster-admin access
- **OpenShift Data Foundation (ODF)** installed and configured with Ceph object storage (RGW)
- `oc` CLI logged into the cluster
- `git` CLI
- `podman` or `docker` (for `pattern.sh`)
- A GitHub account (to fork this repo)

---

## Deployment Steps

### Step 1: Fork and Clone the Repository

```bash
# Fork this repo on GitHub, then clone your fork
git clone git@github.com:<your-github-username>/medical-diagnosis.git
cd medical-diagnosis
```

### Step 2: Get Your Ceph Object Storage Credentials

You need S3-compatible credentials for the Ceph Object Gateway (RGW) in your cluster. If you already have credentials, skip to the next step.

To create a CephObjectStoreUser and retrieve credentials:

```bash
# Check if a CephObjectStoreUser already exists
oc get cephobjectstoreuser -n openshift-storage

# If not, create one
cat <<EOF | oc apply -f -
apiVersion: ceph.rook.io/v1
kind: CephObjectStoreUser
metadata:
  name: xraylab-user
  namespace: openshift-storage
spec:
  store: ocs-storagecluster-cephobjectstore
  displayName: "XRay Lab User"
EOF

# Retrieve the credentials
oc get secret rook-ceph-object-user-ocs-storagecluster-cephobjectstore-xraylab-user \
  -n openshift-storage -o jsonpath='{.data.AccessKey}' | base64 -d && echo
oc get secret rook-ceph-object-user-ocs-storagecluster-cephobjectstore-xraylab-user \
  -n openshift-storage -o jsonpath='{.data.SecretKey}' | base64 -d && echo
```

Note down the `AccessKey` and `SecretKey` — you'll need them in Step 4.

### Step 3: Get Your Ceph RGW Endpoint

```bash
# Internal endpoint (used by pods inside the cluster)
echo "http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc.cluster.local"

# External endpoint (for browser access / verification)
oc get route -n openshift-storage | grep rgw
```

Verify the RGW is accessible by opening the external `s3-rgw` route URL in your browser. You should see XML output (not an error page). **Accept the self-signed certificate** if prompted — this is required for the Grafana dashboard to display images later.

### Step 4: Configure values-secret-medical-diagnosis.yaml

Create the secrets file in your **home directory** (NOT in the git repo):

```bash
cat > ~/values-secret-medical-diagnosis.yaml <<EOF
version: "2.0"
secrets:
  - name: xraylab
    fields:
      - name: database-user
        value: xraylab
      - name: database-host
        value: xraylabdb
      - name: database-db
        value: xraylabdb
      - name: database-master-user
        value: xraylab
      - name: database-password
        value: <choose-a-db-password>
      - name: database-root-password
        value: <choose-a-root-password>
      - name: database-master-password
        value: <choose-a-master-password>
  - name: s3-secret-bck
    fields:
      - name: AWS_ACCESS_KEY_ID
        value: <your-ceph-access-key-from-step-2>
      - name: AWS_SECRET_ACCESS_KEY
        value: <your-ceph-secret-key-from-step-2>
EOF
```

Replace all `<placeholder>` values with your actual credentials.

### Step 5: Configure values-global.yaml

Edit `values-global.yaml` in the repo with your cluster details:

```yaml
global:
  pattern: xray

  datacenter:
    storageClassName: ocs-storagecluster-cephfs
    cloudProvider: onprem
    region: local
    clustername: <your-ocp-cluster-name>
    domain: <your-cluster-domain>

  xraylab:
    namespace: "xraylab-1"
    s3:
      bucketSource: "xray-source"
      bucketBaseName: "xray-source"
      endpoint: "http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc.cluster.local"

main:
  clusterGroupName: hub
  multiSourceConfig:
    enabled: true
  clusterGroupChartVersion: 0.9.*
```

To find your cluster name and domain:

```bash
oc get ingress.config cluster -o jsonpath='{.spec.domain}' && echo
# Output example: apps.mycluster.example.com
# clustername = "mycluster"
# domain = "example.com"
# Or if using TechZone: domain = "698a7c2d3930333074587e84.am1.techzone.ibm.com"
```

### Step 6: Commit and Push Configuration

```bash
git add values-global.yaml
git commit -m "Configure for on-prem Ceph deployment"
git push origin main
```

### Step 7: Deploy the Pattern

```bash
./pattern.sh make install
```

This will:
- Install the Validated Patterns Operator
- Create the Pattern custom resource
- Deploy ArgoCD applications
- Create the `xraylab-1` namespace with all components

Monitor the deployment:

```bash
# Watch ArgoCD applications
watch -n 10 'oc get applications -n openshift-gitops'

# Wait for all pods to be running
watch -n 10 'oc get pods -n xraylab-1'
```

Wait until the `medical-diagnosis-hub` application shows `Synced` and `Healthy`, and the `bucket-init` job shows `Completed`.

### Step 8: Verify Bucket Initialization

```bash
oc get jobs -n xraylab-1
# bucket-init should show STATUS: Complete

oc logs -l job-name=bucket-init -n xraylab-1
# Should show all 3 buckets created and Kafka notifications configured
```

Expected output:
```
Bucket xray-source was created or already existing and owned by this user.
Bucket xray-source-processed was created or already existing and owned by this user.
Bucket xray-source-anonymized was created or already existing and owned by this user.
SNS topic: xray-images was created or already existing.
Notification for bucket: xray-source was created or already existing.
```

### Step 9: Copy X-Ray Images from AWS to Local Ceph Bucket

Since we are not using AWS, the source X-ray images must be copied from the upstream public AWS bucket into your local Ceph bucket. The AWS bucket contains two folders — `PNEUMONIA/` and `NORMAL/` — and **both must be copied** for the pipeline to work correctly.

This one-time step runs a pod inside the cluster that downloads images directly from the public AWS bucket and uploads them to your Ceph bucket.

**Copy all images:**

```bash
oc run upload-xrays --rm -it --restart=Never \
  --image=python:3.9-slim -n xraylab-1 -- bash -c "pip install boto3 -q && python3 -c \"
import boto3
from botocore import UNSIGNED
from botocore.config import Config

# Source: upstream public AWS bucket (no credentials needed)
src = boto3.client('s3', region_name='us-east-1', config=Config(signature_version=UNSIGNED))

# Destination: local Ceph bucket
dst = boto3.client('s3',
    endpoint_url='http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc.cluster.local',
    aws_access_key_id='<your-ceph-access-key>',
    aws_secret_access_key='<your-ceph-secret-key>')

paginator = src.get_paginator('list_objects_v2')
total = 0

for folder in ['PNEUMONIA/', 'NORMAL/']:
    count = 0
    for page in paginator.paginate(Bucket='validated-patterns-md-xray', Prefix=folder):
        for obj in page.get('Contents', []):
            key = obj['Key']
            data = src.get_object(Bucket='validated-patterns-md-xray', Key=key)['Body'].read()
            dst.put_object(Bucket='xray-source', Key=key, Body=data)
            count += 1
            total += 1
            if count % 20 == 0:
                print(f'  [{folder}] Copied {count} images...')
    print(f'{folder}: {count} images copied.')

print(f'All done! Total: {total} images copied to xray-source bucket.')
\""
```

**Replace** `<your-ceph-access-key>` and `<your-ceph-secret-key>` with your actual Ceph credentials from Step 2.

This will take several minutes. Wait for it to complete and confirm the total count.

**Verify the upload:**

```bash
oc run verify-bucket --rm -it --restart=Never \
  --image=python:3.9-slim -n xraylab-1 -- bash -c "pip install boto3 -q && python3 -c \"
import boto3
s3 = boto3.client('s3',
    endpoint_url='http://rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc.cluster.local',
    aws_access_key_id='<your-ceph-access-key>',
    aws_secret_access_key='<your-ceph-secret-key>')
paginator = s3.get_paginator('list_objects_v2')
for prefix in ['PNEUMONIA/', 'NORMAL/']:
    count = 0
    size = 0
    for page in paginator.paginate(Bucket='xray-source', Prefix=prefix):
        for obj in page.get('Contents', []):
            count += 1
            size += obj['Size']
    print(f'{prefix}: {count} images, {size/1024/1024:.1f} MB')
\""
```

Expected output:
```
PNEUMONIA/: 390 images, 28.6 MB
NORMAL/: 234 images, 17.2 MB
```

If counts don't match, re-run the upload command — it is idempotent and will overwrite existing files.

### Step 10: Start the Image Generator

The image-generator deployment starts at 0 replicas by design. Scale it up to begin the AI/ML pipeline:

**Option A — CLI:**
```bash
oc scale deployment/image-generator --replicas=1 -n xraylab-1
```

**Option B — OpenShift Console:**
1. Switch to **Developer** view → **Topology** → select `xraylab-1` project
2. Right-click the `image-generator` pod → **Edit Pod count** → set to `1`

### Step 11: Accept SSL Certificates for S3 Route

The Grafana dashboard loads images directly from the S3 RGW route. With self-signed certificates, your browser will block these images unless you accept the certificate.

```bash
oc get route -n openshift-storage | grep s3-rgw
```

Open the `s3-rgw` route URL in your browser and **accept the self-signed certificate**.

### Step 12: View the Grafana Dashboard

1. In the OpenShift Console, click the app launcher (nine-dots menu) → **Grafana**
2. Or get the route directly:
   ```bash
   oc get route -n xraylab-1 | grep grafana
   ```
3. In Grafana, go to **Dashboards** → `xraylab-1` folder → **XRay Lab**

Within 5–10 minutes of scaling up image-generator, you should see:
- Incoming images counter increasing
- Processed images with risk assessment results
- Anonymized images (PII stripped)
- Distribution chart showing Normal / Unsure / Pneumonia detected
- CPU and memory metrics for risk-assessment pods

---

## Key Files Modified for On-Prem Ceph

These are the files changed from the [upstream pattern](https://github.com/validatedpatterns/medical-diagnosis) to support on-prem Ceph instead of AWS:

| File | Change |
|------|--------|
| `values-global.yaml` | Ceph endpoint, on-prem storage class, local bucket names |
| `charts/all/medical-diagnosis/image-generator/templates/image-generator-buckets-cm.yaml` | Removed hardcoded `https://s3.amazonaws.com/` prefix from bucket-source |
| `charts/all/medical-diagnosis/image-generator/templates/image-gen-deployment.yaml` | Changed env vars to use `s3-secret-bck` secret and `service-point`/`buckets-config` configmaps instead of OBC (`md-xray-source`) |

---

## Troubleshooting

### Grafana dashboard is blank
- Verify image-generator is scaled to 1+: `oc get deployment image-generator -n xraylab-1`
- Check image-generator logs: `oc logs deployment/image-generator -n xraylab-1`
- Verify the source bucket has images in both `PNEUMONIA/` and `NORMAL/` folders (see Step 9 verification command)
- Accept the SSL certificate for the S3 RGW route (see Step 11)

### image-generator CrashLoopBackOff with "NoSuchBucket"
- Verify buckets exist: `oc logs -l job-name=bucket-init -n xraylab-1`
- Check the `buckets-config` configmap has correct values: `oc get cm buckets-config -n xraylab-1 -o yaml`
- Ensure `bucket-source` is just the bucket name (e.g., `xray-source`), not a full URL
- Restart the deployment after fixing: `oc rollout restart deployment/image-generator -n xraylab-1`

### Bucket-init job fails
- Check S3 credentials in the `s3-secret-bck` secret
- Verify the Ceph RGW service is running: `oc get pods -n openshift-storage | grep rgw`

### ArgoCD application not syncing
- Verify your Git branch matches what the Pattern CR is tracking:
  ```bash
  oc get pattern -A -o yaml | grep targetRevision
  ```
- Force a sync:
  ```bash
  oc patch application medical-diagnosis-hub -n openshift-gitops \
    --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
  ```

### S3 credentials invalid (InvalidAccessKeyId)
- If the cluster was reprovisioned, OBC credentials may have changed
- Re-retrieve credentials from your CephObjectStoreUser (see Step 2)
- Update `~/values-secret-medical-diagnosis.yaml` and redeploy

---

## Architecture Reference

| Component | Purpose |
|-----------|---------|
| `bucket-init` (Job) | Creates S3 buckets and configures Kafka notifications on Ceph RGW |
| `image-generator` (Deployment) | Reads X-ray images from source bucket and writes to processing bucket |
| `risk-assessment` (KNative Service) | ML model that assesses pneumonia risk from X-ray images |
| `xraylabdb` (Deployment) | PostgreSQL database storing processing results |
| `xray-cluster` (Kafka) | AMQ Streams Kafka cluster for event notifications |
| `xraylab-grafana` (Deployment) | Grafana instance with pre-configured dashboard |
| `kafdrop` (Deployment) | Kafka topic browser (optional, for debugging) |

---

## Credits

- Original pattern: [Red Hat Validated Patterns — Medical Diagnosis](https://validatedpatterns.io/patterns/medical-diagnosis/)
- X-ray dataset: [Chest X-Ray Images (Pneumonia)](https://www.kaggle.com/datasets/paultimothymooney/chest-xray-pneumonia)
- Upstream repository: [validatedpatterns/medical-diagnosis](https://github.com/validatedpatterns/medical-diagnosis)

## License

[Apache-2.0](LICENSE)
