// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversionSummary {

 String get id; String get status; int get partsReady; Duration get playable; int? get partCount; String? get failureReason;
/// Create a copy of ConversionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionSummaryCopyWith<ConversionSummary> get copyWith => _$ConversionSummaryCopyWithImpl<ConversionSummary>(this as ConversionSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.partsReady, partsReady) || other.partsReady == partsReady)&&(identical(other.playable, playable) || other.playable == playable)&&(identical(other.partCount, partCount) || other.partCount == partCount)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,partsReady,playable,partCount,failureReason);

@override
String toString() {
  return 'ConversionSummary(id: $id, status: $status, partsReady: $partsReady, playable: $playable, partCount: $partCount, failureReason: $failureReason)';
}


}

/// @nodoc
abstract mixin class $ConversionSummaryCopyWith<$Res>  {
  factory $ConversionSummaryCopyWith(ConversionSummary value, $Res Function(ConversionSummary) _then) = _$ConversionSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String status, int partsReady, Duration playable, int? partCount, String? failureReason
});




}
/// @nodoc
class _$ConversionSummaryCopyWithImpl<$Res>
    implements $ConversionSummaryCopyWith<$Res> {
  _$ConversionSummaryCopyWithImpl(this._self, this._then);

  final ConversionSummary _self;
  final $Res Function(ConversionSummary) _then;

/// Create a copy of ConversionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? partsReady = null,Object? playable = null,Object? partCount = freezed,Object? failureReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,partsReady: null == partsReady ? _self.partsReady : partsReady // ignore: cast_nullable_to_non_nullable
as int,playable: null == playable ? _self.playable : playable // ignore: cast_nullable_to_non_nullable
as Duration,partCount: freezed == partCount ? _self.partCount : partCount // ignore: cast_nullable_to_non_nullable
as int?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversionSummary].
extension ConversionSummaryPatterns on ConversionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionSummary value)  $default,){
final _that = this;
switch (_that) {
case _ConversionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  int partsReady,  Duration playable,  int? partCount,  String? failureReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionSummary() when $default != null:
return $default(_that.id,_that.status,_that.partsReady,_that.playable,_that.partCount,_that.failureReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  int partsReady,  Duration playable,  int? partCount,  String? failureReason)  $default,) {final _that = this;
switch (_that) {
case _ConversionSummary():
return $default(_that.id,_that.status,_that.partsReady,_that.playable,_that.partCount,_that.failureReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  int partsReady,  Duration playable,  int? partCount,  String? failureReason)?  $default,) {final _that = this;
switch (_that) {
case _ConversionSummary() when $default != null:
return $default(_that.id,_that.status,_that.partsReady,_that.playable,_that.partCount,_that.failureReason);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionSummary implements ConversionSummary {
  const _ConversionSummary({required this.id, required this.status, required this.partsReady, required this.playable, this.partCount, this.failureReason});
  

@override final  String id;
@override final  String status;
@override final  int partsReady;
@override final  Duration playable;
@override final  int? partCount;
@override final  String? failureReason;

/// Create a copy of ConversionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionSummaryCopyWith<_ConversionSummary> get copyWith => __$ConversionSummaryCopyWithImpl<_ConversionSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.partsReady, partsReady) || other.partsReady == partsReady)&&(identical(other.playable, playable) || other.playable == playable)&&(identical(other.partCount, partCount) || other.partCount == partCount)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,partsReady,playable,partCount,failureReason);

@override
String toString() {
  return 'ConversionSummary(id: $id, status: $status, partsReady: $partsReady, playable: $playable, partCount: $partCount, failureReason: $failureReason)';
}


}

/// @nodoc
abstract mixin class _$ConversionSummaryCopyWith<$Res> implements $ConversionSummaryCopyWith<$Res> {
  factory _$ConversionSummaryCopyWith(_ConversionSummary value, $Res Function(_ConversionSummary) _then) = __$ConversionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, int partsReady, Duration playable, int? partCount, String? failureReason
});




}
/// @nodoc
class __$ConversionSummaryCopyWithImpl<$Res>
    implements _$ConversionSummaryCopyWith<$Res> {
  __$ConversionSummaryCopyWithImpl(this._self, this._then);

  final _ConversionSummary _self;
  final $Res Function(_ConversionSummary) _then;

/// Create a copy of ConversionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? partsReady = null,Object? playable = null,Object? partCount = freezed,Object? failureReason = freezed,}) {
  return _then(_ConversionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,partsReady: null == partsReady ? _self.partsReady : partsReady // ignore: cast_nullable_to_non_nullable
as int,playable: null == playable ? _self.playable : playable // ignore: cast_nullable_to_non_nullable
as Duration,partCount: freezed == partCount ? _self.partCount : partCount // ignore: cast_nullable_to_non_nullable
as int?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ReadingPoint {

 int get wordIndex; Duration get audio; DateTime get recordedAt;
/// Create a copy of ReadingPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingPointCopyWith<ReadingPoint> get copyWith => _$ReadingPointCopyWithImpl<ReadingPoint>(this as ReadingPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingPoint&&(identical(other.wordIndex, wordIndex) || other.wordIndex == wordIndex)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}


@override
int get hashCode => Object.hash(runtimeType,wordIndex,audio,recordedAt);

@override
String toString() {
  return 'ReadingPoint(wordIndex: $wordIndex, audio: $audio, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class $ReadingPointCopyWith<$Res>  {
  factory $ReadingPointCopyWith(ReadingPoint value, $Res Function(ReadingPoint) _then) = _$ReadingPointCopyWithImpl;
@useResult
$Res call({
 int wordIndex, Duration audio, DateTime recordedAt
});




}
/// @nodoc
class _$ReadingPointCopyWithImpl<$Res>
    implements $ReadingPointCopyWith<$Res> {
  _$ReadingPointCopyWithImpl(this._self, this._then);

  final ReadingPoint _self;
  final $Res Function(ReadingPoint) _then;

/// Create a copy of ReadingPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wordIndex = null,Object? audio = null,Object? recordedAt = null,}) {
  return _then(_self.copyWith(
wordIndex: null == wordIndex ? _self.wordIndex : wordIndex // ignore: cast_nullable_to_non_nullable
as int,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as Duration,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingPoint].
extension ReadingPointPatterns on ReadingPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingPoint value)  $default,){
final _that = this;
switch (_that) {
case _ReadingPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingPoint value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int wordIndex,  Duration audio,  DateTime recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingPoint() when $default != null:
return $default(_that.wordIndex,_that.audio,_that.recordedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int wordIndex,  Duration audio,  DateTime recordedAt)  $default,) {final _that = this;
switch (_that) {
case _ReadingPoint():
return $default(_that.wordIndex,_that.audio,_that.recordedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int wordIndex,  Duration audio,  DateTime recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReadingPoint() when $default != null:
return $default(_that.wordIndex,_that.audio,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingPoint implements ReadingPoint {
  const _ReadingPoint({required this.wordIndex, required this.audio, required this.recordedAt});
  

@override final  int wordIndex;
@override final  Duration audio;
@override final  DateTime recordedAt;

/// Create a copy of ReadingPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingPointCopyWith<_ReadingPoint> get copyWith => __$ReadingPointCopyWithImpl<_ReadingPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingPoint&&(identical(other.wordIndex, wordIndex) || other.wordIndex == wordIndex)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}


@override
int get hashCode => Object.hash(runtimeType,wordIndex,audio,recordedAt);

@override
String toString() {
  return 'ReadingPoint(wordIndex: $wordIndex, audio: $audio, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$ReadingPointCopyWith<$Res> implements $ReadingPointCopyWith<$Res> {
  factory _$ReadingPointCopyWith(_ReadingPoint value, $Res Function(_ReadingPoint) _then) = __$ReadingPointCopyWithImpl;
@override @useResult
$Res call({
 int wordIndex, Duration audio, DateTime recordedAt
});




}
/// @nodoc
class __$ReadingPointCopyWithImpl<$Res>
    implements _$ReadingPointCopyWith<$Res> {
  __$ReadingPointCopyWithImpl(this._self, this._then);

  final _ReadingPoint _self;
  final $Res Function(_ReadingPoint) _then;

/// Create a copy of ReadingPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wordIndex = null,Object? audio = null,Object? recordedAt = null,}) {
  return _then(_ReadingPoint(
wordIndex: null == wordIndex ? _self.wordIndex : wordIndex // ignore: cast_nullable_to_non_nullable
as int,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as Duration,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$LibraryItem {

 String get documentId; String get title; LibraryStatus get status; DateTime get importedAt; int? get pageCount; int? get charCount;/// Raison stable d'un échec d'extraction (`unreadable`, `ocr_no_text`…).
 String? get extractionError;/// 0 à 100, seulement quand la conversion est complète.
 int? get progressPercent; ConversionSummary? get conversion; ReadingPoint? get position;
/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryItemCopyWith<LibraryItem> get copyWith => _$LibraryItemCopyWithImpl<LibraryItem>(this as LibraryItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryItem&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.importedAt, importedAt) || other.importedAt == importedAt)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.charCount, charCount) || other.charCount == charCount)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent)&&(identical(other.conversion, conversion) || other.conversion == conversion)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,title,status,importedAt,pageCount,charCount,extractionError,progressPercent,conversion,position);

@override
String toString() {
  return 'LibraryItem(documentId: $documentId, title: $title, status: $status, importedAt: $importedAt, pageCount: $pageCount, charCount: $charCount, extractionError: $extractionError, progressPercent: $progressPercent, conversion: $conversion, position: $position)';
}


}

/// @nodoc
abstract mixin class $LibraryItemCopyWith<$Res>  {
  factory $LibraryItemCopyWith(LibraryItem value, $Res Function(LibraryItem) _then) = _$LibraryItemCopyWithImpl;
@useResult
$Res call({
 String documentId, String title, LibraryStatus status, DateTime importedAt, int? pageCount, int? charCount, String? extractionError, int? progressPercent, ConversionSummary? conversion, ReadingPoint? position
});


$ConversionSummaryCopyWith<$Res>? get conversion;$ReadingPointCopyWith<$Res>? get position;

}
/// @nodoc
class _$LibraryItemCopyWithImpl<$Res>
    implements $LibraryItemCopyWith<$Res> {
  _$LibraryItemCopyWithImpl(this._self, this._then);

  final LibraryItem _self;
  final $Res Function(LibraryItem) _then;

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? title = null,Object? status = null,Object? importedAt = null,Object? pageCount = freezed,Object? charCount = freezed,Object? extractionError = freezed,Object? progressPercent = freezed,Object? conversion = freezed,Object? position = freezed,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LibraryStatus,importedAt: null == importedAt ? _self.importedAt : importedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,charCount: freezed == charCount ? _self.charCount : charCount // ignore: cast_nullable_to_non_nullable
as int?,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,progressPercent: freezed == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int?,conversion: freezed == conversion ? _self.conversion : conversion // ignore: cast_nullable_to_non_nullable
as ConversionSummary?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as ReadingPoint?,
  ));
}
/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionSummaryCopyWith<$Res>? get conversion {
    if (_self.conversion == null) {
    return null;
  }

  return $ConversionSummaryCopyWith<$Res>(_self.conversion!, (value) {
    return _then(_self.copyWith(conversion: value));
  });
}/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingPointCopyWith<$Res>? get position {
    if (_self.position == null) {
    return null;
  }

  return $ReadingPointCopyWith<$Res>(_self.position!, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryItem].
extension LibraryItemPatterns on LibraryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryItem value)  $default,){
final _that = this;
switch (_that) {
case _LibraryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryItem value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  String title,  LibraryStatus status,  DateTime importedAt,  int? pageCount,  int? charCount,  String? extractionError,  int? progressPercent,  ConversionSummary? conversion,  ReadingPoint? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
return $default(_that.documentId,_that.title,_that.status,_that.importedAt,_that.pageCount,_that.charCount,_that.extractionError,_that.progressPercent,_that.conversion,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  String title,  LibraryStatus status,  DateTime importedAt,  int? pageCount,  int? charCount,  String? extractionError,  int? progressPercent,  ConversionSummary? conversion,  ReadingPoint? position)  $default,) {final _that = this;
switch (_that) {
case _LibraryItem():
return $default(_that.documentId,_that.title,_that.status,_that.importedAt,_that.pageCount,_that.charCount,_that.extractionError,_that.progressPercent,_that.conversion,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  String title,  LibraryStatus status,  DateTime importedAt,  int? pageCount,  int? charCount,  String? extractionError,  int? progressPercent,  ConversionSummary? conversion,  ReadingPoint? position)?  $default,) {final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
return $default(_that.documentId,_that.title,_that.status,_that.importedAt,_that.pageCount,_that.charCount,_that.extractionError,_that.progressPercent,_that.conversion,_that.position);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryItem extends LibraryItem {
  const _LibraryItem({required this.documentId, required this.title, required this.status, required this.importedAt, this.pageCount, this.charCount, this.extractionError, this.progressPercent, this.conversion, this.position}): super._();
  

@override final  String documentId;
@override final  String title;
@override final  LibraryStatus status;
@override final  DateTime importedAt;
@override final  int? pageCount;
@override final  int? charCount;
/// Raison stable d'un échec d'extraction (`unreadable`, `ocr_no_text`…).
@override final  String? extractionError;
/// 0 à 100, seulement quand la conversion est complète.
@override final  int? progressPercent;
@override final  ConversionSummary? conversion;
@override final  ReadingPoint? position;

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryItemCopyWith<_LibraryItem> get copyWith => __$LibraryItemCopyWithImpl<_LibraryItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryItem&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.importedAt, importedAt) || other.importedAt == importedAt)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.charCount, charCount) || other.charCount == charCount)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent)&&(identical(other.conversion, conversion) || other.conversion == conversion)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,title,status,importedAt,pageCount,charCount,extractionError,progressPercent,conversion,position);

@override
String toString() {
  return 'LibraryItem(documentId: $documentId, title: $title, status: $status, importedAt: $importedAt, pageCount: $pageCount, charCount: $charCount, extractionError: $extractionError, progressPercent: $progressPercent, conversion: $conversion, position: $position)';
}


}

/// @nodoc
abstract mixin class _$LibraryItemCopyWith<$Res> implements $LibraryItemCopyWith<$Res> {
  factory _$LibraryItemCopyWith(_LibraryItem value, $Res Function(_LibraryItem) _then) = __$LibraryItemCopyWithImpl;
@override @useResult
$Res call({
 String documentId, String title, LibraryStatus status, DateTime importedAt, int? pageCount, int? charCount, String? extractionError, int? progressPercent, ConversionSummary? conversion, ReadingPoint? position
});


@override $ConversionSummaryCopyWith<$Res>? get conversion;@override $ReadingPointCopyWith<$Res>? get position;

}
/// @nodoc
class __$LibraryItemCopyWithImpl<$Res>
    implements _$LibraryItemCopyWith<$Res> {
  __$LibraryItemCopyWithImpl(this._self, this._then);

  final _LibraryItem _self;
  final $Res Function(_LibraryItem) _then;

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? title = null,Object? status = null,Object? importedAt = null,Object? pageCount = freezed,Object? charCount = freezed,Object? extractionError = freezed,Object? progressPercent = freezed,Object? conversion = freezed,Object? position = freezed,}) {
  return _then(_LibraryItem(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LibraryStatus,importedAt: null == importedAt ? _self.importedAt : importedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,charCount: freezed == charCount ? _self.charCount : charCount // ignore: cast_nullable_to_non_nullable
as int?,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,progressPercent: freezed == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int?,conversion: freezed == conversion ? _self.conversion : conversion // ignore: cast_nullable_to_non_nullable
as ConversionSummary?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as ReadingPoint?,
  ));
}

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionSummaryCopyWith<$Res>? get conversion {
    if (_self.conversion == null) {
    return null;
  }

  return $ConversionSummaryCopyWith<$Res>(_self.conversion!, (value) {
    return _then(_self.copyWith(conversion: value));
  });
}/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingPointCopyWith<$Res>? get position {
    if (_self.position == null) {
    return null;
  }

  return $ReadingPointCopyWith<$Res>(_self.position!, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}

// dart format on
