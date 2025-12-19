#!/bin/bash
source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/executor.sh
source /home/amir/netmanager/lib/validators.sh

add_route() {
    local dest=$1
    local gw=$2
    local mode=$3 # temp or permanent

    validate_ip $dest || { log_error "Invalid destination IP"; return 1; }
    validate_ip $gw || { log_error "Invalid gateway"; return 1; }

    if [[ $mode == "temp" ]]; then
        safe_exec "ip route add $dest via $gw"
        log_info "Temporary route $dest via $gw added"
    else
        echo "ip route add $dest via $gw" >> /etc/rc.local
        safe_exec "ip route add $dest via $gw"
        log_info "Permanent route $dest via $gw added"
    fi
}

del_route() {
    local dest=$1
    local mode=$2
    if [[ $mode == "temp" ]]; then
        safe_exec "ip route del $dest"
        log_info "Temporary route $dest deleted"
    else
        # حذف از rc.local باید دستی باشه
        safe_exec "ip route del $dest"
        log_info "Permanent route $dest deleted (manual cleanup in rc.local needed)"
    fi
}
