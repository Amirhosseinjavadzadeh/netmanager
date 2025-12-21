#!/bin/bash
# /home/amir/netmanager/network/routes.sh
# Debian-compatible routes manager

source /home/amir/netmanager/lib/logger.sh
source /home/amir/netmanager/lib/validators.sh

ROUTES_CONF="/etc/netmanager/routes.conf"
mkdir -p "$(dirname "$ROUTES_CONF")"
touch "$ROUTES_CONF"

# -------------------------------
# Validation functions
# -------------------------------
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

    # ذخیره در routes.conf
    echo "$iface $dest $gw" >> "$ROUTES_CONF"
    log_info "PERM route saved: $dest via $gw dev $iface"

    # ذخیره دائمی در /etc/network/interfaces.d/<iface>
    local iface_file="/etc/network/interfaces.d/$iface"
    mkdir -p "/etc/network/interfaces.d"
    touch "$iface_file"

    # اگر مسیر مشابه موجود نبود، اضافه کن
    if ! grep -q "$dest via $gw" "$iface_file"; then
        echo "up ip route add $dest via $gw dev $iface" >> "$iface_file"
        echo "down ip route del $dest dev $iface" >> "$iface_file"
        log_info "PERM route added to $iface_file"
    fi

    # اعمال فوری
    ip route add "$dest" via "$gw" dev "$iface" 2>/dev/null \
        && log_info "PERM route applied immediately: $dest via $gw dev $iface" \
        || log_error "Failed to apply PERM route: $dest via $gw dev $iface"
}

del_route_perm() {
    local iface=$1
    local dest=$2

    validate_iface "$iface" || { log_error "Invalid interface: $iface"; return 1; }
    validate_cidr "$dest" || { log_error "Invalid destination: $dest"; return 1; }

    # حذف از routes.conf
    if [[ -f "$ROUTES_CONF" ]]; then
        sed -i "\|^$iface $dest |d" "$ROUTES_CONF"
        log_info "PERM route removed from config: $dest dev $iface"
    fi

    # حذف از /etc/network/interfaces.d/<iface>
    local iface_file="/etc/network/interfaces.d/$iface"
    if [[ -f "$iface_file" ]]; then
        sed -i "\|ip route add $dest via|d" "$iface_file"
        sed -i "\|ip route del $dest dev|d" "$iface_file"
        log_info "PERM route removed from $iface_file"
    fi

    # حذف فوری
    ip route del "$dest" dev "$iface" 2>/dev/null \
        && log_info "PERM route deleted: $dest dev $iface" \
        || log_error "Failed to delete PERM route: $dest dev $iface"
}

# -------------------------------
# Apply all permanent routes from routes.conf
# -------------------------------
apply_perm_routes() {
    if [[ ! -f "$ROUTES_CONF" ]]; then
        log_info "No permanent routes to apply."
        return
    fi

    while read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        iface=$(echo "$line" | awk '{print $1}')
        dest=$(echo "$line" | awk '{print $2}')
        gw=$(echo "$line" | awk '{print $3}')

        validate_iface "$iface" || { log_error "Invalid interface in routes.conf: $iface"; continue; }
        validate_cidr "$dest" || { log_error "Invalid CIDR in routes.conf: $dest"; continue; }
        validate_ip "$gw" || { log_error "Invalid gateway in routes.conf: $gw"; continue; }

        ip route add "$dest" via "$gw" dev "$iface" 2>/dev/null \
            && log_info "PERM route applied: $dest via $gw dev $iface" \
            || log_error "Failed to apply PERM route: $dest via $gw dev $iface"
    done < "$ROUTES_CONF"
}

# -------------------------------
# Main interface for scripts
# -------------------------------
case "$1" in
    -apply)
        apply_perm_routes
        ;;
    *)
        log_info "Usage: $0 -apply"
        ;;
esac
