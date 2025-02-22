---
title: 'Flutter Clean Architecture'
description: Dive into Clean Architecture for Flutter or Dart projects
images:
- assets/opengraph.png
date: 2025-01-12T00:12:04+07:00
draft: false
tags:
  - programming
  - flutter
---

![flutter-clean-architecture](assets/flutter_dash.png)

## What is Clean Architecture?
Do you ever wondering how to manage your Flutter code? How to make it neat, modular, easy to maintain and test? Here where *clean architecture* comes in.

Basically, clean architecture is a way to organize your code into separated pieces that will make your project cleaner. It may looks complicated at first and a lot of boiler code for some reasons. But trust me, it will be a lot easier if you apply the clean architecture in your code, especially in medium to bigger projects.

In this set of Clean Architecture articles, we will create a basic mobile app that uses [WeatherAPI](https://www.weatherapi.com/) to get current weather. Let's get started!

> Please note that this guide requires basic knowledge of Dart and Flutter. So I don't recommend going through this guide if you are completely new to the topic.
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
│   ├── features
│   │   ├── feature_name
│   │   │   ├── data
│   │   │   │   ├── data_sources
│   │   │   │   │   ├── local
│   │   │   │   │   ├── remote
│   │   │   │   ├── models
│   │   │   │   ├── repositories
│   │   │   ├── domain
│   │   │   │   ├── repositories
│   │   │   │   ├── use_cases
│   │   │   ├── presentation
│   │
│   ├── injection_container.dart
│   ├── main.dart
│
├── ... other files
```

---
### Core
You'll stores all reusable code inside `core`. Things like abstract classes (maybe a model base, error base, etc), or maybe a base widgets, snackbars, dialogs, also your app router, anything that you need to access across your app are best to keep inside `core` directory.
#### Core - Data
`core/data` stores base classes related to your data. Divided into `local` for locally-stored data (ex: configs, persistence, cache), and `remote` for data from external sources (ex: web API).

Let's create a local `config.dart` base class to store app configuration using [shared_preferences](https://pub.dev/packages/shared_preferences) .

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

For an example, we want to have a config for storing our app theme mode. So the app can restore theme mode data (light mode and dark mode) each time we open it.

```dart
// lib/core/data/local/theme_mode_config.dart

import 'package:clean_architecture/core/data/local/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode shared preferences key
const themeModeConfigKey = 'themeMode';

/// Theme mode configuration
class ThemeModeConfig extends Config<ThemeMode> {
  /// Default constructor
  ThemeModeConfig({required this.sharedPreferences});

  /// Shared preferences instance
  final SharedPreferences sharedPreferences;

  @override
  Future<ThemeMode> get() async {
    final mode = sharedPreferences.getString(themeModeConfigKey);
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> set(ThemeMode value) async {
    switch (value) {
      case ThemeMode.dark:
        await sharedPreferences.setString(themeModeConfigKey, 'dark');
      case ThemeMode.light:
        await sharedPreferences.setString(themeModeConfigKey, 'light');
      case ThemeMode.system:
        await sharedPreferences.setString(themeModeConfigKey, 'system');
    }
  }
}
```

Then we also need to add `weather_api_response.dart` model class for the [WeatherAPI](https://www.weatherapi.com/) response using [json_serializable](https://pub.dev/packages/json_serializable) package.

```dart
// lib/core/data/remote/models/weather_api_response_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'weather_api_response_model.g.dart';

@JsonSerializable()
class WeatherApiResponseModel {
  final WeatherApiLocationModel? location;
  final WeatherApiErrorModel? error;

  WeatherApiResponseModel({
    required this.location,
    required this.error,
  });

  factory WeatherApiResponseModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiResponseModelFromJson(json);
}

@JsonSerializable()
class WeatherApiLocationModel {
  final String name;
  final String region;
  final String country;

  const WeatherApiLocationModel({
    required this.name,
    required this.region,
    required this.country,
  });

  factory WeatherApiLocationModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiLocationModelFromJson(json);
}

@JsonSerializable()
class WeatherApiErrorModel {
  final int code;
  final String message;

  const WeatherApiErrorModel({
    required this.code,
    required this.message,
  });

  factory WeatherApiErrorModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherApiErrorModelFromJson(json);
}
```
#### Core - Domain
`core/domain` contains *use case* base class. If you unfamiliar with a *use case* (also called *unit-of-work*), it's a **single-purpose** class that has a method `execute/call` to do particular function in your app. We'll find out how it works in several sections ahead.

In this class we use [fpdart](https://pub.dev/packages/fpdart)'s `Either` class. In [Functional Programming](), `Either` means a function that will return a `Right` value for positive/success scenario, or `Left` when it fails. You can read about it in the previous links.

I'll try to explain briefly, `use_case.dart` below has 2 generics. `Type` is a return type when the *use case* is succesfully executed, and `Params` contains parameters that are required to execute the *use case*. Then in `call` method it has return type of `Either<Failure, Type>`. It means this method will returns `Type` if success, and `Failure` when things got ugly.

```dart
// lib/core/domain/use_case.dart

import 'package:clean_architecture/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// [Type] is the return type of a successful use case call.
/// [Params] are the parameters that are required to call the use case.
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Either<Failure, Type>> call(Params params);
}
```
#### Core - Error
We'll use `core/error` dir to stores `Failure` classes. `Failure` used when the app throws errors and exceptions. It's like having a custom exception class.

```dart
// lib/core/error/failures.dart

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

Then we'll add some custom exceptions to handle different exceptions that might happen in our application.

```dart
// lib/core/error/exceptions.dart

/// Exception class for server error  
/// Generally, this exception is thrown when the server returns an error response  
class ServerException implements Exception {  
  const ServerException(this.message);  
  
  final String message;  
}  
  
/// Exception class for unauthorized client error  
/// this exception is thrown when the client is not authorized  
/// to access the resource (server returns 401)  
class UnauthorizedException implements Exception {  
  const UnauthorizedException(this.message);  
  
  final String message;  
}
```
#### Core - Network
We will need a HTTP client to get data from [WeatherAPI](https://www.weatherapi.com/). I'll use [http](https://pub.dev/packages/http) package, but you can also use [dio](https://pub.dev/packages/dio) or another similar packages.

```dart
// lib/core/network/network.dart

import 'dart:convert';  
import 'dart:io';  
import 'package:clean_architecture/core/error/exceptions.dart';  
import 'package:http/http.dart' as http;  
  
/// Network interface  
abstract class Network {  
  /// Get data from uri  
  Future<String> get(  
    Uri uri, {  
    Map<String, String>? headers,  
  });
}  

/// Network implementation  
class NetworkImpl implements Network {  
  NetworkImpl(http.Client httpClient) : _httpClient = httpClient;  
  
  final http.Client _httpClient;  
  
  @override  
  Future<String> get(  
    Uri uri, {  
    Map<String, String>? headers,  
  }) async {  
    final response = await _httpClient.get(  
      uri,  
      headers: headers,  
    );    final stringResponse = utf8.decode(response.bodyBytes);  
  
    if (response.statusCode == HttpStatus.unauthorized) {  
      throw UnauthorizedException(stringResponse);  
    }  
    if (response.statusCode != HttpStatus.ok) {  
      throw ServerException(stringResponse);  
    }  
    return stringResponse;  
  }
}
```

If you are still new in programming, you may wonder: *Why I should create an abstract class here? It will be okay with a concrete Network class without inheritance*. I'll explain it later, but for now is enough for you to know that this abstract class will be used as a *mock* in testing.
#### Core - Presentation
`core/presentation` contains UI widgets and other presentation related classes that will be used across your app. We can also have a UI-related business logic that will be used across the app. Since our app will have theme mode switching feature, we will add a `cubit` to do the theme mode switch here.

```dart
// lib/core/presentation/theme/app_theme.dart 

import 'package:flutter/material.dart';  
import 'package:google_fonts/google_fonts.dart';  
  
/// App light theme  
ThemeData lightTheme = ThemeData(  
  colorScheme: ColorScheme.fromSeed(  
    seedColor: const Color(0xFF6F43C0),  
  ),  useMaterial3: true,  
  fontFamily: GoogleFonts.dmSans().fontFamily,  
);  
  
/// App dark theme  
ThemeData darkTheme = ThemeData(  
  colorScheme: ColorScheme.fromSeed(  
    seedColor: const Color(0xFF6F43C0),  
    brightness: Brightness.dark,  
  ),  useMaterial3: true,  
  fontFamily: GoogleFonts.dmSans().fontFamily,  
);
```

```dart
// lib/core/presentation/theme/theme_mode_cubit.dart

import 'package:clean_architecture/core/data/local/config.dart';  
import 'package:flutter/material.dart';  
import 'package:flutter_bloc/flutter_bloc.dart';  
  
/// Theme mode cubit for theme mode management  
class ThemeModeCubit extends Cubit<ThemeMode> {  
  /// Default [ThemeMode] is [ThemeMode.system]  
  ThemeModeCubit({  
    required this.themeModeConfig,  
    required this.initialThemeMode,  
  }) : super(initialThemeMode);  
  
  /// Theme mode config  
  final Config<ThemeMode> themeModeConfig;  
  
  /// Initial theme mode  
  final ThemeMode initialThemeMode;  
  
  /// Set theme mode  
  void setThemeMode(ThemeMode themeMode) {  
    themeModeConfig.set(themeMode);  
    emit(themeMode);  
  }}
```
#### Core - Routes
There is a package called [auto_route](https://pub.dev/packages/auto_route) that will ease you to manage routes in your app yet keep your code clean. Using the guide from their package page, we'll have `app_router.dart` inside `core/routes` directory. Since we don't have any page to route to yet, just leave it empty.
#### Env File
Storing secret directly in the code is a bad practice and we shouldn't do that. There are many ways to hardcode it into the code and one of them is to have an `env` file. You can read more about it [here](https://dart.dev/libraries/core/environment-declarations).

```dart
// lib/core/env.dart

abstract class Env {  
  String get weatherApiHost;  
  String get weatherApiKey;  
}  
  
class EnvImpl implements Env {  
  @override  
  String get weatherApiHost => const String.fromEnvironment('WEATHER_API_HOST');  
  
  @override  
  String get weatherApiKey => const String.fromEnvironment('WEATHER_API_KEY');  
}
```

---
### Feature
In clean architecture, we divide our application into **features**. For example, in this project will have a **weather** feature. Each feature will have its own (but not always neccessarily) `domain`, `data` and `presentation`.
#### Feature - Data
`data` as it's namesake, will deals with all data needed by the app. It contains (not limited to) `model`, `repository` implementation, and `data sources`. `Model` and `repository` classes are self-explanatory, and `data sources` will be used to access data from both local and remote sources.

Let's create a model for [WeatherAPI](https://www.weatherapi.com/) current weather response.

```dart
// lib/features/weather/data/models/current_weather_model.dart

import 'package:clean_architecture/core/data/remote/models/weather_api_response_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'current_weather_model.g.dart';

@JsonSerializable()
class CurrentWeatherModel extends WeatherApiResponseModel {
  @JsonKey(name: 'current')
  final WeatherApiDataModel? data;

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
  final double feelslikeC;
  final WeatherApiConditionModel condition;
  final double windKph;
  final String windDir;
  final double precipMm;
  final int humidity;
  final int cloud;
  final double visKm;
  final double uv;

  const WeatherApiDataModel({
    required this.lastUpdated,
    required this.tempC,
    required this.feelslikeC,
    required this.condition,
    required this.windKph,
    required this.windDir,
    required this.precipMm,
    required this.humidity,
    required this.cloud,
    required this.visKm,
    required this.uv,
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
// lib/features/weather/data/data_sources/remote/weather_api_remote_data_source.dart

import 'dart:convert';  
  
import 'package:clean_architecture/core/env.dart';  
import 'package:clean_architecture/core/network/network.dart';  
import 'package:clean_architecture/features/weather/data/models/current_weather_model.dart';  
  
abstract class WeatherApiRemoteDataSource {  
  Future<CurrentWeatherModel> getCurrentWeather(String city);  
}  
  
class WeatherApiRemoteDataSourceImpl implements WeatherApiRemoteDataSource {  
  final Env env;  
  final Network network;  
  
  WeatherApiRemoteDataSourceImpl({  
    required this.env,  
    required this.network,  
  });  
  @override
  Future<CurrentWeatherModel> getCurrentWeather(String city) async {  
    final uri = Uri(  
      scheme: 'https',  
      host: env.weatherApiHost,  
      path: 'v1/current.json',  
      queryParameters: {  
        'key': env.weatherApiKey,  
        'q': city,  
      },
    );
    final response = await network.get(uri);  
    final jsonResponse = jsonDecode(response) as Map<String, dynamic>;  
    return CurrentWeatherModel.fromJson(jsonResponse);  
  }
}
```
#### Feature - Domain
`domain` stores `entities`, `use cases` and `abstract repository` classes, as they are the ‘domain’ or ‘subject’ area of an application. If you aren’t familiar with the term, you can think that this ‘domain’ is the base requirement of an application.

First thing, we need to create an `entity` for current weather data. This entity will represent what kind of data we want to show to the user.

```dart
// lib/features/weather/domain/entities/current_weather.dart

import 'package:clean_architecture/features/weather/data/models/current_weather_model.dart';

class CurrentWeather {
  final DateTime? lastUpdated;
  final double? tempC;
  final double? feelslikeC;
  final double? windKph;
  final String? windDir;
  final double? precipMm;
  final int? humidity;
  final int? cloud;
  final double? visKm;
  final double? uv;
  final String? conditionText;
  final String? conditionIcon;
  final String? locationName;
  final String? locationRegion;
  final String? locationCountry;

  const CurrentWeather({
    this.lastUpdated,
    this.tempC,
    this.feelslikeC,
    this.windKph,
    this.windDir,
    this.precipMm,
    this.humidity,
    this.cloud,
    this.visKm,
    this.uv,
    this.conditionText,
    this.conditionIcon,
    this.locationName,
    this.locationRegion,
    this.locationCountry,
  });

  factory CurrentWeather.fromModel(CurrentWeatherModel model) => CurrentWeather(
        lastUpdated: model.data?.lastUpdated,
        tempC: model.data?.tempC,
        feelslikeC: model.data?.feelslikeC,
        windKph: model.data?.windKph,
        windDir: model.data?.windDir,
        precipMm: model.data?.precipMm,
        humidity: model.data?.humidity,
        cloud: model.data?.cloud,
        visKm: model.data?.visKm,
        uv: model.data?.uv,
        conditionText: model.data?.condition.text,
        conditionIcon: model.data?.condition.icon,
        locationName: model.location?.name,
        locationRegion: model.location?.region,
        locationCountry: model.location?.country,
      );
}
```

Then create an abstract class for [WeatherAPI](https://www.weatherapi.com) repository.

```dart
// lib/features/weather/domain/repositories/weather_api_repository.dart

import 'package:clean_architecture/core/error/failures.dart';
import 'package:clean_architecture/features/weather/domain/entities/current_weather.dart';
import 'package:fpdart/fpdart.dart';

abstract class WeatherApiRepository {
  Future<Either<Failure, CurrentWeather>> getCurrentWeather(String city);
}
```

Things to keep in mind: `data source` returns `model`, `repository` uses one or more `data source` and gathers data from them, process it and returns `entity`. With this pattern, you can create an `entity` that contains data from several sources.

Next we will create a `use case` for getting current weather data using the repository above.

```dart
// lib/features/weather/domain/use_cases/get_current_weather.dart

import 'package:clean_architecture/core/domain/use_case.dart';
import 'package:clean_architecture/core/error/failures.dart';
import 'package:clean_architecture/features/weather/domain/entities/current_weather.dart';
import 'package:clean_architecture/features/weather/domain/repositories/weather_api_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

class GetCurrentWeather
    extends UseCase<CurrentWeather, GetCurrentWeatherParams> {
  final WeatherApiRepository weatherApiRepository;

  GetCurrentWeather({required this.weatherApiRepository});

  @override
  Future<Either<Failure, CurrentWeather>> call(
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

We almost finished the `data` and `domain` for weather feature. Last thing is to create an implementation of `weather_api_repository` in the `data` layer.

```dart
// lib/features/weather/data/repositories/weather_api_repository_impl.dart

import 'package:clean_architecture/core/error/failures.dart';
import 'package:clean_architecture/features/weather/data/data_sources/remote/weather_api_remote_data_source.dart';
import 'package:clean_architecture/features/weather/domain/entities/current_weather.dart';
import 'package:clean_architecture/features/weather/domain/repositories/weather_api_repository.dart';
import 'package:fpdart/fpdart.dart';

class WeatherApiRepositoryImpl implements WeatherApiRepository {
  final WeatherApiRemoteDataSource weatherApiRemoteSource;

  WeatherApiRepositoryImpl({required this.weatherApiRemoteSource});

  @override
  Future<Either<Failure, CurrentWeather>> getCurrentWeather(String city) async {
    try {
      final result = await weatherApiRemoteSource.getCurrentWeather(city);

      if (result.error != null) {
        return left(ServerFailure(message: result.error!.message));
      }

      final entity = CurrentWeather.fromModel(result);
      return right(entity);
    } on Exception catch (e) {
      return left(ServerFailure(message: e.toString(), cause: e));
    }
  }
}
```
#### Feature - Presentation
`presentation` stores **pages** and **widgets**. These are the 'presentation' or 'view' area of the application. If you aren't familiar with the term, you can think that this 'presentation' is the actual view of an application.

In this `presentation` layer, we use [auto_route](https://pub.dev/packages/auto_route) package to manage our pages routing. Then [flutter_bloc](https://pub.dev/packages/flutter_bloc) package will help us to manage state management hence keeping our code clean because we will separate the logic from the UI.

When creating a page/UI, keep in mind that **it should be dumb**. Means that it should not contain any logic. The logic should be handled in the `bloc`. Generally, a bloc is composed of **state**, **event**, and the **bloc** itself. The **state** will be used to manage the state of the page and the **event** will be used to communicate with the bloc to update the state. Let's create the `bloc` for the `current_weather` page.

```dart
// lib/features/weather/presentation/bloc/current_weather_states.dart

part of 'current_weather_bloc.dart';

abstract class CurrentWeatherState extends Equatable {
  const CurrentWeatherState();
}

class CurrentWeatherInitialState extends CurrentWeatherState {
  const CurrentWeatherInitialState();

  @override
  List<Object?> get props => [];
}

class CurrentWeatherLoadingState extends CurrentWeatherState {
  const CurrentWeatherLoadingState();

  @override
  List<Object?> get props => [];
}

class CurrentWeatherLoadedState extends CurrentWeatherState {
  final CurrentWeather currentWeather;

  const CurrentWeatherLoadedState({required this.currentWeather});

  @override
  List<Object?> get props => [currentWeather];
}

class CurrentWeatherErrorState extends CurrentWeatherState
    implements ErrorState {
  @override
  final String message;

  @override
  final Exception? cause;

  const CurrentWeatherErrorState({required this.message, this.cause});

  @override
  List<Object?> get props => [message, cause];
}
```

```dart
// lib/features/weather/presentation/bloc/current_weather_events.dart

part of 'current_weather_bloc.dart';

abstract class CurrentWeatherEvent extends Equatable {
  const CurrentWeatherEvent();
}

class GetCurrentWeatherEvent extends CurrentWeatherEvent {
  final String city;

  const GetCurrentWeatherEvent({required this.city});

  @override
  List<Object?> get props => [city];
}
```

```dart
// lib/features/weather/presentation/bloc/current_weather_bloc.dart

import 'package:clean_architecture/core/presentation/bloc/error_state.dart';
import 'package:clean_architecture/features/weather/domain/entities/current_weather.dart';
import 'package:clean_architecture/features/weather/domain/use_cases/get_current_weather.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'current_weather_events.dart';
part 'current_weather_states.dart';

class CurrentWeatherBloc
    extends Bloc<CurrentWeatherEvent, CurrentWeatherState> {
  final GetCurrentWeather getCurrentWeather;

  CurrentWeatherBloc({
    required this.getCurrentWeather,
  }) : super(const CurrentWeatherInitialState()) {
    on<GetCurrentWeatherEvent>(_onGetCurrentWeatherEvent);
  }

  Future<void> _onGetCurrentWeatherEvent(
    GetCurrentWeatherEvent event,
    Emitter<CurrentWeatherState> emit,
  ) async {
    emit(const CurrentWeatherLoadingState());

    final result = await getCurrentWeather(
      GetCurrentWeatherParams(city: event.city),
    );

    result.fold(
      (l) => emit(CurrentWeatherErrorState(message: l.message)),
      (r) => emit(CurrentWeatherLoadedState(currentWeather: r)),
    );
  }
}
```

We are missing the `ErrorState` class, let’s create it in the core so all error states can be inherited from it and makes all error uniform across the application.

```dart
// lib/core/presentation/bloc/error_state.dart

abstract class ErrorState {
  final String message;
  final Exception? cause;

  const ErrorState({
    required this.message,
    this.cause,
  });
}
```

That's it. Now we have the `bloc` for the `current_weather` page. The code itself is quite self-explanatory. When the `CurrentWeatherBloc` receives a `GetCurrentWeatherEvent` event, it will emit a `CurrentWeatherLoadingState` and then a `CurrentWeatherLoadedState` or `CurrentWeatherErrorState` depending on the result of the `GetCurrentWeather` use case.

The next part is to create weather page in `presentation` directory.

```dart
// lib/features/weather/presentation/current_weather_page.dart

import 'package:auto_route/auto_route.dart';  
import 'package:clean_architecture/core/router/app_router.gr.dart';  
import 'package:clean_architecture/features/weather/presentation/bloc/current_weather_bloc.dart';  
import 'package:flutter/material.dart';  
import 'package:flutter_bloc/flutter_bloc.dart';  
  
@RoutePage()  
class CurrentWeatherPage extends StatefulWidget {  
  const CurrentWeatherPage({super.key});  
  
  @override  
  State<CurrentWeatherPage> createState() => _CurrentWeatherPageState();  
}  
  
class _CurrentWeatherPageState extends State<CurrentWeatherPage> {  
  final _cityTextCtl = TextEditingController();  
  final _cityTextFocus = FocusNode();  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(  
        title: const Text('Current Weather'),  
        actions: [  
          IconButton(  
            icon: const Icon(Icons.settings),  
            onPressed: () {  
              context.router.push(const AppSettingsRoute());  
            },
          ),
        ],
      ),      
      body: BlocBuilder<CurrentWeatherBloc, CurrentWeatherState>(  
        builder: (context, state) {  
          return ListView(  
            padding: const EdgeInsets.symmetric(horizontal: 16),  
            children: [  
              TextField(  
                controller: _cityTextCtl,  
                focusNode: _cityTextFocus,  
                decoration: const InputDecoration(  
                  hintText: 'City',  
                ),
              ),
              const SizedBox(height: 8),  
              ElevatedButton(  
                onPressed: () {  
                  context.read<CurrentWeatherBloc>().add(  
                        GetCurrentWeatherEvent(  
                          city: _cityTextCtl.text,  
                        ),
                      );
                    },
                child: const Text('Get Weather'),  
              ),
              const SizedBox(height: 16),  
              _buildWeather(state),  
            ],
          );
        },
      ),    
    );  
  }  
  
  Widget _buildWeather(CurrentWeatherState state) {  
    if (state is CurrentWeatherLoadedState) {  
      _cityTextFocus.unfocus();  
  
      final weatherIconUrl =  
          'https:${state.currentWeather.conditionIcon ?? '//placehold.co/64x64/png'}';  
  
      return Column(  
        children: [  
          Image.network(weatherIconUrl),  
          Text(  
            state.currentWeather.conditionText ?? '-',  
            style: Theme.of(context).textTheme.headlineSmall,  
          ),
          Text(  
              '${state.currentWeather.locationName}, ${state.currentWeather.locationRegion}'),  
          Text('${state.currentWeather.locationCountry}'),  
          const SizedBox(height: 16),  
          GridView.count(  
            crossAxisCount: 3,  
            shrinkWrap: true,  
            physics: const NeverScrollableScrollPhysics(),  
            children: [  
              _buildDataCard(  
                'Temp (C)',  
                '${state.currentWeather.tempC ?? '-'}',  
              ),              
              _buildDataCard(  
                'Feels Like (C)',  
                '${state.currentWeather.feelslikeC ?? '-'}',  
              ),              
              _buildDataCard(  
                'Wind (km/h)',  
                '${state.currentWeather.windKph ?? '-'}',  
              ),              
              _buildDataCard(  
                'Wind Dir',  
                state.currentWeather.windDir,  
              ),              
              _buildDataCard(  
                'Precip (mm)',  
                '${state.currentWeather.precipMm ?? '-'}',  
              ),              
              _buildDataCard(  
                'Humidity (%)',  
                '${state.currentWeather.humidity ?? '-'}',  
              ),              
              _buildDataCard(  
                'Cloud (%)',  
                '${state.currentWeather.cloud ?? '-'}',  
              ),              
              _buildDataCard(  
                'Vis (km)',  
                '${state.currentWeather.visKm ?? '-'}',  
              ),              
              _buildDataCard(  
                'UV',  
                '${state.currentWeather.uv ?? '-'}',  
              ),
            ],
          ),          
          const SizedBox(height: 16),  
          Text(  
            'Last Updated: ${state.currentWeather.lastUpdated}',  
            style: Theme.of(context).textTheme.bodySmall,  
          ),        
        ],      
      );    
    }  
    if (state is CurrentWeatherLoadingState) {  
      return const Center(child: CircularProgressIndicator());  
    }  
    if (state is CurrentWeatherErrorState) {  
      return Text(state.message);  
    }  
    return const SizedBox();  
  }  
  Widget _buildDataCard(String header, String? content) {  
    return Card(  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.center,  
        mainAxisAlignment: MainAxisAlignment.center,  
        children: [  
          Text(header, textAlign: TextAlign.center),  
          Text(  
            content ?? '-',  
            textAlign: TextAlign.center,  
            style: Theme.of(context).textTheme.headlineLarge,  
          ),        
        ],      
      ),    
    );  
  }
}
```

and we also need a page to change application configurations (for now we only have a theme mode config).

```dart
// lib/features/app_settings/presentation/app_settings_page.dart

import 'package:auto_route/auto_route.dart';  
import 'package:clean_architecture/core/presentation/theme/theme_mode_cubit.dart';  
import 'package:flutter/material.dart';  
import 'package:flutter_bloc/flutter_bloc.dart';  
  
@RoutePage()  
class AppSettingsPage extends StatefulWidget {  
  const AppSettingsPage({super.key});  
  
  @override  
  State<AppSettingsPage> createState() => _AppSettingsPageState();  
}  
  
class _AppSettingsPageState extends State<AppSettingsPage> {  
  @override  
  Widget build(BuildContext context) {  
    final themeSetting = Row(  
      mainAxisAlignment: MainAxisAlignment.spaceBetween,  
      children: [  
        const Text('App Theme'),  
        DropdownButton<ThemeMode>(  
          items: const [  
            DropdownMenuItem(  
              value: ThemeMode.system,  
              child: Text('System'),  
            ),            DropdownMenuItem(  
              value: ThemeMode.light,  
              child: Text('Light'),  
            ),            DropdownMenuItem(  
              value: ThemeMode.dark,  
              child: Text('Dark'),  
            ),
          ],
          value: context.watch<ThemeModeCubit>().state,  
          onChanged: (value) {  
            context.read<ThemeModeCubit>().setThemeMode(value!);  
          },
        ),
      ],
    );  
    return Scaffold(  
      appBar: AppBar(  
        title: const Text('App Settings'),  
      ),
      body: ListView(  
        padding: const EdgeInsets.symmetric(horizontal: 16),  
        children: [  
          themeSetting,  
        ],      
	  ),    
	);
  }
}
```

As for the routing I mentioned in the previously, we will create an `app_router.dart` file in the `core/router` directory.

```dart
// lib/core/router/app_router.dart

import 'package:auto_route/auto_route.dart';  
import 'package:clean_architecture/core/router/app_router.gr.dart';  
  
@AutoRouterConfig()  
class AppRouter extends RootStackRouter {  
  @override  
  List<AutoRoute> get routes => [  
        AutoRoute(  
          page: CurrentWeatherRoute.page,  
          initial: true,  
        ),        
        AutoRoute(page: AppSettingsRoute.page),  
      ];
    }
```

---
## Dependency Injection
In clean architecture, we use **dependency injection** (or DI in short) to make our project cleaner. In a traditional way of creating an instance, we need to use **contructor injection** as we pass the required parameters to the constructor. It will make a mess if we are creating many instances throughout the project, because it will scattered anywhere.

There are many ways to achieve dependency injection in Flutter, for this project I will use [GetIt](https://pub.dev/packages/get_it). Let's create our `injection_container`, this class is responsible for creating all the instances that we need in our project.

```dart
// lib/injection_container.dart

import 'package:clean_architecture/core/data/local/config.dart';
import 'package:clean_architecture/core/data/local/theme_mode_config.dart';
import 'package:clean_architecture/core/env.dart';
import 'package:clean_architecture/core/network/network.dart';
import 'package:clean_architecture/core/presentation/theme/theme_mode_cubit.dart';
import 'package:clean_architecture/features/weather/data/data_sources/remote/weather_api_remote_data_source.dart';
import 'package:clean_architecture/features/weather/data/repositories/weather_api_repository_impl.dart';
import 'package:clean_architecture/features/weather/domain/repositories/weather_api_repository.dart';
import 'package:clean_architecture/features/weather/domain/use_cases/get_current_weather.dart';
import 'package:clean_architecture/features/weather/presentation/bloc/current_weather_bloc.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

final getIt = GetIt.instance;

void setup() {
  // env
  getIt.registerSingleton<Env>(EnvImpl());

  // network
  getIt.registerLazySingleton<http.Client>(() => http.Client());
  getIt.registerLazySingleton<Network>(() => NetworkImpl(getIt()));

  // shared preferences
  getIt.registerSingletonAsync<SharedPreferences>(
    () async {
      final prefs = await SharedPreferences.getInstance();
      return prefs;
    },
  );

  // configs
  getIt.registerSingletonWithDependencies<Config<ThemeMode>>(
    () => ThemeModeConfig(sharedPreferences: getIt()),
    dependsOn: [SharedPreferences],
  );

  // data sources
  getIt.registerLazySingleton<WeatherApiRemoteDataSource>(
    () => WeatherApiRemoteDataSourceImpl(
      env: getIt(),
      network: getIt(),
    ),
  );

  // repositories
  getIt.registerLazySingleton<WeatherApiRepository>(
    () => WeatherApiRepositoryImpl(
      weatherApiRemoteSource: getIt(),
    ),
  );

  // use cases
  getIt.registerLazySingleton<GetCurrentWeather>(
    () => GetCurrentWeather(
      weatherApiRepository: getIt(),
    ),
  );

  // blocs
  getIt.registerSingletonAsync<ThemeModeCubit>(
    () async {
      final initialThemeMode = await getIt<Config<ThemeMode>>().get();
      return ThemeModeCubit(
        themeModeConfig: getIt(),
        initialThemeMode: initialThemeMode,
      );
    },
    dependsOn: [SharedPreferences, Config<ThemeMode>],
  );
  getIt.registerFactory<CurrentWeatherBloc>(
    () => CurrentWeatherBloc(
      getCurrentWeather: getIt(),
    ),
  );

  // others
}
```

To monitor events and states in our bloc, also add a `bloc observer` class.

```dart
// lib/core/presentation/bloc/app_bloc_observer.dart

import 'dart:developer' as dev;  
  
import 'package:flutter_bloc/flutter_bloc.dart';  
  
class AppBlocObserver extends BlocObserver {  
  @override  
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {  
    dev.log("[bloc_error] $bloc\nerror: $error\nstacktrace: $stackTrace");  
    super.onError(bloc, error, stackTrace);  
  }  
  @override  
  void onChange(BlocBase bloc, Change change) {  
    dev.log(  
        "[${bloc.runtimeType}] ${DateTime.now().toIso8601String()}\nFrom: ${change.currentState}\nNext: ${change.nextState}");  
    super.onChange(bloc, change);  
  }
}
```

Now we have all the required components for our app, lets look at the `main.dart` file.

```dart
// lib/main.dart

import 'package:clean_architecture/core/presentation/bloc/app_bloc_observer.dart';  
import 'package:clean_architecture/core/presentation/theme/app_theme.dart';  
import 'package:clean_architecture/core/presentation/theme/theme_mode_cubit.dart';  
import 'package:clean_architecture/core/router/app_router.dart';  
import 'package:clean_architecture/features/weather/presentation/bloc/current_weather_bloc.dart';  
import 'package:flutter/material.dart';  
import 'package:flutter_bloc/flutter_bloc.dart';  
import 'injection_container.dart' as ic;  
  
Future<void> main() async {  
  WidgetsFlutterBinding.ensureInitialized();  
  
  // dependency injection setup  
  ic.setup();  
  await ic.getIt.allReady();  
  
  // register bloc observer  
  Bloc.observer = AppBlocObserver();  
  
  runApp(WeatherApp());  
}  
  
class WeatherApp extends StatelessWidget {  
  WeatherApp({super.key});  
  
  final _appRouter = AppRouter();  
  
  @override  
  Widget build(BuildContext context) {  
    return MultiBlocProvider(  
      providers: [  
        BlocProvider<ThemeModeCubit>(  
          create: (context) => ic.getIt(),  
        ),
        BlocProvider<CurrentWeatherBloc>(  
          create: (context) => ic.getIt(),  
        ),      
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(  
        builder: (context, state) {  
          return MaterialApp.router(  
            debugShowCheckedModeBanner: false,  
            title: 'Weather App',  
            theme: lightTheme,  
            darkTheme: darkTheme,  
            themeMode: state,  
            routerConfig: _appRouter.config(),  
          );
        },
      ),
    );  
  }
}
```

---
## Testing
.

---

All the codes in this set of articles are available on [GitHub](https://github.com/dhemasnurjaya/flutter-clean-architecture), and will be updated regularly because I use them too as my project starter.