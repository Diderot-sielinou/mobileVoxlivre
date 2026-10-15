// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_sheet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutlineEntry {

 String get title; int get level; int get pageNumber;
/// Create a copy of OutlineEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutlineEntryCopyWith<OutlineEntry> get copyWith => _$OutlineEntryCopyWithImpl<OutlineEntry>(this as OutlineEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutlineEntry&&(identical(other.title, title) || other.title == title)&&(identical(other.level, level) || other.level == level)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber));
}


@override
int get hashCode => Object.hash(runtimeType,title,level,pageNumber);

@override
String toString() {
  return 'OutlineEntry(title: $title, level: $level, pageNumber: $pageNumber)';
}


}

/// @nodoc
abstract mixin class $OutlineEntryCopyWith<$Res>  {
  factory $OutlineEntryCopyWith(OutlineEntry value, $Res Function(OutlineEntry) _then) = _$OutlineEntryCopyWithImpl;
@useResult
$Res call({
 String title, int level, int pageNumber
});




}
/// @nodoc
class _$OutlineEntryCopyWithImpl<$Res>
    implements $OutlineEntryCopyWith<$Res> {
  _$OutlineEntryCopyWithImpl(this._self, this._then);

  final OutlineEntry _self;
  final $Res Function(OutlineEntry) _then;

/// Create a copy of OutlineEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? level = null,Object? pageNumber = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OutlineEntry].
extension OutlineEntryPatterns on OutlineEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutlineEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutlineEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutlineEntry value)  $default,){
final _that = this;
switch (_that) {
case _OutlineEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutlineEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OutlineEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int level,  int pageNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutlineEntry() when $default != null:
return $default(_that.title,_that.level,_that.pageNumber);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int level,  int pageNumber)  $default,) {final _that = this;
switch (_that) {
case _OutlineEntry():
return $default(_that.title,_that.level,_that.pageNumber);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int level,  int pageNumber)?  $default,) {final _that = this;
switch (_that) {
case _OutlineEntry() when $default != null:
return $default(_that.title,_that.level,_that.pageNumber);case _:
  return null;

}
}

}

/// @nodoc


class _OutlineEntry implements OutlineEntry {
  const _OutlineEntry({required this.title, required this.level, required this.pageNumber});
  

@override final  String title;
@override final  int level;
@override final  int pageNumber;

/// Create a copy of OutlineEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutlineEntryCopyWith<_OutlineEntry> get copyWith => __$OutlineEntryCopyWithImpl<_OutlineEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutlineEntry&&(identical(other.title, title) || other.title == title)&&(identical(other.level, level) || other.level == level)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber));
}


@override
int get hashCode => Object.hash(runtimeType,title,level,pageNumber);

@override
String toString() {
  return 'OutlineEntry(title: $title, level: $level, pageNumber: $pageNumber)';
}


}

