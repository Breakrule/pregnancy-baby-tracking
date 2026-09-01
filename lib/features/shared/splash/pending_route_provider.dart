import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A go_router location captured before the app was ready (e.g. the app was
/// launched from a notification). Consumed and cleared right after bootstrap
/// completes, once the router is mounted.
final pendingRouteProvider = StateProvider<String?>((ref) => null);
