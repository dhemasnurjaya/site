---
title: 'Kuwot'
description: 'Flutter Daily Quote App'
date: 2025-02-20T15:26:04+07:00
draft: true
tags:
  - programming
  - flutter
---

I made [Kuwot](https://play.google.com/store/apps/details?id=com.dhemasnurjaya.kuwot) last year in my spare time. I want to share it, you can use it as an inspiration, practice app, or something else is up to you since I open-sourced the code (links below).

## Introduction
The Flutter app itself was built using [Clean Architecture]({{< ref "/posts/flutter-clean-architecture/index.md" >}}). It has all basic features from a daily quote application. At first, my idea is to make a simple daily quote application. Showing random quote everytime the app is opened, and give it an image background to make it more appealing.

## Hunting for quote data
First thing I did was searching some kind of quote data that available for free. I stumbled across several choices:

- Use available quote API, eg: [Zen Quotes](https://zenquotes.io)
- Scraping quotes website
- Find dataset that already compiled somewhere in [Github](https://github.com)

After many consideration, I'd like to use this [Quotes 500k](https://github.com/ShivaliGoel/Quotes-500K) as my quote data source. Originally, that quote data was used for a research paper and made by scraping several quote websites.

First problem solved, since I have the quote dataset I was thinking whether I embed this dataset as SQLite database into the app or do something else. But then I remember that I still need to get the background image for the app and it will make no sense to embed the background images into the app as well. So I decided to create a simple REST API for Kuwot.

## Building the API
Now I need a simple, easy to make REST API. I was thinking to use Python's [FastAPI](https://fastapi.tiangolo.com/) but after some onboarding tutorial, I just don't like it. Then I found [dart_frog](https://dartfrog.vgv.dev/)! It's a minimalist backend framework written in Dart. There are no reason to not use this since it use same language as my Flutter app, that was I thought.

Building the API is straight-forward, [dart_frog](https://dartfrog.vgv.dev/) has everything I need to build the API.

## Reshaping dataset
The data I got from [Quotes 500k](https://github.com/ShivaliGoel/Quotes-500K) is looking like this:

| Quote | Author | Tags |
| ----- | ------ | ---- |
| A friend is someone who knows all about you and still loves you. | Elbert Hubbard | friend, friendship, knowledge, love |

Now, I didn't want the tags and I don't want a long quote. So I make a Python script to filter those quotes into a new dataset I need.

```python

```

## UI Design
I want to make it as simple as possible while focusing on the functionality. 