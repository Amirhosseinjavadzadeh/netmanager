#!/bin/bash

# -----------------------
# NetManager - Main TUI
# -----------------------

# Resolve project root

# Root check (VERY IMPORTANT: first)
if [[ $EUID -ne 0 ]]; then
    echo "❌ This program must be run as root"
    exit 1
fi

# Load libs (ABSOLUTE PATH)
source "/home/amir/netmanager/lib/logger.sh"
source "/home/amir/netmanager/lib/executor.sh"
source "/home/amir/netmanager/lib/validators.sh"

# Load network modules
source "/home/amir/netmanager/network/dns.sh"
source "/home/amir/netmanager/network/ip.sh"
source "/home/amir/netmanager/network/hostname.sh"
source "/home/amir/netmanager/network/routes.sh"

log_info "NetManager started"

whiptail --title "NetManager" \
--msgbox "Welcome to Linux Network Manager (TUI)" 10 50

# -----------------------
# Main Menu Loop
# -----------------------
while true; do
    CHOICE=$(whiptail --title "NetManager Menu" \
        --menu "Choose an action:" 20 60 10 \
        "1" "Set DNS" \
        "2" "Set IP" \
        "3" "Set Hostname" \
        "4" "Manage Routes" \
        "5" "Exit" \
        3>&1 1>&2 2>&3)

    [[ $? -ne 0 ]] && continue

    case "$CHOICE" in
        1)
            DNS=$(whiptail --inputbox "Enter DNS IP:" 10 40 8.8.8.8 3>&1 1>&2 2>&3) || continue
            MODE=$(whiptail --menu "Permanent or Temporary?" 10 40 2 \
                "perm" "Permanent" \
                "temp" "Temporary" 3>&1 1>&2 2>&3) || continue

            log_info "User selected DNS=$DNS MODE=$MODE"
            set_dns "$DNS" "$MODE"
            ;;
        2)
            IFACE=$(whiptail --inputbox "Enter interface:" 10 40 ens33 3>&1 1>&2 2>&3) || continue
            METHOD=$(whiptail --menu "Choose method" 10 40 2 \
                "static" "Static IP" \
                "dhcp" "DHCP" 3>&1 1>&2 2>&3) || continue

            if [[ "$METHOD" == "static" ]]; then
                IP=$(whiptail --inputbox "Enter IP address:" 10 40 192.168.56.100 3>&1 1>&2 2>&3) || continue
                GW=$(whiptail --inputbox "Enter Gateway:" 10 40 192.168.56.1 3>&1 1>&2 2>&3) || continue
                log_info "Set static IP on $IFACE ($IP via $GW)"
                set_ip_static "$IFACE" "$IP" "$GW"
            else
                log_info "Set DHCP on $IFACE"
                set_ip_dhcp "$IFACE"
            fi
            ;;
        3)
            NAME=$(whiptail --inputbox "Enter Hostname:" 10 40 MyServer 3>&1 1>&2 2>&3) || continue
            log_info "Set hostname to $NAME"
            set_hostname "$NAME"
            ;;
        4)
            ROUTE_CHOICE=$(whiptail --title "Route Menu" \
                --menu "Choose action:" 20 60 10 \
                "1" "Add Temporary Route" \
                "2" "Delete Temporary Route" \
                "3" "Add Permanent Route" \
                "4" "Delete Permanent Route" \
                "5" "Back" \
                3>&1 1>&2 2>&3) || continue

            case "$ROUTE_CHOICE" in
                1)
                    IFACE=$(whiptail --inputbox "Enter interface:" 10 40 ens33 3>&1 1>&2 2>&3) || continue
                    DEST=$(whiptail --inputbox "Enter destination (CIDR):" 10 40 192.168.56.0/24 3>&1 1>&2 2>&3) || continue
                    GW=$(whiptail --inputbox "Enter gateway:" 10 40 192.168.56.1 3>&1 1>&2 2>&3) || continue
                    log_info "Add TEMP route: $DEST via $GW dev $IFACE"
                    add_route_temp "$IFACE" "$DEST" "$GW"
                    ;;
                2)
                    IFACE=$(whiptail --inputbox "Enter interface:" 10 40 ens33 3>&1 1>&2 2>&3) || continue
                    DEST=$(whiptail --inputbox "Enter destination (CIDR):" 10 40 192.168.56.0/24 3>&1 1>&2 2>&3) || continue
                    log_info "Delete TEMP route: $DEST dev $IFACE"
                    del_route_temp "$IFACE" "$DEST"
                    ;;
                3)
                    IFACE=$(whiptail --inputbox "Enter interface:" 10 40 ens33 3>&1 1>&2 2>&3) || continue
                    DEST=$(whiptail --inputbox "Enter destination (CIDR):" 10 40 192.168.56.0/24 3>&1 1>&2 2>&3) || continue
                    GW=$(whiptail --inputbox "Enter gateway:" 10 40 192.168.56.1 3>&1 1>&2 2>&3) || continue
                    log_info "Add PERM route: $DEST via $GW dev $IFACE"
                    add_route_perm "$IFACE" "$DEST" "$GW"
                    ;;
                4)
                    IFACE=$(whiptail --inputbox "Enter interface:" 10 40 ens33 3>&1 1>&2 2>&3) || continue
                    DEST=$(whiptail --inputbox "Enter destination (CIDR):" 10 40 192.168.56.0/24 3>&1 1>&2 2>&3) || continue
                    log_info "Delete PERM route: $DEST dev $IFACE"
                    del_route_perm "$IFACE" "$DEST"
                    ;;
                5) continue ;;
            esac
            ;;
        5)
            log_info "NetManager exited"
            exit 0
            ;;
    esac
done