/// @nodoc
abstract mixin class _$OutlineEntryCopyWith<$Res> implements $OutlineEntryCopyWith<$Res> {
  factory _$OutlineEntryCopyWith(_OutlineEntry value, $Res Function(_OutlineEntry) _then) = __$OutlineEntryCopyWithImpl;
@override @useResult
$Res call({
 String title, int level, int pageNumber
});




}
/// @nodoc
class __$OutlineEntryCopyWithImpl<$Res>
    implements _$OutlineEntryCopyWith<$Res> {
  __$OutlineEntryCopyWithImpl(this._self, this._then);

  final _OutlineEntry _self;
  final $Res Function(_OutlineEntry) _then;

/// Create a copy of OutlineEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? level = null,Object? pageNumber = null,}) {
  return _then(_OutlineEntry(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$DocumentSheet {

 String get id; String get title; DocumentStage get stage; int? get pageCount; int? get charCount; ExtractionMethod? get method; String? get extractionError;/// Pendant la reconnaissance d'un scan : pages faites / total.
 ({int done, int total})? get ocrProgress;/// Confiance faible sur au moins une page : relecture avant conversion.
 bool get reviewRequired; DateTime? get reviewedAt; List<OutlineEntry> get outline;
/// Create a copy of DocumentSheet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentSheetCopyWith<DocumentSheet> get copyWith => _$DocumentSheetCopyWithImpl<DocumentSheet>(this as DocumentSheet, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentSheet&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.charCount, charCount) || other.charCount == charCount)&&(identical(other.method, method) || other.method == method)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.ocrProgress, ocrProgress) || other.ocrProgress == ocrProgress)&&(identical(other.reviewRequired, reviewRequired) || other.reviewRequired == reviewRequired)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other.outline, outline));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,stage,pageCount,charCount,method,extractionError,ocrProgress,reviewRequired,reviewedAt,const DeepCollectionEquality().hash(outline));

@override
String toString() {
  return 'DocumentSheet(id: $id, title: $title, stage: $stage, pageCount: $pageCount, charCount: $charCount, method: $method, extractionError: $extractionError, ocrProgress: $ocrProgress, reviewRequired: $reviewRequired, reviewedAt: $reviewedAt, outline: $outline)';
}


}

/// @nodoc
abstract mixin class $DocumentSheetCopyWith<$Res>  {
  factory $DocumentSheetCopyWith(DocumentSheet value, $Res Function(DocumentSheet) _then) = _$DocumentSheetCopyWithImpl;
@useResult
$Res call({
 String id, String title, DocumentStage stage, int? pageCount, int? charCount, ExtractionMethod? method, String? extractionError, ({int done, int total})? ocrProgress, bool reviewRequired, DateTime? reviewedAt, List<OutlineEntry> outline
});




}
/// @nodoc
class _$DocumentSheetCopyWithImpl<$Res>
    implements $DocumentSheetCopyWith<$Res> {
  _$DocumentSheetCopyWithImpl(this._self, this._then);

  final DocumentSheet _self;
  final $Res Function(DocumentSheet) _then;

/// Create a copy of DocumentSheet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? stage = null,Object? pageCount = freezed,Object? charCount = freezed,Object? method = freezed,Object? extractionError = freezed,Object? ocrProgress = freezed,Object? reviewRequired = null,Object? reviewedAt = freezed,Object? outline = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as DocumentStage,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,charCount: freezed == charCount ? _self.charCount : charCount // ignore: cast_nullable_to_non_nullable
as int?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as ExtractionMethod?,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,ocrProgress: freezed == ocrProgress ? _self.ocrProgress : ocrProgress // ignore: cast_nullable_to_non_nullable
as ({int done, int total})?,reviewRequired: null == reviewRequired ? _self.reviewRequired : reviewRequired // ignore: cast_nullable_to_non_nullable
as bool,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,outline: null == outline ? _self.outline : outline // ignore: cast_nullable_to_non_nullable
as List<OutlineEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentSheet].
extension DocumentSheetPatterns on DocumentSheet {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentSheet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentSheet() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentSheet value)  $default,){
final _that = this;
switch (_that) {
case _DocumentSheet():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentSheet value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentSheet() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DocumentStage stage,  int? pageCount,  int? charCount,  ExtractionMethod? method,  String? extractionError,  ({int done, int total})? ocrProgress,  bool reviewRequired,  DateTime? reviewedAt,  List<OutlineEntry> outline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentSheet() when $default != null:
return $default(_that.id,_that.title,_that.stage,_that.pageCount,_that.charCount,_that.method,_that.extractionError,_that.ocrProgress,_that.reviewRequired,_that.reviewedAt,_that.outline);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DocumentStage stage,  int? pageCount,  int? charCount,  ExtractionMethod? method,  String? extractionError,  ({int done, int total})? ocrProgress,  bool reviewRequired,  DateTime? reviewedAt,  List<OutlineEntry> outline)  $default,) {final _that = this;
switch (_that) {
case _DocumentSheet():
return $default(_that.id,_that.title,_that.stage,_that.pageCount,_that.charCount,_that.method,_that.extractionError,_that.ocrProgress,_that.reviewRequired,_that.reviewedAt,_that.outline);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DocumentStage stage,  int? pageCount,  int? charCount,  ExtractionMethod? method,  String? extractionError,  ({int done, int total})? ocrProgress,  bool reviewRequired,  DateTime? reviewedAt,  List<OutlineEntry> outline)?  $default,) {final _that = this;
switch (_that) {
case _DocumentSheet() when $default != null:
return $default(_that.id,_that.title,_that.stage,_that.pageCount,_that.charCount,_that.method,_that.extractionError,_that.ocrProgress,_that.reviewRequired,_that.reviewedAt,_that.outline);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentSheet extends DocumentSheet {
  const _DocumentSheet({required this.id, required this.title, required this.stage, this.pageCount, this.charCount, this.method, this.extractionError, this.ocrProgress, this.reviewRequired = false, this.reviewedAt, final  List<OutlineEntry> outline = const []}): _outline = outline,super._();
  

@override final  String id;
@override final  String title;
@override final  DocumentStage stage;
@override final  int? pageCount;
@override final  int? charCount;
@override final  ExtractionMethod? method;
@override final  String? extractionError;
/// Pendant la reconnaissance d'un scan : pages faites / total.
@override final  ({int done, int total})? ocrProgress;
/// Confiance faible sur au moins une page : relecture avant conversion.
@override@JsonKey() final  bool reviewRequired;
@override final  DateTime? reviewedAt;
 final  List<OutlineEntry> _outline;
@override@JsonKey() List<OutlineEntry> get outline {
  if (_outline is EqualUnmodifiableListView) return _outline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outline);
}


/// Create a copy of DocumentSheet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentSheetCopyWith<_DocumentSheet> get copyWith => __$DocumentSheetCopyWithImpl<_DocumentSheet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentSheet&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.charCount, charCount) || other.charCount == charCount)&&(identical(other.method, method) || other.method == method)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.ocrProgress, ocrProgress) || other.ocrProgress == ocrProgress)&&(identical(other.reviewRequired, reviewRequired) || other.reviewRequired == reviewRequired)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other._outline, _outline));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,stage,pageCount,charCount,method,extractionError,ocrProgress,reviewRequired,reviewedAt,const DeepCollectionEquality().hash(_outline));

@override
String toString() {
  return 'DocumentSheet(id: $id, title: $title, stage: $stage, pageCount: $pageCount, charCount: $charCount, method: $method, extractionError: $extractionError, ocrProgress: $ocrProgress, reviewRequired: $reviewRequired, reviewedAt: $reviewedAt, outline: $outline)';
}


}

/// @nodoc
abstract mixin class _$DocumentSheetCopyWith<$Res> implements $DocumentSheetCopyWith<$Res> {
  factory _$DocumentSheetCopyWith(_DocumentSheet value, $Res Function(_DocumentSheet) _then) = __$DocumentSheetCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DocumentStage stage, int? pageCount, int? charCount, ExtractionMethod? method, String? extractionError, ({int done, int total})? ocrProgress, bool reviewRequired, DateTime? reviewedAt, List<OutlineEntry> outline
});




}
/// @nodoc
class __$DocumentSheetCopyWithImpl<$Res>
    implements _$DocumentSheetCopyWith<$Res> {
  __$DocumentSheetCopyWithImpl(this._self, this._then);

  final _DocumentSheet _self;
  final $Res Function(_DocumentSheet) _then;

/// Create a copy of DocumentSheet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? stage = null,Object? pageCount = freezed,Object? charCount = freezed,Object? method = freezed,Object? extractionError = freezed,Object? ocrProgress = freezed,Object? reviewRequired = null,Object? reviewedAt = freezed,Object? outline = null,}) {
  return _then(_DocumentSheet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as DocumentStage,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,charCount: freezed == charCount ? _self.charCount : charCount // ignore: cast_nullable_to_non_nullable
as int?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as ExtractionMethod?,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,ocrProgress: freezed == ocrProgress ? _self.ocrProgress : ocrProgress // ignore: cast_nullable_to_non_nullable
as ({int done, int total})?,reviewRequired: null == reviewRequired ? _self.reviewRequired : reviewRequired // ignore: cast_nullable_to_non_nullable
as bool,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,outline: null == outline ? _self._outline : outline // ignore: cast_nullable_to_non_nullable
as List<OutlineEntry>,
  ));
}


}

// dart format on
