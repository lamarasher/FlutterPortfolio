// ================= App Setting Property ===========================
/// This is an example of clean code and single purpose classes with
/// dependencies declared from the constructor.
/// `AppSettings` & `AppSettingsProperty` classes where created to simplify
/// changing app setting values that are stored in a database.
///
/// Note:
/// As this is all in one dart file, the benefits of using private variables
/// cannot be seen.

// ================= Supported Class Snippets =======================

/// Represents a database that stores the settings values.
/// In the case of Novus, where this code was taken from,
/// This is a NoSQL database Hive Box - https://pub.dev/packages/hive
class Box {
  get(name, {defaultValue}) {}
  put(name, value) {}
  clear() {}
}

/// This is a snippet of base settings class that stores
/// the setting properties in the database
abstract class BaseSettings {
  /// Map of all the settings
  final _settingProperties = Map<String, IAppSettingsProperty>();

  /// Reference to the NoSQL database where that values are saved.
  final Box _box;

  BaseSettings(this._box);

  /// Resets all of the settings by clearing the database
  Future clearSettings() => _box.clear();
}

bool isNullOrWhitespace(String? s) => s == null || s.trim() == "";

// ===================== Example Use Case ============================
// AppSettingsProperty Follow the format:
// - Declare
// - Getter
// - Setter
//
// This was inspired by the WPF Dependency Properties

/// Settings class for general app properties.
/// Several of thes can be made. For instance, Novus has a class for
/// Developer Properties.
///
/// Once set, app settings can simply be updated using:
/// `AppSettings.isDarkMode = true`
/// And this is automatically saved to the underlying database.
class AppSettings extends BaseSettings {
  /// Declared & Registered property for `isDarkMode`
  AppSettingsProperty<bool> get _isDarkModeProperty =>
      AppSettingsProperty.register<bool>(this, "isDarkMode", true);

  /// Get a value indicating whether the app is in dark mode
  bool get isDarkMode => _isDarkModeProperty.value;

  /// Sets a value indicating whether the app is in dark mode
  set isDarkMode(bool value) => _isDarkModeProperty.value = value;

  /// Settings constructor with a reference to the setting database
  AppSettings(Box box) : super(box);

  // Not all code is syncronous. If the database or any dependencies needs
  // accessing asynchronously like it does in Novus, then the settings
  // constrcutor should be made private and a Future should be used instead
  // See the Novus code snippet Below
  // ---------------------------------------------------------------------------
  // static Future<AppSettings> createAsync(ILoggingService loggingService) async {
  //   var box = await Hive.openBox(_settingsBoxName);
  //   var packageInfo = await PackageInfo.fromPlatform();
  //   return AppSettings._(box, packageInfo);
  // }
  // ---------------------------------------------------------------------------
}

// ========================== Class ==================================

/// Interface that the generic class of AppSettingsProperty implements
abstract class IAppSettingsProperty {
  /// Gets the property name.
  String get name;

  /// Gets the property type.
  Type get type;
}

/// Property responsible for getting and setting a app setting value.
/// The property updates the settings database live
class AppSettingsProperty<M> implements IAppSettingsProperty {
  /// Reference to the database
  final Box _box;

  /// Name of the property
  final String name;

  /// Properties default value. If the value is missing from the database,
  /// this is what will be returned in the get method
  final M _defaultValue;

  /// The serialised version of `_defaultValue`
  final String? _serialisedDefaultValue;

  /// Optional method use to serialise the property type to another that can be
  /// stored in the database. Must be set with `deserialise`.
  final String Function(M)? serialise;

  /// Optional method use to deserialise the property type from another that can
  /// be stored in the database. Must be set with `serialise`.
  final M Function(String)? deserialise;

  /// Gets the property type
  Type get type => M;

  /// Gets the property value
  M get value {
    if (deserialise != null) {
      final serialisedValue =
          _box.get(name, defaultValue: _serialisedDefaultValue);
      return deserialise!(serialisedValue);
    }
    return _box.get(name, defaultValue: _defaultValue);
  }

  /// Sets the property value
  set value(M value) {
    if (serialise != null) {
      _box.put(name, serialise!(value));
      return;
    }
    _box.put(name, value);
  }

  /// Private constructor to create the property
  /// We only want devs to use the `register` method
  AppSettingsProperty._(this._box, this.name, this._defaultValue,
      this.serialise, this.deserialise)
      : _serialisedDefaultValue = serialise?.call(_defaultValue);

  /// Creates and initialises a new setting property.
  /// A property requires a unique name and can only be registered once.
  static AppSettingsProperty<M> register<M>(
      BaseSettings context, String name, M defaultValue,
      {String Function(M)? serialise, M Function(String)? deserialise}) {
    assert(!isNullOrWhitespace(name), "Setting name cannot be null");
    if (serialise != null || deserialise != null) {
      assert(serialise != null && deserialise != null,
          "serialise and deserialise must both be implemented or niether");
    } else {
      assert(_isTypeValid(M), "Setting type is not supported");
    }
    if (context._settingProperties.containsKey(name)) {
      final property = context._settingProperties[name]!;
      assert(property.type == M,
          "Setting type does not match preregistered setting");
      return property as AppSettingsProperty<M>;
    }
    final newProperty = AppSettingsProperty<M>._(
        context._box, name, defaultValue, serialise, deserialise);
    context._settingProperties[name] = newProperty;
    return newProperty;
  }

  /// Returns a value indicating whether the type is supported by the
  /// the database.
  static bool _isTypeValid(Type type) {
    return [
      bool,
      int,
      double,
      String,
    ].contains(type);
  }
}
