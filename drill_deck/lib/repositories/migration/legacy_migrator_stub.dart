import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/repositories/migration/legacy_migrator.dart';

/// No-op migrator used on non-web platforms (and as the default in tests
/// unless overridden). The actual web implementation lives in
/// `legacy_migrator_web.dart`.
class LegacyMigratorImpl implements LegacyMigrator {
  @override
  AppStateSnapshot? migrate() => null;

  @override
  void clearLegacy() {}
}
