#!/bin/bash

function main() {
    local log_directory="${1}"
    local sleep_interval="${2}"

    create_log_directory "${log_directory}"

    touch '/tmp/keep-logging'

    collect_data "/proc/stat" "${log_directory}/cpu.log" "${sleep_interval}" &
    collect_data "/proc/meminfo" "${log_directory}/memory.log" "${sleep_interval}" &
    collect_data "/proc/diskstats" "${log_directory}/disk.log" "${sleep_interval}" &
    collect_data "/proc/net/dev" "${log_directory}/network.log" "${sleep_interval}" &

    wait_for_stop "${sleep_interval}"
    kill_collector_processes
}

function create_log_directory() {
    local log_directory="${1}"

    if [ ! -d "${log_directory}" ]; then
        mkdir -p "${log_directory}" || die "Cannot create log directory."
    fi
}

function collect_data() {
    local data_file="${1}"
    local log_file="${2}"
    local sleep_interval="${3}"

    echo "Collecting data from ${data_file} with interval ${sleep_interval}" >> "${log_file}"
    
    while true; do
        echo "$(date --rfc-3339=ns)" >> "${log_file}"
        cat "${data_file}" >> "${log_file}"
        echo >> "${log_file}"

        sleep "${sleep_interval}"
    done
}

function wait_for_stop() {
    local sleep_interval="${1}"

    while [ -f '/tmp/keep-logging' ]; do
        sleep "${sleep_interval}"
    done
}

function kill_collector_processes() {
    pkill -P $$
}

main "$@"
