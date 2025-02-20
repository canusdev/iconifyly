library iconify_viewer;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:iconifyly/iconifyly.dart';
import 'package:string_similarity/string_similarity.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

extension StringCasingExtension on String {
  String get toCapitalized =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String get toTitleCase => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized)
      .join(' ');
}

class Controller extends GetxController {
  var iconSets = Iconifyly.asMap();
  List<Map<String, dynamic>> infoList = List.empty(growable: true);
  var baseLoading = true.obs;
  var loading = false.obs;
  var loadingMore = false.obs;

  var selectedItemCategory = "".obs;
  var selectedIconset = "".obs;
  var loadingTotal = 0.obs;
  var waitingMore = false.obs;

  RxMap<String, List<String>> iconSetsiconsNames = RxMap({});

  ScrollController _scrollController = ScrollController();
  ScrollController _gridScrollController = ScrollController();
  RxMap<String, String?> cachedIcons = RxMap({});

  RxMap<String, String?> icons = RxMap({});
  RxMap<String, List<String>> currentCategories = RxMap({});
  RxMap<String, Map<String, List<String>>> iconsSetsCategories = RxMap({});

  Future<void> loadInitial() async {
    for (var item in iconSets.entries) {
      var info = Iconifyly.getInfo(item.key);
      info["key"] = item.key;
      infoList.add(info);
      iconSetsiconsNames.addAll({item.key: Iconifyly.iconSetItems(item.key)});

      Map<String, List<String>> iconSetCat = {};
      for (var e in Iconifyly.getCategories(item.key).entries) {
        iconSetCat.addAll({e.key: e.value as List<String>});
      }

      if (iconSetCat.isNotEmpty) {
        iconsSetsCategories.addAll({item.key: iconSetCat});
      }
    }
  }

  bool isolatedMore() {
    List<String> iconList = [];
    waitingMore(false);
    if (loadingTotal > cachedIcons.length) {
      loadingMore(true);
      if (selectedItemCategory.value.isEmpty) {
        if (iconSetsiconsNames.containsKey(selectedIconset.value)) {
          iconList.addAll(iconSetsiconsNames[selectedIconset.value]!
              .getRange(cachedIcons.length, cachedIcons.length + 50));
          waitingMore(true);
        }
      } else {
        debugPrint("load more categories");
        if (currentCategories.containsKey(selectedItemCategory.value)) {
          iconList.addAll(currentCategories[selectedItemCategory.value]!
              .getRange(icons.length, icons.length + 50));
          waitingMore(true);
        }
      }
      var result = {for (var itm in iconList) itm: itm};
      icons.addAll(result);

      loadingMore(false);
    }

    return true;
  }

  Future<void> loadMore() async {
    debugPrint(
        "${_gridScrollController.offset} ${_gridScrollController.position.maxScrollExtent * 0.8} ${_gridScrollController.position.maxScrollExtent}");
    if (_gridScrollController.position.maxScrollExtent * 0.8 >
        _gridScrollController.offset) {
      return;
    }
    if (loadingMore.isTrue) {
      return;
    }

    isolatedMore();
  }

  Future<void> searchItems(String keyword) async {
    Map<String, List<String>> matchList = {};
    Map<String, List<String>> matchListSecond = {};
    loading(true);
    icons({});
    var results = await compute((iconSetsicons) {
      Map<String, List<String>> matchList = {};
      Map<String, List<String>> matchListSecond = {};

      for (var item in iconSetsicons.entries) {
        List<String> founded = [];
        List<String> foundedSecond = [];
        var matches = StringSimilarity.findBestMatch(
            keyword, item.value.map((e) => e.replaceAll("-", " ")).toList());
        for (var m in matches.ratings) {
          if (m.rating! > 0.6) {
            founded.add(m.target!);
          }
          if (m.rating! > 0.5 && m.rating! < 0.6) {
            foundedSecond.add(m.target!);
          }
        }
        matchList[item.key] = founded;
        matchListSecond[item.key] = foundedSecond;
      }
      return [matchList, matchListSecond];
    }, iconSetsiconsNames);
    matchList = results[0];
    matchListSecond = results[0];
    icons({
      for (var ex in matchList.entries)
        for (var z in ex.value) z: "${ex.key}/$z"
    });
    loading(false);
    selectedIconset("");
  }

  @override
  void onInit() {
    loadInitial();
    _gridScrollController.addListener(loadMore);
    super.onInit();
  }

  Future<void> onSelectedItem(String name) async {
    waitingMore(false);
    selectedItemCategory("");
    debugPrint("item selected $name");
    List<String> iconList = [];
    if (iconSetsiconsNames.containsKey(name)) {
      loadingTotal(iconSetsiconsNames[name]!.length);
      if (loadingTotal.value > 100) {
        iconList.addAll(iconSetsiconsNames[name]!.getRange(0, 100));
        waitingMore(true);
      }
    }
    currentCategories(iconsSetsCategories[name]);

    var result = await compute((e) {
      return {for (var itm in e) itm: "$name/$itm"};
    }, iconList);

    loading(false);
    icons(result);
    debugPrint("item selected $name ${icons.length}");
    selectedIconset(name);
    refresh();
  }

  void onSelectedItemCategory(String name) async {
    waitingMore(false);
    _gridScrollController.position.moveTo(0);
    if (selectedItemCategory.value == name) {
      selectedItemCategory("");
      onSelectedItem(selectedIconset.value);
      return;
    }
    selectedItemCategory(name);
    var iconList = currentCategories[name]!;
    if (iconList.length > 100) {
      waitingMore(true);
      iconList = iconList.getRange(0, 100).toList();
    }
    var result = await compute((e) {
      return {for (var itm in e) itm: itm};
    }, iconList);
    icons(result);
    loading(false);
  }
}

