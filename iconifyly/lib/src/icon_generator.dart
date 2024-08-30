// Iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.
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
  String get toAsName => "r${toClassName.toLowerCase()}";
  String get toDartReflectFile =>
      "${slugify(toTitleCase.replaceDartNames, delimiter: "_")}.icon.reflectable.dart";
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
              "file": e.key.toDartFile,
              "reflect": e.key.toDartReflectFile,
              "rname": e.key.toAsName
            })
        .toList();

    final items =
        iconList.map((e) => "\"${e['name']}\":${e['class']}").join(",");
    final itemsReflect = iconList
        .map((e) => "\"${e['name']}\":${e['rname']}.initializeReflectable")
        .join(",");
    final iconyfyClass = Class((b) => b
      ..name = "Iconifyly"
      ..methods.add(Method((m1) => m1
        ..name = 'getIcon'
        ..static = true
        ..returns = refer("Widget")
        ..requiredParameters.add(Parameter((p) => p
          ..name = "name"
          ..type = refer("String")))
        ..optionalParameters.addAll([
          Parameter((p) => p
            ..name = "height"
            ..named = true
            ..type = refer("double?")),
          Parameter((p) => p
            ..name = "width"
            ..named = true
            ..type = refer("double?")),
          Parameter((p) => p
            ..name = "rotate"
            ..named = true
            ..type = refer("double?")),
          Parameter((p) => p
            ..name = "color"
            ..named = true
            ..type = refer("Color?"))
        ])
        ..body = const Code("""
try {
      var items = Iconifyly.asMap();
      var ref = Iconifyly.asRefMap();
      var iconDataInfo = name.split('/');
      var package = iconDataInfo[0];
      ref[package]!();
      var icon = iconDataInfo[1];
      ClassMirror pack = reflector.reflectType(items[package]!) as ClassMirror;

      Widget? item = pack.invoke('getIcon', [
        icon
      ], {
        Symbol("height"): height,
        Symbol("width"): width,
        Symbol("rotate"): rotate,
        Symbol("color"): color
      }) as Widget?;
      return item!;
    } catch (e) {
      return Center();
    }
            """)))
      ..methods.add(Method((m1) => m1
        ..name = 'getInfo'
        ..static = true
        ..returns = refer("Map<String,dynamic>")
        ..requiredParameters.add(Parameter((p) => p
          ..name = "name"
          ..type = refer("String")))
        ..body = const Code("var items = Iconifyly.asMap();"
            "var ref = Iconifyly.asRefMap();"
            "ref[name]!();"
            "ClassMirror pack = reflector.reflectType(items[name]!) as ClassMirror;"
            """
            Map<String,dynamic>? item = pack.invoke('info',[]) as Map<String,dynamic>?;
    return item!;
            """)))
      ..methods.add(Method((m2) => m2
        ..name = 'asRefMap'
        ..static = true
        ..returns = refer("Map<String, void Function()>")
        ..body = Code("return {$itemsReflect};")))
      ..methods.add(Method((m2) => m2
        ..name = 'asMap'
        ..static = true
        ..returns = refer("Map<String, Type>")
        ..body = Code("return {$items};"))));
    final dartfmt = DartFormatter();
    var libraryItem = Library((l) => l
      ..comments.addAll([
        "Iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.",
        "This code is licensed under MIT license (see LICENSE file for details)"
      ])
      ..generatedByComment
      ..directives.add(Directive.import("package:flutter/widgets.dart"))
      ..directives.add(Directive.import("package:iconifyly/reflected.dart"))
      ..directives
          .add(Directive.import("package:iconifyly/reflected.reflectable.dart"))
      ..directives.add(Directive.import("package:reflectable/reflectable.dart"))
      ..directives.addAll(iconList
          .map((e) => Directive.import("package:iconifyly/icons/${e["file"]}")))
      ..directives.addAll(iconList.map((e) => Directive.import(
          "package:iconifyly/icons/${e["reflect"]}",
          as: "${e["rname"]}")))
      ..body.addAll([iconyfyClass]));
    var total = iconList.length;
    var cur = 0;

    for (var icf in iconList) {
      cur++;
      log.log(log.level, "Building icon ($cur/$total): ${icf["name"]} ");
      var resultData = await http.get(Uri.parse(
          "https://raw.githubusercontent.com/iconify/icon-sets/master/json/${icf["name"]}.json"));
      final Map<String, dynamic> dataBody = jsonDecode(resultData.body);
      var info = dataBody["info"];
      var categories = dataBody["categories"];
      var alias = dataBody["alias"];
      var icons = dataBody["icons"] as Map<String, dynamic>;
      var iconFile = File('lib/icons/${icf["file"]}');
      var iconClass = Class((c) => c
        ..annotations.add(CodeExpression(Code("reflector")))
        ..extend = refer("IconifylyInterface")
        ..name = icf["class"]
        ..methods.add(Method(
          (m) => m
            ..name = "info"
            ..static = true
            ..returns = refer("Map<String,dynamic>")
            ..body = Code("return ${jsonEncode(info)};"),
        ))
        ..methods.add(Method(
          (m) => m
            ..name = "categories"
            ..static = true
            ..returns = refer("Map<String,dynamic>")
            ..body = Code("return ${jsonEncode(categories ?? {})};"),
        ))
        ..methods.add(Method(
          (m) => m
            ..name = "aliases"
            ..static = true
            ..returns = refer("Map<String,dynamic>")
            ..body = Code("return ${jsonEncode(alias ?? {})};"),
        ))
        ..methods.add(Method(
          (m) => m
            ..name = "names"
            ..static = true
            ..returns = refer("Map<String,Map<String,dynamic>>")
            ..body = Code(
                "return {${icons.entries.map((e) => generateIconEntry(e)).join(",")}};"),
        ))
        ..methods.add(Method((m) => m
          ..static = true
          ..optionalParameters.addAll([
            Parameter((p) => p
              ..name = "height"
              ..named = true
              ..type = refer("double?")),
            Parameter((p) => p
              ..name = "width"
              ..named = true
              ..type = refer("double?")),
            Parameter((p) => p
              ..name = "rotate"
              ..named = true
              ..type = refer("double?")),
            Parameter((p) => p
              ..name = "color"
              ..named = true
              ..type = refer("Color?"))
          ])
          ..requiredParameters.add(Parameter((p) => p
            ..name = "name"
            ..type = refer("String")))
          ..returns = refer("Widget")
          ..body = Code("var data =  ${icf["class"]}.names()[name]!;"
              "var info = ${icf["class"]}.info();"
              """

    var h = (data["height"] ?? data["width"]) ??
        (info["height"] ?? (info["width"] ?? "16"));
    var w = (data["width"] ?? data["height"]) ??
        ((info["width"] ?? info["height"]) ?? 16);
    var t = data["top"] ?? (info["top"] ?? "0");
    var l = data["left"] ?? (info["left"] ?? "0");
    ColorFilter? cfilter;
    if (color != null) {
      cfilter = ColorFilter.mode(color!, BlendMode.srcIn);
    }
    return SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" height="1em" width="1em" viewBox="\$t \$l \$w \$h" version="1.1">\${data["body"]}</svg>',
        colorFilter: cfilter,
        width: width,
        height: height); """)
          ..name = "getIcon")));

      var iconFileLib = Library((l) => l
        ..comments.addAll([
          "${info["name"]} Copyright (c), ${info["author"]["name"]}${info["author"]["url"] != null ? "(${info["author"]["url"]})" : ""}. All rights reserved.",
          "Use of this icons source code is governed by a",
          "${info["license"]["title"]} license${info["license"]["url"] != null ? " that can be found in the ${info["license"]["url"]} url" : ""}.\n"
        ])
        ..comments.addAll([
          "",
          "",
          "Iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.",
          "This code is licensed under MIT license (see LICENSE file for details)"
        ])
        ..generatedByComment
        ..directives.add(Directive.import("package:flutter/widgets.dart"))
        ..directives.add(Directive.import("package:iconifyly/reflected.dart"))
        ..directives
            .add(Directive.import("package:flutter_svg/flutter_svg.dart"))
        ..directives.add(Directive.import(
            "package:iconifyly/icons/${icf["name"]}.icon.reflectable.dart"))
        ..body.add(iconClass)
        ..body.add(Code("""
void main() {
  initializeReflectable();
}
""")));
      iconFile.writeAsString(
          dartfmt.format('${iconFileLib.accept(DartEmitter())}'));
    }
    return dartfmt.format('${libraryItem.accept(DartEmitter())}');
  }
}
