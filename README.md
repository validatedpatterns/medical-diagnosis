# Validated Pattern - XRay analysis automated pipeline

This Validated Pattern is based on a demo implemetation of an automated data pipeline for chest Xray
analysis previously developed by Red Hat.  The original demo can be found in https://github.com/red-hat-data-services/jumpstart-library[here].

The Validated Pattern includes the same functionality as the original demonstration.  The difference is
that we use the *GitOps* to deploy most of the components which includes operators, creation of namespaces,
and cluster configuration.

The Validated Pattern includes:

* Ingest chest Xrays into an object store based on Ceph.
* The Object store sends notifications to a Kafka topic.
* A KNative Eventing Listener to the topic triggers a KNative Serving function.
* An ML-trained model running in a container makes a risk of Pneumonia assessment for incoming images.
* A Grafana dashboard displays the pipeline in real time, along with images incoming, processed and anonymized, as well as full metrics.

This pipeline is showcased link: https://www.youtube.com/watch?v=zja83FVsm14[in this video].

![Pipeline dashboard](doc/dashboard.png)


This validated pattern is still being developed.  More to come in the next few weeks. Any questions or concerns
please contact [Jonny Rickard](jrickard@redhat.com) or [Lester Claudio](claudiol@redhat.com).
