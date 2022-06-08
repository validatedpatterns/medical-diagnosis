ARGO_TARGET_NAMESPACE=xraylab-1
PATTERN=medical-diagnosis
COMPONENT=datacenter
SECRET_NAME="argocd-env"
TARGET_REPO=$(shell git remote show origin | grep Push | sed -e 's/.*URL://' -e 's%:[a-z].*@%@%' -e 's%:%/%' -e 's%git@%https://%' )
CHART_OPTS=-f values-global.yaml -f values-datacenter.yaml --set global.targetRevision=main --set global.valuesDirectoryURL="https://github.com/pattern-clone/pattern/raw/main/" --set global.pattern="medical-diagnosis" --set global.namespace="pattern-namespace"

.PHONY: default
default: show

%:
	echo "Delegating $* target"
	make -f common/Makefile $*

install: deploy
	echo "Bootstrapping Medical Diagnosis Pattern"
	make bootstrap

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
