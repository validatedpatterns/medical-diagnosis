ARGO_TARGET_NAMESPACE=xraylab-1
PATTERN=medical-diagnosis
COMPONENT=datacenter
SECRET_NAME="argocd-env"
TARGET_REPO=$(shell git remote show origin | grep Push | sed -e 's/.*URL://' -e 's%:[a-z].*@%@%' -e 's%:%/%' -e 's%git@%https://%' )
CHART_OPTS=-f values-global.yaml -f values-datacenter.yaml --set global.targetRevision=main --set global.valuesDirectoryURL="https://github.com/pattern-clone/pattern/raw/main/" --set global.pattern="medical-diagnosis" --set global.namespace="pattern-namespace"

<<<<<<< HEAD
.PHONY: default
default: show
=======
# --set values always take precedence over the contents of -f
HELM_OPTS=-f values-global.yaml -f $(SECRETS) --set main.git.repoURL="$(TARGET_REPO)" --set main.git.revision=$(TARGET_BRANCH) --set global.hubClusterDomain=$(HUBCLUSTER_APPS_DOMAIN)
TEST_OPTS= -f common/examples/values-secret.yaml -f values-global.yaml --set global.repoURL="https://github.com/pattern-clone/mypattern" --set main.git.repoURL="https://github.com/pattern-clone/mypattern" --set main.git.revision=main --set global.valuesDirectoryURL="https://github.com/pattern-clone/mypattern/raw/main" --set global.pattern="mypattern" --set global.namespace="pattern-namespace" --set global.hubClusterDomain=hub.example.com --set global.localClusterDomain=region.example.com --set "clusterGroup.imperative.jobs[0].name"="test" --set "clusterGroup.imperative.jobs[0].playbook"="ansible/test.yml"
PATTERN_OPTS=-f common/examples/values-example.yaml
>>>>>>> c16f89e (Add some helm tests for imperative jobs)

%:
	echo "Delegating $* target"
	make -f common/Makefile $*

install: deploy
	echo "Bootstrapping Medical Diagnosis Pattern"
	make vault-init
	make load-secrets
	echo "Installed"

predeploy:
	./scripts/precheck.sh

update: upgrade
	echo "Bootstrapping Medical Diagnosis Pattern"
	make bootstrap

bootstrap:
	#./scripts/bootstrap-medical-edge.sh
	ansible-playbook -e pattern_repo_dir="{{lookup('env','PWD')}}" -e helm_charts_dir="{{lookup('env','PWD')}}/charts/datacenter" ./ansible/site.yaml

common-test:
	make -C common -f common/Makefile test

test:
	make -f common/Makefile CHARTS="secrets $(shell find charts/datacenter -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}" \;)" PATTERN_OPTS="-f values-datacenter.yaml" test
	make -f common/Makefile CHARTS="$(wildcard charts/factory/*)" PATTERN_OPTS="-f values-factory.yaml" test

helmlint:
	@for t in "secrets $(shell find charts/datacenter -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}" \;)"; do helm lint $$t; if [ $$? != 0 ]; then exit 1; fi; done
