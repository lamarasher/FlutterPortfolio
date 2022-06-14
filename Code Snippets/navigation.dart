// ================= Flutter App Navigation ===========================
// This code snippet shows how navigation can be setup in flutter.
// Making use of a NaviationService class that is passed to a service provider,
// we can invoke a navigation anywhere in the app. (service provider is container<>)
// 
// `onGenerateRoute` shows how navigation can be intercepted and redirected
// `initialisePageRegistrations()` shows how pages can be registered to a route

class NavigationApp extends StatelessWidget {
  // Get the navigation service from the service provider.
  final _navigator = container<NavigationService>();
  final AppSettings appSettings;

  @override
  Widget build(context) {
    initialisePageRegistrations();

    return MaterialApp(
      title: "Example",
      debugShowCheckedModeBanner: false,
      // ...
      onGenerateRoute: onGenerateRoute,
      initialRoute: Routes.splash,
      navigatorKey: _navigator.key,
    );
  }

  /// This allows us to intercept navigation and redirect the user under certain
  /// conditions. You will see below, that if the user is not signed in, the 
  /// app will navigate to the sign in page instead.
  Route onGenerateRoute(RouteSettings settings) {
    // Get the userservice from the service provider
    var userService = container<IUserService>();

    var userlessRoutes = {
      Routes.splash,
      Routes.about,
      Routes.signIn,
      Routes.signUp,
      Routes.forgotPassword,
    };

    if (!userlessRoutes.contains(settings.name) && !userService.isSignedIn) {
      // go to the sign in screen if the user is not signed in
      return _navigator.generateRoute(RouteSettings(name: Routes.signIn));
    }

    return _navigator.generateRoute(settings);
  }

  /// This method links a `Routes` constant to a flutter page.
  /// We can also declare how we want the transition animation for the page.
  void initialisePageRegistrations() {
    _navigator.register(Routes.splash, (_, __) => SplashScreen(),
        transition: PageTransitionType.fade);

    _navigator.register(Routes.signIn,
        (_, args) => SignInScreen(BaseRouteArgs.from(args).heroTag),
        transition: PageTransitionType.fade);

    _navigator.register(Routes.signUp,
        (_, args) => SignUpScreen(BaseRouteArgs.from(args).heroTag),
        transition: PageTransitionType.fade);

    _navigator.register(Routes.forgotPassword,
        (_, args) => ForgotPasswordScreen(args != null ? args["email"] : ""),
        transition: PageTransitionType.fade);

    _navigator.register(Routes.home, (_, __) => HomeScreen(),
        transition: PageTransitionType.fade);

    _navigator.register(Routes.settings, (_, __) => SettingsScreen(),
        transition: PageTransitionType.fade);

    // etc ...
  }
}

/// This class maintains all the routes that navigate to different pages
/// This can be simplified to an enum or expanded to classes of their own, 
/// declaring what type or arguments are required for navigation.
class Routes {
  /// Route for Splash Page
  static const String splash = "splash";

  /// Route for Splash Page
  static const String signIn = "signIn";

  /// Route for Splash Page
  static const String signUp = "signUp";

  /// Etc .....
}

// ========================= Invoke Navigation ================================
// using container<> the service provider, we can get the navigation service 
// anywhere. Once this is done, you can simply call this method to navigate.
_navigationService.navigateWithArgs(Routes.createDocument,
        CreateDocumentArgs(folder, _projectService.current));

