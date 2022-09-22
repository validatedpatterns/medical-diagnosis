.PHONY: default
default: show

%:
	echo "Delegating $* target"
	make -f common/Makefile $*

install: operator-deploy post-install ## installs the pattern, inits the vault and loads the secrets
	echo "Installed"

legacy-install: legacy-deploy post-install ## install the pattern the old way without the operator
	echo "Installed"

post-install: ## Post-install tasks - vault init and load-secrets
	@if grep -v -e '^\s\+#' "values-hub.yaml" | grep -q -e "insecureUnsealVaultInsideCluster:\s\+true"; then \
	  echo "Skipping 'make vault-init' as we're unsealing the vault from inside the cluster"; \
	else \
	  make vault-init; \
	fi
	make load-secrets
	echo "Done"

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

.phony: install test
