#!/bin/bash

# مسیر لاگ ثابت
LOG_DIR="/home/amir/netmanager/logs"
LOG_FILE="$LOG_DIR/netmanager.log"

# ایجاد دایرکتوری در صورت نبودن
mkdir -p "$LOG_DIR"

# تابع لاگ INFO
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

# تابع لاگ ERROR
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}
