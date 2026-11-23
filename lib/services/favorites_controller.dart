import 'package:flutter/foundation.dart';

import 'favorites_storage.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._storage);

  final FavoritesStorage _storage;
  List<String> _mealIds = const [];
  bool _loading = false;
  bool _loadFailed = false;
  bool _saving = false;
  bool _disposed = false;

  List<String> get mealIds => _mealIds;
  bool get loading => _loading;
  bool get loadFailed => _loadFailed;
  bool get canEdit => !_loading && !_loadFailed && !_saving;

  Future<void> load() async {
    if (_loading || _saving) return;
    _loading = true;
    _loadFailed = false;
    notifyListeners();

    try {
      _mealIds = List.unmodifiable((await _storage.load()).toSet());
    } catch (_) {
      _loadFailed = true;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> toggle(String mealId) async {
    if (!canEdit) return false;
    final previous = _mealIds;
    final next = previous.toSet();
    if (!next.remove(mealId)) next.add(mealId);
    _mealIds = List.unmodifiable(next);
    _saving = true;
    notifyListeners();

    try {
      await _storage.save(_mealIds);
      return true;
    } catch (_) {
      _mealIds = previous;
      return false;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
