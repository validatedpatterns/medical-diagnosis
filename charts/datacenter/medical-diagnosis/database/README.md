# Database

This chart deploys a mariadb datbase used for persisting data about the xray images that have been processed.

#### Kubernetes Resources:

|resource|description|SyncWave|
|:--------:|-----------|------|
|db-host-cm | ConfigMap - Establishes the name for the xraylab database | 1 |
|db-init-cm | ConfigMap - Creates script for deploymentConfig to initialize the database | 1 |
|db-dc | DeployConfig - Deploy database!| 5 |
|pvc| Persistent volume for mariadb| 10 |
|service| database service resource| 8 |


The database chart is a primary component of the medical diagnosis pattern. There are several other applications which depend on the database deployment.
- grafana
- image-generator
- image-server
- risk-assessment

### Additional Information:

**Dependencies**:
none

**Reinitialize the database**
```shell
DROP TABLE images_uploaded;
DROP TABLE images_processed;
DROP TABLE images_anonymized;

CREATE TABLE images_uploaded(time TIMESTAMP, name VARCHAR(255));
CREATE TABLE images_processed(time TIMESTAMP, name VARCHAR(255), model VARCHAR(10), label VARCHAR(20));
CREATE TABLE images_anonymized(time TIMESTAMP, name VARCHAR(255));

INSERT INTO images_uploaded(time,name) SELECT CURRENT_TIMESTAMP(), '';
INSERT INTO images_processed(time,name,model,label) SELECT CURRENT_TIMESTAMP(), '', '','';
INSERT INTO images_anonymized(time,name) SELECT CURRENT_TIMESTAMP(), '';
```
**Display rows from each table**
```shell
SELECT * FROM images_uploaded;
SELECT * FROM images_processed;
SELECT * FROM images_anonymized;
```