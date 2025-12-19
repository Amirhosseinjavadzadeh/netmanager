#!/bin/bash
# /home/amir/netmanager/network/routes.sh

source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/validators.sh

ROUTES_CONF="/etc/netmanager/routes.conf"
mkdir -p "$(dirname "$ROUTES_CONF")"
touch "$ROUTES_CONF"

# Validate destination CIDR
validate_cidr() {
    local cidr=$1
    if [[ $cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    else
        return 1
    fi
}

# -------------------------------
# Temporary routes
# -------------------------------
add_route_temp() {
    local iface=$1
    local dest=$2
    local gw=$3

    validate_iface "$iface" || { log_error "Invalid interface: $iface"; return 1; }
    validate_cidr "$dest" || { log_error "Invalid destination: $dest"; return 1; }
    validate_ip "$gw" || { log_error "Invalid gateway: $gw"; return 1; }

    ip route add "$dest" via "$gw" dev "$iface" 2>/dev/null \
        && log_info "TEMP route added: $dest via $gw dev $iface" \
        || log_error "Failed to add TEMP route: $dest via $gw dev $iface"
}

del_route_temp() {
    local iface=$1
    local dest=$2

    validate_iface "$iface" || { log_error "Invalid interface: $iface"; return 1; }
    validate_cidr "$dest" || { log_error "Invalid destination: $dest"; return 1; }

    ip route del "$dest" dev "$iface" 2>/dev/null \
        && log_info "TEMP route deleted: $dest dev $iface" \
        || log_error "Failed to delete TEMP route: $dest dev $iface"
}

# -------------------------------
# Permanent routes
# -------------------------------
add_route_perm() {
    local iface=$1
    local dest=$2
    local gw=$3

    validate_iface "$iface" || { log_error "Invalid interface: $iface"; return 1; }
    validate_cidr "$dest" || { log_error "Invalid destination: $dest"; return 1; }
    validate_ip "$gw" || { log_error "Invalid gateway: $gw"; return 1; }

    # Save to routes.conf
    echo "$iface $dest $gw" >> "$ROUTES_CONF"
    log_info "PERM route saved: $dest via $gw dev $iface"

    # Apply immediately
    ip route add "$dest" via "$gw" dev "$iface" 2>/dev/null \
        && log_info "PERM route applied immediately: $dest via $gw dev $iface" \
        || log_error "Failed to apply PERM route: $dest via $gw dev $iface"
}

del_route_perm() {
    local iface=$1
    local dest=$2

    validate_iface "$iface" || { log_error "Invalid interface: $iface"; return 1; }
    validate_cidr "$dest" || { log_error "Invalid destination: $dest"; return 1; }

    # Remove from routes.conf
    if [[ -f "$ROUTES_CONF" ]]; then
        sed -i "\|^$iface $dest |d" "$ROUTES_CONF"
        log_info "PERM route removed from config: $dest dev $iface"
    fi

    # Remove immediately
    ip route del "$dest" dev "$iface" 2>/dev/null \
        && log_info "PERM route deleted: $dest dev $iface" \
        || log_error "Failed to delete PERM route: $dest dev $iface"
}
