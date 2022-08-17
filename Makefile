PATTERN=medical-diagnosis

.PHONY: default
default: show

%:
	echo "Delegating $* target"
	make -f common/Makefile $*

install: validate-origin deploy
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

super-linter: ## Runs super linter locally
	podman run -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true	\
					-e VALIDATE_BASH=false \
					-e VALIDATE_JSCPD=false \
					-e VALIDATE_KUBERNETES_KUBEVAL=false \
					-e VALIDATE_YAML=false \
					-e VALIDATE_ANSIBLE=false \
					-v $(PWD):/tmp/lint:rw,z docker.io/github/super-linter:slim-v4

.phony: install test
