import os
import subprocess
import tkinter as tk
import time
import re

def ping_site():
    site = "google.com"
    result = subprocess.run(["ping", "-c", "1", site], capture_output=True, text=True)
    if "1 packets transmitted, 1 packets received" in result.stdout:
        return None  # Ping successful
    return "Ping failed: All pings failed!"  # Ping failed

def show_alert(message):
    root = tk.Tk()
    root.withdraw()  # Hide the main window

    # Create a top-level window for the alert
    alert = tk.Toplevel(root)
    alert.title("Alert")
    alert.attributes("-topmost", True)
    alert.attributes("-alpha", 0.85)
    tk.Label(alert, text=message).pack(padx=20, pady=20)

    # Add a close button that stops the program
    def close_program():
        alert.destroy()
        root.quit()
        os._exit(0)  # Stop the program

    close_button = tk.Button(alert, text="Close", command=close_program)
    close_button.pack(pady=10)

    # Function to close the alert after a delay
    def close_alert():
        alert.destroy()
        root.quit()

    # Set the timer for 1 second to close the alert automatically
    alert.after(1000, close_alert)

    root.mainloop()

while True:
    message = ping_site()
    if message:
        show_alert(message)
    time.sleep(5)  # Wait for 5 seconds before the next ping
