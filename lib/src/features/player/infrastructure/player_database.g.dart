// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_database.dart';

// ignore_for_file: type=lint
class $ReadingPositionsTable extends ReadingPositions
    with TableInfo<$ReadingPositionsTable, StoredPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversionIdMeta = const VerificationMeta(
    'conversionId',
  );
  @override
  late final GeneratedColumn<String> conversionId = GeneratedColumn<String>(
    'conversion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIndexMeta = const VerificationMeta(
    'wordIndex',
  );
  @override
  late final GeneratedColumn<int> wordIndex = GeneratedColumn<int>(
    'word_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioMsMeta = const VerificationMeta(
    'audioMs',
  );
  @override
  late final GeneratedColumn<int> audioMs = GeneratedColumn<int>(
    'audio_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    conversionId,
    wordIndex,
    audioMs,
    recordedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversion_id')) {
      context.handle(
        _conversionIdMeta,
        conversionId.isAcceptableOrUnknown(
          data['conversion_id']!,
          _conversionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversionIdMeta);
    }
    if (data.containsKey('word_index')) {
      context.handle(
        _wordIndexMeta,
        wordIndex.isAcceptableOrUnknown(data['word_index']!, _wordIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIndexMeta);
    }
    if (data.containsKey('audio_ms')) {
      context.handle(
        _audioMsMeta,
        audioMs.isAcceptableOrUnknown(data['audio_ms']!, _audioMsMeta),
      );
    } else if (isInserting) {
      context.missing(_audioMsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversionId};
  @override
  StoredPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredPosition(
      conversionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversion_id'],
      )!,
      wordIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_index'],
      )!,
      audioMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}audio_ms'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $ReadingPositionsTable createAlias(String alias) {
    return $ReadingPositionsTable(attachedDatabase, alias);
  }
}

class StoredPosition extends DataClass implements Insertable<StoredPosition> {
  final String conversionId;
  final int wordIndex;
  final int audioMs;
  final DateTime recordedAt;

