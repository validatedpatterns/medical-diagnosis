BOOTSTRAP=1
PATTERN=example
COMPONENT=datacenter
SECRET_NAME="argocd-env"

.PHONY: default
default: show

%:
	make -f common/Makefile $*

install: deploy
