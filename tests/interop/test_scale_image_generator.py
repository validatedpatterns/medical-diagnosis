import logging
import time

import pytest
from validatedpatterns_tests.interop.crd import DeploymentConfig

from . import __loggername__

logger = logging.getLogger(__loggername__)


@pytest.mark.scale_image_generator
def test_scale_image_generator(openshift_dyn_client):
    name = "image-generator"
    replicas = 1
    body = {"spec": {"replicas": replicas}, "metadata": {"name": name}}

    logger.info("Check current replicas for image-generator deploymentconfig")
    dc = DeploymentConfig.get(
        dyn_client=openshift_dyn_client, namespace="xraylab-1", name=name
    )
    dc = next(dc)

    if int(dc.instance.status.replicas) != 0:
        err_msg = "Expected 0 replicas for image-generator deploymentconfig"
        logger.error(f"FAIL: {err_msg}")
        assert False, err_msg
    else:
        logger.info(f"Replicas found: {dc.instance.status.replicas}")

    logger.info("Scale image-generator deploymentconfig")
    dc.update(resource_dict=body)

    logger.info("Wait for image-generator pod")
    timeout = time.time() + 120
    while time.time() < timeout:
        time.sleep(5)
        dc = DeploymentConfig.get(
            dyn_client=openshift_dyn_client, namespace="xraylab-1", name=name
        )
        dc = next(dc)
        if int(dc.instance.status.replicas) == replicas:
            break

    if int(dc.instance.status.replicas) != replicas:
        err_msg = f"Expected {replicas} replicas for {name} deploymentconfig"
        logger.error(f"FAIL: {err_msg}")
        assert False, err_msg
    else:
        logger.info("PASS: Scale image-generator test passed")
