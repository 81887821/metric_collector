#!/bin/bash

source "${0%/*}/library/path.sh" 2>/dev/null || source "library/path.sh" || exit 1
source "$(get_absolute_path_of_executable_directory)/settings.sh" || exit 1

readonly remote_script_path="$(get_absolute_path_of_executable_directory)/${script}"
pids=""
collecting="true"
remote_log_directory=""
local_log_directory=""

function main() {
    trap on_interrupt SIGINT
    parse_arguments "$@"
    copy_script_to_targets
    execute_script
    wait_for_jobs_and_collect
}

function parse_arguments() {
    local experiment_name="${1}"

    if [ "${experiment_name}" == "" ]; then
        print_usage
        die
    fi

    remote_log_directory="${remote_log_directory_base}-${experiment_name}"
    local_log_directory="${local_log_directory_base}-${experiment_name}"
}

function print_usage() {
    echo "collect.sh [experiment_name]"
}

function copy_script_to_targets() {
    local host

    for host in "${target_hosts[@]}"; do
        scp "${remote_script_path}" "${remote_user}@${host}:/tmp/${script}" || die "Failed to copy script ${script} to ${host}"
    done
}

function execute_script() {
    local host
    local i=0

    for host in "${target_hosts[@]}"; do
        ssh -l "${remote_user}" "${host}" "/tmp/${script}" "${remote_log_directory}" "${sleep_interval}" &
        pids[${i}]=$!
        i=$(expr ${i} + 1)
    done
}

function on_interrupt() {
    local pid

    echo "Stopping..."
    for pid in "${pids[@]}"; do
        kill "${pid}"
    done

    collecting="false"
}

function wait_for_jobs_and_collect() {
    local pid
    local host

    for pid in "${pids[@]}"; do
        ${collecting} && wait "${pid}"
    done

    for host in "${target_hosts[@]}"; do
        ssh -l "${remote_user}" "${host}" rm '/tmp/keep-logging' &
    done

    wait        

    for host in "${target_hosts[@]}"; do
        mkdir -p "${local_log_directory}/${host}" || (error "Failed to make log directory: ${local_log_directory}/${host}"; continue)
        rsync -a --remove-source-files "${remote_user}@${host}:${remote_log_directory}/" "${local_log_directory}/${host}/" || error "Copying log from ${host} failed." &
    done

    wait

    for host in "${target_hosts[@]}"; do
        ssh -l "${remote_user}" "${host}" rmdir "${remote_log_directory}" &
    done
}

function error() {
    echo "$@" 1>&2
}

function die() {
    error "$@"
    exit 1
}

main "$@"
