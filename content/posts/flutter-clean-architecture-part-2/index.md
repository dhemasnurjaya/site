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

#### Domain

`domain` stores **use cases** and **abstract repository classes**, as they are the 'domain' or 'subject' area of an application. If you aren't familiar with the term, you can think that this 'domain' is the base requirement of an application.

First create an abstract class for [WeatherAPI](https://www.weatherapi.com/) repository.

```dart
// features/weather/domain/repositories/weather_api_repository.dart

import 'package:clean_architecture/core/error/failure.dart';
import 'package:clean_architecture/data/models/current_weather_model.dart';
import 'package:fpdart/fpdart.dart';

abstract class WeatherApiRepository {
  Future<Either<Failure, CurrentWeatherModel>> getCurrentWeather(String city);
}
```

and a use case for getting current weather data using the repository above.

```dart
// features/weather/domain/use_cases/get_current_weather.dart

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
// features/weather/data/models/current_weather_model.dart

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
// features/weather/data/data_sources/weather_api_remote_source.dart

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
// features/weather/domain/repositories/weather_api_repository_impl.dart

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

In this `presentation` layer, we use [auto_route](https://pub.dev/packages/auto_route) package to manage our pages routing. Then [flutter_bloc](https://pub.dev/packages/flutter_bloc) package will help us to manage state management hence keeping our code clean because we will separate the logic from the UI.

When creating a page/UI, keep in mind that **it should be dumb**. Means that it should not contain any logic. The logic should be handled in the `bloc`. Generally, a bloc is composed of **state**, **event**, and the **bloc** itself. The **state** will be used to manage the state of the page and the **event** will be used to communicate with the bloc to update the state. Let's create the `bloc` for the `current_weather` page.

```dart
// features/current_weather/presentation/bloc/current_weather_states.dart

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
// features/current_weather/presentation/bloc/current_weather_events.dart

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
// features/current_weather/presentation/bloc/current_weather_bloc.dart

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

That's it. Now we have the `bloc` for the `current_weather` page. The code itself is quite self-explanatory. When the `CurrentWeatherBloc` receives a `GetCurrentWeatherEvent` event, it will emit a `CurrentWeatherLoadingState` and then a `CurrentWeatherLoadedState` or `CurrentWeatherErrorState` depending on the result of the `GetCurrentWeather` use case.

The next part is to create weather page in `presentation` directory.

```dart
// features/current_weather/presentation/current_weather_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:clean_architecture/core/router/app_router.dart';
import 'package:clean_architecture/features/weather/presentation/current_weather/blocs/current_weather_bloc.dart';
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

As for the routing I mentioned in the previously, we will create an `app_router.dart` file in the `core/router` directory.

```dart
import 'package:auto_route/auto_route.dart';
import 'package:clean_architecture/features/weather/presentation/current_weather/current_weather_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: CurrentWeatherRoute.page,
          initial: true,
        ),
      ];
}
```

I think it's already a long post for this part. We'll continue in the next part to complete our application, including `dependency injection` and `testing`.

If there are any missing steps or typos, please let me know, or you can always open an issue or directly create a pull request on this [blog repository](https://github.com/dhemasnurjaya/site).