// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsViewModel {

 ThemeMode get theme; Currency get currency;@Uint8ListConverter() Uint8List? get profilePicture; String? get userName; String? get email; bool? get isFirstTime;@FlexSchemeConverter() FlexScheme get colorScheme;
/// Create a copy of SettingsViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsViewModelCopyWith<SettingsViewModel> get copyWith => _$SettingsViewModelCopyWithImpl<SettingsViewModel>(this as SettingsViewModel, _$identity);

  /// Serializes this SettingsViewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsViewModel&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.profilePicture, profilePicture)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.email, email) || other.email == email)&&(identical(other.isFirstTime, isFirstTime) || other.isFirstTime == isFirstTime)&&(identical(other.colorScheme, colorScheme) || other.colorScheme == colorScheme));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,currency,const DeepCollectionEquality().hash(profilePicture),userName,email,isFirstTime,colorScheme);

@override
String toString() {
  return 'SettingsViewModel(theme: $theme, currency: $currency, profilePicture: $profilePicture, userName: $userName, email: $email, isFirstTime: $isFirstTime, colorScheme: $colorScheme)';
}


}

/// @nodoc
abstract mixin class $SettingsViewModelCopyWith<$Res>  {
  factory $SettingsViewModelCopyWith(SettingsViewModel value, $Res Function(SettingsViewModel) _then) = _$SettingsViewModelCopyWithImpl;
@useResult
$Res call({
 ThemeMode theme, Currency currency,@Uint8ListConverter() Uint8List? profilePicture, String? userName, String? email, bool? isFirstTime,@FlexSchemeConverter() FlexScheme colorScheme
});




}
/// @nodoc
class _$SettingsViewModelCopyWithImpl<$Res>
    implements $SettingsViewModelCopyWith<$Res> {
  _$SettingsViewModelCopyWithImpl(this._self, this._then);

  final SettingsViewModel _self;
  final $Res Function(SettingsViewModel) _then;

/// Create a copy of SettingsViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? currency = null,Object? profilePicture = freezed,Object? userName = freezed,Object? email = freezed,Object? isFirstTime = freezed,Object? colorScheme = null,}) {
  return _then(_self.copyWith(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeMode,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as Uint8List?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,isFirstTime: freezed == isFirstTime ? _self.isFirstTime : isFirstTime // ignore: cast_nullable_to_non_nullable
as bool?,colorScheme: null == colorScheme ? _self.colorScheme : colorScheme // ignore: cast_nullable_to_non_nullable
as FlexScheme,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsViewModel].
extension SettingsViewModelPatterns on SettingsViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsViewModel value)  $default,){
final _that = this;
switch (_that) {
case _SettingsViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode theme,  Currency currency, @Uint8ListConverter()  Uint8List? profilePicture,  String? userName,  String? email,  bool? isFirstTime, @FlexSchemeConverter()  FlexScheme colorScheme)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsViewModel() when $default != null:
return $default(_that.theme,_that.currency,_that.profilePicture,_that.userName,_that.email,_that.isFirstTime,_that.colorScheme);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode theme,  Currency currency, @Uint8ListConverter()  Uint8List? profilePicture,  String? userName,  String? email,  bool? isFirstTime, @FlexSchemeConverter()  FlexScheme colorScheme)  $default,) {final _that = this;
switch (_that) {
case _SettingsViewModel():
return $default(_that.theme,_that.currency,_that.profilePicture,_that.userName,_that.email,_that.isFirstTime,_that.colorScheme);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode theme,  Currency currency, @Uint8ListConverter()  Uint8List? profilePicture,  String? userName,  String? email,  bool? isFirstTime, @FlexSchemeConverter()  FlexScheme colorScheme)?  $default,) {final _that = this;
switch (_that) {
case _SettingsViewModel() when $default != null:
return $default(_that.theme,_that.currency,_that.profilePicture,_that.userName,_that.email,_that.isFirstTime,_that.colorScheme);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsViewModel implements SettingsViewModel {
  const _SettingsViewModel({required this.theme, required this.currency, @Uint8ListConverter() this.profilePicture, this.userName, this.email, this.isFirstTime, @FlexSchemeConverter() this.colorScheme = FlexScheme.bahamaBlue});
  factory _SettingsViewModel.fromJson(Map<String, dynamic> json) => _$SettingsViewModelFromJson(json);

@override final  ThemeMode theme;
@override final  Currency currency;
@override@Uint8ListConverter() final  Uint8List? profilePicture;
@override final  String? userName;
@override final  String? email;
@override final  bool? isFirstTime;
@override@JsonKey()@FlexSchemeConverter() final  FlexScheme colorScheme;

/// Create a copy of SettingsViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsViewModelCopyWith<_SettingsViewModel> get copyWith => __$SettingsViewModelCopyWithImpl<_SettingsViewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsViewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsViewModel&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.profilePicture, profilePicture)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.email, email) || other.email == email)&&(identical(other.isFirstTime, isFirstTime) || other.isFirstTime == isFirstTime)&&(identical(other.colorScheme, colorScheme) || other.colorScheme == colorScheme));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,currency,const DeepCollectionEquality().hash(profilePicture),userName,email,isFirstTime,colorScheme);

@override
String toString() {
  return 'SettingsViewModel(theme: $theme, currency: $currency, profilePicture: $profilePicture, userName: $userName, email: $email, isFirstTime: $isFirstTime, colorScheme: $colorScheme)';
}


}

/// @nodoc
abstract mixin class _$SettingsViewModelCopyWith<$Res> implements $SettingsViewModelCopyWith<$Res> {
  factory _$SettingsViewModelCopyWith(_SettingsViewModel value, $Res Function(_SettingsViewModel) _then) = __$SettingsViewModelCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode theme, Currency currency,@Uint8ListConverter() Uint8List? profilePicture, String? userName, String? email, bool? isFirstTime,@FlexSchemeConverter() FlexScheme colorScheme
});




}
/// @nodoc
class __$SettingsViewModelCopyWithImpl<$Res>
    implements _$SettingsViewModelCopyWith<$Res> {
  __$SettingsViewModelCopyWithImpl(this._self, this._then);

  final _SettingsViewModel _self;
  final $Res Function(_SettingsViewModel) _then;

/// Create a copy of SettingsViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? currency = null,Object? profilePicture = freezed,Object? userName = freezed,Object? email = freezed,Object? isFirstTime = freezed,Object? colorScheme = null,}) {
  return _then(_SettingsViewModel(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeMode,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as Uint8List?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,isFirstTime: freezed == isFirstTime ? _self.isFirstTime : isFirstTime // ignore: cast_nullable_to_non_nullable
as bool?,colorScheme: null == colorScheme ? _self.colorScheme : colorScheme // ignore: cast_nullable_to_non_nullable
as FlexScheme,
  ));
}


}

// dart format on
