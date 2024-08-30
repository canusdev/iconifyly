library iconify_viewer;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:iconifyly/iconifyly.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

class IconifyViewer extends StatefulWidget {
  const IconifyViewer({super.key});

  @override
  _IconifyViewer createState() => _IconifyViewer();
}

class _IconifyViewer extends State<IconifyViewer> {
  var items = Iconifyly.asMap();
  List<Map<String, dynamic>> infoList = List.empty(growable: true);
  List<String> categories = List.empty(growable: true);
  String? selectedIconPack;
  List<Widget?>? icons;
  List<String> foundedPacks = List.empty(growable: true);
  List<String> foundedCategories = List.empty(growable: true);

  void onSelectedItem(String name) {
    icons = Iconifyly.getIconSetItems(name)
        .map((e) => Iconifyly.getIcon("$name/$e"))
        .toList();
    selectedIconPack = name;
    setState(() {});
  }

  @override
  void initState() {
    for (var item in items.entries) {
      var info = Iconifyly.getInfo(item.key);
      info["key"] = item.key;
      infoList.add(info);
      categories.add(info["category"] ?? "Other");
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Row(
      children: [
        SizedBox(
          width: 400,
          child: Expanded(
              child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: infoList.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  onSelectedItem(infoList.elementAt(index)["key"]);
                },
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(infoList.elementAt(index)["name"]),
                    Row(children: [
                      Text(
                        "${infoList.elementAt(index)["total"]}",
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      SizedBox(
                        width: 50,
                        child: Row(
                          children: [
                            Iconifyly.getIcon(
                                "fluent/arrow-autofit-height-in-24-regular",
                                width: 12,
                                height: 12),
                            Text(
                                "${infoList.elementAt(index)["height"] ?? "-"}",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black45))
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (infoList.elementAt(index)["samples"] != null)
                          ...(infoList.elementAt(index)["samples"]
                                  as List<String>)
                              .map((e) =>
                                  Iconifyly.getIcon(
                                      "${infoList.elementAt(index)["key"]}/$e",
                                      height: 16,
                                      width: 16) ??
                                  Text(" X "))
                      ],
                    ),
                    Text(infoList.elementAt(index)["license"]["title"]),
                  ],
                ),
              );
            },
          )),
        ),
        Expanded(
            child: GridView.builder(
          itemCount: icons?.length ?? 0,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
          itemBuilder: (context, index) {
            return SizedBox(
              child: icons![index],
              width: 48,
              height: 48,
            );
          },
        ))
      ],
    ));
  }
}
