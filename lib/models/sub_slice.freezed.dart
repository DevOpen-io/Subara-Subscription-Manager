// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sub_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubSlice {

 Brand? get brand; String get name; double get amount; int get color; DateTime get startDate; Frequency get frequency; String? get category;
/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubSliceCopyWith<SubSlice> get copyWith => _$SubSliceCopyWithImpl<SubSlice>(this as SubSlice, _$identity);

  /// Serializes this SubSlice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubSlice&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,brand,name,amount,color,startDate,frequency,category);

@override
String toString() {
  return 'SubSlice(brand: $brand, name: $name, amount: $amount, color: $color, startDate: $startDate, frequency: $frequency, category: $category)';
}


}

/// @nodoc
abstract mixin class $SubSliceCopyWith<$Res>  {
  factory $SubSliceCopyWith(SubSlice value, $Res Function(SubSlice) _then) = _$SubSliceCopyWithImpl;
@useResult
$Res call({
 Brand? brand, String name, double amount, int color, DateTime startDate, Frequency frequency, String? category
});


$BrandCopyWith<$Res>? get brand;

}
/// @nodoc
class _$SubSliceCopyWithImpl<$Res>
    implements $SubSliceCopyWith<$Res> {
  _$SubSliceCopyWithImpl(this._self, this._then);

  final SubSlice _self;
  final $Res Function(SubSlice) _then;

/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? brand = freezed,Object? name = null,Object? amount = null,Object? color = null,Object? startDate = null,Object? frequency = null,Object? category = freezed,}) {
  return _then(_self.copyWith(
brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as Brand?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrandCopyWith<$Res>? get brand {
    if (_self.brand == null) {
    return null;
  }

  return $BrandCopyWith<$Res>(_self.brand!, (value) {
    return _then(_self.copyWith(brand: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubSlice].
extension SubSlicePatterns on SubSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubSlice value)  $default,){
final _that = this;
switch (_that) {
case _SubSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubSlice value)?  $default,){
final _that = this;
switch (_that) {
case _SubSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Brand? brand,  String name,  double amount,  int color,  DateTime startDate,  Frequency frequency,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubSlice() when $default != null:
return $default(_that.brand,_that.name,_that.amount,_that.color,_that.startDate,_that.frequency,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Brand? brand,  String name,  double amount,  int color,  DateTime startDate,  Frequency frequency,  String? category)  $default,) {final _that = this;
switch (_that) {
case _SubSlice():
return $default(_that.brand,_that.name,_that.amount,_that.color,_that.startDate,_that.frequency,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Brand? brand,  String name,  double amount,  int color,  DateTime startDate,  Frequency frequency,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _SubSlice() when $default != null:
return $default(_that.brand,_that.name,_that.amount,_that.color,_that.startDate,_that.frequency,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubSlice extends SubSlice {
  const _SubSlice({this.brand, required this.name, required this.amount, required this.color, required this.startDate, this.frequency = Frequency.monthly, this.category}): super._();
  factory _SubSlice.fromJson(Map<String, dynamic> json) => _$SubSliceFromJson(json);

@override final  Brand? brand;
@override final  String name;
@override final  double amount;
@override final  int color;
@override final  DateTime startDate;
@override@JsonKey() final  Frequency frequency;
@override final  String? category;

/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubSliceCopyWith<_SubSlice> get copyWith => __$SubSliceCopyWithImpl<_SubSlice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubSliceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubSlice&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,brand,name,amount,color,startDate,frequency,category);

@override
String toString() {
  return 'SubSlice(brand: $brand, name: $name, amount: $amount, color: $color, startDate: $startDate, frequency: $frequency, category: $category)';
}


}

/// @nodoc
abstract mixin class _$SubSliceCopyWith<$Res> implements $SubSliceCopyWith<$Res> {
  factory _$SubSliceCopyWith(_SubSlice value, $Res Function(_SubSlice) _then) = __$SubSliceCopyWithImpl;
@override @useResult
$Res call({
 Brand? brand, String name, double amount, int color, DateTime startDate, Frequency frequency, String? category
});


@override $BrandCopyWith<$Res>? get brand;

}
/// @nodoc
class __$SubSliceCopyWithImpl<$Res>
    implements _$SubSliceCopyWith<$Res> {
  __$SubSliceCopyWithImpl(this._self, this._then);

  final _SubSlice _self;
  final $Res Function(_SubSlice) _then;

/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? brand = freezed,Object? name = null,Object? amount = null,Object? color = null,Object? startDate = null,Object? frequency = null,Object? category = freezed,}) {
  return _then(_SubSlice(
brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as Brand?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrandCopyWith<$Res>? get brand {
    if (_self.brand == null) {
    return null;
  }

  return $BrandCopyWith<$Res>(_self.brand!, (value) {
    return _then(_self.copyWith(brand: value));
  });
}
}

// dart format on
