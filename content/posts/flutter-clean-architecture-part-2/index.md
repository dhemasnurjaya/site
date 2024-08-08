---
title: 'Flutter Clean Architecture Part 2'
description: Dive into Clean Architecture for Flutter or Dart projects - Part 2
date: 2024-08-06T19:02:49+07:00
draft: false
tags:
  - Flutter
---

In this part I will explain the rest of [directory structure]({{< ref "/posts/flutter-clean-architecture-part-1#directory-structure" >}} "Flutter Clean Architecture - Directory Structure") of Flutter Clean Architecture. If you haven't read the first part, [click here]({{< ref "/posts/flutter-clean-architecture-part-1" >}} "Flutter Clean Architecture Part 1") and to read it.


## Directory Structure (Part 2)

### Feature

In clean architecture, we divide our application into **features**. For example, in this project will have a **weather** feature. Each feature will have its own (but not always neccessarily) `domain`, `data` and `presentation`.

### Data

`data` as it's namesake, will deals with all data needed by the app. It contains (not limited to) `model`, `repository` implementation, and `data sources`. `Model` and `repository` classes are self-explanatory, and `data sources` will be used to access data from both local and remote sources.

Let's create a model for [WeatherAPI](https://www.weatherapi.com/) current weather response.

```dart
// lib/features/weather/data/models/current_weather_model.dart

import 'package:clean_architecture/core/data/remote/model/weather_api_response_model.dart';
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

import 'package:clean_architecture/core/data/remote/hosts.dart';
import 'package:clean_architecture/core/network/network.dart';
import 'package:clean_architecture/features/weather/data/models/current_weather_model.dart';

abstract class WeatherApiRemoteDataSource {
  Future<CurrentWeatherModel> getCurrentWeather(String city);
}

class WeatherApiRemoteDataSourceImpl implements WeatherApiRemoteDataSource {
  final Network network;

  WeatherApiRemoteDataSourceImpl({required this.network});

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

#### Domain

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
// features/weather/domain/repositories/weather_api_repository.dart

import 'package:clean_architecture/core/error/failure.dart';
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
import 'package:clean_architecture/core/error/failure.dart';
import 'package:clean_architecture/features/weather/domain/entities/current_weather.dart';
import 'package:clean_architecture/features/weather/domain/repositories/weather_api_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

class GetCurrentWeather
    extends UseCase<CurrentWeather, GetCurrentWeatherParams> {
  final WeatherApiRepository weatherApiRepository;

  GetCurrentWeather({required this.weatherApiRepository});

  @override
  Future<Either<Failure, CurrentWeather>> execute(
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

import 'package:clean_architecture/core/error/failure.dart';
import 'package:clean_architecture/core/error/server_failure.dart';
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

### Presentation

`presentation` stores **pages** and **widgets**. These are the 'presentation' or 'view' area of the application. If you aren't familiar with the term, you can think that this 'presentation' is the actual view of an application.

In this `presentation` layer, we use [auto_route](https://pub.dev/packages/auto_route) package to manage our pages routing. Then [flutter_bloc](https://pub.dev/packages/flutter_bloc) package will help us to manage state management hence keeping our code clean because we will separate the logic from the UI.

When creating a page/UI, keep in mind that **it should be dumb**. Means that it should not contain any logic. The logic should be handled in the `bloc`. Generally, a bloc is composed of **state**, **event**, and the **bloc** itself. The **state** will be used to manage the state of the page and the **event** will be used to communicate with the bloc to update the state. Let's create the `bloc` for the `current_weather` page.

```dart
// lib/features/current_weather/presentation/bloc/current_weather_states.dart

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
// lib/features/current_weather/presentation/bloc/// features/current_weather/presentation/bloc/current_weather_events.dart

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
// lib/features/current_weather/presentation/bloc/current_weather_bloc.dart

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

    final result = await getCurrentWeather.execute(
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
// lib/features/current_weather/presentation/current_weather_page.dart

import 'package:auto_route/auto_route.dart';
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
      ];
}
```


## See you in the last part!

I think it's already a long post for this part. We'll continue in the next part to complete our application, including `dependency injection` and `testing`.

If there are any missing steps or typos, please let me know, or you can always open an issue or directly create a pull request on this [blog repository](https://github.com/dhemasnurjaya/site).