import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pet_state.dart';

/// Persists the single [PetState] as one JSON blob.
///
/// One key, one schema version: there is exactly one pet, and a partial write
/// of several keys is how a pet ends up half reset. A corrupt or unreadable
/// blob yields null (→ a fresh piglet) rather than a crash loop.
class PetStore {
  PetStore({this.key = 'pet_v1'});

  final String key;

  Future<PetState?> load(DateTime now) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      return PetState.fromJson(j, now);
    } catch (e) {
      debugPrint('pet load failed, starting fresh: $e');
      return null;
    }
  }

  Future<void> save(PetState s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, jsonEncode(s.toJson()));
    } catch (e) {
      debugPrint('pet save failed: $e');
    }
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(key);
  }
}
