// Iconifyly Dart Copyright (c) 2024, Mustafa US. All rights reserved.
// This code is licensed under MIT license (see LICENSE file for details)
library Iconifyly;

import 'package:build/build.dart';
import 'package:iconifyly/src/icon_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder iconLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      IconLibraryGenerator(),
      generatedExtension: '.icon.dart',
      additionalOutputExtensions: ["lib/icons/*.dart"],
    );
