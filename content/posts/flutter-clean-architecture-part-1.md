---
title: 'Flutter Clean Architecture Part 1'
date: 2024-03-20T13:49:04+07:00
draft: true
---

## What is Clean Architecture?

Do you ever wondering how to manage your Flutter code? How to make it neat, modular, easy to maintain and test? Here where *clean architecture* comes in. Basically, clean architecture is a way to organize your code into separated pieces that will make your project cleaner. It may looks complicated at first and a lot of boiler code for some reasons. But trust me, it will be a lot easier if you apply the clean architecture in your code, especially in medium to bigger projects.

In this set of Clean Architecture articles, we will create a basic mobile app that uses [Weather API](https://www.weatherapi.com/) to get current weather. Let's get started!


## Directory Structure

I use this directory structure to organize my code into clean architecture. Once you got the idea, you may modify the structure to match your needs. I myself like to separate `core` and `features`, but this is not mandatory if you have a relatively small project.


```
your-flutter-project-dir
├── pubspec.yaml
├── lib
│   ├── core
│   │   ├── data
│   │   ├── domain
│   │   ├── error
│   │   ├── network
│   │   ├── presentation
│   │   ├── routes
│   │
│   ├── data
│   ├── domain
│   ├── presentation
│   │   ├── home
│   │   │   ├── blocs
│   │   │   ├── widgets
│   │   │   ├── home_page.dart
│   │   │
│   │   ├── ... other presentations
│   │
│   ├── injection_container.dart
│   ├── main.dart
│
├── ... other files
```


### Core

You'll stores all reusable code inside `core`. Things like abstract classes (maybe a model base, error base, etc), also your app router, anything that you need to access across your `features` best to keep inside `core` directory.

#### Data

