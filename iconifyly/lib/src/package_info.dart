import 'package:json_annotation/json_annotation.dart';

part 'package_info.g.dart';

@JsonSerializable()
class PackageInfo {
  String prefix;
  Info info;
  int lastModified;
  int width;
  int height;
  Categories categories;

  PackageInfo({
    required this.prefix,
    required this.info,
    required this.lastModified,
    required this.width,
    required this.height,
    required this.categories,
  });
  factory PackageInfo.fromJson(Map<String, dynamic> json) =>
      _$PackageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PackageInfoToJson(this);
}

@JsonSerializable()
class Categories {
  List<String> actions;
  List<String> brand;
  List<String> enterprise;
  List<String> organization;
  List<String> person;
  List<String> planning;
  List<String> tools;

  Categories({
    required this.actions,
    required this.brand,
    required this.enterprise,
    required this.organization,
    required this.person,
    required this.planning,
    required this.tools,
  });
  factory Categories.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriesToJson(this);
}

@JsonSerializable()
class Info {
  String name;
  int total;
  String version;
  Author author;
  License license;
  List<String> samples;
  int height;
  int displayHeight;
  String category;

  Info({
    required this.name,
    required this.total,
    required this.version,
    required this.author,
    required this.license,
    required this.samples,
    required this.height,
    required this.displayHeight,
    required this.category,
  });
  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

  Map<String, dynamic> toJson() => _$InfoToJson(this);
}

@JsonSerializable()
class Author {
  String name;
  String url;

  Author({
    required this.name,
    required this.url,
  });
  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}

@JsonSerializable()
class License {
  String title;
  String spdx;
  String url;

  License({
    required this.title,
    required this.spdx,
    required this.url,
  });
  factory License.fromJson(Map<String, dynamic> json) =>
      _$LicenseFromJson(json);

  Map<String, dynamic> toJson() => _$LicenseToJson(this);
}
