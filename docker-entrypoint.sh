#!/bin/bash

function read_env {
    for var in `env`
    do
      if [[ "$var" =~ ^flink_ ]]; then
        env_var=`echo "$var" | sed -r "s/(.*)=.*/\1/g"` #extract just the env var name out of $var
        flink_property=`echo "$env_var" | tr _ .  | sed -e "s/flink.//g"`
        echo "$flink_property: ${!env_var}"
        echo "$flink_property: ${!env_var}" >> $FLINK_CONFIG_FILE
      fi
    done
}

if [ "$1" = "jobmanager" ]; then

    echo "container debug : "
    echo "hostname -f : " 
    hostname -f
    echo "hostname -i : " 
    hostname -i

    rpcPort=${job_manager_rpc_port_override:-$PORT0}
    webPort=${job_manager_web_port_override:-$PORT1}
    blobPort=${job_manager_blob_port_override:-$PORT2}

    echo "port 0 : $rpcPort" 
    echo "port 1 : $webPort" 
    echo "port 2 : $blobPort" 

    export flink_jobmanager_rpc_address=${job_manager_rpc_override:-$(hostname -i)}
    export flink_jobmanager_rpc_port=$rpcPort
    export flink_jobmanager_web_port=$webPort
    export flink_blob_server_port=$blobPort

    read_env

    echo "Starting Job Manager"
    $FLINK_HOME/bin/jobmanager.sh start cluster
    echo "Config file: " && grep '^[^\n#]' $FLINK_CONFIG_FILE
    echo "Sleeping 10 seconds, then start to tail the log file"
    sleep 10 && tail -f `ls $FLINK_HOME/log/*.log | head -n1`

elif [ "$1" = "taskmanager" ]; then

    export flink_taskmanager_hostname=$(hostname -i)
    export flink_taskmanager_rpc_port=$PORT0
    export flink_taskmanager_data_port=$PORT1
    export flink_blob_server_port=$PORT2

    read_env

    echo "Starting Task Manager"
    $FLINK_HOME/bin/taskmanager.sh start
    echo "Config file: " && grep '^[^\n#]' $FLINK_CONFIG_FILE
    echo "Sleeping 10 seconds, then start to tail the log file"
    sleep 10 && tail -f `ls $FLINK_HOME/log/*.log | head -n1`

else
    $@
fi
