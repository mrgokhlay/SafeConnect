import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../services/presence_service.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>(
      (ref) => ProfileController(),
    );

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController() : super(const AsyncData(null));

  // ================================
  // 🟢 GO ONLINE
  // ================================
  Future<void> goOnline() async {
    state = const AsyncLoading();

    try {
      await PresenceService.instance.initPresence();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // ================================
  // 🔴 GO OFFLINE
  // ================================
  Future<void> goOffline() async {
    state = const AsyncLoading();

    try {
      await PresenceService.instance.goOffline();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
