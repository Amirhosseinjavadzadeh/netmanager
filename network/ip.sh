#!/bin/bash
source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/executor.sh
source /home/amir/netmanager/lib/validators.sh

# پیدا کردن کانکشن فعال واقعی روی اینترفیس
get_conn_name() {
    local iface=$1
    nmcli -t -f NAME,DEVICE con show --active | grep ":$iface$" | cut -d: -f1
}

set_ip_static() {
    local iface=$1
    local ip=$2
    local gw=$3

    validate_ip $ip || { log_error "Invalid IP"; return 1; }
    validate_ip $gw || { log_error "Invalid Gateway"; return 1; }

    local conn=$(get_conn_name $iface)
    if [[ -z $conn ]]; then
        log_error "No active connection found for $iface"
        return 1
    fi

    safe_exec "nmcli con mod '$conn' ipv4.addresses $ip/24"
    safe_exec "nmcli con mod '$conn' ipv4.gateway $gw"
    safe_exec "nmcli con mod '$conn' ipv4.method manual"
    safe_exec "nmcli con up '$conn'"

    log_info "Static IP set on $iface: $ip"
}

set_ip_dhcp() {
    local iface=$1

    local conn=$(get_conn_name $iface)
    if [[ -z $conn ]]; then
        log_error "No active connection found for $iface"
        return 1
    fi

    safe_exec "nmcli con mod '$conn' ipv4.method auto"
    safe_exec "nmcli con up '$conn'"

    log_info "DHCP enabled on $iface"
}
