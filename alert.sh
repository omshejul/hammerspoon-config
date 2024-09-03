#!/bin/bash

# while true; do
#     if ping -c 1 google.com > /dev/null; then
#         osascript -e 'display alert "Ping Successful" message "google.com is reachable"'
#     else
#         osascript -e 'display alert "Ping Failed" message "All pings failed!"'
#     fi
#     sleep 5
# done

# Log file location
LOG_FILE="/Users/omshejul/.hammerspoon/ping.log"
PREVIOUS_FAIL=0

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    PING_RESULT=$(ping -c 1 google.com 2>&1)  # Set timeout to 1 second
    
    if echo "$PING_RESULT" | grep "1 packets transmitted, 1 packets received" > /dev/null; then
        PING_TIME=$(echo "$PING_RESULT" | grep -oE 'time=[0-9.]+ ms')
        LOG_ENTRY="$TIMESTAMP: Ping successful, $PING_TIME"
        PREVIOUS_FAIL=0  # Reset the failure counter
        # osascript -e "display alert \"Ping Successful\" message \"$PING_TIME\""
    else
        ERROR_MSG=$(echo "$PING_RESULT" | grep -i "ping: cannot resolve\|ping: unknown host\|ping: sendto")
        if [ -z "$ERROR_MSG" ]; then
            ERROR_MSG="Ping failed: Network is unreachable or no response from host."
        fi
        LOG_ENTRY="$TIMESTAMP: $ERROR_MSG"
        
        if [ "$PREVIOUS_FAIL" -eq 1 ]; then
            osascript -e "display alert \"Ping Failed\" message \"$LOG_ENTRY\""
        fi
        PREVIOUS_FAIL=1  # Set the failure counter to 1
    fi

    # Add the log entry to the top of the log file
    (echo "$LOG_ENTRY"; cat "$LOG_FILE") > /tmp/ping.log && mv /tmp/ping.log "$LOG_FILE"

    sleep 2
done
