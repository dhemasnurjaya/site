---
title: 'Fix ADB Insufficient Permission'
description: 'udev rules for fixing ADB Insufficient permission in Linux'
date: 2025-02-24T11:29:30+07:00
draft: false
tags:
  - android
  - adb
  - linux
---

## Why need this?
Connecting an Android device to a Linux computer could has problem with permission. Listing devices with `adb devices` might show `unauthorized` status or `insufficient permission` error message.

```bash
$ adb devices

List of devices attached
15241JEC211677  device
RR2M9002AHY     unauthorized
```

This happens because by default, in Linux, when you connect an Android device via USB, the system assigns it to the `root` user and a restrictive permission mode (often 0600), meaning that regular users cannot access it.

## How to fix

1. Check `vendor id` and `device id` from connected Android device with `lsusb`.

```bash
$ lsusb

# ...some other devices
Bus 001 Device 005: ID 18d1:4ee7 Google Inc. Nexus/Pixel Device
```

`18d1` is *vendor id* and `4ee7` is the *product id*.

2. Create an `udev` rule for this device, I create mine in `/etc/udev/rules.d/51-android.rules`.

```bash
SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="4ee7", MODE="0666", GROUP="plugdev", SYMLINK+="google_pixel_4a_%n"
```

- `SUBSYSTEM=="usb"` ensures the rule applies only to USB devices.
- `ATTRS{idVendor}=="18d1" and ATTRS{idProduct}=="4ee7"` match the Google Pixel USB devices by their vendor and product IDs.
- `MODE="0666"` sets the device's permission mode to 0666, meaning read/write access for all users.
- `GROUP="plugdev"` assigns the device to the plugdev group, which allows users in that group to access it.
- `SYMLINK+="google_pixel_4a_%n"` creates a symlink (shortcut) under /dev/ with a readable name for easier identification.

3. Reconnect the device to make sure the rule is correct. If not, try to reload `udev` rules and restart it.

```bash
$ sudo udevadm control --reload-rules
```
