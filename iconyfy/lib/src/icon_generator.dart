// iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.
// This code is licensed under MIT license (see LICENSE file for details)
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:slugify/slugify.dart';
import 'package:source_gen/source_gen.dart';
import 'package:http/http.dart' as http;
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

String replaceDart(String text) {
  var dartNames = ["map", "default", "switch", "case"];
  for (var name in dartNames) {
    if (text.startsWith(name)) {
      text = "icon $text";
    }
  }
  return text;
}

extension StringCasingExtension on String {
  String get toCapitalized =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String get replaceDartNames => replaceDart(this);
  String get toClassName => slugify(
      replaceAll("-", " ").replaceAll("  ", " ").replaceDartNames.toTitleCase,
      delimiter: "",
      lowercase: false);
  String get toDartFile =>
      "${slugify(toTitleCase.replaceDartNames, delimiter: "_")}.icon.dart";
  String get toTitleCase => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized)
      .join(' ');
}

String generateIconEntry(MapEntry<String, dynamic> icon) {
  var widget = jsonEncode(icon.value);
  return '"${icon.key}":$widget';
}

class IconLibraryGenerator extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    var url = Uri.parse(
        "https://raw.githubusercontent.com/iconify/icon-sets/master/collections.json");
    var response = await http.get(url);
    final Map<String, dynamic> dataBody = jsonDecode(response.body);
    final iconList = dataBody.entries
        .map((e) => {
              "name": e.key,
              "class": e.key.toClassName,
              "file": e.key.toDartFile
            })
        .toList();

    final items =
        iconList.map((e) => "\"${e['name']}\":${e['class']}.get").join(",");
    final iconifylyClass = Class((b) => b
      ..name = "iconifyly"
      ..methods.add(Method((m1) => m1
        ..name = 'get'
        ..static = true
        ..returns = refer("Widget")
        ..requiredParameters.add(Parameter((p) => p
          ..name = "name"
          ..type = refer("String")))
        ..optionalParameters.addAll([
          Parameter((p) => p
            ..name = "height"
            ..named = true
            ..type = refer("num?")),
          Parameter((p) => p
            ..name = "width"
            ..named = true
            ..type = refer("num?")),
          Parameter((p) => p
            ..name = "rotate"
            ..named = true
            ..type = refer("num?")),
          Parameter((p) => p
            ..name = "color"
            ..named = true
            ..type = refer("Color?"))
        ])
        ..body = const Code("var items = iconifyly.asMap();"
            "var iconDataInfo = name.split('/');"
            "var package=iconDataInfo[0];"
            "var icon=iconDataInfo[1];"
            "return items[package]!(icon,height:height,width:width,rotate:rotate,color:color);")))
      ..methods.add(Method((m2) => m2
        ..name = 'asMap'
        ..static = true
        ..returns = refer("Map<String, Widget Function(String name,{"
            "num? height,"
            "num? width,"
            "num? rotate,"
            "Color? color,"
            "})>")
        ..body = Code("return {$items};"))));
    final dartfmt = DartFormatter();
    var libraryItem = Library((l) => l
      ..comments.addAll([
        "iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.",
        "This code is licensed under MIT license (see LICENSE file for details)"
      ])
      ..generatedByComment
      ..directives.add(Directive.import("package:flutter/widgets.dart"))
      ..directives.addAll(iconList
          .map((e) => Directive.import("package:iconifyly/icons/${e["file"]}")))
      ..body.add(iconifylyClass));
    for (var icf in iconList) {
      var resultData = await http.get(Uri.parse(
          "https://raw.githubusercontent.com/iconify/icon-sets/master/json/${icf["name"]}.json"));
      final Map<String, dynamic> dataBody = jsonDecode(resultData.body);
      var info = dataBody["info"];
      var icons = dataBody["icons"] as Map<String, dynamic>;
      var iconFile = File('lib/icons/${icf["file"]}');
      var iconClass = Class((c) => c
        ..name = icf["class"]
        ..fields.add(Field((f) => f
          ..name = "info"
          ..static = true
          ..assignment = Code(jsonEncode(info))
          ..type = refer("Map<String,dynamic>")))
        ..fields.add(Field((f) => f
          ..name = "names"
          ..static = true
          ..assignment = Code(
              "{${icons.entries.map((e) => generateIconEntry(e)).join(",")}}")
          ..type = refer("Map<String,Map<String,dynamic>>")))
        ..methods.add(Method((m) => m
          ..static = true
          ..optionalParameters.addAll([
            Parameter((p) => p
              ..name = "height"
              ..named = true
              ..type = refer("num?")),
            Parameter((p) => p
              ..name = "width"
              ..named = true
              ..type = refer("num?")),
            Parameter((p) => p
              ..name = "rotate"
              ..named = true
              ..type = refer("num?")),
            Parameter((p) => p
              ..name = "color"
              ..named = true
              ..type = refer("Color?"))
          ])
          ..requiredParameters.add(Parameter((p) => p
            ..name = "name"
            ..type = refer("String")))
          ..returns = refer("Widget")
          ..body = Code("var data =  ${icf["class"]}.names[name]!;"
              "var info = ${icf["class"]}.info;"
              'var h = height ?? (data["height"] ?? (info["height"] ?? "16"));'
              'var w = width ?? (data["width"] ?? (info["width"] ?? "16"));'
              'var t=data["top"] ?? (info["top"] ?? "0");'
              'var l=data["left"] ?? (info["left"] ?? "0");'
              'ColorFilter? cfilter =(color ?? ColorFilter.mode(color!, BlendMode.clear)) as ColorFilter?;'
              'return SvgPicture.string(\'<svg xmlns="http://www.w3.org/2000/svg" width="1em" viewBox="\$t \$l \$w \$h" height="1em" version="1.1">\${data["body"]}</svg>\', colorFilter:cfilter);'
              "")
          ..name = "get")));
      var iconFileLib = Library((l) => l
        ..comments.addAll([
          "${info["name"]} Copyright (c), ${info["author"]["name"]}${info["author"]["url"] != null ? "(${info["author"]["url"]})" : ""}. All rights reserved.",
          "Use of this icons source code is governed by a",
          "${info["license"]["title"]} license${info["license"]["url"] != null ? " that can be found in the ${info["license"]["url"]} url" : ""}.\n"
        ])
        ..comments.addAll([
          "",
          "",
          "iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.",
          "This code is licensed under MIT license (see LICENSE file for details)"
        ])
        ..generatedByComment
        ..directives.add(Directive.import("package:flutter/widgets.dart"))
        ..directives
            .add(Directive.import("package:flutter_svg/flutter_svg.dart"))
        ..body.add(iconClass));
      iconFile.writeAsString(
          dartfmt.format('${iconFileLib.accept(DartEmitter())}'));
    }
    return dartfmt.format('${libraryItem.accept(DartEmitter())}');
  }
}
