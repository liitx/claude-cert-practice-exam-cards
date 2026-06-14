import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/repositories/migration/legacy_migrator_stub.dart'
    if (dart.library.js_interop) 'package:drill_deck/repositories/migration/legacy_migrator_web.dart'
    as impl;

/// Reads the legacy `drill-decks-v2` key from the browser's localStorage
/// (where the static-site version of the app stored its state) and translates
/// it into an [AppStateSnapshot]. Returns null if nothing is present or the
/// data is unrecoverable.
abstract class LegacyMigrator {
  /// Constructs the platform-appropriate implementation. On the web that's
  /// the `package:web` backed reader; on other platforms it's a no-op.
  factory LegacyMigrator() = impl.LegacyMigratorImpl;

  /// Returns a snapshot translated from the legacy storage, or null when
  /// nothing was found / the payload was unrecoverably malformed.
  AppStateSnapshot? migrate();

  /// Clears the legacy key after a successful second launch (rollback window).
  void clearLegacy();
}
