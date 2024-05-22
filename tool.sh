#!/bin/bash
# 定义日志打印函数
function quote_and_concatenate() {
    local result=""
    for arg in "$@"; do
        result+="'$arg' "
    done
    result=${result% }
    echo "$result"
}
function log_info() {
    local script_name=$(basename "$0")
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${timestamp} INFO ${script_name} | $*"
}

function log_error() {
    local script_name=$(basename "$0")
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${timestamp} ERROR ${script_name} | $*"
}

function control_core_files() {
    # 定义一个bash函数，实现核心文件数量控制
    # 用法
    # control_core_files [dir] [core max num]
    core_dir=$1       # 核心文件所在的目录
    max_core_files=$2 # 最大核心文件数目

    # 获取核心文件列表，并按修改时间排序
    core_files=($(ls -t $core_dir/core.* 2>/dev/null))

    if [ ${#core_files[@]} -gt $max_core_files ]; then
        # 计算要删除的核心文件数目
        num_files_to_delete=$((${#core_files[@]} - $max_core_files))

        # 删除多余的核心文件
        for ((i = $max_core_files; i < ${#core_files[@]}; i++)); do
            rm "${core_files[$i]}"
            log_info "Deleted core file: ${core_files[$i]}"
        done
    fi
}

function is_running() {
    ps x | grep -v grep | grep "$program_name" >/dev/null
}

function daemon_pragma() {
    if [ $# -le 1 ]; then
        echo "$(date) | daemon_pragma ERROR: 请提供至少两个参数"
        echo "usage: daemon_pragma [program_name] [restart_command] [check period:default is 5]"
        exit 1
    fi
    logger="./log/daemon_pragma.$(date +"%Y%m%d" && mkdir -p log)"
    echo "$(date) | start ..." >>$logger
    program_name="$1"
    restart_command="$2"
    printf '\t>>> program_name: "%s"\n' "$program_name" >>$logger
    printf '\t>>> restart_command: "%s"\n' "$restart_command" >>$logger
    check_period=5
    if [ $# -ge 3 ]; then
        check_period="$3"
    fi
    printf "\t>>> check_period: %s\n" "$check_period" >>$logger

    echo "$(date) | start monitor program $program_name" >>$logger
    while true; do
        logger="./log/daemon_pragma.$(date +"%Y%m%d" && mkdir -p log)"
        echo "$(date) | check $program_name ..." >>$logger
        if ! is_running; then
            echo "$(date) | start program $program_name" >>$logger
            eval "$restart_command"
        fi
        sleep $check_period
    done
}

function apply_dynamic_update() {
    if [ $# -le 1 ]; then
        echo "$(date) | ERROR 参数个数不足2个"
        echo "usage: apply_dynamic_update [source] [target]"
        exit 1
    fi
    source_file="$1"
    target_file="$2"
    if [ ! -f $source_file ]; then
        echo "ERROR $source_file is not exits"
        return 1
    fi
    for i in {1..10}; do
        cp -v $source_file $target_file
        if [ $? -ne 0 ]; then
            log_info "update again"
            sleep 1
        else
            log_info "update successful!"
            return 0
        fi
    done
    log_error "update $source_file fail!"
    return 1
}

function sync_remote_project() {
    server=$1
    remote_dir=$2
    local_dir=$3
    target_dir=$(realpath $local_dir)
    mkdir -p ${local_dir}

    FALG="--bwlimit=50 --size-only --compress-level 9 --transfers 1"
    echo "[$(date)] begin download file from ${server}:${remote_dir}"

    # 使用 rclone lsf 命令列出远程文件夹的内容
    tmp_remote_dir="$server:$remote_dir/log"
    #rclone lsf "$tmp_remote_dir"
    rclone lsf "$tmp_remote_dir" >/dev/null
    if [ $? -eq 0 ]; then
        echo "[$(date)] 文件夹${tmp_remote_dir}存在"
        rclone move -v --min-age 2h $FALG ${tmp_remote_dir} ${target_dir}/log/ >/dev/null
        if [ $? -eq 0 ]; then
            echo "[$(date)] load $server:$remote_dir/log successful!"
        else
            log_error "load $server:$remote_dir/log fail!"
        fi
    else
        log_error "文件夹${tmp_remote_dir}不存在"
    fi

    tmp_remote_dir="$server:$remote_dir/data"
    rclone lsf "$tmp_remote_dir" >/dev/null
    if [ $? -eq 0 ]; then
        echo "[$(date)] 文件夹${tmp_remote_dir}存在"
        rclone move -v --min-age 2h $FALG $tmp_remote_dir ${target_dir}/data/ >/dev/null
        if [ $? -eq 0 ]; then
            echo "[$(date)] load $server:$remote_dir/data successful!"
        else
            echo "ERROR [$(date)] load $server:$remote_dir/data fail!"
        fi
    else
        echo "[$(date)] 文件夹${tmp_remote_dir}不存在"
    fi
}

function run_forever() {
    if [ $# -le 0 ]; then
        log_error "请提供至少一个参数"
        echo "usage: run_forever [command] [sleep period:default is 3600]"
        return 1
    fi
    task_command="$1"
    sleep_period=3600
    if [ $# -ge 2 ]; then
        sleep_period="$2"
    fi
    log_info "task_command is ${task_command} sleep_period: ${sleep_period}"
    while true; do
        exec >>./log/$(basename ${BASH_SOURCE[0]}).$(date +"%Y%m%d" && mkdir -p log) 2>&1
        eval $task_command
        log_info "finish task, sleep $sleep_period"
        sleep $sleep_period
    done
}

function checkout() {
    if [ $# -le 0 ]; then
        log_error "请提供至少一个参数"
        echo "usage: checkout [command]"
        return 1
    fi
    cmd=$(quote_and_concatenate "$@")
    eval "$cmd" >/dev/null
    if [[ $? -eq 0 ]]; then
        log_info "run [$cmd] successful!"
        return 0
    else
        log_error "run [$cmd] fail!"
        return 2
    fi
}
function checkout_silently() {
    if [ $# -le 0 ]; then
        log_error "请提供至少一个参数"
        echo "usage: checkout [command]"
        return 1
    fi
    cmd=$(quote_and_concatenate "$@")
    eval "$cmd" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        log_info "run [$cmd] successful!"
        return 0
    else
        log_error "run [$cmd] fail!"
        return 2
    fi
}
