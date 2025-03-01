---
title: 'Remap Infinix Air Pro+ Copilot Key in Linux'
description: 'Re-using Copilot key for something else more useful'
date: 2025-03-01T22:41:32+07:00
draft: false
tags:
  - linux
  - laptop
  - infinix
  - tweak
---

> Since I'm moving to Linux, my Copilot key becomes useless. 

Let me rephrase that! Even when I was using Windows, I never using this Copilot shortcut key in my keyboard 😬. Fortunately, using Linux I can remap this key for something else ~~more useful~~.

## Requirements
- A laptop (I'm using Infinix Air Pro+) with a working keyboard.
- [keyd](https://github.com/rvaiya/keyd)

## Finding what this Copilot key do
- Open your favorite terminal and execute `sudo keyd monitor`. This command will print what events are triggered when a particular key is pressed.
- Press the Copilot key and read the output. In my laptop, it print out this:

```bash
AT Translated Set 2 keyboard  0001:0001:70533846  leftmeta down
AT Translated Set 2 keyboard  0001:0001:70533846  leftshift down
AT Translated Set 2 keyboard  0001:0001:70533846  f23 down
```

- Now I know that my copilot key triggers `leftmeta`, `leftshift`, and `f23`. It's seem legit combination of modifier keys and a function key. But unfortunately when I tried to use it in my desktop environment (I use KDE) to bind a shortcut, it only detect the modifier `meta` and `shift`.

## `keyd` for the rescue
Edit `/etc/keyd/default.conf` file and I added these lines:

```plaintext
[ids]  
0001:0001:70533846  
  
[main]  
f23 = f13
```

`ids` is my keyboad ID, and the last line tells to remap `f23` key to `f13` (which is doesn't exist physically). Then reload `keyd` with `sudo keyd reload`. Now I can bind my Copilot key to something else. I'm using it for [yakuake](https://github.com/KDE/yakuake) show/hide toggle.
