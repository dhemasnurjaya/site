---
title: 'Fix Infinix Air Pro+ Screen Color'
description: 'Fixing Infinix Air Pro+ washed out screen color in Windows and Linux'
date: 2025-02-21T18:09:54+07:00
draft: false
tags:
  - laptop
  - infinix
  - tweak
  - script
---

I have Infinix Air Pro+ and I use it for my work. I can say it is a good laptop coding mainly because it has 2.5k OLED 16:10 screen. But I found a problem with its screen color. When the screen brightness is below about 50% and the screen turned off (to save power, not necessarily going system sleep/suspend) and turns back on, the color looks washed out. 

First time I noticed this issue is because I was using a pitch black wallpaper image (so I can flex my OLED display). After my screen turns back on, my wallpaper's black color becomes grainy, washed out, as its doesn't have pitch black color anymore. Then I noticed, the color will be fixed after I crank the brightness to above 50%. Turning the brightness down again after this still gives me correct black level.

So, I was wondering if I create a script that will turn the brightness to above 50% and restore it to where it was every time my screen is waking up from a sleep. With a help from Google and ChatGPT, I create these scripts as a workaround for this annoying issue.

## Windows
Before continuing, I'm sorry I can't give any screenshot for this Windows section because I already switched to Linux, but I hope I can write it clearly.

### Get screen wake up event
I need to listen to an event that tells me "Hey, the screen is turning on". Fortunately, Windows has [Event Viewer](https://learn.microsoft.com/en-us/shows/inside/event-viewer) that I can use for this. I found that an event from *Kernel-Power* with event ID *507* is the correct event that means the screen in turned back on.

### Script
Next thing to do is create the script to control screen brightness. After trial and error, I found [NirCmd](https://www.nirsoft.net/utils/nircmd.html) can help me to change my screen brightness. Then I create this Powershell script.

```powershell
# Infinix Air Pro Plus suffers from washed out colors 
# after the display goes off and back on if the brightness is below 50%. 
# This script will increase the brightness to 60% when initial brightness 
# is below 50% else it will increase 10% from current brightness and turn 
# back to initial brightness value.

# Path to NirCmd executable
$nircmd = "C:\nircmd-x64\nircmd.exe"

# Function to temporarily adjust brightness
function Adjust-Brightness {
    param (
        [int]$InitialBrightness,
        [int]$TargetBrightness
    )

    # Set brightness to target
    & $nircmd "setbrightness" $TargetBrightness
    Start-Sleep -Seconds 2

    # Restore to initial brightness
    & $nircmd "setbrightness" $InitialBrightness
}

# Dummy current brightness (replace this with actual detection logic if available)
$currentBrightness = (Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness).CurrentBrightness

if ($currentBrightness -lt 50) {
    # If brightness is below 50%, temporarily set to 60
    Adjust-Brightness -InitialBrightness $currentBrightness -TargetBrightness 60
} else {
    # Otherwise, increase brightness by 10%
    $newBrightness = [Math]::Min($currentBrightness + 10, 100)
    Adjust-Brightness -InitialBrightness $currentBrightness -TargetBrightness $newBrightness
}
```

### Make a schedule
I use Windows' [Task Scheduler](https://www.windowscentral.com/how-create-automated-tasks-windows-11) to run the script each time *Kernel-Power* with event ID *507* occurs. I can't show the step-by-step guide because I'm on Linux now, but I have a backup file for this task. All you need is just to import [this task](assets/Restore%20OLED%20Colors.xml) in Task Scheduler.

> Note: You have to change the command it executes to where you save the Powershell script. Also change the author into `YOUR_PC_NAME\YOUR_USERNAME`.

## Linux
I'm using [EndeavourOS](https://endeavouros.com/) which use `systemd`. So this guide is applicable to `systemd` init system only. If your linux use something else, you need to adjust it with your init system.

### Get screen wake up event
I already tried several ways to listen the screen wake up events. But I can't find any using `acpi` and `udev`. So I tried different approach. I check `dpms` property from screen device in `/sys/class/drm/card1-eDP-1/dpms`. It has `On` and `Off` value that I can use for triggering a script to fix the color.

### Script
I have 2 scripts for this approach. One for checking `/sys/class/drm/card1-eDP-1/dpms` value and another one for fixing the color.

```bash
#!/bin/bash
# monitor /sys/class/drm/card1-eDP-1/dpms value
# place it to /usr/local/bin/monitor_screen_power.sh

prev_state=""

while true; do
    state=$(cat /sys/class/drm/card1-eDP-1/dpms)
    
    if [[ "$state" != "$prev_state" && "$state" == "On" ]]; then
        echo "Screen turned on! Running script..."
        /usr/local/bin/brightness_fix.sh
    fi

    prev_state=$state
    sleep 1  # Adjust polling interval as needed
done
```

```bash
#!/bin/bash
# adjust the brightness
# place it to /usr/local/bin/brightness_fix.sh

# Path to brightness control (may vary based on hardware, check /sys/class/backlight/)
BRIGHTNESS_PATH="/sys/class/backlight/intel_backlight/brightness"
MAX_BRIGHTNESS_PATH="/sys/class/backlight/intel_backlight/max_brightness"

# Read current brightness
CURRENT_BRIGHTNESS=$(cat "$BRIGHTNESS_PATH")
MAX_BRIGHTNESS=$(cat "$MAX_BRIGHTNESS_PATH")

# Convert brightness levels to percentage
CURRENT_PERCENT=$(( CURRENT_BRIGHTNESS * 100 / MAX_BRIGHTNESS ))

# Function to set brightness based on percentage
set_brightness() {
    local TARGET_PERCENT=$1
    local TARGET_BRIGHTNESS=$(( TARGET_PERCENT * MAX_BRIGHTNESS / 100 ))
    echo $TARGET_BRIGHTNESS | sudo tee "$BRIGHTNESS_PATH" > /dev/null
}

# Adjust brightness logic
if [ "$CURRENT_PERCENT" -lt 50 ]; then
    set_brightness 60
    sleep 0.5
    set_brightness "$CURRENT_PERCENT"
else
    TARGET_PERCENT=$(( CURRENT_PERCENT + 10 ))
    if [ "$TARGET_PERCENT" -gt 100 ]; then
        TARGET_PERCENT=100
    fi
    set_brightness "$TARGET_PERCENT"
    sleep 0.5
    set_brightness "$CURRENT_PERCENT"
fi
```

### Make a systemd service
Make a `systemd` service in `/etc/systemd/system/brightness-fix.service` to run the first script.

```plaintext
[Unit]
Description=Fix screen brightness on wake
After=multi-user.target

[Service]
ExecStart=/usr/local/bin/monitor_screen_power.sh
Restart=always
User=dhemas

[Install]
WantedBy=multi-user.target
```

and another one to run `brightness-fix.sh` after waking up from suspend/sleep, I put it in `/etc/systemd/system/brightness-fix-wakeup.service`.

```plaintext
[Unit]
Description=Fix screen brightness after wakeup
After=suspend.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/brightness_fix.sh

[Install]
WantedBy=suspend.target
```

Then register, enable, and start it.

```bash
sudo systemctl daemon-reload 
sudo systemctl enable brightness-fix.service
sudo systemctl enable brightness-fix-wakeup.service
sudo systemctl start brightness-fix.service
```

One more thing, you can add also `/usr/local/bin/brightness_fix.sh` to autostart (I'm using KDE) so it will run each time you login.