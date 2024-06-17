#!/bin/bash

WORKSPACE=/opt/mongodb

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

UILT_PATH=$SCRIPT_PATH/util.sh

MONGO_USERNAME=mongod


function create_workspace(){
  sh $UILT_PATH -m confirm_delete -a "$WORKSPACE"
  mkdir -p $WORKSPACE/data $WORKSPACE/log $WORKSPACE/conf $WORKSPACE/pid
  chown -R $MONGO_USERNAME:$MONGO_USERNAME $WORKSPACE
}


function set_selinux_policy(){

  if [[ -e "$SCRIPT_PATH/mongodb_cgroup_memory.pp" ]]; then
    checkmodule -M -m -o $SCRIPT_PATH/mongodb_cgroup_memory.mod $SCRIPT_PATH/mongodb_cgroup_memory.te
    semodule_package -o $SCRIPT_PATH/mongodb_cgroup_memory.pp -m $SCRIPT_PATH/mongodb_cgroup_memory.mod
    semodule -i $SCRIPT_PATH/mongodb_cgroup_memory.pp
  fi

  if [[ -e "$SCRIPT_PATH/mongodb_proc_net.pp" ]]; then
    checkmodule -M -m -o $SCRIPT_PATH/mongodb_proc_net.mod $SCRIPT_PATH/mongodb_proc_net.te
    semodule_package -o $SCRIPT_PATH/mongodb_proc_net.pp -m $SCRIPT_PATH/mongodb_proc_net.mod
    semodule -i $SCRIPT_PATH/mongodb_proc_net.pp
  fi

  # 自定义目录
  semanage fcontext -a -t mongod_var_lib_t "$WORKSPACE/data.*"
  chcon -Rv -u system_u -t mongod_var_lib_t "$WORKSPACE/data"
  restorecon -R -v "$WORKSPACE/data"

  # semanage fcontext -d "$WORKSPACE/data.*"
  # restorecon -R -v "$WORKSPACE/data"

  semanage fcontext -a -t mongod_log_t "$WORKSPACE/log.*"
  chcon -Rv -u system_u -t mongod_log_t "$WORKSPACE/log"
  restorecon -R -v "$WORKSPACE/log"

  # semanage fcontext -d "$WORKSPACE/log.*"
  # restorecon -R -v "$WORKSPACE/log"

  # 自定义端口
  # sudo semanage port -a -t mongod_port_t -p tcp <portnumber>
}


function create_user(){
  sh $UILT_PATH -m create_user -a $MONGO_USERNAME 
  if [[ $? != 0 ]]; then
	echo "create user failure" 
  	exit 1
  fi
}


function check_limit(){
  sh $UILT_PATH -m set_limit -a "$MONGO_USERNAME - nofile:65535"
  sh $UILT_PATH -m set_sysctl -a "vm.max_map_count:262144"
  if [[ $? != 0 ]]; then
    echo "check limit item failure"
    exit 1
  fi
}


function close_hugepages(){
  # 关闭巨页vm.max_map_count=262144

  sh $UILT_PATH -m set_sysctl -a "vm.nr_hugepages:0"

  # 临时关闭透明巨页
  local transparent_hugepage_enabled="/sys/kernel/mm/transparent_hugepage/enabled"
  local transparent_hugepage_defrag="/sys/kernel/mm/transparent_hugepage/defrag"

  if [[ $(cat "$transparent_hugepage_enabled" | egrep '\[never' | wc -l) == "0" ]]; then
    echo never | tee "$transparent_hugepage_enabled"
  fi

  if [[ $(cat "$transparent_hugepage_defrag" | egrep '\[never' | wc -l) == "0" ]]; then
   echo never | tee "$transparent_hugepage_defrag"
  fi
}


