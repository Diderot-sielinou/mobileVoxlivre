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
  @override
  List<GeneratedColumn> get $columns => [
    conversionId,
    wordIndex,
    audioMs,
    recordedAt,
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
  const StoredPosition({
    required this.conversionId,
    required this.wordIndex,
    required this.audioMs,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversion_id'] = Variable<String>(conversionId);
    map['word_index'] = Variable<int>(wordIndex);
    map['audio_ms'] = Variable<int>(audioMs);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  ReadingPositionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingPositionsCompanion(
      conversionId: Value(conversionId),
      wordIndex: Value(wordIndex),
      audioMs: Value(audioMs),
      recordedAt: Value(recordedAt),
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
    };
  }

  StoredPosition copyWith({
    String? conversionId,
    int? wordIndex,
    int? audioMs,
    DateTime? recordedAt,
  }) => StoredPosition(
    conversionId: conversionId ?? this.conversionId,
    wordIndex: wordIndex ?? this.wordIndex,
    audioMs: audioMs ?? this.audioMs,
    recordedAt: recordedAt ?? this.recordedAt,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPosition(')
          ..write('conversionId: $conversionId, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('audioMs: $audioMs, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conversionId, wordIndex, audioMs, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPosition &&
          other.conversionId == this.conversionId &&
          other.wordIndex == this.wordIndex &&
          other.audioMs == this.audioMs &&
          other.recordedAt == this.recordedAt);
}

class ReadingPositionsCompanion extends UpdateCompanion<StoredPosition> {
  final Value<String> conversionId;
  final Value<int> wordIndex;
  final Value<int> audioMs;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const ReadingPositionsCompanion({
    this.conversionId = const Value.absent(),
    this.wordIndex = const Value.absent(),
    this.audioMs = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPositionsCompanion.insert({
    required String conversionId,
    required int wordIndex,
    required int audioMs,
    required DateTime recordedAt,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversionId != null) 'conversion_id': conversionId,
      if (wordIndex != null) 'word_index': wordIndex,
      if (audioMs != null) 'audio_ms': audioMs,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPositionsCompanion copyWith({
    Value<String>? conversionId,
    Value<int>? wordIndex,
    Value<int>? audioMs,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return ReadingPositionsCompanion(
      conversionId: conversionId ?? this.conversionId,
      wordIndex: wordIndex ?? this.wordIndex,
      audioMs: audioMs ?? this.audioMs,
      recordedAt: recordedAt ?? this.recordedAt,
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [readingPositions];
}

typedef $$ReadingPositionsTableCreateCompanionBuilder =
    ReadingPositionsCompanion Function({
      required String conversionId,
      required int wordIndex,
      required int audioMs,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$ReadingPositionsTableUpdateCompanionBuilder =
    ReadingPositionsCompanion Function({
      Value<String> conversionId,
      Value<int> wordIndex,
      Value<int> audioMs,
      Value<DateTime> recordedAt,
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
                Value<int> rowid = const Value.absent(),
              }) => ReadingPositionsCompanion(
                conversionId: conversionId,
                wordIndex: wordIndex,
                audioMs: audioMs,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversionId,
                required int wordIndex,
                required int audioMs,
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingPositionsCompanion.insert(
                conversionId: conversionId,
                wordIndex: wordIndex,
                audioMs: audioMs,
                recordedAt: recordedAt,
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

class $PlayerDatabaseManager {
  final _$PlayerDatabase _db;
  $PlayerDatabaseManager(this._db);
  $$ReadingPositionsTableTableManager get readingPositions =>
      $$ReadingPositionsTableTableManager(_db, _db.readingPositions);
}
