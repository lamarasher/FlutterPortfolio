// ================= NRI app resources ===========================
// This was created to make accessing resources from the app easier.
// Various controls like NriImage resolve the Nri to retrieve images
// In Novus, Nri is also used for project file locations to ensure
// relative paths.
// Note this file is pre null-safety

String appResourceScheme = "nars";
String packageResourceScheme = "npkrs";
String userResourceScheme = "nurs";
String networkResourceScheme = "uri";
String projectResourceScheme = "nprs";

List<String> _schemes = [
  appResourceScheme,
  packageResourceScheme,
  userResourceScheme,
  networkResourceScheme,
  projectResourceScheme,
];

class PackageNri {
  final Nri nri;
  PackageNri(this.nri) {
    if (!nri.isPackageResource) {
      throw Exception("Nri is does not have the package resource scheme");
    }
  }
  PackageNri.from(Nri nri) : this(nri);
  String? get package => nri.isPackageResource && nri.segments.isNotEmpty
      ? nri.segments.first
      : null;
  String get path => nri.segments.skip(1).join("/");
}

class Nri {
  final String scheme;
  final List<String> segments;
  final Map<String, String?> queries;

  Nri(this.scheme, this.segments, this.queries);

  factory Nri.fromString(String nri) => parse(nri);

  String get nriString => "$scheme::$path$_queriesString";
  String get nriStringWithoutScheme => "$path$_queriesString";

  String get path => segments.join("/");

  String get _queriesString {
    var queryString = "";
    queries.forEach((key, val) {
      queryString += queryString.isNotEmpty ? "&" : "?";

      if (val != null) {
        queryString += "$key=$val";
      } else {
        queryString += key;
      }
    });

    return queryString;
  }

  bool get isAppResource => scheme == appResourceScheme;
  bool get isPackageResource => scheme == packageResourceScheme;
  bool get isUserResource => scheme == userResourceScheme;
  bool get isNetworkResource => scheme == networkResourceScheme;
  bool get isProjectResource => scheme == projectResourceScheme;

  static Nri appResource(String path) =>
      Nri.fromString("$appResourceScheme::$path");
  static Nri packageResource(String path) =>
      Nri.fromString("$packageResourceScheme::$path");
  static Nri userResource(String path) =>
      Nri.fromString("$userResourceScheme::$path");
  static Nri networkResource(String path) =>
      Nri.fromString("$networkResourceScheme::$path");
  static Nri projectResource(String path) =>
      Nri.fromString("$projectResourceScheme::$path");

  @Deprecated("Please use FileService")
  Nri getAbsoluteNri(String projectPath) {
    if (isProjectResource) {
      return fullNri(projectPath, nriStringWithoutScheme);
    }
    return this;
  }

  @Deprecated("Please use FileService")
  Nri getRelativePath(String projectPath) {
    if (isUserResource && path.contains("$projectPath/")) {
      var relativePath =
          nriStringWithoutScheme.replaceFirst("$projectPath/", "");
      return parse("$projectResourceScheme::$relativePath");
    }
    return this;
  }

  ValueType getQueryValue<ValueType>(
      String key, ValueType Function(String?) convert) {
    if (queries.containsKey(key)) {
      return convert(queries[key]);
    }
    throw ArgumentError.value(
        key, "key does not exist in query. Unable to convert");
  }

  bool operator ==(o) => o is Nri && o.nriString == nriString;

  @Deprecated("Please use FileService")
  static Nri fullNri(String projectPath, String relativePath) =>
      parse("$userResourceScheme::$projectPath/$relativePath");

  static Nri? tryParse(String? nri) {
    if (nri == null || nri.isEmpty) {
      return null;
    }
    try {
      return parse(nri);
    } catch (e) {
      return null;
    }
  }

