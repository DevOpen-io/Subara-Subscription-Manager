// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsViewModel {

 ThemeMode get theme; Currency get currency;@Uint8ListConverter() Uint8List? get profilePicture; String? get userName; String? get email; bool? get isFirstTime;@FlexSchemeConverter() FlexScheme get colorScheme;/// Reminder time of day, in minutes after midnight.
 int get reminderMinutes;/// User-entered rates: how many units of [currency] one unit of each
/// other currency is worth. Never fetched, so the app stays offline.
@ExchangeRatesConverter() Map<Currency, double> get exchangeRates;/// Monthly spending limit in the main currency; null = no budget.
@PositiveDoubleConverter() double? get monthlyBudget;/// Ask for the device lock / biometrics to open the app.
 bool get appLock;/// User-added categories, after the built-in ones.
@StringListConverter() List<String> get customCategories;
/// Create a copy of SettingsViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsViewModelCopyWith<SettingsViewModel> get copyWith => _$SettingsViewModelCopyWithImpl<SettingsViewModel>(this as SettingsViewModel, _$identity);

  /// Serializes this SettingsViewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SettingsViewModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsViewModel&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&const DeepCollectionEquality().equals(other.profilePicture, _this.profilePicture)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.isFirstTime, _this.isFirstTime) || other.isFirstTime == _this.isFirstTime)&&(identical(other.colorScheme, _this.colorScheme) || other.colorScheme == _this.colorScheme)&&(identical(other.reminderMinutes, _this.reminderMinutes) || other.reminderMinutes == _this.reminderMinutes)&&const DeepCollectionEquality().equals(other.exchangeRates, _this.exchangeRates)&&(identical(other.monthlyBudget, _this.monthlyBudget) || other.monthlyBudget == _this.monthlyBudget)&&(identical(other.appLock, _this.appLock) || other.appLock == _this.appLock)&&const DeepCollectionEquality().equals(other.customCategories, _this.customCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SettingsViewModel;
  return Object.hash(runtimeType,_this.theme,_this.currency,const DeepCollectionEquality().hash(_this.profilePicture),_this.userName,_this.email,_this.isFirstTime,_this.colorScheme,_this.reminderMinutes,const DeepCollectionEquality().hash(_this.exchangeRates),_this.monthlyBudget,_this.appLock,const DeepCollectionEquality().hash(_this.customCategories));
}

@override
String toString() {
  final _this = this as SettingsViewModel;
  return 'SettingsViewModel(theme: ${_this.theme}, currency: ${_this.currency}, profilePicture: ${_this.profilePicture}, userName: ${_this.userName}, email: ${_this.email}, isFirstTime: ${_this.isFirstTime}, colorScheme: ${_this.colorScheme}, reminderMinutes: ${_this.reminderMinutes}, exchangeRates: ${_this.exchangeRates}, monthlyBudget: ${_this.monthlyBudget}, appLock: ${_this.appLock}, customCategories: ${_this.customCategories})';
}


}

