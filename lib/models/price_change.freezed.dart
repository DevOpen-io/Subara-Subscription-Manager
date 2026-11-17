// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriceChange {

 double get amount; DateTime get until;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) Currency? get currency;
/// Create a copy of PriceChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceChangeCopyWith<PriceChange> get copyWith => _$PriceChangeCopyWithImpl<PriceChange>(this as PriceChange, _$identity);

  /// Serializes this PriceChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PriceChange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceChange&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.until, _this.until) || other.until == _this.until)&&(identical(other.currency, _this.currency) || other.currency == _this.currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PriceChange;
  return Object.hash(runtimeType,_this.amount,_this.until,_this.currency);
}

@override
String toString() {
  final _this = this as PriceChange;
  return 'PriceChange(amount: ${_this.amount}, until: ${_this.until}, currency: ${_this.currency})';
}


}

/// @nodoc
abstract mixin class $PriceChangeCopyWith<$Res>  {
  factory $PriceChangeCopyWith(PriceChange value, $Res Function(PriceChange) _then) = _$PriceChangeCopyWithImpl;
@useResult
$Res call({
 double amount, DateTime until,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) Currency? currency
});




}
/// @nodoc
class _$PriceChangeCopyWithImpl<$Res>
    implements $PriceChangeCopyWith<$Res> {
  _$PriceChangeCopyWithImpl(this._self, this._then);

  final PriceChange _self;
  final $Res Function(PriceChange) _then;

/// Create a copy of PriceChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? until = null,Object? currency = freezed,}) {
  return _then(PriceChange(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency?,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceChange].
extension PriceChangePatterns on PriceChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceChange value)  $default,){
final _that = this;
switch (_that) {
case _PriceChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceChange value)?  $default,){
final _that = this;
switch (_that) {
case _PriceChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double amount,  DateTime until, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  Currency? currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceChange() when $default != null:
return $default(_that.amount,_that.until,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double amount,  DateTime until, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  Currency? currency)  $default,) {final _that = this;
switch (_that) {
case _PriceChange():
return $default(_that.amount,_that.until,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double amount,  DateTime until, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  Currency? currency)?  $default,) {final _that = this;
switch (_that) {
case _PriceChange() when $default != null:
return $default(_that.amount,_that.until,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceChange implements PriceChange {
  const _PriceChange({required this.amount, required this.until, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.currency});
  factory _PriceChange.fromJson(Map<String, dynamic> json) => _$PriceChangeFromJson(json);

@override final  double amount;
@override final  DateTime until;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  Currency? currency;

/// Create a copy of PriceChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceChangeCopyWith<_PriceChange> get copyWith => __$PriceChangeCopyWithImpl<_PriceChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceChangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceChange&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.until, until) || other.until == until)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount,until,currency);
}

@override
String toString() {
    return 'PriceChange(amount: $amount, until: $until, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$PriceChangeCopyWith<$Res> implements $PriceChangeCopyWith<$Res> {
  factory _$PriceChangeCopyWith(_PriceChange value, $Res Function(_PriceChange) _then) = __$PriceChangeCopyWithImpl;
@override @useResult
$Res call({
 double amount, DateTime until,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) Currency? currency
});




}
/// @nodoc
class __$PriceChangeCopyWithImpl<$Res>
    implements _$PriceChangeCopyWith<$Res> {
  __$PriceChangeCopyWithImpl(this._self, this._then);

  final _PriceChange _self;
  final $Res Function(_PriceChange) _then;

/// Create a copy of PriceChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? until = null,Object? currency = freezed,}) {
  return _then(_PriceChange(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency?,
  ));
}


}

// dart format on
