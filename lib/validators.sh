#!/bin/bash

# -----------------------------
# IP validation (existing)
# -----------------------------
validate_ip() {
    local ip=$1
    [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

validate_iface() {
    ip link show "$1" &>/dev/null
}

# -----------------------------
# CIDR validation
# -----------------------------
validate_cidr() {
    local cidr=$1

    # format check
    [[ "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]] || return 1

    local ip="${cidr%%/*}"
    local prefix="${cidr##*/}"

    validate_ip "$ip" || return 1
    (( prefix >= 0 && prefix <= 32 )) || return 1

    return 0
}

# -----------------------------
# Check gateway reachability
# -----------------------------
validate_gateway() {
    local gw=$1
    local iface=$2

    validate_ip "$gw" || return 1
    validate_iface "$iface" || return 1

    # آیا gateway داخل subnet کارت شبکه هست؟
    ip route get "$gw" &>/dev/null
}

# -----------------------------
# Prevent invalid route addition
# -----------------------------
validate_route_add() {
    local iface=$1
    local dest=$2
    local gw=$3

    # Interface exists
    validate_iface "$iface" || {
        log_error "Interface $iface does not exist"
        return 1
    }

    # Destination CIDR
    validate_cidr "$dest" || {
        log_error "Invalid destination CIDR: $dest"
        return 1
    }

    # Gateway reachable
    validate_gateway "$gw" "$iface" || {
        log_error "Gateway $gw is not reachable via $iface"
        return 1
    }

    # Prevent adding route to directly connected subnet
    if ip route show dev "$iface" | grep -q "^$dest"; then
        log_error "Route $dest is directly connected on $iface"
        return 1
    fi

    # Prevent duplicate route
    if ip route show | grep -q "^$dest"; then
        log_error "Route $dest already exists"
        return 1
    fi

    return 0
}
