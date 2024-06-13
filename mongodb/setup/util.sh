#!/bin/bash

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
DEFAULT_USER_NAME="mongod"
DEFAULT_USER_PASS="mongod@1024"

function create_user() {
  check_root

  local user=${1:-$DEFAULT_USER_NAME}
  if ! id "$user" > /dev/null 2>&1 ; then
    info "create user <$user>"
    useradd -s /bin/bash -m $user
    echo "$user:$DEFAULT_USER_PASS" | chpasswd
  else
	  warning "create user <$user> already exist, id $user: "
  fi
  info $(su - $user -c 'id $whoami')
}

function remove_user(){
  check_root

  local user=${1:-$DEFAULT_USER_NAME}
  if [ -z $user ]; then
    error "remove user args is empty"
    exit 1
  fi		

  if  id "$user" > /dev/null 2>&1 ; then
    info "remove user <$user>" 
    userdel -r $user
    if [[ $? != 0 ]]; then
      echo "remove user failure"
      exit 1
    fi
  else
	  warning "not found user <$user>"
  fi
}

function check_root(){
  if [[ "$(whoami)" == "root" ]]; then
  	return 0
  else
    error "must need <root> user execute method. current user <$(whoami)>"
    exit 2	
  fi
}

#
# 参数格式 -m set_limit -a 'mongod - nofile:65535' 
#
function set_limit(){
  check_root	

  local backup_path="/tmp/backup/limit"
  local limit_path="/etc/security/limits.conf"
  mkdir -p $backup_path && cp $limit_path "$backup_path/limit_$(date +'%Y%m%d_%H%M%S')"

  local content=$(cat $limit_path | egrep -v '#|^$')
  local args_str="$1"
  declare -A args_map

  str_to_map "$args_str" args_map
  for key in "${!args_map[@]}"; do
    local val=${args_map[$key]}  
    local repl_key="${key// /.+}"
    local ret=$(echo "$content" |egrep "$repl_key.+${args_map[$key]}")
    
    info "check_exist($key,$val)"
    if [[ -z "$ret" ]]; then
      info "attend item to limits.conf: $key $val"
      echo "$key $val" >> $limit_path
    else
      warning "already exist <$ret> in file limits.conf"
    fi
  done
}


function set_sysctl(){
  check_root

  local backup_path="/tmp/backup/sysctl"
  local limit_path="/etc/sysctl.conf"
  mkdir -p $backup_path
  sysctl -a > "$backup_path/sysctl_$(date +'%Y%m%d_%H%M%S')"

  local is_print=0
  local content=$(cat $limit_path | egrep -v '#|^$')
  local args_str="$1"
  declare -A args_map
  str_to_map "$args_str" args_map
  
  for key in "${!args_map[@]}"; do
    local val=${args_map[$key]}  
    local repl_key="${key// /.+}"
    local ret=$(echo "$content" |egrep "$repl_key.+$val")
    
    info "check_exist($key,$val)"
    if [[ -z "$ret" ]]; then
      is_print=1
      info "attend item to sysctl.conf: $key $val"
      echo "$key = $val" >> $limit_path
    else
      warning "already exist <$ret> in file sysctl.conf"
    fi
  done

  if [[ "$is_print" == "1" ]]; then
    sysctl -p
  fi
}


# =========================================== OUTPUT=====================================

function info(){
  echo -e "\e[34m[INFO]\e[0m: $@"
}

function error(){
  echo -e "\e[31m[ERROR]\e[0m: $@"
}

function warning(){
  echo -e "\e[33m[WARNING]\e[0m $@"
}

function str_to_map(){
  local input="$1"
  declare -n result_map="$2"

  IFS="," read -ra pairs <<< "$input"

  for pair in "${pairs[@]}"; do
  	IFS=':' read -r key value <<< "$pair"
	  result_map["$key"]="$value"
  done
}

function str_to_arr(){
  local split="$1"
  local input="$2"
  declare -n result_array="$3"

  IFS="$split" read -ra result_array <<< "$input"
}

function confirm_delete(){
  local path=$1
  if [[ ! -e "$path" ]]; then
    warning "not found target <$path>"
    exit 0
  fi

  echo -en "\e[34m[INFO]\e[0m: confirm delete <$path> [y/n]: "
  read confirm
  case "$confirm" in
    [Yy]* )
      rm -rf $path
      info "delete complete"
      ;;
    [Nn]* )
      info "cancel delete"
      ;;
    * )
      error "input invalid"
      ;;
  esac
}

function clean_dir_link(){
  local args_str=$1
  declare -A args_map

  str_to_map "$args_str" args_map
  local link_path=${args_map['link']}
  local target_path=${args_map['target']}
  
  if [[ -z "$link_path" || -z "$target_path" ]]; then
    error 'must args <link/target/src> is not empty'
    exit 1
  fi

  if [[ ! -e "$target_path" ]]; then
    error "target directoy is not exist"
    exit 1
  fi

  local link_list=()
  local link_list_str=$(find "$target_path" -type l  | awk '{ret=$0" "ret}END{print ret}')

  str_to_arr " " "$link_list_str" link_list
  for link in "${link_list[@]}"; do
    local readlink_ret=$(readlink $link)

    if [[ $readlink_ret =~ ^$link_path/ ]]; then 
      info "unlink $link->$readlink_ret"
      unlink $link
    fi
  done
}

# ========================================= INPUT ========================================

# Usage message
usage() {
    echo "Usage: $0 [OPTIONS] FILE"
    echo "Options:"
    echo "  -h,          Display this help message and exit"
    echo "  -m,          execute method"
    echo "  -a,          execute method argument"
    echo ""
    echo "Description:"
    echo "  This script performs some operation on a file."
    echo "  Example usage: $0 -v -f -l output.log input.txt"
    exit 1
}

while getopts "a:m:h" arg 
do
	case $arg in
             a)
                METHOD_ARGS=$OPTARG
                ;;
             m)
                METHOD=$OPTARG
                ;;
             h)
                usage
                ;;
             ?)  
            	echo "unkonw argument"
        exit 1
        ;;
        esac
done

# Check if FILE is provided
if [[ -z "$METHOD" ]]; then
    echo "Error: <-m> argument is required."
    usage
fi

$METHOD "$METHOD_ARGS"