function unzip_mongo_pkg(){
  local linux="rhel80"
  local version="7.0.9"
  local arch="$(uname -i)"

  local sh_tar_name="mongosh-*-linux-x64"
  local db_tar_name="mongodb-linux-$arch-$linux-$version"

  local pkg_path="$SCRIPT_PATH/../../package"
  local sh_tar_path="$pkg_path/$sh_tar_name.tgz"
  local db_tar_path="$pkg_path/$db_tar_name.tgz"
 
  if [[ $(find $sh_tar_path 2>/dev/null | wc -l) == 0 ]]; then
    wget https://downloads.mongodb.com/compass/mongosh-2.2.5-linux-x64.tgz
  fi

  if [[ $(find $db_tar_path 2>/dev/null | wc -l) == 0 ]]; then
    wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel80-7.0.9.tgz
  fi

  sh_tar_name=$(basename -s .tgz $sh_tar_path) 
  db_tar_name=$(basename -s .tgz $db_tar_path) 

  tar -zxf $sh_tar_path -C $WORKSPACE
  tar -zxf $db_tar_path -C $WORKSPACE

  cd $WORKSPACE
  mv $db_tar_name/* ./ && rm -rf $db_tar_name
  mv $sh_tar_name/bin/* ./bin && rm -rf $sh_tar_name

  sh $UILT_PATH -m clean_dir_link -a "link:$WORKSPACE,target:/usr/local/bin"
  ln -s $WORKSPACE/bin/* /usr/local/bin/
  chown -R $MONGO_USERNAME:$MONGO_USERNAME $WORKSPACE
}


function start(){
  cp -r $SCRIPT_PATH/sample/mongod.conf $WORKSPACE/conf
  sed -i "s#/path/to#$WORKSPACE#g" $WORKSPACE/conf/mongod.conf 

  cp -r $SCRIPT_PATH/sample/mongod.service /etc/systemd/system
  sed -i "s#/path/to#$WORKSPACE#g" /etc/systemd/system/mongod.service

  systemctl daemon-reload
  systemctl start mongod && systemctl enable mongod  
  systemctl status mongod 
}


function install(){
  sh $UILT_PATH -m check_root 
  if [[ $? != 0 ]]; then
    exit 1
  fi

  local mongod_status=$(systemctl status mongod.service 2>/dev/null | grep -i 'active:' |tr -d " "| awk -F"(" '{print $1}'|awk -F: '{print $2}')
  if [[ ! -z "$mongod_status" && "inactive" != "$mongod_status" ]]; then
    error "Stop the installation because the MongoDB service status is active"
    exit 1
  fi

  info "1. create user"
  create_user

  info "2. set environment config"
  check_limit
  close_hugepages

  info "3. create workspace directory"
  create_workspace

  info "4. unzip mongo package"
  unzip_mongo_pkg
  mv /tmp/backup $SCRIPT_PATH/backup_$(date +'%Y%m%d_%H%M%S')

  info "5. start mongod"
  start 

  #set_selinux_policy
}

function uninstall(){
  sh $UILT_PATH -m check_root 
  if [[ $? != 0 ]]; then
    exit 1
  fi

  info "1. close mongod"
  if [[ -e "/etc/systemd/system/mongod.service" ]]; then
    systemctl stop mongod && systemctl disable mongod 
    systemctl status mongod 
    rm -f /etc/systemd/system/mongod.service && systemctl daemon-reload
  fi

  info "2. clean soft link"
  sh $UILT_PATH -m clean_dir_link -a "link:$WORKSPACE,target:/usr/local/bin"

  info "3. reset environment config"

  info "4. remove user"
  sh $UILT_PATH -m remove_user 

  info "5. clean workspace directory"
  rm -rf $WORKSPACE
}

function test(){
  ehco "1"
}

function info(){
  sh $UILT_PATH -m info -a "$1"
}

function error(){
  sh $UILT_PATH -m error -a "$1"
}

# Usage message
usage() {
    echo "Usage: $0 [OPTIONS] FILE"
    echo "Options:"
    echo "  -i,          install and start mongod"
    echo "  -r,          stop and remove mongod"
    echo "  -h,          show args detail"
    echo ""
    exit 1
}

METHOD="usage"

while getopts "irh" arg 
do
	case $arg in
             i)
                METHOD="install"
                ;;
             r)
                METHOD="uninstall"
                ;;
             t)
                METHOD="test"
                ;;
             h)
                METHOD="usage"
                ;;
             *)  
            	echo "unkonw argument"
        exit 1
        ;;
        esac
done

$METHOD
