import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_loader.dart';
import 'models.dart';

final contentProvider = FutureProvider<ContentBundle>((ref) {
  return ContentLoader.load();
});
