---
title: 'Flutter Clean Architecture Part 3'
description: Dive into Clean Architecture for Flutter or Dart projects - Part 3
date: 2024-08-06T23:16:46+07:00
draft: false
tags:
  - Flutter
---

After following the first 2 parts, it comes time for the last part. I think I put too much code in 2 previous part and because it still incomplete, we don't have a chance to run it. Maybe some other time I'll rewrite it with clearer steps, but for now let's just finish what we have so far.

## Dependency Injection
In clean architecture, we use **dependency injection** (or DI in short) to make our project cleaner. In a traditional way of creating an instance, we need to use **contructor injection** as we pass the required parameters to the constructor. It will make a mess if we are creating many instances throughout the project, because it will scattered anywhere.

There are many ways to achieve dependency injection in Flutter, for this project I will use [GetIt](https://pub.dev/packages/get_it). Let's create our `injection_container`, this class is responsible for creating all the instances that we need in our project.

```dart
// injection_container.dart

import 'package:clean_architecture/core/network/network.dart';
import 'package:clean_architecture/features/weather/data/data_sources/remote/weather_api_remote_data_source.dart';
import 'package:clean_architecture/features/weather/data/repositories/weather_api_repository_impl.dart';
import 'package:clean_architecture/features/weather/domain/repositories/weather_api_repository.dart';
import 'package:clean_architecture/features/weather/domain/use_cases/get_current_weather.dart';
import 'package:clean_architecture/features/weather/presentation/bloc/current_weather_bloc.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setup() {
  // network
  getIt.registerLazySingleton<Network>(() => NetworkImpl());

  // data sources
  getIt.registerLazySingleton<WeatherApiRemoteDataSource>(
    () => WeatherApiRemoteDataSourceImpl(
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
  getIt.registerFactory<CurrentWeatherBloc>(
    () => CurrentWeatherBloc(
      getCurrentWeather: getIt(),
    ),
  );
}
```

Now we have all the required components for our app, lets look at the `main.dart` file.

```dart
// lib/main.dart

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

  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  WeatherApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CurrentWeatherBloc>(
          create: (context) => ic.getIt(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Weather App',
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
```

## Testing

.