import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope is the root that stores all Riverpod provider state.
  runApp(const ProviderScope(child: EruMindApp()));
}
