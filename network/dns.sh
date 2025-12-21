#!/bin/bash

source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/executor.sh
source /home/amir/netmanager/lib/validators.sh

change_dns() {
    local dns_input="$1"
    local mode="$2"
    local conn_name="ens33"  # نام connection واقعی روی سیستم شما

    # اعتبارسنجی IP های DNS
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
        # اگر connection وجود ندارد، آن را بساز و حتما ifname مشخص کن
        if ! nmcli connection show "$conn_name" &>/dev/null; then
            log_info "Connection $conn_name not found. Creating..."
            nmcli connection add type ethernet ifname ens33 con-name "$conn_name"
        else
            # اگر connection موجود است، مطمئن شو به ens33 متصل است
            nmcli connection modify "$conn_name" connection.interface-name ens33
        fi

        # اعمال DNS
        safe_exec "nmcli connection modify $conn_name ipv4.dns \"$dns_input\""
        safe_exec "nmcli connection modify $conn_name ipv4.ignore-auto-dns yes"

        # فعال کردن connection روی ens33
        safe_exec "nmcli connection up $conn_name ifname ens33"

        log_info "DNS permanently set to: $dns_input"
    else
        log_error "Unknown DNS mode: $mode"
        return 1
    fi
}

set_dns() {
    change_dns "$@"
}
