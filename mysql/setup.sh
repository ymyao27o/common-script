
#!/bin/bash
set -e

MYSQL_MASTER_CONTAINER_NAME="mysql-master"
MYSQL_SLAVE_01_CONTAINER_NAME="mysql-slave-01"
MYSQL_COMMON_USER="root"
MYSQL_COMMON_PASS="admin@1024"

CONNECT_MASTER_PATH="sql/connect_master.sql"
CREATE_SLAVE_PATH="sql/create_slave_user.sql"
TEST_CREATE_SYNC_PATH="sql/test_create_sync.sql"
TEST_QUERY_PATH="sql/test_query.sql"

WAIT_HEALTHY_ATTEMPT=12

function create_slave_user(){
    echo "create slave user in master node"
    docker cp $CREATE_SLAVE_PATH $MYSQL_MASTER_CONTAINER_NAME:/tmp
    docker exec -it $MYSQL_MASTER_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS < /tmp/${CREATE_SLAVE_PATH#sql/}"
}

function modify_conn_info(){
    echo "modify connect info by master status"

    local file_flag_num=$(egrep 'Position|File' "$CONNECT_MASTER_PATH" | wc -l)
    if [[ "$file_flag_num" == "2" ]]; then
        cp -r "$CONNECT_MASTER_PATH"{,.bak}
    else
        if [[ -e "$CONNECT_MASTER_PATH.bak" ]]; then
            rm -f "$CONNECT_MASTER_PATH"
            cp -r "$CONNECT_MASTER_PATH"{.bak,}
        else
            echo "don't complete of $CONNECT_MASTER_PATH"
            exit 1
        fi
    fi

    local master_status=$(docker exec -it $MYSQL_MASTER_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS -e 'SHOW MASTER STATUS\G'" | egrep -i 'file|position' | tr -d " ")
    local file=$(echo "$master_status" | awk -F: '$1=="File"{print $2}' | tr -d "\r") 
    local position=$(echo "$master_status" | awk -F: '$1=="Position"{print $2}' | tr -d "\r") 

    sed -i "s/File/$file/g" $CONNECT_MASTER_PATH
    sed -i "s/Position/$position/g" $CONNECT_MASTER_PATH
}  

function connect_master(){
    echo "connect master of slave node"
    docker cp $CONNECT_MASTER_PATH $MYSQL_SLAVE_01_CONTAINER_NAME:/tmp
    docker exec -it $MYSQL_SLAVE_01_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS < /tmp/${CONNECT_MASTER_PATH#sql/}"
}


function test_sync_data(){
    echo "test sync ddl/dml data"
    docker cp $TEST_CREATE_SYNC_PATH $MYSQL_MASTER_CONTAINER_NAME:/tmp
    docker exec -it $MYSQL_MASTER_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS < /tmp/${TEST_CREATE_SYNC_PATH#sql/}"

    docker cp $TEST_QUERY_PATH $MYSQL_MASTER_CONTAINER_NAME:/tmp
    docker cp $TEST_QUERY_PATH $MYSQL_SLAVE_01_CONTAINER_NAME:/tmp
    docker exec -it $MYSQL_MASTER_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS < /tmp/${TEST_QUERY_PATH#sql/}"
    docker exec -it $MYSQL_SLAVE_01_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS < /tmp/${TEST_QUERY_PATH#sql/}"

    docker exec -it $MYSQL_MASTER_CONTAINER_NAME bash -c "mysql -u$MYSQL_COMMON_USER -p$MYSQL_COMMON_PASS -e 'drop database company;'"
}

function up(){
    docker compose -f docker-compose.yml up -d
}

function down(){
    local container_num=$(docker ps --filter 'name=mysql-*' --format 'table{{.Names}}\t{{.Status}}' | wc -l)
    if [[ $container_num -gt 1 ]]; then
        docker compose -f docker-compose.yml down --volumes
    fi
}

function check_healthy(){
    local healthy_num=$(docker ps --filter 'name=mysql-*' --format 'table{{.Names}}\t{{.Status}}' |grep '(healthy)' | wc -l)
    if [[ $healthy_num -ge 2 ]]; then
        return 0
    else 
        return 1
    fi
}

function wait_healthy(){
    local attempt=0
    while ! check_healthy; do
        if [[ $attempt -ge $WAIT_HEALTHY_ATTEMPT ]]; then
            echo "Container is not healthy after $WAIT_HEALTHY_ATTEMPT attempts."
            exit 1
        fi

        echo "Waiting for container to become healthy (attempt $attempt/$WAIT_HEALTHY_ATTEMPT)..."
        attempt=$((attempt + 1))
        sleep 5
    done
}



function setup(){
    down
    up
    wait_healthy
    create_slave_user
    modify_conn_info
    connect_master
    test_sync_data
}

# Usage message
usage() {
    echo "Usage: $0 [OPTIONS] "
    echo "Options:"
    echo "  -i,          setup sync group"
    echo "  -m,          modify conn info"
    echo "  -c,          connect master"
    echo "  -s,          create slave user"
    echo "  -t,          test sync data"
    echo "  -u,          compose up"
    echo "  -d,          compose down"
    echo ""
    exit 1
}

METHOD="usage"

while getopts "imcstudh" arg 
do
	case $arg in
             i)
                METHOD="setup"
                ;;
             m)
                METHOD="modify_conn_info"
                ;;
             c)
                METHOD="connect_master"
                ;;
             s)
                METHOD="create_slave_user"
                ;;
             t)
                METHOD="test_sync_data"
                ;;
             u)
                METHOD="up"
                ;;
             d)
                METHOD="down"
                ;;
             h)
                METHOD="check_healthy"
                ;;
             *)  
            	echo "unkonw argument"
        exit 1
        ;;
        esac
done

$METHOD