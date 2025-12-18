#!/bin/bash

safe_exec() {
    local cmd="$1"

    log_info "EXEC: $cmd"

    # Block dangerous commands
    if echo "$cmd" | grep -Eq "(rm -rf|shutdown|reboot|mkfs|dd )"; then
        log_error "Blocked dangerous command"
        return 1
    fi

    bash -c "$cmd"
    local status=$?

    if [[ $status -ne 0 ]]; then
        log_error "Command failed"
        return 1
    fi

    return 0
}