  /// Pas encore reçue par le serveur (ADR-0011).
  final bool pending;
  const StoredPosition({
    required this.conversionId,
    required this.wordIndex,
    required this.audioMs,
    required this.recordedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversion_id'] = Variable<String>(conversionId);
    map['word_index'] = Variable<int>(wordIndex);
    map['audio_ms'] = Variable<int>(audioMs);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  ReadingPositionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingPositionsCompanion(
      conversionId: Value(conversionId),
      wordIndex: Value(wordIndex),
      audioMs: Value(audioMs),
      recordedAt: Value(recordedAt),
      pending: Value(pending),
    );
  }

  factory StoredPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredPosition(
      conversionId: serializer.fromJson<String>(json['conversionId']),
      wordIndex: serializer.fromJson<int>(json['wordIndex']),
      audioMs: serializer.fromJson<int>(json['audioMs']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversionId': serializer.toJson<String>(conversionId),
      'wordIndex': serializer.toJson<int>(wordIndex),
      'audioMs': serializer.toJson<int>(audioMs),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  StoredPosition copyWith({
    String? conversionId,
    int? wordIndex,
    int? audioMs,
    DateTime? recordedAt,
    bool? pending,
  }) => StoredPosition(
    conversionId: conversionId ?? this.conversionId,
    wordIndex: wordIndex ?? this.wordIndex,
    audioMs: audioMs ?? this.audioMs,
    recordedAt: recordedAt ?? this.recordedAt,
    pending: pending ?? this.pending,
  );
  StoredPosition copyWithCompanion(ReadingPositionsCompanion data) {
    return StoredPosition(
      conversionId: data.conversionId.present
          ? data.conversionId.value
          : this.conversionId,
      wordIndex: data.wordIndex.present ? data.wordIndex.value : this.wordIndex,
      audioMs: data.audioMs.present ? data.audioMs.value : this.audioMs,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPosition(')
          ..write('conversionId: $conversionId, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('audioMs: $audioMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(conversionId, wordIndex, audioMs, recordedAt, pending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPosition &&
          other.conversionId == this.conversionId &&
          other.wordIndex == this.wordIndex &&
          other.audioMs == this.audioMs &&
          other.recordedAt == this.recordedAt &&
          other.pending == this.pending);
}

class ReadingPositionsCompanion extends UpdateCompanion<StoredPosition> {
  final Value<String> conversionId;
  final Value<int> wordIndex;
  final Value<int> audioMs;
  final Value<DateTime> recordedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const ReadingPositionsCompanion({
    this.conversionId = const Value.absent(),
    this.wordIndex = const Value.absent(),
    this.audioMs = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPositionsCompanion.insert({
    required String conversionId,
    required int wordIndex,
    required int audioMs,
    required DateTime recordedAt,
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversionId = Value(conversionId),
       wordIndex = Value(wordIndex),
       audioMs = Value(audioMs),
       recordedAt = Value(recordedAt);
  static Insertable<StoredPosition> custom({
    Expression<String>? conversionId,
    Expression<int>? wordIndex,
    Expression<int>? audioMs,
    Expression<DateTime>? recordedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversionId != null) 'conversion_id': conversionId,
      if (wordIndex != null) 'word_index': wordIndex,
      if (audioMs != null) 'audio_ms': audioMs,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPositionsCompanion copyWith({
    Value<String>? conversionId,
    Value<int>? wordIndex,
    Value<int>? audioMs,
    Value<DateTime>? recordedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return ReadingPositionsCompanion(
      conversionId: conversionId ?? this.conversionId,
      wordIndex: wordIndex ?? this.wordIndex,
      audioMs: audioMs ?? this.audioMs,
      recordedAt: recordedAt ?? this.recordedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversionId.present) {
      map['conversion_id'] = Variable<String>(conversionId.value);
    }
    if (wordIndex.present) {
      map['word_index'] = Variable<int>(wordIndex.value);
    }
    if (audioMs.present) {
      map['audio_ms'] = Variable<int>(audioMs.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPositionsCompanion(')
          ..write('conversionId: $conversionId, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('audioMs: $audioMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadedBooksTable extends DownloadedBooks
    with TableInfo<$DownloadedBooksTable, StoredBookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversionIdMeta = const VerificationMeta(
    'conversionId',
  );
  @override
  late final GeneratedColumn<String> conversionId = GeneratedColumn<String>(
    'conversion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manifestJsonMeta = const VerificationMeta(
    'manifestJson',
  );
  @override
  late final GeneratedColumn<String> manifestJson = GeneratedColumn<String>(
    'manifest_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [conversionId, manifestJson, complete];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredBookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversion_id')) {
      context.handle(
        _conversionIdMeta,
        conversionId.isAcceptableOrUnknown(
          data['conversion_id']!,
          _conversionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversionIdMeta);
    }
    if (data.containsKey('manifest_json')) {
      context.handle(
        _manifestJsonMeta,
        manifestJson.isAcceptableOrUnknown(
          data['manifest_json']!,
          _manifestJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manifestJsonMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversionId};
  @override
  StoredBookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredBookRow(
      conversionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversion_id'],
      )!,
      manifestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest_json'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
    );
  }

  @override
  $DownloadedBooksTable createAlias(String alias) {
    return $DownloadedBooksTable(attachedDatabase, alias);
  }
}

class StoredBookRow extends DataClass implements Insertable<StoredBookRow> {
  final String conversionId;
  final String manifestJson;
  final bool complete;
  const StoredBookRow({
    required this.conversionId,
    required this.manifestJson,
    required this.complete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversion_id'] = Variable<String>(conversionId);
    map['manifest_json'] = Variable<String>(manifestJson);
    map['complete'] = Variable<bool>(complete);
    return map;
  }

  DownloadedBooksCompanion toCompanion(bool nullToAbsent) {
    return DownloadedBooksCompanion(
      conversionId: Value(conversionId),
      manifestJson: Value(manifestJson),
      complete: Value(complete),
    );
  }

  factory StoredBookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredBookRow(
      conversionId: serializer.fromJson<String>(json['conversionId']),
      manifestJson: serializer.fromJson<String>(json['manifestJson']),
      complete: serializer.fromJson<bool>(json['complete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversionId': serializer.toJson<String>(conversionId),
      'manifestJson': serializer.toJson<String>(manifestJson),
      'complete': serializer.toJson<bool>(complete),
    };
  }

  StoredBookRow copyWith({
    String? conversionId,
    String? manifestJson,
    bool? complete,
  }) => StoredBookRow(
    conversionId: conversionId ?? this.conversionId,
    manifestJson: manifestJson ?? this.manifestJson,
    complete: complete ?? this.complete,
  );
  StoredBookRow copyWithCompanion(DownloadedBooksCompanion data) {
    return StoredBookRow(
      conversionId: data.conversionId.present
          ? data.conversionId.value
          : this.conversionId,
      manifestJson: data.manifestJson.present
          ? data.manifestJson.value
          : this.manifestJson,
      complete: data.complete.present ? data.complete.value : this.complete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredBookRow(')
          ..write('conversionId: $conversionId, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('complete: $complete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conversionId, manifestJson, complete);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredBookRow &&
          other.conversionId == this.conversionId &&
          other.manifestJson == this.manifestJson &&
          other.complete == this.complete);
}

class DownloadedBooksCompanion extends UpdateCompanion<StoredBookRow> {
  final Value<String> conversionId;
  final Value<String> manifestJson;
  final Value<bool> complete;
  final Value<int> rowid;
  const DownloadedBooksCompanion({
    this.conversionId = const Value.absent(),
    this.manifestJson = const Value.absent(),
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedBooksCompanion.insert({
    required String conversionId,
    required String manifestJson,
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversionId = Value(conversionId),
       manifestJson = Value(manifestJson);
  static Insertable<StoredBookRow> custom({
    Expression<String>? conversionId,
    Expression<String>? manifestJson,
    Expression<bool>? complete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversionId != null) 'conversion_id': conversionId,
      if (manifestJson != null) 'manifest_json': manifestJson,
      if (complete != null) 'complete': complete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedBooksCompanion copyWith({
    Value<String>? conversionId,
    Value<String>? manifestJson,
    Value<bool>? complete,
    Value<int>? rowid,
  }) {
    return DownloadedBooksCompanion(
      conversionId: conversionId ?? this.conversionId,
      manifestJson: manifestJson ?? this.manifestJson,
      complete: complete ?? this.complete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversionId.present) {
      map['conversion_id'] = Variable<String>(conversionId.value);
    }
    if (manifestJson.present) {
      map['manifest_json'] = Variable<String>(manifestJson.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedBooksCompanion(')
          ..write('conversionId: $conversionId, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('complete: $complete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VerifiedPartsTable extends VerifiedParts
    with TableInfo<$VerifiedPartsTable, VerifiedPartRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VerifiedPartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversionIdMeta = const VerificationMeta(
    'conversionId',
  );
  @override
  late final GeneratedColumn<String> conversionId = GeneratedColumn<String>(
    'conversion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partIndexMeta = const VerificationMeta(
    'partIndex',
  );
  @override
  late final GeneratedColumn<int> partIndex = GeneratedColumn<int>(
    'part_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [conversionId, partIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verified_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<VerifiedPartRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversion_id')) {
      context.handle(
        _conversionIdMeta,
        conversionId.isAcceptableOrUnknown(
          data['conversion_id']!,
          _conversionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversionIdMeta);
    }
    if (data.containsKey('part_index')) {
      context.handle(
        _partIndexMeta,
        partIndex.isAcceptableOrUnknown(data['part_index']!, _partIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_partIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversionId, partIndex};
  @override
  VerifiedPartRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VerifiedPartRow(
      conversionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversion_id'],
      )!,
      partIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_index'],
      )!,
    );
  }

  @override
  $VerifiedPartsTable createAlias(String alias) {
    return $VerifiedPartsTable(attachedDatabase, alias);
  }
}

class VerifiedPartRow extends DataClass implements Insertable<VerifiedPartRow> {
  final String conversionId;
  final int partIndex;
  const VerifiedPartRow({required this.conversionId, required this.partIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversion_id'] = Variable<String>(conversionId);
    map['part_index'] = Variable<int>(partIndex);
    return map;
  }

  VerifiedPartsCompanion toCompanion(bool nullToAbsent) {
    return VerifiedPartsCompanion(
      conversionId: Value(conversionId),
      partIndex: Value(partIndex),
    );
  }

  factory VerifiedPartRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VerifiedPartRow(
      conversionId: serializer.fromJson<String>(json['conversionId']),
      partIndex: serializer.fromJson<int>(json['partIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversionId': serializer.toJson<String>(conversionId),
      'partIndex': serializer.toJson<int>(partIndex),
    };
  }

  VerifiedPartRow copyWith({String? conversionId, int? partIndex}) =>
      VerifiedPartRow(
        conversionId: conversionId ?? this.conversionId,
        partIndex: partIndex ?? this.partIndex,
      );
  VerifiedPartRow copyWithCompanion(VerifiedPartsCompanion data) {
    return VerifiedPartRow(
      conversionId: data.conversionId.present
          ? data.conversionId.value
          : this.conversionId,
      partIndex: data.partIndex.present ? data.partIndex.value : this.partIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VerifiedPartRow(')
          ..write('conversionId: $conversionId, ')
          ..write('partIndex: $partIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conversionId, partIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VerifiedPartRow &&
          other.conversionId == this.conversionId &&
          other.partIndex == this.partIndex);
}

class VerifiedPartsCompanion extends UpdateCompanion<VerifiedPartRow> {
  final Value<String> conversionId;
  final Value<int> partIndex;
  final Value<int> rowid;
  const VerifiedPartsCompanion({
    this.conversionId = const Value.absent(),
    this.partIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VerifiedPartsCompanion.insert({
    required String conversionId,
    required int partIndex,
    this.rowid = const Value.absent(),
  }) : conversionId = Value(conversionId),
       partIndex = Value(partIndex);
  static Insertable<VerifiedPartRow> custom({
    Expression<String>? conversionId,
    Expression<int>? partIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversionId != null) 'conversion_id': conversionId,
      if (partIndex != null) 'part_index': partIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VerifiedPartsCompanion copyWith({
    Value<String>? conversionId,
    Value<int>? partIndex,
    Value<int>? rowid,
  }) {
    return VerifiedPartsCompanion(
      conversionId: conversionId ?? this.conversionId,
      partIndex: partIndex ?? this.partIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversionId.present) {
      map['conversion_id'] = Variable<String>(conversionId.value);
    }
    if (partIndex.present) {
      map['part_index'] = Variable<int>(partIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VerifiedPartsCompanion(')
          ..write('conversionId: $conversionId, ')
          ..write('partIndex: $partIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, StoredBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIndexMeta = const VerificationMeta(
    'wordIndex',
  );
  @override
  late final GeneratedColumn<int> wordIndex = GeneratedColumn<int>(
    'word_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excerptMeta = const VerificationMeta(
    'excerpt',
  );
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
    'excerpt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageNumber,
    wordIndex,
    excerpt,
    note,
    needsReview,
    createdAt,
    updatedAt,
    deletedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('word_index')) {
      context.handle(
        _wordIndexMeta,
        wordIndex.isAcceptableOrUnknown(data['word_index']!, _wordIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIndexMeta);
    }
    if (data.containsKey('excerpt')) {
      context.handle(
        _excerptMeta,
        excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta),
      );
    } else if (isInserting) {
      context.missing(_excerptMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredBookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      wordIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_index'],
      )!,
      excerpt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excerpt'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class StoredBookmark extends DataClass implements Insertable<StoredBookmark> {
  final String id;
  final String documentId;
  final int pageNumber;
  final int wordIndex;
  final String excerpt;
  final String note;
  final bool needsReview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool pending;
  const StoredBookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.wordIndex,
    required this.excerpt,
    required this.note,
    required this.needsReview,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    map['word_index'] = Variable<int>(wordIndex);
    map['excerpt'] = Variable<String>(excerpt);
    map['note'] = Variable<String>(note);
    map['needs_review'] = Variable<bool>(needsReview);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      wordIndex: Value(wordIndex),
      excerpt: Value(excerpt),
      note: Value(note),
      needsReview: Value(needsReview),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pending: Value(pending),
    );
  }

  factory StoredBookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredBookmark(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      wordIndex: serializer.fromJson<int>(json['wordIndex']),
      excerpt: serializer.fromJson<String>(json['excerpt']),
      note: serializer.fromJson<String>(json['note']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'wordIndex': serializer.toJson<int>(wordIndex),
      'excerpt': serializer.toJson<String>(excerpt),
      'note': serializer.toJson<String>(note),
      'needsReview': serializer.toJson<bool>(needsReview),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  StoredBookmark copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    int? wordIndex,
    String? excerpt,
    String? note,
    bool? needsReview,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pending,
  }) => StoredBookmark(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    wordIndex: wordIndex ?? this.wordIndex,
    excerpt: excerpt ?? this.excerpt,
    note: note ?? this.note,
    needsReview: needsReview ?? this.needsReview,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pending: pending ?? this.pending,
  );
  StoredBookmark copyWithCompanion(BookmarksCompanion data) {
    return StoredBookmark(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      wordIndex: data.wordIndex.present ? data.wordIndex.value : this.wordIndex,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      note: data.note.present ? data.note.value : this.note,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredBookmark(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('excerpt: $excerpt, ')
          ..write('note: $note, ')
          ..write('needsReview: $needsReview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    pageNumber,
    wordIndex,
    excerpt,
    note,
    needsReview,
    createdAt,
    updatedAt,
    deletedAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredBookmark &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.wordIndex == this.wordIndex &&
          other.excerpt == this.excerpt &&
          other.note == this.note &&
          other.needsReview == this.needsReview &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pending == this.pending);
}

class BookmarksCompanion extends UpdateCompanion<StoredBookmark> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<int> wordIndex;
  final Value<String> excerpt;
  final Value<String> note;
  final Value<bool> needsReview;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.wordIndex = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.note = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String documentId,
    required int pageNumber,
    required int wordIndex,
    required String excerpt,
    required String note,
    this.needsReview = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       wordIndex = Value(wordIndex),
       excerpt = Value(excerpt),
       note = Value(note),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StoredBookmark> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<int>? wordIndex,
    Expression<String>? excerpt,
    Expression<String>? note,
    Expression<bool>? needsReview,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (wordIndex != null) 'word_index': wordIndex,
      if (excerpt != null) 'excerpt': excerpt,
      if (note != null) 'note': note,
      if (needsReview != null) 'needs_review': needsReview,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<int>? wordIndex,
    Value<String>? excerpt,
    Value<String>? note,
    Value<bool>? needsReview,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      wordIndex: wordIndex ?? this.wordIndex,
      excerpt: excerpt ?? this.excerpt,
      note: note ?? this.note,
      needsReview: needsReview ?? this.needsReview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (wordIndex.present) {
      map['word_index'] = Variable<int>(wordIndex.value);
    }
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('excerpt: $excerpt, ')
          ..write('note: $note, ')
          ..write('needsReview: $needsReview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PlayerDatabase extends GeneratedDatabase {
  _$PlayerDatabase(QueryExecutor e) : super(e);
  $PlayerDatabaseManager get managers => $PlayerDatabaseManager(this);
  late final $ReadingPositionsTable readingPositions = $ReadingPositionsTable(
    this,
  );
  late final $DownloadedBooksTable downloadedBooks = $DownloadedBooksTable(
    this,
  );
  late final $VerifiedPartsTable verifiedParts = $VerifiedPartsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readingPositions,
    downloadedBooks,
    verifiedParts,
    bookmarks,
  ];
}

typedef $$ReadingPositionsTableCreateCompanionBuilder =
    ReadingPositionsCompanion Function({
      required String conversionId,
      required int wordIndex,
      required int audioMs,
      required DateTime recordedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$ReadingPositionsTableUpdateCompanionBuilder =
    ReadingPositionsCompanion Function({
      Value<String> conversionId,
      Value<int> wordIndex,
      Value<int> audioMs,
      Value<DateTime> recordedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$ReadingPositionsTableFilterComposer
    extends Composer<_$PlayerDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordIndex => $composableBuilder(
    column: $table.wordIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get audioMs => $composableBuilder(
    column: $table.audioMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPositionsTableOrderingComposer
    extends Composer<_$PlayerDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordIndex => $composableBuilder(
    column: $table.wordIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get audioMs => $composableBuilder(
    column: $table.audioMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPositionsTableAnnotationComposer
    extends Composer<_$PlayerDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordIndex =>
      $composableBuilder(column: $table.wordIndex, builder: (column) => column);

  GeneratedColumn<int> get audioMs =>
      $composableBuilder(column: $table.audioMs, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$ReadingPositionsTableTableManager
    extends
        RootTableManager<
          _$PlayerDatabase,
          $ReadingPositionsTable,
          StoredPosition,
          $$ReadingPositionsTableFilterComposer,
          $$ReadingPositionsTableOrderingComposer,
          $$ReadingPositionsTableAnnotationComposer,
          $$ReadingPositionsTableCreateCompanionBuilder,
          $$ReadingPositionsTableUpdateCompanionBuilder,
          (
            StoredPosition,
            BaseReferences<
              _$PlayerDatabase,
              $ReadingPositionsTable,
              StoredPosition
            >,
          ),
          StoredPosition,
          PrefetchHooks Function()
        > {
  $$ReadingPositionsTableTableManager(
    _$PlayerDatabase db,
    $ReadingPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversionId = const Value.absent(),
                Value<int> wordIndex = const Value.absent(),
                Value<int> audioMs = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPositionsCompanion(
                conversionId: conversionId,
                wordIndex: wordIndex,
                audioMs: audioMs,
                recordedAt: recordedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversionId,
                required int wordIndex,
                required int audioMs,
                required DateTime recordedAt,
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPositionsCompanion.insert(
                conversionId: conversionId,
                wordIndex: wordIndex,
                audioMs: audioMs,
                recordedAt: recordedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlayerDatabase,
      $ReadingPositionsTable,
      StoredPosition,
      $$ReadingPositionsTableFilterComposer,
      $$ReadingPositionsTableOrderingComposer,
      $$ReadingPositionsTableAnnotationComposer,
      $$ReadingPositionsTableCreateCompanionBuilder,
      $$ReadingPositionsTableUpdateCompanionBuilder,
      (
        StoredPosition,
        BaseReferences<
          _$PlayerDatabase,
          $ReadingPositionsTable,
          StoredPosition
        >,
      ),
      StoredPosition,
      PrefetchHooks Function()
    >;
typedef $$DownloadedBooksTableCreateCompanionBuilder =
    DownloadedBooksCompanion Function({
      required String conversionId,
      required String manifestJson,
      Value<bool> complete,
      Value<int> rowid,
    });
typedef $$DownloadedBooksTableUpdateCompanionBuilder =
    DownloadedBooksCompanion Function({
      Value<String> conversionId,
      Value<String> manifestJson,
      Value<bool> complete,
      Value<int> rowid,
    });

class $$DownloadedBooksTableFilterComposer
    extends Composer<_$PlayerDatabase, $DownloadedBooksTable> {
  $$DownloadedBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedBooksTableOrderingComposer
    extends Composer<_$PlayerDatabase, $DownloadedBooksTable> {
  $$DownloadedBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedBooksTableAnnotationComposer
    extends Composer<_$PlayerDatabase, $DownloadedBooksTable> {
  $$DownloadedBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);
}

class $$DownloadedBooksTableTableManager
    extends
        RootTableManager<
          _$PlayerDatabase,
          $DownloadedBooksTable,
          StoredBookRow,
          $$DownloadedBooksTableFilterComposer,
          $$DownloadedBooksTableOrderingComposer,
          $$DownloadedBooksTableAnnotationComposer,
          $$DownloadedBooksTableCreateCompanionBuilder,
          $$DownloadedBooksTableUpdateCompanionBuilder,
          (
            StoredBookRow,
            BaseReferences<
              _$PlayerDatabase,
              $DownloadedBooksTable,
              StoredBookRow
            >,
          ),
          StoredBookRow,
          PrefetchHooks Function()
        > {
  $$DownloadedBooksTableTableManager(
    _$PlayerDatabase db,
    $DownloadedBooksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversionId = const Value.absent(),
                Value<String> manifestJson = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedBooksCompanion(
                conversionId: conversionId,
                manifestJson: manifestJson,
                complete: complete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversionId,
                required String manifestJson,
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedBooksCompanion.insert(
                conversionId: conversionId,
                manifestJson: manifestJson,
                complete: complete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$PlayerDatabase,
      $DownloadedBooksTable,
      StoredBookRow,
      $$DownloadedBooksTableFilterComposer,
      $$DownloadedBooksTableOrderingComposer,
      $$DownloadedBooksTableAnnotationComposer,
      $$DownloadedBooksTableCreateCompanionBuilder,
      $$DownloadedBooksTableUpdateCompanionBuilder,
      (
        StoredBookRow,
        BaseReferences<_$PlayerDatabase, $DownloadedBooksTable, StoredBookRow>,
      ),
      StoredBookRow,
      PrefetchHooks Function()
    >;
typedef $$VerifiedPartsTableCreateCompanionBuilder =
    VerifiedPartsCompanion Function({
      required String conversionId,
      required int partIndex,
      Value<int> rowid,
    });
typedef $$VerifiedPartsTableUpdateCompanionBuilder =
    VerifiedPartsCompanion Function({
      Value<String> conversionId,
      Value<int> partIndex,
      Value<int> rowid,
    });

class $$VerifiedPartsTableFilterComposer
    extends Composer<_$PlayerDatabase, $VerifiedPartsTable> {
  $$VerifiedPartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partIndex => $composableBuilder(
    column: $table.partIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VerifiedPartsTableOrderingComposer
    extends Composer<_$PlayerDatabase, $VerifiedPartsTable> {
  $$VerifiedPartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partIndex => $composableBuilder(
    column: $table.partIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VerifiedPartsTableAnnotationComposer
    extends Composer<_$PlayerDatabase, $VerifiedPartsTable> {
  $$VerifiedPartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversionId => $composableBuilder(
    column: $table.conversionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partIndex =>
      $composableBuilder(column: $table.partIndex, builder: (column) => column);
}

class $$VerifiedPartsTableTableManager
    extends
        RootTableManager<
          _$PlayerDatabase,
          $VerifiedPartsTable,
          VerifiedPartRow,
          $$VerifiedPartsTableFilterComposer,
          $$VerifiedPartsTableOrderingComposer,
          $$VerifiedPartsTableAnnotationComposer,
          $$VerifiedPartsTableCreateCompanionBuilder,
          $$VerifiedPartsTableUpdateCompanionBuilder,
          (
            VerifiedPartRow,
            BaseReferences<
              _$PlayerDatabase,
              $VerifiedPartsTable,
              VerifiedPartRow
            >,
          ),
          VerifiedPartRow,
          PrefetchHooks Function()
        > {
  $$VerifiedPartsTableTableManager(
    _$PlayerDatabase db,
    $VerifiedPartsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VerifiedPartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VerifiedPartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VerifiedPartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversionId = const Value.absent(),
                Value<int> partIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerifiedPartsCompanion(
                conversionId: conversionId,
                partIndex: partIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversionId,
                required int partIndex,
                Value<int> rowid = const Value.absent(),
              }) => VerifiedPartsCompanion.insert(
                conversionId: conversionId,
                partIndex: partIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VerifiedPartsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlayerDatabase,
      $VerifiedPartsTable,
      VerifiedPartRow,
      $$VerifiedPartsTableFilterComposer,
      $$VerifiedPartsTableOrderingComposer,
      $$VerifiedPartsTableAnnotationComposer,
      $$VerifiedPartsTableCreateCompanionBuilder,
      $$VerifiedPartsTableUpdateCompanionBuilder,
      (
        VerifiedPartRow,
        BaseReferences<_$PlayerDatabase, $VerifiedPartsTable, VerifiedPartRow>,
      ),
      VerifiedPartRow,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String documentId,
      required int pageNumber,
      required int wordIndex,
      required String excerpt,
      required String note,
      Value<bool> needsReview,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> pageNumber,
      Value<int> wordIndex,
      Value<String> excerpt,
      Value<String> note,
      Value<bool> needsReview,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$PlayerDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordIndex => $composableBuilder(
    column: $table.wordIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$PlayerDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordIndex => $composableBuilder(
    column: $table.wordIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$PlayerDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordIndex =>
      $composableBuilder(column: $table.wordIndex, builder: (column) => column);

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$PlayerDatabase,
          $BookmarksTable,
          StoredBookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (
            StoredBookmark,
            BaseReferences<_$PlayerDatabase, $BookmarksTable, StoredBookmark>,
          ),
          StoredBookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$PlayerDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<int> wordIndex = const Value.absent(),
                Value<String> excerpt = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                wordIndex: wordIndex,
                excerpt: excerpt,
                note: note,
                needsReview: needsReview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageNumber,
                required int wordIndex,
                required String excerpt,
                required String note,
                Value<bool> needsReview = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                wordIndex: wordIndex,
                excerpt: excerpt,
                note: note,
                needsReview: needsReview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$PlayerDatabase,
      $BookmarksTable,
      StoredBookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (
        StoredBookmark,
        BaseReferences<_$PlayerDatabase, $BookmarksTable, StoredBookmark>,
      ),
      StoredBookmark,
      PrefetchHooks Function()
    >;

class $PlayerDatabaseManager {
  final _$PlayerDatabase _db;
  $PlayerDatabaseManager(this._db);
  $$ReadingPositionsTableTableManager get readingPositions =>
      $$ReadingPositionsTableTableManager(_db, _db.readingPositions);
  $$DownloadedBooksTableTableManager get downloadedBooks =>
      $$DownloadedBooksTableTableManager(_db, _db.downloadedBooks);
  $$VerifiedPartsTableTableManager get verifiedParts =>
      $$VerifiedPartsTableTableManager(_db, _db.verifiedParts);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
}