/// @nodoc
abstract mixin class $SettingsViewModelCopyWith<$Res>  {
  factory $SettingsViewModelCopyWith(SettingsViewModel value, $Res Function(SettingsViewModel) _then) = _$SettingsViewModelCopyWithImpl;
@useResult
$Res call({
 ThemeMode theme, Currency currency,@Uint8ListConverter() Uint8List? profilePicture, String? userName, String? email, bool? isFirstTime,@FlexSchemeConverter() FlexScheme colorScheme, int reminderMinutes,@ExchangeRatesConverter() Map<Currency, double> exchangeRates,@PositiveDoubleConverter() double? monthlyBudget, bool appLock,@StringListConverter() List<String> customCategories
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
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? currency = null,Object? profilePicture = freezed,Object? userName = freezed,Object? email = freezed,Object? isFirstTime = freezed,Object? colorScheme = null,Object? reminderMinutes = null,Object? exchangeRates = null,Object? monthlyBudget = freezed,Object? appLock = null,Object? customCategories = null,}) {
  return _then(SettingsViewModel(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeMode,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as Uint8List?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,isFirstTime: freezed == isFirstTime ? _self.isFirstTime : isFirstTime // ignore: cast_nullable_to_non_nullable
as bool?,colorScheme: null == colorScheme ? _self.colorScheme : colorScheme // ignore: cast_nullable_to_non_nullable
as FlexScheme,reminderMinutes: null == reminderMinutes ? _self.reminderMinutes : reminderMinutes // ignore: cast_nullable_to_non_nullable
as int,exchangeRates: null == exchangeRates ? _self.exchangeRates : exchangeRates // ignore: cast_nullable_to_non_nullable
as Map<Currency, double>,monthlyBudget: freezed == monthlyBudget ? _self.monthlyBudget : monthlyBudget // ignore: cast_nullable_to_non_nullable
as double?,appLock: null == appLock ? _self.appLock : appLock // ignore: cast_nullable_to_non_nullable
as bool,customCategories: null == customCategories ? _self.customCategories : customCategories // ignore: cast_nullable_to_non_nullable
as List<String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode theme,  Currency currency, @Uint8ListConverter()  Uint8List? profilePicture,  String? userName,  String? email,  bool? isFirstTime, @FlexSchemeConverter()  FlexScheme colorScheme,  int reminderMinutes, @ExchangeRatesConverter()  Map<Currency, double> exchangeRates, @PositiveDoubleConverter()  double? monthlyBudget,  bool appLock, @StringListConverter()  List<String> customCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsViewModel() when $default != null:
return $default(_that.theme,_that.currency,_that.profilePicture,_that.userName,_that.email,_that.isFirstTime,_that.colorScheme,_that.reminderMinutes,_that.exchangeRates,_that.monthlyBudget,_that.appLock,_that.customCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode theme,  Currency currency, @Uint8ListConverter()  Uint8List? profilePicture,  String? userName,  String? email,  bool? isFirstTime, @FlexSchemeConverter()  FlexScheme colorScheme,  int reminderMinutes, @ExchangeRatesConverter()  Map<Currency, double> exchangeRates, @PositiveDoubleConverter()  double? monthlyBudget,  bool appLock, @StringListConverter()  List<String> customCategories)  $default,) {final _that = this;
switch (_that) {
case _SettingsViewModel():
return $default(_that.theme,_that.currency,_that.profilePicture,_that.userName,_that.email,_that.isFirstTime,_that.colorScheme,_that.reminderMinutes,_that.exchangeRates,_that.monthlyBudget,_that.appLock,_that.customCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode theme,  Currency currency, @Uint8ListConverter()  Uint8List? profilePicture,  String? userName,  String? email,  bool? isFirstTime, @FlexSchemeConverter()  FlexScheme colorScheme,  int reminderMinutes, @ExchangeRatesConverter()  Map<Currency, double> exchangeRates, @PositiveDoubleConverter()  double? monthlyBudget,  bool appLock, @StringListConverter()  List<String> customCategories)?  $default,) {final _that = this;
switch (_that) {
case _SettingsViewModel() when $default != null:
return $default(_that.theme,_that.currency,_that.profilePicture,_that.userName,_that.email,_that.isFirstTime,_that.colorScheme,_that.reminderMinutes,_that.exchangeRates,_that.monthlyBudget,_that.appLock,_that.customCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsViewModel implements SettingsViewModel {
  const _SettingsViewModel({required this.theme, required this.currency, @Uint8ListConverter() this.profilePicture, this.userName, this.email, this.isFirstTime, @FlexSchemeConverter() this.colorScheme = FlexScheme.bahamaBlue, this.reminderMinutes = 12 * 60, @ExchangeRatesConverter()  Map<Currency, double> exchangeRates = const <Currency, double>{}, @PositiveDoubleConverter() this.monthlyBudget, this.appLock = false, @StringListConverter()  List<String> customCategories = const <String>[]}): _exchangeRates = exchangeRates,_customCategories = customCategories;
  factory _SettingsViewModel.fromJson(Map<String, dynamic> json) => _$SettingsViewModelFromJson(json);

@override final  ThemeMode theme;
@override final  Currency currency;
@override@Uint8ListConverter() final  Uint8List? profilePicture;
@override final  String? userName;
@override final  String? email;
@override final  bool? isFirstTime;
@override@JsonKey()@FlexSchemeConverter() final  FlexScheme colorScheme;
/// Reminder time of day, in minutes after midnight.
@override@JsonKey() final  int reminderMinutes;
/// User-entered rates: how many units of [currency] one unit of each
/// other currency is worth. Never fetched, so the app stays offline.
 final  Map<Currency, double> _exchangeRates;
/// User-entered rates: how many units of [currency] one unit of each
/// other currency is worth. Never fetched, so the app stays offline.
@override@JsonKey()@ExchangeRatesConverter() Map<Currency, double> get exchangeRates {
  if (_exchangeRates is EqualUnmodifiableMapView) return _exchangeRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_exchangeRates);
}

/// Monthly spending limit in the main currency; null = no budget.
@override@PositiveDoubleConverter() final  double? monthlyBudget;
/// Ask for the device lock / biometrics to open the app.
@override@JsonKey() final  bool appLock;
/// User-added categories, after the built-in ones.
 final  List<String> _customCategories;
/// User-added categories, after the built-in ones.
@override@JsonKey()@StringListConverter() List<String> get customCategories {
  if (_customCategories is EqualUnmodifiableListView) return _customCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customCategories);
}


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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsViewModel&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.profilePicture, profilePicture)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.email, email) || other.email == email)&&(identical(other.isFirstTime, isFirstTime) || other.isFirstTime == isFirstTime)&&(identical(other.colorScheme, colorScheme) || other.colorScheme == colorScheme)&&(identical(other.reminderMinutes, reminderMinutes) || other.reminderMinutes == reminderMinutes)&&const DeepCollectionEquality().equals(other.exchangeRates, _exchangeRates)&&(identical(other.monthlyBudget, monthlyBudget) || other.monthlyBudget == monthlyBudget)&&(identical(other.appLock, appLock) || other.appLock == appLock)&&const DeepCollectionEquality().equals(other.customCategories, _customCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,theme,currency,const DeepCollectionEquality().hash(profilePicture),userName,email,isFirstTime,colorScheme,reminderMinutes,const DeepCollectionEquality().hash(_exchangeRates),monthlyBudget,appLock,const DeepCollectionEquality().hash(_customCategories));
}

@override
String toString() {
    return 'SettingsViewModel(theme: $theme, currency: $currency, profilePicture: $profilePicture, userName: $userName, email: $email, isFirstTime: $isFirstTime, colorScheme: $colorScheme, reminderMinutes: $reminderMinutes, exchangeRates: $exchangeRates, monthlyBudget: $monthlyBudget, appLock: $appLock, customCategories: $customCategories)';
}


}

/// @nodoc
abstract mixin class _$SettingsViewModelCopyWith<$Res> implements $SettingsViewModelCopyWith<$Res> {
  factory _$SettingsViewModelCopyWith(_SettingsViewModel value, $Res Function(_SettingsViewModel) _then) = __$SettingsViewModelCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode theme, Currency currency,@Uint8ListConverter() Uint8List? profilePicture, String? userName, String? email, bool? isFirstTime,@FlexSchemeConverter() FlexScheme colorScheme, int reminderMinutes,@ExchangeRatesConverter() Map<Currency, double> exchangeRates,@PositiveDoubleConverter() double? monthlyBudget, bool appLock,@StringListConverter() List<String> customCategories
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
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? currency = null,Object? profilePicture = freezed,Object? userName = freezed,Object? email = freezed,Object? isFirstTime = freezed,Object? colorScheme = null,Object? reminderMinutes = null,Object? exchangeRates = null,Object? monthlyBudget = freezed,Object? appLock = null,Object? customCategories = null,}) {
  return _then(_SettingsViewModel(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeMode,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as Uint8List?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,isFirstTime: freezed == isFirstTime ? _self.isFirstTime : isFirstTime // ignore: cast_nullable_to_non_nullable
as bool?,colorScheme: null == colorScheme ? _self.colorScheme : colorScheme // ignore: cast_nullable_to_non_nullable
as FlexScheme,reminderMinutes: null == reminderMinutes ? _self.reminderMinutes : reminderMinutes // ignore: cast_nullable_to_non_nullable
as int,exchangeRates: null == exchangeRates ? _self._exchangeRates : exchangeRates // ignore: cast_nullable_to_non_nullable
as Map<Currency, double>,monthlyBudget: freezed == monthlyBudget ? _self.monthlyBudget : monthlyBudget // ignore: cast_nullable_to_non_nullable
as double?,appLock: null == appLock ? _self.appLock : appLock // ignore: cast_nullable_to_non_nullable
as bool,customCategories: null == customCategories ? _self._customCategories : customCategories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
