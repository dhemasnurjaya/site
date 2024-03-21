---
title: 'Flutter Clean Architecture Part 1'
date: 2024-03-20T13:49:04+07:00
draft: false
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


#### Core - Data

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


#### Core - Domain

`core/domain` contains *use case* base class. If you unfamiliar with a *use case* (also called *unit-of-work*), it's a **single-purpose** class that has a method `execute/call` to do particular function in your app. We'll find out how it works in several sections ahead.

In this class we use [fpdart](https://pub.dev/packages/fpdart)'s `Either` class. In [Functional Programming](), `Either` means a function that will return a `Right` value for positive/success scenario, or `Left` when it fails. You can read about it in the previous links.

I'll try to explain briefly, `use_case.dart` below has 2 generics. `Type` is a return type when the *use case* is succesfully executed, and `Params` contains parameters that are required to execute the *use case*. Then in `execute` method it has return type of `Either<Failure, Type>`. It means this method will returns `Type` if success, and `Failure` when things got ugly.

```dart
// lib/core/domain/use_case.dart

import 'package:clean_architecture/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

/// [Type] is the return type of a successful use case call.
/// [Params] are the parameters that are required to call the use case.
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Either<Failure, Type>> execute(Params params);
}
```


#### Core - Error

We'll use `core/error` dir to stores `Failure` classes. `Failure` used when the app throws errors and exceptions. It's like having a custom exception class.

```dart
// lib/core/error/failure.dart

import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.cause,
  });

  /// Message of the failure
  final String message;

  /// Cause of the failure
  final Exception? cause;

  @override
  List<Object?> get props => [message, cause];
}
```

Let's make a concrete class using `Failure` base class.

```dart
// lib/core/error/server_failure.dart
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.cause,
  });
}

// lib/core/error/unknown_failure.dart
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.cause,
  });
}
```


#### Core - Network

We will need a HTTP client to get data from [WeatherAPI](https://www.weatherapi.com/). I'll use [http](https://pub.dev/packages/http) package, but you can also use [dio](https://pub.dev/packages/dio) or another similar packages.

```dart
// lib/core/network/network.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Network interface
abstract class Network {
  /// Get data from uri
  Future<String> get(Uri uri);
}

/// Network implementation
class NetworkImpl implements Network {
  final _client = http.Client();

  @override
  Future<String> get(Uri uri) async {
    final response = await _client.get(uri);
    return utf8.decode(response.bodyBytes);
  }
}
```

If you are still new in programming, you may wonder: *Why I should create an abstract class here? It will be okay with a concrete Network class without inheritance*. I'll explain it later, but for now is enough for you to know that this abstract class will be used as a *mock* in testing.


#### Core - Presentation

`core/presentation` contains UI widgets and other presentation related classes that will be used across your app. For now, just leave it empty.


#### Core - Routes

There is a package called [auto_route](https://pub.dev/packages/auto_route) that will ease you to manage routes in your app yet keep your code clean. Using the guide from their package page, we'll have `app_router.dart` inside `core/routes` directory. Since we don't have any page to route to yet, just leave it empty.


## See you in the next part!

Use your time to read more about several flutter packages we used in this article. So in the next part you already know how to use them.

All the codes in this set of articles are available on [GitHub](https://github.com/dhemasnurjaya/flutter-clean-architecture), and will be updated regularly because I use them too as my skeleton project.