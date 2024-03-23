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

`domain` stores **use cases** and **abstract repository classes**, as they are the 'domain' or 'subject' area of an application. If you aren't familiar with the term, you can think that this 'domain' is the base requirement of an application. We will come this directory later.


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