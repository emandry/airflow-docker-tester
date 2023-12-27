#!/bin/sh
export AIRFLOW_HOME="/airflow"
export DAG_FOLDER="dags"
export VARIABLE_FILE="variables.json"

airflow db init

echo "******** before Import variables $file"

echo "******** before Import variables $VARIABLE_FILE"

if [ ! -z $VARIABLE_FILE ] ; then
    echo ">>>>>>>> VAraible llena" 
    if [ -f "$AIRFLOW_HOME/variables/$VARIABLE_FILE" ] ; then
        echo "******** Import variables $VARIABLE_FILE"
        airflow variables import $AIRFLOW_HOME/variables/$VARIABLE_FILE
    fi;
#else
#   echo "ERROR: A variable file was defined an it doesn't exist"
#    exit 1
fi

 echo "******** After Import variables $file"

a=0;
for file in $(ls $AIRFLOW_HOME/$DAG_FOLDER/*.py); do 
    echo "******** Execute lint on $file"
    flake8  --ignore E501 $file
    echo "******** End of lint on $file"

    echo "******** Execute python on $file"
    python $file ; 
    if [[ $? == 1 ]] ; then
        a=1;
    fi
    echo "******** End python on $file"
    
    echo "******** Execute  black on $file"
    pytest $file --black -v  -W ignore::DeprecationWarning
    echo "******** End of lint on $file"
done

if [ -z "$TESTS_FOLDER" ] ; then
    echo "******** Execute test on all dags in folder"
    pytest $AIRFLOW_HOME/$DAG_FOLDER/$TESTS_FOLDER/*.py -v -W ignore::DeprecationWarning
    if [[ $? == 1 ]] ; then
        a=1;
    fi

    if [[ $a == 1 ]] ; then
        echo "There are tests that failed"
    fi
fi

exit $a

