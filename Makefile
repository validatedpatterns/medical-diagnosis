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

install: predeploy deploy
ifeq ($(BOOTSTRAP),1)
	echo "Bootstrapping Medical Diagnosis Pattern"
	make bootstrap
endif

predeploy:
	./scripts/precheck.sh

update: predeploy upgrade
ifeq ($(BOOTSTRAP),1)
	echo "Bootstrapping Medical Diagnosis Pattern"
	make bootstrap
endif

bootstrap:
	./scripts/bootstrap-medical-edge.sh

test:
	make -f common/Makefile CHARTS="$(wildcard charts/datacenter/*)" PATTERN_OPTS="-f values-datacenter.yaml" test
	make -f common/Makefile CHARTS="$(wildcard charts/factory/*)" PATTERN_OPTS="-f values-factory.yaml" test

