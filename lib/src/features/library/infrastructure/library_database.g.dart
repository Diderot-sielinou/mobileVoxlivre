// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_database.dart';

// ignore_for_file: type=lint
class $CachedLibraryItemsTable extends CachedLibraryItems
    with TableInfo<$CachedLibraryItemsTable, CachedLibraryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLibraryItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, rank, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_library_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLibraryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  CachedLibraryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLibraryItem(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedLibraryItemsTable createAlias(String alias) {
    return $CachedLibraryItemsTable(attachedDatabase, alias);
  }
}

class CachedLibraryItem extends DataClass
    implements Insertable<CachedLibraryItem> {
  final String documentId;
  final int rank;
  final String payload;
  const CachedLibraryItem({
    required this.documentId,
    required this.rank,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['rank'] = Variable<int>(rank);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedLibraryItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedLibraryItemsCompanion(
      documentId: Value(documentId),
      rank: Value(rank),
      payload: Value(payload),
    );
  }

  factory CachedLibraryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLibraryItem(
      documentId: serializer.fromJson<String>(json['documentId']),
      rank: serializer.fromJson<int>(json['rank']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'rank': serializer.toJson<int>(rank),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedLibraryItem copyWith({
    String? documentId,
    int? rank,
    String? payload,
  }) => CachedLibraryItem(
    documentId: documentId ?? this.documentId,
    rank: rank ?? this.rank,
    payload: payload ?? this.payload,
  );
  CachedLibraryItem copyWithCompanion(CachedLibraryItemsCompanion data) {
    return CachedLibraryItem(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      rank: data.rank.present ? data.rank.value : this.rank,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLibraryItem(')
          ..write('documentId: $documentId, ')
          ..write('rank: $rank, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, rank, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLibraryItem &&
          other.documentId == this.documentId &&
          other.rank == this.rank &&
          other.payload == this.payload);
}

class CachedLibraryItemsCompanion extends UpdateCompanion<CachedLibraryItem> {
  final Value<String> documentId;
  final Value<int> rank;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedLibraryItemsCompanion({
    this.documentId = const Value.absent(),
    this.rank = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLibraryItemsCompanion.insert({
    required String documentId,
    required int rank,
    required String payload,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       rank = Value(rank),
       payload = Value(payload);
  static Insertable<CachedLibraryItem> custom({
    Expression<String>? documentId,
    Expression<int>? rank,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (rank != null) 'rank': rank,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLibraryItemsCompanion copyWith({
    Value<String>? documentId,
    Value<int>? rank,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedLibraryItemsCompanion(
      documentId: documentId ?? this.documentId,
      rank: rank ?? this.rank,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLibraryItemsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('rank: $rank, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryCacheStateTable extends LibraryCacheState
    with TableInfo<$LibraryCacheStateTable, LibraryCacheStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryCacheStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refreshedAtMeta = const VerificationMeta(
    'refreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refreshedAt = GeneratedColumn<DateTime>(
    'refreshed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_cache_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryCacheStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(
        _refreshedAtMeta,
        refreshedAt.isAcceptableOrUnknown(
          data['refreshed_at']!,
          _refreshedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryCacheStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryCacheStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      refreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refreshed_at'],
      )!,
    );
  }

  @override
  $LibraryCacheStateTable createAlias(String alias) {
    return $LibraryCacheStateTable(attachedDatabase, alias);
  }
}

class LibraryCacheStateData extends DataClass
    implements Insertable<LibraryCacheStateData> {
  final int id;
  final DateTime refreshedAt;
  const LibraryCacheStateData({required this.id, required this.refreshedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['refreshed_at'] = Variable<DateTime>(refreshedAt);
    return map;
  }

  LibraryCacheStateCompanion toCompanion(bool nullToAbsent) {
    return LibraryCacheStateCompanion(
      id: Value(id),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory LibraryCacheStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryCacheStateData(
      id: serializer.fromJson<int>(json['id']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  LibraryCacheStateData copyWith({int? id, DateTime? refreshedAt}) =>
      LibraryCacheStateData(
        id: id ?? this.id,
        refreshedAt: refreshedAt ?? this.refreshedAt,
      );
  LibraryCacheStateData copyWithCompanion(LibraryCacheStateCompanion data) {
    return LibraryCacheStateData(
      id: data.id.present ? data.id.value : this.id,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryCacheStateData(')
          ..write('id: $id, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryCacheStateData &&
          other.id == this.id &&
          other.refreshedAt == this.refreshedAt);
}

class LibraryCacheStateCompanion
    extends UpdateCompanion<LibraryCacheStateData> {
  final Value<int> id;
  final Value<DateTime> refreshedAt;
  const LibraryCacheStateCompanion({
    this.id = const Value.absent(),
    this.refreshedAt = const Value.absent(),
  });
  LibraryCacheStateCompanion.insert({
    this.id = const Value.absent(),
    required DateTime refreshedAt,
  }) : refreshedAt = Value(refreshedAt);
  static Insertable<LibraryCacheStateData> custom({
    Expression<int>? id,
    Expression<DateTime>? refreshedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
    });
  }

  LibraryCacheStateCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? refreshedAt,
  }) {
    return LibraryCacheStateCompanion(
      id: id ?? this.id,
      refreshedAt: refreshedAt ?? this.refreshedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<DateTime>(refreshedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryCacheStateCompanion(')
          ..write('id: $id, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedDocumentsTable extends CachedDocuments
    with TableInfo<$CachedDocumentsTable, CachedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outlineMeta = const VerificationMeta(
    'outline',
  );
  @override
  late final GeneratedColumn<String> outline = GeneratedColumn<String>(
    'outline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, payload, outline];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('outline')) {
      context.handle(
        _outlineMeta,
        outline.isAcceptableOrUnknown(data['outline']!, _outlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  CachedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocument(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      outline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outline'],
      ),
    );
  }

  @override
  $CachedDocumentsTable createAlias(String alias) {
    return $CachedDocumentsTable(attachedDatabase, alias);
  }
}

class CachedDocument extends DataClass implements Insertable<CachedDocument> {
  final String documentId;
  final String payload;
  final String? outline;
  const CachedDocument({
    required this.documentId,
    required this.payload,
    this.outline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || outline != null) {
      map['outline'] = Variable<String>(outline);
    }
    return map;
  }

  CachedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentsCompanion(
      documentId: Value(documentId),
      payload: Value(payload),
      outline: outline == null && nullToAbsent
          ? const Value.absent()
          : Value(outline),
    );
  }

  factory CachedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocument(
      documentId: serializer.fromJson<String>(json['documentId']),
      payload: serializer.fromJson<String>(json['payload']),
      outline: serializer.fromJson<String?>(json['outline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'payload': serializer.toJson<String>(payload),
      'outline': serializer.toJson<String?>(outline),
    };
  }

  CachedDocument copyWith({
    String? documentId,
    String? payload,
    Value<String?> outline = const Value.absent(),
  }) => CachedDocument(
    documentId: documentId ?? this.documentId,
    payload: payload ?? this.payload,
    outline: outline.present ? outline.value : this.outline,
  );
  CachedDocument copyWithCompanion(CachedDocumentsCompanion data) {
    return CachedDocument(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      payload: data.payload.present ? data.payload.value : this.payload,
      outline: data.outline.present ? data.outline.value : this.outline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocument(')
          ..write('documentId: $documentId, ')
          ..write('payload: $payload, ')
          ..write('outline: $outline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, payload, outline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocument &&
          other.documentId == this.documentId &&
          other.payload == this.payload &&
          other.outline == this.outline);
}

class CachedDocumentsCompanion extends UpdateCompanion<CachedDocument> {
  final Value<String> documentId;
  final Value<String> payload;
  final Value<String?> outline;
  final Value<int> rowid;
  const CachedDocumentsCompanion({
    this.documentId = const Value.absent(),
    this.payload = const Value.absent(),
    this.outline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDocumentsCompanion.insert({
    required String documentId,
    required String payload,
    this.outline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       payload = Value(payload);
  static Insertable<CachedDocument> custom({
    Expression<String>? documentId,
    Expression<String>? payload,
    Expression<String>? outline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (payload != null) 'payload': payload,
      if (outline != null) 'outline': outline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDocumentsCompanion copyWith({
    Value<String>? documentId,
    Value<String>? payload,
    Value<String?>? outline,
    Value<int>? rowid,
  }) {
    return CachedDocumentsCompanion(
      documentId: documentId ?? this.documentId,
      payload: payload ?? this.payload,
      outline: outline ?? this.outline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (outline.present) {
      map['outline'] = Variable<String>(outline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('payload: $payload, ')
          ..write('outline: $outline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPagesTable extends CachedPages
    with TableInfo<$CachedPagesTable, CachedPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, pageNumber, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, pageNumber};
  @override
  CachedPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPage(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedPagesTable createAlias(String alias) {
    return $CachedPagesTable(attachedDatabase, alias);
  }
}

class CachedPage extends DataClass implements Insertable<CachedPage> {
  final String documentId;
  final int pageNumber;
  final String payload;
  const CachedPage({
    required this.documentId,
    required this.pageNumber,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedPagesCompanion toCompanion(bool nullToAbsent) {
    return CachedPagesCompanion(
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      payload: Value(payload),
    );
  }

  factory CachedPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPage(
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedPage copyWith({String? documentId, int? pageNumber, String? payload}) =>
      CachedPage(
        documentId: documentId ?? this.documentId,
        pageNumber: pageNumber ?? this.pageNumber,
        payload: payload ?? this.payload,
      );
  CachedPage copyWithCompanion(CachedPagesCompanion data) {
    return CachedPage(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPage(')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, pageNumber, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPage &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.payload == this.payload);
}

class CachedPagesCompanion extends UpdateCompanion<CachedPage> {
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedPagesCompanion({
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPagesCompanion.insert({
    required String documentId,
    required int pageNumber,
    required String payload,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       payload = Value(payload);
  static Insertable<CachedPage> custom({
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPagesCompanion copyWith({
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedPagesCompanion(
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPagesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDatabase extends GeneratedDatabase {
  _$LibraryDatabase(QueryExecutor e) : super(e);
  $LibraryDatabaseManager get managers => $LibraryDatabaseManager(this);
  late final $CachedLibraryItemsTable cachedLibraryItems =
      $CachedLibraryItemsTable(this);
  late final $LibraryCacheStateTable libraryCacheState =
      $LibraryCacheStateTable(this);
  late final $CachedDocumentsTable cachedDocuments = $CachedDocumentsTable(
    this,
  );
  late final $CachedPagesTable cachedPages = $CachedPagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedLibraryItems,
    libraryCacheState,
    cachedDocuments,
    cachedPages,
  ];
}

typedef $$CachedLibraryItemsTableCreateCompanionBuilder =
    CachedLibraryItemsCompanion Function({
      required String documentId,
      required int rank,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedLibraryItemsTableUpdateCompanionBuilder =
    CachedLibraryItemsCompanion Function({
      Value<String> documentId,
      Value<int> rank,
      Value<String> payload,
      Value<int> rowid,
    });

class $$CachedLibraryItemsTableFilterComposer
    extends Composer<_$LibraryDatabase, $CachedLibraryItemsTable> {
  $$CachedLibraryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLibraryItemsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $CachedLibraryItemsTable> {
  $$CachedLibraryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLibraryItemsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $CachedLibraryItemsTable> {
  $$CachedLibraryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$CachedLibraryItemsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $CachedLibraryItemsTable,
          CachedLibraryItem,
          $$CachedLibraryItemsTableFilterComposer,
          $$CachedLibraryItemsTableOrderingComposer,
          $$CachedLibraryItemsTableAnnotationComposer,
          $$CachedLibraryItemsTableCreateCompanionBuilder,
          $$CachedLibraryItemsTableUpdateCompanionBuilder,
          (
            CachedLibraryItem,
            BaseReferences<
              _$LibraryDatabase,
              $CachedLibraryItemsTable,
              CachedLibraryItem
            >,
          ),
          CachedLibraryItem,
          PrefetchHooks Function()
        > {
  $$CachedLibraryItemsTableTableManager(
    _$LibraryDatabase db,
    $CachedLibraryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLibraryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLibraryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLibraryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLibraryItemsCompanion(
                documentId: documentId,
                rank: rank,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int rank,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedLibraryItemsCompanion.insert(
                documentId: documentId,
                rank: rank,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLibraryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $CachedLibraryItemsTable,
      CachedLibraryItem,
      $$CachedLibraryItemsTableFilterComposer,
      $$CachedLibraryItemsTableOrderingComposer,
      $$CachedLibraryItemsTableAnnotationComposer,
      $$CachedLibraryItemsTableCreateCompanionBuilder,
      $$CachedLibraryItemsTableUpdateCompanionBuilder,
      (
        CachedLibraryItem,
        BaseReferences<
          _$LibraryDatabase,
          $CachedLibraryItemsTable,
          CachedLibraryItem
        >,
      ),
      CachedLibraryItem,
      PrefetchHooks Function()
    >;
typedef $$LibraryCacheStateTableCreateCompanionBuilder =
    LibraryCacheStateCompanion Function({
      Value<int> id,
      required DateTime refreshedAt,
    });
typedef $$LibraryCacheStateTableUpdateCompanionBuilder =
    LibraryCacheStateCompanion Function({
      Value<int> id,
      Value<DateTime> refreshedAt,
    });

class $$LibraryCacheStateTableFilterComposer
    extends Composer<_$LibraryDatabase, $LibraryCacheStateTable> {
  $$LibraryCacheStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryCacheStateTableOrderingComposer
    extends Composer<_$LibraryDatabase, $LibraryCacheStateTable> {
  $$LibraryCacheStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryCacheStateTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $LibraryCacheStateTable> {
  $$LibraryCacheStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => column,
  );
}

class $$LibraryCacheStateTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $LibraryCacheStateTable,
          LibraryCacheStateData,
          $$LibraryCacheStateTableFilterComposer,
          $$LibraryCacheStateTableOrderingComposer,
          $$LibraryCacheStateTableAnnotationComposer,
          $$LibraryCacheStateTableCreateCompanionBuilder,
          $$LibraryCacheStateTableUpdateCompanionBuilder,
          (
            LibraryCacheStateData,
            BaseReferences<
              _$LibraryDatabase,
              $LibraryCacheStateTable,
              LibraryCacheStateData
            >,
          ),
          LibraryCacheStateData,
          PrefetchHooks Function()
        > {
  $$LibraryCacheStateTableTableManager(
    _$LibraryDatabase db,
    $LibraryCacheStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryCacheStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryCacheStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryCacheStateTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
              }) =>
                  LibraryCacheStateCompanion(id: id, refreshedAt: refreshedAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime refreshedAt,
              }) => LibraryCacheStateCompanion.insert(
                id: id,
                refreshedAt: refreshedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryCacheStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $LibraryCacheStateTable,
      LibraryCacheStateData,
      $$LibraryCacheStateTableFilterComposer,
      $$LibraryCacheStateTableOrderingComposer,
      $$LibraryCacheStateTableAnnotationComposer,
      $$LibraryCacheStateTableCreateCompanionBuilder,
      $$LibraryCacheStateTableUpdateCompanionBuilder,
      (
        LibraryCacheStateData,
        BaseReferences<
          _$LibraryDatabase,
          $LibraryCacheStateTable,
          LibraryCacheStateData
        >,
      ),
      LibraryCacheStateData,
      PrefetchHooks Function()
    >;
typedef $$CachedDocumentsTableCreateCompanionBuilder =
    CachedDocumentsCompanion Function({
      required String documentId,
      required String payload,
      Value<String?> outline,
      Value<int> rowid,
    });
typedef $$CachedDocumentsTableUpdateCompanionBuilder =
    CachedDocumentsCompanion Function({
      Value<String> documentId,
      Value<String> payload,
      Value<String?> outline,
      Value<int> rowid,
    });

class $$CachedDocumentsTableFilterComposer
    extends Composer<_$LibraryDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDocumentsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDocumentsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get outline =>
      $composableBuilder(column: $table.outline, builder: (column) => column);
}

class $$CachedDocumentsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $CachedDocumentsTable,
          CachedDocument,
          $$CachedDocumentsTableFilterComposer,
          $$CachedDocumentsTableOrderingComposer,
          $$CachedDocumentsTableAnnotationComposer,
          $$CachedDocumentsTableCreateCompanionBuilder,
          $$CachedDocumentsTableUpdateCompanionBuilder,
          (
            CachedDocument,
            BaseReferences<
              _$LibraryDatabase,
              $CachedDocumentsTable,
              CachedDocument
            >,
          ),
          CachedDocument,
          PrefetchHooks Function()
        > {
  $$CachedDocumentsTableTableManager(
    _$LibraryDatabase db,
    $CachedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> outline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion(
                documentId: documentId,
                payload: payload,
                outline: outline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String payload,
                Value<String?> outline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion.insert(
                documentId: documentId,
                payload: payload,
                outline: outline,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $CachedDocumentsTable,
      CachedDocument,
      $$CachedDocumentsTableFilterComposer,
      $$CachedDocumentsTableOrderingComposer,
      $$CachedDocumentsTableAnnotationComposer,
      $$CachedDocumentsTableCreateCompanionBuilder,
      $$CachedDocumentsTableUpdateCompanionBuilder,
      (
        CachedDocument,
        BaseReferences<
          _$LibraryDatabase,
          $CachedDocumentsTable,
          CachedDocument
        >,
      ),
      CachedDocument,
      PrefetchHooks Function()
    >;
typedef $$CachedPagesTableCreateCompanionBuilder =
    CachedPagesCompanion Function({
      required String documentId,
      required int pageNumber,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedPagesTableUpdateCompanionBuilder =
    CachedPagesCompanion Function({
      Value<String> documentId,
      Value<int> pageNumber,
      Value<String> payload,
      Value<int> rowid,
    });

class $$CachedPagesTableFilterComposer
    extends Composer<_$LibraryDatabase, $CachedPagesTable> {
  $$CachedPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPagesTableOrderingComposer
    extends Composer<_$LibraryDatabase, $CachedPagesTable> {
  $$CachedPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPagesTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $CachedPagesTable> {
  $$CachedPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$CachedPagesTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $CachedPagesTable,
          CachedPage,
          $$CachedPagesTableFilterComposer,
          $$CachedPagesTableOrderingComposer,
          $$CachedPagesTableAnnotationComposer,
          $$CachedPagesTableCreateCompanionBuilder,
          $$CachedPagesTableUpdateCompanionBuilder,
          (
            CachedPage,
            BaseReferences<_$LibraryDatabase, $CachedPagesTable, CachedPage>,
          ),
          CachedPage,
          PrefetchHooks Function()
        > {
  $$CachedPagesTableTableManager(_$LibraryDatabase db, $CachedPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPagesCompanion(
                documentId: documentId,
                pageNumber: pageNumber,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int pageNumber,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedPagesCompanion.insert(
                documentId: documentId,
                pageNumber: pageNumber,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $CachedPagesTable,
      CachedPage,
      $$CachedPagesTableFilterComposer,
      $$CachedPagesTableOrderingComposer,
      $$CachedPagesTableAnnotationComposer,
      $$CachedPagesTableCreateCompanionBuilder,
      $$CachedPagesTableUpdateCompanionBuilder,
      (
        CachedPage,
        BaseReferences<_$LibraryDatabase, $CachedPagesTable, CachedPage>,
      ),
      CachedPage,
      PrefetchHooks Function()
    >;

class $LibraryDatabaseManager {
  final _$LibraryDatabase _db;
  $LibraryDatabaseManager(this._db);
  $$CachedLibraryItemsTableTableManager get cachedLibraryItems =>
      $$CachedLibraryItemsTableTableManager(_db, _db.cachedLibraryItems);
  $$LibraryCacheStateTableTableManager get libraryCacheState =>
      $$LibraryCacheStateTableTableManager(_db, _db.libraryCacheState);
  $$CachedDocumentsTableTableManager get cachedDocuments =>
      $$CachedDocumentsTableTableManager(_db, _db.cachedDocuments);
  $$CachedPagesTableTableManager get cachedPages =>
      $$CachedPagesTableTableManager(_db, _db.cachedPages);
}
