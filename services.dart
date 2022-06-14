// ============================ Services ===========================
// This snippet makes the use of Get It - https://pub.dev/packages/get_it
// As a service locator for inversion of control.
// This makes various services accessible anywhere in the app.
// All services are registered once at the start of the application ( or
// unit test).

GetIt container = GetIt.instance;

void main() {
  // initial setup ...

  initialiseContainer();

  // Run Application ...
}

void initialiseContainer() {
  container.registerSingleton<ILoggingService>(loggingService);
  container.registerSingleton<ILogger>(loggingService);
  container.registerLazySingleton(() => config);
  container.registerLazySingleton(() => firebaseApp);
  container.registerLazySingleton(() {
    assert(settings != null, "Settings has not been initialised");
    return settings;
  });
  container.registerLazySingleton(() => navigationService);
  // ... more registrations
}

// Getting a service
final appSettings = container<AppSettings>();
final _navigationService = container<NavigationService>();
final _userService = container<IUserService>();
final _syncService = container<ISyncService>();
final _membershipService = container<IMembershipService>();
final _tutorialService = container<ITutorialService>();