  static Nri parse(String nri) {
    if (nri.isEmpty) throw ArgumentError.value(nri, "nri cannot be empty");
    if (!nri.contains("::"))
      throw ArgumentError.value(nri, "nri has no valid scheme");

    var schemeSplit = nri.split("::");

    if (schemeSplit.length > 2)
      throw ArgumentError.value(nri, "nri multiple '::'");

    var scheme = schemeSplit.first;

    if (!_schemes.contains(scheme))
      throw ArgumentError.value(nri, "$scheme is not a valid scheme");

    var nriPathWithQueries = schemeSplit[1];
    var nriPathWithQueriesSplit = nriPathWithQueries.split("?");

    var segements = nriPathWithQueriesSplit.first.split("/");

    var queryStrings = nriPathWithQueriesSplit.length > 1
        ? nriPathWithQueriesSplit[1].split("&")
        : <String>[];

    if (segements.isEmpty) throw ArgumentError.value(nri, "nri has no path");

    // parse queries

    var queries = Map<String, String?>();
    for (var query in queryStrings) {
      if (query.contains("=")) {
        var keyVal = query.split("=");
        queries.putIfAbsent(keyVal.first, () => keyVal.last);
      } else {
        queries.putIfAbsent(query, () => null);
      }
    }

    return Nri(scheme, segements, queries);
  }
}

class NriPath {
  static String getNriFilename(Nri nri) => getFilename(nri.path);
  static String getFilename(String? path) {
    if (path == null || path == "") {
      return "";
    }
    var segments = path.split("/");
    return segments.last;
  }

  static String getNriFilenameWithoutExtension(Nri nri) =>
      getFilenameWithoutExtension(nri.path);
  static String getFilenameWithoutExtension(String path) {
    var segments = getFilename(path).split(".");
    return segments.first;
  }

  static String getNriExtension(Nri nri) => getExtension(nri.path);
  static String getExtension(String path) {
    var segments = getFilename(path).split(".");
    if (segments.length > 1) {
      return segments.last;
    }
    return "";
  }
}

class NQuery {
  String key;
  String? value;
  bool hasValue;

  NQuery(this.key, this.value, [this.hasValue = true]);
  NQuery.key(String key) : this(key, null, false);

  String asQueryString() => hasValue ? "$key=$value" : key;
}

// ==================== Use & Control Example ===========================

// Center(
//     child: Image(
//     image: NriImage.from(Nri.appResource("assets/images/logo/novus_orbit.png")),
//     width: 125,
//     height: 125,
//     color: _logoColor.value,
// ))

class NriImage {
  static ImageProvider fromString(String nri,
          {double scale, String projectPath, ImageThumbnail thumbnail}) =>
      from(Nri.parse(nri), scale: scale, projectPath: projectPath);

  static ImageProvider from(Nri nri,
      {double scale, String projectPath, ImageThumbnail thumbnail}) {
    if (nri == null) {
      return null;
    }

    if (nri.queries.containsKey("scale")) {
      scale = nri.getQueryValue<double>("scale", double.parse);
    }
    if (nri.queries.containsKey(ImageThumbnail.queryName) &&
        thumbnail == null) {
      thumbnail =
          ImageThumbnail.tryParse(nri.queries[ImageThumbnail.queryName]);
    }

    if (nri.isAppResource) {
      return scale != null
          ? ExactAssetImage(nri.path, scale: scale)
          : AssetImage(nri.path);
    } else if (nri.isPackageResource) {
      var pNri = PackageNri.from(nri);

      return scale != null
          ? ExactAssetImage(pNri.path, scale: scale, package: pNri.package)
          : AssetImage(pNri.path, package: pNri.package);
    } else if (nri.isUserResource) {
      if (thumbnail != null) {
        final thumbnailFile = File(thumbnail.createNri(nri).path);
        if (thumbnailFile.existsSync()) {
          return FileImage(thumbnailFile, scale: scale ?? 1.0);
        }
      }
      return FileImage(File(nri.path), scale: scale ?? 1.0);
    } else if (nri.isNetworkResource) {
      return NetworkImage(nri.nriStringWithoutScheme, scale: scale ?? 1.0);
    } else if (nri.isProjectResource) {
      projectPath =
          projectPath ?? container<IProjectService>().current?.directoryPath;
      if (projectPath == null) {
        throw ArgumentError.notNull(projectPath);
      }
      final fullPath = projectPath + "/" + nri.path;
      if (thumbnail != null) {
        final thumbnailFile = File(thumbnail.createThumbnailPath(fullPath));
        if (thumbnailFile.existsSync()) {
          return FileImage(thumbnailFile, scale: scale ?? 1.0);
        }
      }
      return FileImage(File(fullPath), scale: scale ?? 1.0);
    } else
      return null;
  }
}