class IconifyViewer extends StatelessWidget {
  final controller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Obx(() => Column(
              children: [
                SizedBox(
                  height: 45,
                  child: TextField(
                    onChanged: (value) {
                      if (value.length > 3) {
                        controller.searchItems(value);
                      }
                    },
                    onSubmitted: (value) {},
                    decoration: InputDecoration(
                        prefixIcon: Iconifyly.icon("material-symbols/search"),
                        hintText: "Search"),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 400,
                        child: Expanded(
                            child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: controller.infoList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () {
                                controller.loading(true);
                                controller.onSelectedItem(controller.infoList
                                    .elementAt(index)["key"]);
                              },
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(controller.infoList
                                      .elementAt(index)["name"]),
                                  Row(children: [
                                    Text(
                                      "${controller.infoList.elementAt(index)["total"]}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black45),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Row(
                                        children: [
                                          Iconifyly.icon(
                                              "fluent/arrow-autofit-height-in-24-regular",
                                              width: 12,
                                              height: 12),
                                          Text(
                                              "${controller.infoList.elementAt(index)["height"] ?? "-"}",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45))
                                        ],
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (controller.infoList
                                              .elementAt(index)["samples"] !=
                                          null)
                                        ...(controller.infoList
                                                    .elementAt(index)["samples"]
                                                as List<String>)
                                            .map((e) =>
                                                Iconifyly.icon(
                                                    "${controller.infoList.elementAt(index)["key"]}/$e",
                                                    height: 16,
                                                    width: 16) ??
                                                const Text(" X "))
                                    ],
                                  ),
                                  Text(controller.infoList
                                      .elementAt(index)["license"]["title"]),
                                ],
                              ),
                            );
                          },
                        )),
                      ),
                      Expanded(
                          child: Column(
                        children: [
                          SizedBox(
                            height: 60,
                            child: Scrollbar(
                                thumbVisibility: true,
                                trackVisibility: true,
                                controller: controller._scrollController,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  controller: controller._scrollController,
                                  itemCount:
                                      controller.currentCategories.value.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: TextButton.icon(
                                        style: ButtonStyle(
                                            iconSize:
                                                const WidgetStatePropertyAll(
                                                    12),
                                            elevation:
                                                const WidgetStatePropertyAll(1),
                                            visualDensity: const VisualDensity(
                                                vertical: 0),
                                            padding:
                                                const WidgetStatePropertyAll(
                                                    EdgeInsets.only(
                                                        bottom: 1, top: 1)),
                                            maximumSize:
                                                const WidgetStatePropertyAll(
                                                    Size(250, 40)),
                                            backgroundColor:
                                                WidgetStatePropertyAll(controller
                                                            .currentCategories
                                                            .value
                                                            .entries
                                                            .elementAt(index)
                                                            .key ==
                                                        controller
                                                            .selectedItemCategory
                                                            .value
                                                    ? Colors.grey.shade300
                                                    : null)),
                                        icon: Iconifyly.icon(
                                            // ignore: invalid_use_of_protected_member
                                            "${controller.selectedIconset}/${controller.currentCategories.value.entries.elementAt(index).value[0]}"),
                                        label: Text(controller
                                            .currentCategories.value.entries
                                            .elementAt(index)
                                            .key),
                                        onPressed: () async {
                                          controller.onSelectedItemCategory(
                                              controller.currentCategories.value
                                                  .entries
                                                  .elementAt(index)
                                                  .key);
                                        },
                                      ),
                                    );
                                  },
                                )),
                          ),
                          Expanded(
                              child: controller.loading.isTrue
                                  ? const SizedBox(
                                      width: 200,
                                      height: 40,
                                      child: Column(
                                        children: [
                                          Text("Loading icons"),
                                          CircularProgressIndicator(
                                            semanticsLabel: "Loading...",
                                          )
                                        ],
                                      ),
                                    )
                                  : (controller.icons.entries.length == 0
                                      ? Text(
                                          "Please select a iconset or search a keyword")
                                      : GridView.builder(
                                          shrinkWrap: true,
                                          controller:
                                              controller._gridScrollController,
                                          itemCount:
                                              controller.icons.entries.length +
                                                  1,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 5,
                                                  mainAxisSpacing: 4,
                                                  crossAxisSpacing: 4),
                                          itemBuilder: (context, index) {
                                            if (index >
                                                controller
                                                        .icons.entries.length -
                                                    1) {
                                              if (controller
                                                  .waitingMore.isFalse) {
                                                return Center();
                                              }
                                              return const CircularProgressIndicator(
                                                semanticsLabel: "Loading...",
                                              );
                                            }
                                            return Card(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                    child: Text(
                                                      "${(controller.icons.entries.elementAt(index).value!.replaceAll("-", " ") as String).toString().toTitleCase} ${controller.icons.entries.elementAt(index).value}",
                                                      style: TextStyle(
                                                          overflow: TextOverflow
                                                              .fade),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Iconifyly.icon(
                                                        controller.icons.entries
                                                            .elementAt(index)
                                                            .value!,
                                                        color: Colors.black,
                                                        width: 48,
                                                        height: 48),
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                        )))
                        ],
                      ))
                    ],
                  ),
                )
              ],
            )));
  }
}
