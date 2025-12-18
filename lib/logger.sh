#!/bin/bash

LOG_FILE="logs/netmanager.log"

mkdir -p logs

log_info() {
    echo "$(date '+%F %T') [INFO] $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "$(date '+%F %T') [WARN] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%F %T') [ERROR] $1" | tee -a "$LOG_FILE" >&2
}
