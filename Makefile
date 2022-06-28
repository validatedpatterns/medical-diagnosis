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

deploy: validate-origin ## deploys the pattern
	helm install $(NAME) common/install/ $(HELM_OPTS)

upgrade: validate-origin ## runs helm upgrade
	helm upgrade $(NAME) common/install/ $(HELM_OPTS)

uninstall: ## runs helm uninstall
	helm uninstall $(NAME)

vault-init: ## inits, unseals and configured the vault
	common/scripts/vault-utils.sh vault_init common/pattern-vault.init

vault-unseal: ## unseals the vault
	common/scripts/vault-utils.sh vault_unseal common/pattern-vault.init

load-secrets: ## loads the secrets into the vault
	common/scripts/ansible-push-vault-secrets.sh

super-linter: ## Runs super linter locally
	podman run -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true	\
					-e VALIDATE_BASH=false \
					-e VALIDATE_JSCPD=false \
					-e VALIDATE_KUBERNETES_KUBEVAL=false \
					-e VALIDATE_YAML=false \
					-e VALIDATE_ANSIBLE=false \
					-v $(PWD):/tmp/lint:rw,z docker.io/github/super-linter:slim-v4

.phony: install test
