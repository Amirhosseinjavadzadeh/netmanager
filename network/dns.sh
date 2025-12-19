#!/bin/bash

source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/executor.sh
source /home/amir/netmanager/lib/validators.sh


# موتور اجرایی (هیچ read ای ندارد)
change_dns() {
    local dns_input="$1"
    local mode="$2"

    for dns in $dns_input; do
        validate_ip "$dns" || { log_error "Invalid DNS IP: $dns"; return 1; }
    done

    if [[ "$mode" == "temp" ]]; then
        {
            echo "# Temporary DNS"
            for dns in $dns_input; do
                echo "nameserver $dns"
            done
        } > /etc/resolv.conf

        log_info "DNS temporarily set to: $dns_input"

    elif [[ "$mode" == "perm" ]]; then
        safe_exec "nmcli con mod netplan-ens33 ipv4.dns \"$dns_input\""
        safe_exec "nmcli con mod netplan-ens33 ipv4.ignore-auto-dns yes"
        safe_exec "nmcli con up netplan-ens33"

        log_info "DNS permanently set to: $dns_input"
    else
        log_error "Unknown DNS mode: $mode"
        return 1
    fi
}

# این تابع همونی است که main صدا می‌زند
set_dns() {
    change_dns "$@"
}
