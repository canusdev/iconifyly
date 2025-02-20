// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageInfo _$PackageInfoFromJson(Map<String, dynamic> json) => PackageInfo(
      prefix: json['prefix'] as String,
      info: Info.fromJson(json['info'] as Map<String, dynamic>),
      lastModified: (json['lastModified'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      categories:
          Categories.fromJson(json['categories'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PackageInfoToJson(PackageInfo instance) =>
    <String, dynamic>{
      'prefix': instance.prefix,
      'info': instance.info,
      'lastModified': instance.lastModified,
      'width': instance.width,
      'height': instance.height,
      'categories': instance.categories,
    };

Categories _$CategoriesFromJson(Map<String, dynamic> json) => Categories(
      actions:
          (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
      brand: (json['brand'] as List<dynamic>).map((e) => e as String).toList(),
      enterprise: (json['enterprise'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      organization: (json['organization'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      person:
          (json['person'] as List<dynamic>).map((e) => e as String).toList(),
      planning:
          (json['planning'] as List<dynamic>).map((e) => e as String).toList(),
      tools: (json['tools'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$CategoriesToJson(Categories instance) =>
    <String, dynamic>{
      'actions': instance.actions,
      'brand': instance.brand,
      'enterprise': instance.enterprise,
      'organization': instance.organization,
      'person': instance.person,
      'planning': instance.planning,
      'tools': instance.tools,
    };

Info _$InfoFromJson(Map<String, dynamic> json) => Info(
      name: json['name'] as String,
      total: (json['total'] as num).toInt(),
      version: json['version'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      license: License.fromJson(json['license'] as Map<String, dynamic>),
      samples:
          (json['samples'] as List<dynamic>).map((e) => e as String).toList(),
      height: (json['height'] as num).toInt(),
      displayHeight: (json['displayHeight'] as num).toInt(),
      category: json['category'] as String,
    );

Map<String, dynamic> _$InfoToJson(Info instance) => <String, dynamic>{
      'name': instance.name,
      'total': instance.total,
      'version': instance.version,
      'author': instance.author,
      'license': instance.license,
      'samples': instance.samples,
      'height': instance.height,
      'displayHeight': instance.displayHeight,
      'category': instance.category,
    };

Author _$AuthorFromJson(Map<String, dynamic> json) => Author(
      name: json['name'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$AuthorToJson(Author instance) => <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
    };

License _$LicenseFromJson(Map<String, dynamic> json) => License(
      title: json['title'] as String,
      spdx: json['spdx'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$LicenseToJson(License instance) => <String, dynamic>{
      'title': instance.title,
      'spdx': instance.spdx,
      'url': instance.url,
    };
