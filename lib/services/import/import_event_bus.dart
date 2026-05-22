import 'package:flutter/foundation.dart';

/// Notifies any listening view models that imported records have been
/// written to storage and they should reload.
///
/// The Purchase and Sell list views are kept-alive across tab switches and
/// only call their load function in initState — without this signal, freshly
/// imported rows wouldn't appear until the user fully restarted the app.
enum ImportedDataKind { purchase, invoice }

class ImportEventBus extends ChangeNotifier {
  ImportEventBus._();
  static final ImportEventBus instance = ImportEventBus._();

  ImportedDataKind? _lastKind;
  ImportedDataKind? get lastKind => _lastKind;

  void notifyImported(ImportedDataKind kind) {
    _lastKind = kind;
    notifyListeners();
  }
}
