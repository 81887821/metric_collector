#!/bin/bash

function get_absolute_path_of_executable_directory() {
    local executable_path="${0}"
    local absolute_path

    executable_path="${executable_path%/*}"
    if [ "${executable_path}" == "." ]; then
        executable_path=""
    fi

    if [ "${executable_path:0:1}" == "/" ]; then
        absolute_path="${executable_path}"
    else
        absolute_path="$(pwd)/${executable_path}"
    fi

    absolute_path="${absolute_path%/}"
    echo "${absolute_path}"
}
