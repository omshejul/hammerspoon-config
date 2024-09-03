import os
import time
import subprocess

# Configuration
sites = ["google.com", "cloudflare.com", "opendns.com"]
log_file = os.path.expanduser("~/ping_log.txt")
ping_interval = 5  # seconds

def log_message(message):
    with open(log_file, "a") as log:
        log.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: {message}\n")

def show_alert(message):
    applescript = f'display notification "{message}" with title "Ping Monitor"'
    subprocess.run(["osascript", "-e", applescript])

def ping_site():
    success = False
    for site in sites:
        result = subprocess.run(["ping", "-c", "1", site], capture_output=True, text=True)
        if "1 packets transmitted, 1 packets received" in result.stdout:
            success = True
            message = f"Ping successful: {site}"
            show_alert(message)
            log_message(message)
            break
        else:
            message = f"Ping failed: {site}"
            log_message(message)
            show_alert(message)

    if not success:
        message = "All pings failed!"
        show_alert(message)
        log_message(message)

while True:
    ping_site()
    time.sleep(ping_interval)
