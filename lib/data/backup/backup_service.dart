import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../db/app_database.dart';

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exports and restores the whole database as an AES-256-CBC encrypted
/// JSON envelope. Everything stays on-device; the file is written through
/// the platform file picker.
///
/// Envelope format: UTF-8 JSON `{app, schemaVersion, exportedAt, salt, iv,
/// checksum, payload}` where `payload` is the serialized tables, encrypted
/// with key = SHA-256(passphrase:salt); `checksum` is SHA-256 of the
/// plaintext payload and verified after decryption.
class BackupService {
  BackupService({this.schemaVersionOverride});

  /// Test seam: force a fake schema version into the envelope.
  final int? schemaVersionOverride;

  Future<Uint8List> export(AppDatabase db, {required String passphrase}) async {
    final payload = await _serialize(db);
    final payloadString = jsonEncode(payload);
    final checksum = sha256.convert(utf8.encode(payloadString)).toString();

    final random = Random.secure();
    final saltBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final ivBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final salt = base64Encode(saltBytes);
    final iv = base64Encode(ivBytes);

    final cipher = _cipherFor(passphrase, salt);
    final encrypted = cipher.encrypt(payloadString, iv: enc.IV(ivBytes));

    final envelope = jsonEncode({
      'app': 'nurture',
      'schemaVersion': schemaVersionOverride ?? db.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'salt': salt,
      'iv': iv,
      'checksum': checksum,
      'payload': encrypted.base64,
    });
    return Uint8List.fromList(utf8.encode(envelope));
  }

  Future<void> import(
    AppDatabase db,
    List<int> bytes, {
    required String passphrase,
  }) async {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('Not a valid Nurture backup file.');
    }
    if (envelope['app'] != 'nurture') {
      throw BackupException('Not a valid Nurture backup file.');
    }
    final version = envelope['schemaVersion'];
    if (version is! int || version > db.schemaVersion) {
      throw BackupException(
        'Backup is from a newer app version ($version). '
        'Update the app first.',
      );
    }

    final salt = envelope['salt'] as String;
    final iv = envelope['iv'] as String;
    final cipher = _cipherFor(passphrase, salt);

    String payloadString;
    try {
      payloadString = cipher.decrypt64(
        envelope['payload'] as String,
        iv: enc.IV(base64Decode(iv)),
      );
    } catch (_) {
      throw BackupException('Could not decrypt. Wrong passphrase?');
    }

    final checksum = sha256.convert(utf8.encode(payloadString)).toString();
    if (checksum != envelope['checksum']) {
      throw BackupException('Backup file is corrupted.');
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('Backup file is corrupted.');
    }
    await _restore(db, payload);
  }

  enc.Encrypter _cipherFor(String passphrase, String salt) {
    final key = Uint8List.fromList(
      sha256.convert(utf8.encode('$passphrase:$salt')).bytes,
    );
    return enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
  }

  Future<Map<String, dynamic>> _serialize(AppDatabase db) async {
    return {
      'pregnancies': await _rows(db.select(db.pregnancies)),
      'settings': await _rows(db.select(db.settingsRows)),
      'weight_entries': await _rows(db.select(db.weightEntries)),
      'symptoms': await _rows(db.select(db.symptoms)),
      'medications': await _rows(db.select(db.medications)),
      'med_logs': await _rows(db.select(db.medLogs)),
      'appointments': await _rows(db.select(db.appointments)),
    };
  }

  /// Serializes rows to JSON-safe Dart-level values: DateTime becomes an
  /// ISO-8601 UTC string, blobs become base64. Column names are the SQL
  /// names, so values round-trip via [RawValuesInsertable] without touching
  /// autoincrement counters or foreign keys.
  Future<List<Map<String, Object?>>> _rows(
    SimpleSelectStatement<HasResultSet, dynamic> query,
  ) async {
    final results = await query.get();
    return [
      for (final row in results)
        {
          for (final entry in (row as Insertable).toColumns(false).entries)
            entry.key: _encodeValue((entry.value as Variable).value),
        },
    ];
  }

  Object? _encodeValue(Object? value) => switch (value) {
    DateTime dt => dt.toUtc().toIso8601String(),
    Uint8List blob => base64Encode(blob),
    _ => value,
  };

  Future<void> _restore(AppDatabase db, Map<String, dynamic> payload) async {
    await db.transaction(() async {
      // Children first so foreign keys never dangle mid-restore.
      await _clearTable(db, db.medLogs);
      await _clearTable(db, db.medications);
      await _clearTable(db, db.symptoms);
      await _clearTable(db, db.weightEntries);
      await _clearTable(db, db.appointments);
      await _clearTable(db, db.pregnancies);
      await _clearTable(db, db.settingsRows);

      await _insertAll(
        db,
        db.pregnancies,
        payload['pregnancies'] as List<dynamic>?,
      );
      await _insertAll(
        db,
        db.settingsRows,
        payload['settings'] as List<dynamic>?,
      );
      await _insertAll(
        db,
        db.weightEntries,
        payload['weight_entries'] as List<dynamic>?,
      );
      await _insertAll(db, db.symptoms, payload['symptoms'] as List<dynamic>?);
      await _insertAll(
        db,
        db.medications,
        payload['medications'] as List<dynamic>?,
      );
      await _insertAll(db, db.medLogs, payload['med_logs'] as List<dynamic>?);
      await _insertAll(
        db,
        db.appointments,
        payload['appointments'] as List<dynamic>?,
      );
    });
  }

  Future<void> _clearTable<T extends Table, D>(
    AppDatabase db,
    TableInfo<T, D> table,
  ) {
    return db.delete(table).go();
  }

  Future<void> _insertAll<T extends Table, D>(
    AppDatabase db,
    TableInfo<T, D> table,
    List<dynamic>? rows,
  ) async {
    if (rows == null) return;
    final columnsByName = {for (final c in table.$columns) c.name: c};
    for (final raw in rows.cast<Map<String, dynamic>>()) {
      final values = <String, Expression<Object>>{
        for (final entry in raw.entries)
          entry.key: _decodeValue(columnsByName[entry.key], entry.value),
      };
      await db.into(table).insert(RawValuesInsertable(values));
    }
  }

  /// Rebuilds a typed [Variable] from a JSON-decoded value using the
  /// column's declared SQL type, so drift applies the right binding.
  Expression<Object> _decodeValue(GeneratedColumn? column, Object? value) {
    if (value == null || column == null) return Variable<Object>(value);
    switch (column.type) {
      case DriftSqlType.dateTime:
        return Variable<DateTime>(DateTime.parse(value as String));
      case DriftSqlType.bool:
        return Variable<bool>(value as bool);
      case DriftSqlType.int:
        return Variable<int>((value as num).toInt());
      case DriftSqlType.bigInt:
        return Variable<BigInt>(BigInt.parse(value.toString()));
      case DriftSqlType.double:
        return Variable<double>((value as num).toDouble());
      case DriftSqlType.string:
        return Variable<String>(value as String);
      case DriftSqlType.blob:
        return Variable<Uint8List>(base64Decode(value as String));
      default:
        throw BackupException(
          'Backup contains an unsupported column type for "${column.name}".',
        );
    }
  }
}
