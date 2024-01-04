#!/bin/bash

set -e

function readAndImportVar {
    filevar=$1
    fileContent=$(sed -e "s|{DAG}|$filevar|g" /entrypoint/variables.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl
    fileContent=$(sed -e "s|{ROOT_APP_FOLDER}|$ROOT_APP_FOLDER|g" /entrypoint/$filevar.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl
    fileContent=$(sed -e "s|{APP_ENV}|$APP_ENV|g" /entrypoint/$filevar.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl
    fileContent=$(sed -e "s|{VAR_NAME}|$VAR_NAME|g" /entrypoint/$filevar.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl

    eval "/entrypoint/consul-template -template="/entrypoint/$filevar.tmpl:/entrypoint/${filevar}_variable.json" -config /entrypoint/config.hcl -once -log-level info ${logToFile}"
    if ([ -f "/entrypoint/${filevar}_variable.json" ] && [[ ! -z $(grep '[^[:space:]]' "/entrypoint/${filevar}_variable.json") ]]); then
        airflow variables import /entrypoint/${filevar}_variable.json 
    else
        echo "No variables loaded for this dag"
    fi
}

echo "******** Creating Airflow DB..."
eval "airflow db reset --y ${logToFile}"

echo "******** Validating required params..."

logToFile=" &> /var/log/entrypoint_log.txt"
if [ -n "$DEBUG_LOG" ] && [ "$DEBUG_LOG" == "true" ]  ; then
    ToFile=""
fi

if [ -z $USE_CONSUL ]; then
    echo "USE_CONSUL is missing"
    exit 1
fi

if ($USE_CONSUL); then 
    if [ -z $APP_ENV ]; then
        echo "APP_ENV is missing"
        exit 2
    fi

    if [ -z $ROOT_APP_FOLDER ]; then
        echo "ROOT_APP_FOLDER is missing"
        exit 3
    fi

    if [ -z $CONSUL_HTTP_ADDR ]; then
        echo "CONSUL_HTTP_ADDR is missing"
        exit 4
    fi

    if [ -z $CONSUL_HTTP_TOKEN ]; then
        echo "CONSUL_HTTP_TOKEN is missing"
        exit 5
    fi

    if [ -z $VAR_NAME ]; then
        echo "VAR_NAME is missing"
        exit 6
    fi

    echo "******** Import variables $VAR_NAME"
    readAndImportVar "$VAR_NAME"
fi


if [ -n $SECRET_FILE_NAME ] && [ -f $AIRFLOW_HOME/$SECRET_FILE_NAME ] ; then
        jq -Rn '
            [inputs
            | capture("(?<key>[^=]+)=(?<value>.*)")
            | { (.key): .value }
            ] | add
        ' $AIRFLOW_HOME/$SECRET_FILE_NAME > $AIRFLOW_HOME/secrets.json
        echo "******** Import secrets from $VAR_NAME"
        airflow variables import $AIRFLOW_HOME/secrets.json
    else
        echo "SECRET_FILE_NAME is declared and file is missing"
        exit 6
fi

    
echo "******** Importing dags into Airflow"
eval "nohup airflow scheduler -D > /var/log/scheduler_log.txt &"

echo " "
echo "******** List all imported DAGs"
airflow dags list
echo " "

echo "******** List all errors in airflow import process"
airflow dags list-import-errors





if [ -n "$USE_WEB_PAGE" ] && [ "$USE_WEB_PAGE" == "true" ]  ; then
    echo "******** Creating Airflow User Admin for access and staring webserver..."
    eval "airflow users create --role Admin --username admin --email admin --firstname admin --lastname admin --password admin ${logToFile}"
    airflow webserver
fi

