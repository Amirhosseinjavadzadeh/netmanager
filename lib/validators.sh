#!/bin/bash

validate_ip() {
    local ip=$1
    [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

validate_iface() {
    ip link show "$1" &>/dev/null
}
