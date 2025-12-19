#!/bin/bash
source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/executor.sh
source /home/amir/netmanager/lib/validators.sh

set_hostname() {
    local newname=$1
    if [[ -z $newname ]]; then
        log_error "Hostname empty"
        return 1
    fi

    hostnamectl set-hostname "$newname"
    log_info "Hostname set to $newname"
}
