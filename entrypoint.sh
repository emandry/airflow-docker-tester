#!/bin/bash

set -e
echo "Validating required params..."

if [ -z $USE_CONSUL ]; then
  echo "APP_ENV is missing"
  exit 1
fi

if ($USE_CONSUL); then 
    if [ -z $APP_ENV ]; then
    echo "APP_ENV is missing"
    exit 1
    fi

    if [ -z $ROOT_APP_FOLDER ]; then
    echo "ROOT_APP_FOLDER is missing"
    exit 1
    fi

    if [ -z $CONSUL_HTTP_ADDR ]; then
    echo "CONSUL_HTTP_ADDR is missing"
    exit 2
    fi

    if [ -z $CONSUL_HTTP_TOKEN ]; then
    echo "CONSUL_HTTP_TOKEN is missing"
    exit 3
    fi
fi

export AIRFLOW_HOME="/airflow"
export AIRFLOW_CONFIG=/root/$AIRFLOW_HOME/airflow.cfg
export DAG_FOLDER="dags"

function readAndImportVar {
    filevar=$1
    fileContent=$(sed -e "s/{DAG}/$filevar/g" /entrypoint/variables.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl
    fileContent=$(sed -e "s/{ROOT_APP_FOLDER}/$ROOT_APP_FOLDER/g" /entrypoint/$filevar.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl
    fileContent=$(sed -e "s/{APP_ENV}/$APP_ENV/g" /entrypoint/$filevar.tmpl) ; echo $fileContent > /entrypoint/$filevar.tmpl

    /entrypoint/consul-template -template="/entrypoint/$filevar.tmpl:/entrypoint/${filevar}_variable.json" -config /entrypoint/config.hcl -once -log-level info
    if ([ -f "/entrypoint/${filevar}_variable.json" ] && [[ ! -z $(grep '[^[:space:]]' "/entrypoint/${filevar}_variable.json") ]]); then
        airflow variables import /entrypoint/${filevar}_variable.json
    fi
}


airflow db reset --y 
airflow users create --role Admin --username admin --email admin --firstname admin --lastname admin --password admin

if ($USE_CONSUL); then
    for filevar in $(ls "$AIRFLOW_HOME/dags/"); do
        echo "******** Import variables $filevar"
        readAndImportVar "$filevar"
    done; 
    echo "******** Import variables common"
    readAndImportVar "common"
fi
    

airflow scheduler -n=1
airflow dags list-import-errors

# echo "******** before Import variables $file"

# echo "******** before Import variables $VARIABLE_FILE"

# if [ ! -z $VARIABLE_FILE ] ; then
#     echo ">>>>>>>> Varaible llena" 
#     if [ "find . -name variables.json" ] ; then
#         echo "******** Import variables $VARIABLE_FILE"
#         airflow variables import $AIRFLOW_HOME/variables/$VARIABLE_FILE
#     fi;
# #else
# #   echo "ERROR: A variable file was defined an it doesn't exist"
# #    exit 1
# fi

#  echo "******** After Import variables $file"

# a=0;
# for file in $(ls $AIRFLOW_HOME/$DAG_FOLDER/*.py); do 
#     echo "******** Execute lint on $file"
#     flake8  --ignore E501 $file
#     echo "******** End of lint on $file"

#     echo "******** Execute python on $file"
#     python $file ; 
#     if [[ $? == 1 ]] ; then
#         a=1;
#     fi
#     echo "******** End python on $file"
    
#     echo "******** Execute  black on $file"
#     pytest $file --black -v  -W ignore::DeprecationWarning
#     echo "******** End of lint on $file"
# done

# if [ -z "$TESTS_FOLDER" ] ; then
#     echo "******** Execute test on all dags in folder"
#     pytest $AIRFLOW_HOME/$DAG_FOLDER/$TESTS_FOLDER/*.py -v -W ignore::DeprecationWarning
#     if [[ $? == 1 ]] ; then
#         a=1;
#     fi

#     if [[ $a == 1 ]] ; then
#         echo "There are tests that failed"
#     fi
# fi

exit $a

