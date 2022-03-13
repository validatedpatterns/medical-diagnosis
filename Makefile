BOOTSTRAP=1
ARGO_TARGET_NAMESPACE=manuela-ci
PATTERN=industrial-edge
COMPONENT=datacenter
SECRET_NAME="argocd-env"
TARGET_REPO=$(shell git remote show origin | grep Push | sed -e 's/.*URL://' -e 's%:[a-z].*@%@%' -e 's%:%/%' -e 's%git@%https://%' )
CHART_OPTS=-f common/examples/values-secret.yaml -f values-global.yaml -f values-datacenter.yaml --set global.targetRevision=main --set global.valuesDirectoryURL="https://github.com/pattern-clone/pattern/raw/main/" --set global.pattern="industrial-edge" --set global.namespace="pattern-namespace"

.PHONY: default
default: show

%:
	echo "Delegating $* target"
	make -f common/Makefile $*

install: deploy
ifeq ($(BOOTSTRAP),1)
	echo "Bootstrapping Medical Diagnosis Pattern"
	make bootstrap
endif

predeploy:
	./scripts/precheck.sh

update: upgrade
ifeq ($(BOOTSTRAP),1)
	echo "Bootstrapping Medical Diagnosis Pattern"
	make bootstrap
endif

bootstrap:
	#./scripts/bootstrap-medical-edge.sh
	ansible-playbook -e pattern_repo_dir="{{lookup('env','PWD')}}" -e helm_charts_dir="{{lookup('env','PWD')}}/charts/datacenter" ./ansible/site.yml 

common-test:
	make -C common -f common/Makefile test

test:
	make -f common/Makefile CHARTS="secrets $(shell find charts/datacenter -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}"  \;)" PATTERN_OPTS="-f values-datacenter.yaml" test
	make -f common/Makefile CHARTS="$(wildcard charts/factory/*)" PATTERN_OPTS="-f values-factory.yaml" test

helmlint:
	@for t in "$(wildcard charts/datacenter/*)" "$(wildcard charts/factory/*)"; do helm lint $$t; if [ $$? != 0 ]; then exit 1; fi; done
