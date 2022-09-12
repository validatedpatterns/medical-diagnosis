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
	ansible-playbook -e pattern_repo_dir="{{lookup('env','PWD')}}" -e helm_charts_dir="{{lookup('env','PWD')}}/charts/all" ./ansible/site.yaml

common-test:
	make -C common -f common/Makefile test

test:
	make -f common/Makefile CHARTS="$(shell find charts/all -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}" \;)" PATTERN_OPTS="-f values-hub.yaml" test
	make -f common/Makefile CHARTS="$(wildcard charts/region/*)" PATTERN_OPTS="-f values-region-one.yaml" test

helmlint:
	@for t in "$(shell find charts/all -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}" \;)"; do helm lint $$t; if [ $$? != 0 ]; then exit 1; fi; done

super-linter: ## Runs super linter locally
	make -f common/Makefile DISABLE_LINTERS="-e VALIDATE_ANSIBLE=false" super-linter

.phony: install test
