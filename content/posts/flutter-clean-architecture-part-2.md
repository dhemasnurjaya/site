---
title: 'Flutter Clean Architecture Part 2'
date: 2024-03-22T13:44:27+07:00
draft: true
tags:
  - Flutter
---

In this part I will explain the rest of [directory structure]({{< ref "/posts/flutter-clean-architecture-part-1#directory-structure" >}} "Flutter Clean Architecture - Directory Structure") of Flutter Clean Architecture. If you haven't read the first part, [click here]({{< ref "/posts/flutter-clean-architecture-part-1" >}} "Flutter Clean Architecture Part 1") and to read it.


## Directory Structure (Part 2)

### Domain

`domain` stores **use cases** and **abstract repository classes**, as they are the 'domain' or 'subject' area of an application. If you aren't familiar with the term, you can think that this 'domain' is the base requirement of an application.

First create an abstract class for [WeatherAPI](https://www.weatherapi.com/) repository.

```dart
// domain/repositories/weather_api_repository.dart

import 'package:clean_architecture/core/error/failure.dart';
import 'package:clean_architecture/data/models/current_weather_model.dart';
import 'package:fpdart/fpdart.dart';

abstract class WeatherApiRepository {
  Future<Either<Failure, CurrentWeatherModel>> getCurrentWeather(String city);
}
```

and a use case for getting current weather data using the repository above.

```dart
// domain/use_cases/get_current_weather.dart

import 'package:clean_architecture/core/domain/use_case.dart';
import 'package:clean_architecture/core/error/failure.dart';
import 'package:clean_architecture/data/models/current_weather_model.dart';
import 'package:clean_architecture/domain/repositories/weather_api_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

class GetCurrentWeather
    extends UseCase<CurrentWeatherModel, GetCurrentWeatherParams> {
  final WeatherApiRepository weatherApiRepository;

  GetCurrentWeather({required this.weatherApiRepository});

  @override
  Future<Either<Failure, CurrentWeatherModel>> execute(
    GetCurrentWeatherParams params,
  ) async {
    return weatherApiRepository.getCurrentWeather(params.city);
  }
}

class GetCurrentWeatherParams extends Equatable {
  final String city;

  const GetCurrentWeatherParams({required this.city});

  @override
  List<Object?> get props => [city];
}
```

### Data

`data` as it's namesake, will deals with all data needed by the app. It contains (not limited to) `model`, `repository` implementation, and `data sources`. `Model` and `repository` classes are self-explanatory, and `data sources` will be used to access data from both local and remote sources.

Let's create a model for [WeatherAPI](https://www.weatherapi.com/) current weather response.

```dart
// data/models/current_weather_model.dart

import 'package:clean_architecture/core/data/remote/model/weather_api_response_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'current_weather_model.g.dart';

@JsonSerializable()
class CurrentWeatherModel extends WeatherApiResponseModel {
  @JsonKey(name: 'current')
  final WeatherApiDataModel data;

  CurrentWeatherModel({
    required this.data,
    required super.location,
    required super.error,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) =>
      _$CurrentWeatherModelFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WeatherApiDataModel {
  final DateTime lastUpdated;
  final double tempC;
  final WeatherApiConditionModel condition;
  final double windKph;
  final String windDir;
  final double precipMm;
  final int humidity;
  final int cloud;

  const WeatherApiDataModel({
    required this.lastUpdated,
    required this.tempC,
    required this.condition,
    required this.windKph,
    required this.windDir,
    required this.precipMm,
    required this.humidity,
    required this.cloud,
  });

  factory WeatherApiDataModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiDataModelFromJson(json);
}

@JsonSerializable()
class WeatherApiConditionModel {
  final String text;
  final String icon;

  const WeatherApiConditionModel({
    required this.text,
    required this.icon,
  });

  factory WeatherApiConditionModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiConditionModelFromJson(json);
}
```

The next part is create the `data_source`, which will be responsible to access data from both local and remote sources. For accessing [WeatherAPI](https://www.weatherapi.com/), `network` will be used.

```dart
// data/data_sources/weather_api_remote_source.dart

import 'dart:convert';

import 'package:clean_architecture/core/data/remote/hosts.dart';
import 'package:clean_architecture/core/network/network.dart';
import 'package:clean_architecture/data/models/current_weather_model.dart';

abstract class WeatherApiRemoteSource {
  Future<CurrentWeatherModel> getCurrentWeather(String city);
}

class WeatherApiRemoteSourceImpl implements WeatherApiRemoteSource {
  final Network network;

  WeatherApiRemoteSourceImpl({required this.network});

  @override
  Future<CurrentWeatherModel> getCurrentWeather(String city) async {
    final uri = Uri(
      scheme: 'https',
      host: weatherApiHost,
      path: 'v1/current.json',
      queryParameters: {
        'key': 'KEY',
        'q': city,
      },
    );
    final response = await network.get(uri);
    final jsonResponse = jsonDecode(response) as Map<String, dynamic>;
    return CurrentWeatherModel.fromJson(jsonResponse);
  }
}
```

Here come an abstract class again, as I stated in [part 1](flutter-clean-architecture-part-1.md), the abstract class will be used as `mock` for testing.

There is one more `repositories` in the `data` directory, it will contains the `domain/repositories` implementation. Code below is the implementation of `weather_api_repository` from `domain/repositories/weather_api_repository.dart`.

```dart
// domain/repositories/weather_api_repository_impl.dart

import 'package:clean_architecture/core/error/failure.dart';
import 'package:clean_architecture/core/error/server_failure.dart';
import 'package:clean_architecture/data/data_sources/remote/weather_api_remote_source.dart';
import 'package:clean_architecture/data/models/current_weather_model.dart';
import 'package:clean_architecture/domain/repositories/weather_api_repository.dart';
import 'package:fpdart/fpdart.dart';

class WeatherApiRepositoryImpl implements WeatherApiRepository {
  final WeatherApiRemoteSource weatherApiRemoteSource;

  WeatherApiRepositoryImpl({required this.weatherApiRemoteSource});

  @override
  Future<Either<Failure, CurrentWeatherModel>> getCurrentWeather(
      String city) async {
    try {
      final result = await weatherApiRemoteSource.getCurrentWeather(city);
      return right(result);
    } on Exception catch (e) {
      return left(ServerFailure(message: e.toString(), cause: e));
    }
  }
}

```

### Presentation

`presentation` stores **pages** and **widgets**. These are the 'presentation' or 'view' area of the application. If you aren't familiar with the term, you can think that this 'presentation' is the actual view of an application.