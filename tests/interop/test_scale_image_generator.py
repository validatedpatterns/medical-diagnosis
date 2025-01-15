import logging
import time

import pytest
from ocp_resources.deployment import Deployment

from . import __loggername__

logger = logging.getLogger(__loggername__)


@pytest.mark.scale_image_generator
def test_scale_image_generator(openshift_dyn_client):
    name = "image-generator"
    replicas = 1
    body = {"spec": {"replicas": replicas}, "metadata": {"name": name}}

    logger.info("Check current replicas for image-generator deployment")
    deployment = Deployment.get(
        dyn_client=openshift_dyn_client, namespace="xraylab-1", name=name
    )
    deployment = next(deployment)

    if int(deployment.instance.spec.replicas) != 0:
        err_msg = "Expected 0 replicas for image-generator deployment"
        logger.error(f"FAIL: {err_msg}")
        assert False, err_msg
    else:
        logger.info(f"Replicas found: {deployment}")

    logger.info("Scale image-generator deployment")
    deployment.update(resource_dict=body)

    logger.info("Wait for image-generator pod")
    timeout = time.time() + 120
    while time.time() < timeout:
        time.sleep(5)
        deployment = Deployment.get(
            dyn_client=openshift_dyn_client, namespace="xraylab-1", name=name
        )
        deployment = next(deployment)
        if int(deployment.instance.spec.replicas) == replicas:
            break

    if int(deployment.instance.spec.replicas) != replicas:
        err_msg = f"Expected {replicas} replicas for {name} deployment"
        logger.error(f"FAIL: {err_msg}")
        assert False, err_msg
    else:
        logger.info("PASS: Scale image-generator test passed")
