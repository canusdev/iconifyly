import 'package:flutter/widgets.dart';
import 'package:iconifyly/reflected.reflectable.dart';
import 'package:reflectable/reflectable.dart';

@reflector
abstract class IconifylyInterface {
  static Map<String, dynamic> info() {
    return {};
  }

  static Map<String, dynamic> categories() {
    return {};
  }

  static Map<String, dynamic> aliases() {
    return {};
  }

  static Map<String, Map<String, dynamic>> names() {
    return {};
  }

  static Widget(
    String name, {
    num? height,
    num? width,
    num? rotate,
    Color? color,
  }) {
    return Center();
  }
}

class Reflector extends Reflectable {
  const Reflector()
      : super(invokingCapability, typingCapability, reflectedTypeCapability,
            staticInvokeCapability); // Request the capability to invoke methods.
}

const reflector = Reflector();

void main() {
  initializeReflectable();
}
