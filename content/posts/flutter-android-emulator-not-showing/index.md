---
title: 'Android Devices Not Showing on Flutter Project'
description: "A fix for new Flutter project that doesn't have Android devices showing up"
date: 2025-02-22T09:21:22+07:00
draft: false
tags:
  - flutter
  - android
  - emulator
---

When I create a new Flutter project targeting Android device, I can't choose which Android device to run it. Either it a real connected devices or AVDs, even the devices is available and listed in `Device Manager` tab.

![no devices showing](assets/no-devices.webp)

All I need to do is open `File > Project Structure...` or `Ctrl + Alt + Shift + S`.

![project structure window](assets/project-structure.webp)

As you can see, I have no Android SDK selected for my Flutter project. So, go ahead and select one of SDK listed there and click `OK`. That's it! Now you can see all the devices available to run my Flutter project.

![choose android sdk](assets/choose-sdk.webp)

Hope this can help someone who has similar issues with Flutter project and Android devices. 