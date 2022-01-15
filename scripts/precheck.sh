#!/bin/bash

CLUSTERNAME=""

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
#   \033[0K\r - Trailing escape sequence to leave output on the same line
function log {
    if [ -z "$2" ]; then
        echo -e "\033[0K\r\033[1;36m$1\033[0m"
    else
        echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
    fi
}

function datacenterGlobalValues {
    CLUSTERVALUE=$(echo $CLUSTERNAME | cut -d . -f 1)
    DOMAINVALUE=$(echo $CLUSTERNAME | cut -d . -f 2-)
    echo "Please make sure that your values-global.yaml contains the following values: "
    echo '\
  datacenter:
    clustername: $CLUSTERVALUE
    domain: $DOMAINVALUE
    '
    exit 10
}

function externalUrlVariableValue {
    echo "The externalUrl value should be: "
    echo '
      externalUrl: "https://s3-rgw-openshift-storage.apps.$CLUSTERNAME"'
    exit 10
}

function checkValuesGlobal {
    log "Checking values-global.yaml settings"
    #
    # First check datacenter: section in values-global.yaml
    #    
    log -n "Verifying clustername and domain values: "
    CLUSTERVALUE=$(grep -E 'clustername:' ./values-global.yaml | grep -v "#" | cut -d : -f 2 | tr -d ' ' | tr -d '"')
    DOMAINVALUE=$(grep -E '  domain:' ./values-global.yaml | grep -v "#" | cut -d : -f 2 | tr -d ' ' | tr -d '"')

    if [ "$CLUSTERNAME" == "$CLUSTERVALUE.$DOMAINVALUE" ]; then
	echo "pass"
    else
	echo "fail"
	datacenterGlobalValues
    fi

    #
    # Verify externalUrl value
    #
    log -n "Verifying externalUrl value: "
    EXTERNALURL=$(grep -E 'externalUrl' ./values-global.yaml | grep -v "#" | cut -d : -f 2- | tr -d ' ' | tr -d '"')
    CLUSTERVALUE=$(echo $EXTERNALURL | cut -d . -f 3- | tr -d ' ' | tr -d '"')
    if [ "$CLUSTERVALUE" == "$CLUSTERNAME" ]; then
	echo "pass"
    else
	echo "fail"
	externalUrlVariableValue
    fi
}

    
    
function checkVariables {
    #
    # Generate the secrets manifest for S3 and database
    #
    log -n "Making sure that required variables are set ... "
    CLUSTERNAME=$(oc get route -n openshift-console | grep ^console | awk '{print $2}' | cut -d . -f 3-)
    if [ $? != 0 ]; then
	echo "fail."
	echo "Cannot determine the cluster name and domain"
	echo "Make sure that the command 'oc get route -n openshift-console' returns valid routes"
	exit 10
    fi
    checkValuesGlobal
}

function secretsFileTemplate {
    echo "Please ensure that the values-secret.yaml contains the following content:"
    echo '\
secrets: \
  xraylab:\
    db:\
      db_user: "xraylab"\
      db_passwd: "xraylab"\
      db_root_passwd: "xraylab"\
      db_host: "xraylabdb"\
      db_dbname: "xraylabdb"\
      db_master_password: "redhatredhat"\
      db_master_user: "root"'
    exit 10
}

function checkRequiredFiles {
    log -n "Checking file for values-secret.yaml: "
    if [ ! -f "~/values-secret.yaml" ]; then
	echo "pass"
    else
	echo "fail"
	echo "Make sure that the file values-secret.yaml exists in your home directory"
	exit 10
    fi
    log "Check that required secrets sections exist in values-secret.yaml"
    log  "Checking for xraylab sections: "
    for i in secrets: xraylab: db: db_user dn_passwd db_root_passwd db_host db_dbname db_master_password db_master_user
    do
	log -n "Checking [$i] ... "
	EXISTS=$(grep -E '$i' ~/values-secret.yaml)

	if [ $? -gt 0 ]; then
	    echo "pass"
	else
	    echo "fail"
	    secretsFileTemplate
	fi
    done
}

checkVariables
checkRequiredFiles

log "Proceeding with the following values specified in values-global.yaml: "
cat ./values-global.yaml | grep -v "#" | grep -E "datacenter:|  clustername: | domain: | externalUrl: | bucketSource: " 
while ( true )
do
    log -n "Proceed (Y/n)? "
    read -n 1 -r ans
    case $ans in
        [Yy]* ) break;;
        [Nn]* ) echo;exit 10;;
        * ) ;;
    esac    
done
