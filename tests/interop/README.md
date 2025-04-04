# Running tests

## Prerequisites

* Openshift cluster with medical-diagnosis pattern installed
* kubeconfig file for Openshift cluster
* oc client installed at ~/oc_client/oc

## Steps

* create python3 venv, clone medical-diagnosis repository
* export KUBECONFIG=\<path to hub kubeconfig file>
* export INFRA_PROVIDER=\<infra platform description>
* (optional) export WORKSPACE=\<dir to save test results to> (defaults to /tmp)
* cd medical-diagnosis/tests/interop
* pip install -r requirements.txt
* ./run_tests.sh

## Results

* results .xml files will be placed at $WORKSPACE
* test logs will be placed at $WORKSPACE/.results/test_execution_logs/
* CI badge file will be placed at $WORKSPACE

## UI-based tests

* requires [Playwright](https://playwright.dev/docs/intro)Version 1.50.0 and dependencies
* requires included config (playwright.config.ts)
* edit medicaldiag.spec.ts to add values for:
  * \<hub console url\>
  * \<kubeadmin password\>
  * \<hub cluster name\>
* for testing Openshift 4.16 clusters:
  * remove medicaldiag-test-routes-and-grafana-dashboard-1-chromium-linux.417.png
    from snapshots directory
* for testing Openshift 4.17+ clusters:
  * remove medicaldiag-test-routes-and-grafana-dashboard-1-chromium-linux.416.png
    from snapshots directory
* "npx playwright test medicaldiag.spec.ts" to execute
