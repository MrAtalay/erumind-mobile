import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Correct answers needed in a single category to earn its crown. Overridable
/// in tests so they don't have to answer ten questions.
final crownThresholdProvider = Provider<int>((ref) => 10);
