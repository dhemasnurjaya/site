---
title: 'Flutter Clean Architecture Part 1'
date: 2024-03-20T13:49:04+07:00
draft: true
---

## What is Clean Architecture?

Do you ever wondering how to manage your Flutter code? How to make it neat, modular, easy to maintain and test? Here where *clean architecture* comes in. Basically, clean architecture is a way to organize your code into separated pieces that will make your project cleaner. It may looks complicated at first and a lot of boiler code for some reasons. But trust me, it will be a lot easier if you apply the clean architecture in your code, especially in medium to bigger projects.

In this set of Clean Architecture articles, we will create a basic mobile app that uses [WeatherAPI](https://www.weatherapi.com/) to get current weather. Let's get started!


## Directory Structure

I use this directory structure to organize my code into clean architecture. Once you got the idea, you may modify the structure to match your needs.

```
your-flutter-project-dir
├── pubspec.yaml
├── lib
│   ├── core
│   │   ├── data
│   │   │   ├── local
│   │   │   ├── remote
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

You'll stores all reusable code inside `core`. Things like abstract classes (maybe a model base, error base, etc), or maybe a base widgets, snackbars, dialogs, also your app router, anything that you need to access across your app are best to keep inside `core` directory.

#### Data

`core/data` stores base classes related to your data. Divided into `local` for locally-stored data (ex: configs, persistence, cache), and `remote` for data from external sources (ex: web API).

Let's create a `config.dart` base class to store app configuration using [shared_preferences](https://pub.dev/packages/shared_preferences) later

```dart
// lib/core/data/local/config.dart

/// Config base class
abstract class Config<T> {
  /// Get config value
  Future<T> get();

  /// Set config value
  Future<void> set(T value);
}
```

and `weather_api_response.dart` model class for the [WeatherAPI](https://www.weatherapi.com/) response using [freezed](https://pub.dev/packages/freezed#creating-a-model-using-freezed) package.

Note: please don't feel intimidated, it's just a model class. I already throws out many fields from the response though.

```dart
// lib/core/data/remote/model/weather_api_response.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_api_response.freezed.dart';
part 'weather_api_response.g.dart';

@freezed
class WeatherApiResponse with _$WeatherApiResponse {
  const factory WeatherApiResponse({
    required WeatherApiLocation? location,
    required WeatherApiData? data,
    required WeatherApiError? error,
  }) = _WeatherApiResponse;

  factory WeatherApiResponse.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiResponseFromJson(json);
}

@freezed
class WeatherApiLocation with _$WeatherApiLocation {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WeatherApiLocation({
    required String name,
    required String region,
    required String country,
  }) = _WeatherApiLocation;

  factory WeatherApiLocation.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiLocationFromJson(json);
}

@freezed
class WeatherApiData with _$WeatherApiData {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WeatherApiData({
    required DateTime lastUpdated,
    required double tempC,
    required WeatherApiCondition condition,
    required double windKph,
    required String windDir,
    required double precipMm,
    required int humidity,
    required int cloud,
  }) = _WeatherApiData;

  factory WeatherApiData.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiDataFromJson(json);
}

@freezed
class WeatherApiCondition with _$WeatherApiCondition {
  const factory WeatherApiCondition({
    required String text,
    required String icon,
  }) = _WeatherApiCondition;

  factory WeatherApiCondition.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiConditionFromJson(json);
}

@freezed
class WeatherApiError with _$WeatherApiError {
  const factory WeatherApiError({
    required int code,
    required String message,
  }) = _WeatherApiError;

  factory WeatherApiError.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiErrorFromJson(json);
}

```

#### Domain

`core/domain` contains *use case* base class. If you unfamiliar with a *use case* (also called *unit-of-work*), it's a **single-purpose** class that has a method `execute/call` to do particular function in your app. We'll find out how it works in several sections ahead.

In this class we use [fpdart](https://pub.dev/packages/fpdart)'s `Either` class. In [Functional Programming](), `Either` means a function that will return a `Right` value for positive/success scenario, or `Left` when it fails. You can read about it in the previous links.

```dart
// lib/core/domain/use_case.dart

import 'package:fpdart/fpdart.dart';
import 'package:gbikudus/core/error/failures.dart';

/// [Type] is the return type of a successful use case call.
/// [Params] are the parameters that are required to call the use case.
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Either<Failure, Type>> execute(Params params);
}

```

#### Error

We'll use `core/error` dir to stores `Failure` classes.