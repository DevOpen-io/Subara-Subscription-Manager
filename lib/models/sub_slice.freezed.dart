// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sub_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubSlice {

/// Stable identity. Empty only for rows saved before ids existed;
/// `SubsController` fills it on load.
 String get id; Brand? get brand; String get name; double get amount; int get color; DateTime get startDate;@JsonKey(unknownEnumValue: Frequency.monthly) Frequency get frequency; String? get category;@JsonKey(unknownEnumValue: ReminderMode.both) ReminderMode get reminderMode; String? get cardLastFour;/// Free-text payment method ("Credit card", "PayPal"), grouped on in
/// analytics together with [cardLastFour].
 String? get paymentMethod;@JsonKey(unknownEnumValue: SubStatus.active) SubStatus get status; String? get note; DateTime? get trialEndDate;/// Charges every [interval] periods of [frequency] (e.g. 3 x monthly).
/// Use [period] when computing; it never returns less than 1.
 int get interval;/// How many days before a charge the "due soon" reminder fires.
 int get remindDaysBefore;/// When the subscription was cancelled in the app; null if unknown
/// (cancelled before this field existed) or not cancelled.
 DateTime? get cancelledAt;/// User-entered link to manage or cancel the subscription.
 String? get manageUrl;/// Currency this subscription is billed in; null means the main
/// currency from settings. Unknown codes (newer app) fall back to null.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) Currency? get currency;/// Earlier prices, oldest first. Recorded by `SubsController.updateSlice`.
@PriceHistoryConverter() List<PriceChange> get priceHistory;/// How many people split the cost, including you. Use [people].
 int get sharedWith;/// False for subscriptions paid by hand (rent, invoices): each charge is
/// "unpaid" until marked in [paidCharges].
 bool get autoRenew;/// Charge dates (midnight) marked as paid, oldest first; the most recent
/// [maxPaidCharges] are kept.
@PaidChargesConverter() List<DateTime> get paidCharges;/// No reminders for this subscription before this time (snoozed).
 DateTime? get remindersSnoozedUntil;
/// Create a copy of SubSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubSliceCopyWith<SubSlice> get copyWith => _$SubSliceCopyWithImpl<SubSlice>(this as SubSlice, _$identity);

  /// Serializes this SubSlice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubSlice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubSlice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.reminderMode, _this.reminderMode) || other.reminderMode == _this.reminderMode)&&(identical(other.cardLastFour, _this.cardLastFour) || other.cardLastFour == _this.cardLastFour)&&(identical(other.paymentMethod, _this.paymentMethod) || other.paymentMethod == _this.paymentMethod)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.trialEndDate, _this.trialEndDate) || other.trialEndDate == _this.trialEndDate)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&(identical(other.remindDaysBefore, _this.remindDaysBefore) || other.remindDaysBefore == _this.remindDaysBefore)&&(identical(other.cancelledAt, _this.cancelledAt) || other.cancelledAt == _this.cancelledAt)&&(identical(other.manageUrl, _this.manageUrl) || other.manageUrl == _this.manageUrl)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&const DeepCollectionEquality().equals(other.priceHistory, _this.priceHistory)&&(identical(other.sharedWith, _this.sharedWith) || other.sharedWith == _this.sharedWith)&&(identical(other.autoRenew, _this.autoRenew) || other.autoRenew == _this.autoRenew)&&const DeepCollectionEquality().equals(other.paidCharges, _this.paidCharges)&&(identical(other.remindersSnoozedUntil, _this.remindersSnoozedUntil) || other.remindersSnoozedUntil == _this.remindersSnoozedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubSlice;
  return Object.hashAll([runtimeType,_this.id,_this.brand,_this.name,_this.amount,_this.color,_this.startDate,_this.frequency,_this.category,_this.reminderMode,_this.cardLastFour,_this.paymentMethod,_this.status,_this.note,_this.trialEndDate,_this.interval,_this.remindDaysBefore,_this.cancelledAt,_this.manageUrl,_this.currency,const DeepCollectionEquality().hash(_this.priceHistory),_this.sharedWith,_this.autoRenew,const DeepCollectionEquality().hash(_this.paidCharges),_this.remindersSnoozedUntil]);
}

@override
String toString() {
  final _this = this as SubSlice;
  return 'SubSlice(id: ${_this.id}, brand: ${_this.brand}, name: ${_this.name}, amount: ${_this.amount}, color: ${_this.color}, startDate: ${_this.startDate}, frequency: ${_this.frequency}, category: ${_this.category}, reminderMode: ${_this.reminderMode}, cardLastFour: ${_this.cardLastFour}, paymentMethod: ${_this.paymentMethod}, status: ${_this.status}, note: ${_this.note}, trialEndDate: ${_this.trialEndDate}, interval: ${_this.interval}, remindDaysBefore: ${_this.remindDaysBefore}, cancelledAt: ${_this.cancelledAt}, manageUrl: ${_this.manageUrl}, currency: ${_this.currency}, priceHistory: ${_this.priceHistory}, sharedWith: ${_this.sharedWith}, autoRenew: ${_this.autoRenew}, paidCharges: ${_this.paidCharges}, remindersSnoozedUntil: ${_this.remindersSnoozedUntil})';
}


}

/// @nodoc
abstract mixin class $SubSliceCopyWith<$Res>  {
  factory $SubSliceCopyWith(SubSlice value, $Res Function(SubSlice) _then) = _$SubSliceCopyWithImpl;
@useResult
$Res call({
 String id, Brand? brand, String name, double amount, int color, DateTime startDate,@JsonKey(unknownEnumValue: Frequency.monthly) Frequency frequency, String? category,@JsonKey(unknownEnumValue: ReminderMode.both) ReminderMode reminderMode, String? cardLastFour, String? paymentMethod,@JsonKey(unknownEnumValue: SubStatus.active) SubStatus status, String? note, DateTime? trialEndDate, int interval, int remindDaysBefore, DateTime? cancelledAt, String? manageUrl,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) Currency? currency,@PriceHistoryConverter() List<PriceChange> priceHistory, int sharedWith, bool autoRenew,@PaidChargesConverter() List<DateTime> paidCharges, DateTime? remindersSnoozedUntil
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? brand = freezed,Object? name = null,Object? amount = null,Object? color = null,Object? startDate = null,Object? frequency = null,Object? category = freezed,Object? reminderMode = null,Object? cardLastFour = freezed,Object? paymentMethod = freezed,Object? status = null,Object? note = freezed,Object? trialEndDate = freezed,Object? interval = null,Object? remindDaysBefore = null,Object? cancelledAt = freezed,Object? manageUrl = freezed,Object? currency = freezed,Object? priceHistory = null,Object? sharedWith = null,Object? autoRenew = null,Object? paidCharges = null,Object? remindersSnoozedUntil = freezed,}) {
  return _then(SubSlice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as Brand?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,reminderMode: null == reminderMode ? _self.reminderMode : reminderMode // ignore: cast_nullable_to_non_nullable
as ReminderMode,cardLastFour: freezed == cardLastFour ? _self.cardLastFour : cardLastFour // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubStatus,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,trialEndDate: freezed == trialEndDate ? _self.trialEndDate : trialEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,remindDaysBefore: null == remindDaysBefore ? _self.remindDaysBefore : remindDaysBefore // ignore: cast_nullable_to_non_nullable
as int,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,manageUrl: freezed == manageUrl ? _self.manageUrl : manageUrl // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency?,priceHistory: null == priceHistory ? _self.priceHistory : priceHistory // ignore: cast_nullable_to_non_nullable
as List<PriceChange>,sharedWith: null == sharedWith ? _self.sharedWith : sharedWith // ignore: cast_nullable_to_non_nullable
as int,autoRenew: null == autoRenew ? _self.autoRenew : autoRenew // ignore: cast_nullable_to_non_nullable
as bool,paidCharges: null == paidCharges ? _self.paidCharges : paidCharges // ignore: cast_nullable_to_non_nullable
as List<DateTime>,remindersSnoozedUntil: freezed == remindersSnoozedUntil ? _self.remindersSnoozedUntil : remindersSnoozedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Brand? brand,  String name,  double amount,  int color,  DateTime startDate, @JsonKey(unknownEnumValue: Frequency.monthly)  Frequency frequency,  String? category, @JsonKey(unknownEnumValue: ReminderMode.both)  ReminderMode reminderMode,  String? cardLastFour,  String? paymentMethod, @JsonKey(unknownEnumValue: SubStatus.active)  SubStatus status,  String? note,  DateTime? trialEndDate,  int interval,  int remindDaysBefore,  DateTime? cancelledAt,  String? manageUrl, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  Currency? currency, @PriceHistoryConverter()  List<PriceChange> priceHistory,  int sharedWith,  bool autoRenew, @PaidChargesConverter()  List<DateTime> paidCharges,  DateTime? remindersSnoozedUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubSlice() when $default != null:
return $default(_that.id,_that.brand,_that.name,_that.amount,_that.color,_that.startDate,_that.frequency,_that.category,_that.reminderMode,_that.cardLastFour,_that.paymentMethod,_that.status,_that.note,_that.trialEndDate,_that.interval,_that.remindDaysBefore,_that.cancelledAt,_that.manageUrl,_that.currency,_that.priceHistory,_that.sharedWith,_that.autoRenew,_that.paidCharges,_that.remindersSnoozedUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Brand? brand,  String name,  double amount,  int color,  DateTime startDate, @JsonKey(unknownEnumValue: Frequency.monthly)  Frequency frequency,  String? category, @JsonKey(unknownEnumValue: ReminderMode.both)  ReminderMode reminderMode,  String? cardLastFour,  String? paymentMethod, @JsonKey(unknownEnumValue: SubStatus.active)  SubStatus status,  String? note,  DateTime? trialEndDate,  int interval,  int remindDaysBefore,  DateTime? cancelledAt,  String? manageUrl, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  Currency? currency, @PriceHistoryConverter()  List<PriceChange> priceHistory,  int sharedWith,  bool autoRenew, @PaidChargesConverter()  List<DateTime> paidCharges,  DateTime? remindersSnoozedUntil)  $default,) {final _that = this;
switch (_that) {
case _SubSlice():
return $default(_that.id,_that.brand,_that.name,_that.amount,_that.color,_that.startDate,_that.frequency,_that.category,_that.reminderMode,_that.cardLastFour,_that.paymentMethod,_that.status,_that.note,_that.trialEndDate,_that.interval,_that.remindDaysBefore,_that.cancelledAt,_that.manageUrl,_that.currency,_that.priceHistory,_that.sharedWith,_that.autoRenew,_that.paidCharges,_that.remindersSnoozedUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Brand? brand,  String name,  double amount,  int color,  DateTime startDate, @JsonKey(unknownEnumValue: Frequency.monthly)  Frequency frequency,  String? category, @JsonKey(unknownEnumValue: ReminderMode.both)  ReminderMode reminderMode,  String? cardLastFour,  String? paymentMethod, @JsonKey(unknownEnumValue: SubStatus.active)  SubStatus status,  String? note,  DateTime? trialEndDate,  int interval,  int remindDaysBefore,  DateTime? cancelledAt,  String? manageUrl, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  Currency? currency, @PriceHistoryConverter()  List<PriceChange> priceHistory,  int sharedWith,  bool autoRenew, @PaidChargesConverter()  List<DateTime> paidCharges,  DateTime? remindersSnoozedUntil)?  $default,) {final _that = this;
switch (_that) {
case _SubSlice() when $default != null:
return $default(_that.id,_that.brand,_that.name,_that.amount,_that.color,_that.startDate,_that.frequency,_that.category,_that.reminderMode,_that.cardLastFour,_that.paymentMethod,_that.status,_that.note,_that.trialEndDate,_that.interval,_that.remindDaysBefore,_that.cancelledAt,_that.manageUrl,_that.currency,_that.priceHistory,_that.sharedWith,_that.autoRenew,_that.paidCharges,_that.remindersSnoozedUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubSlice extends SubSlice {
  const _SubSlice({this.id = '', this.brand, required this.name, required this.amount, required this.color, required this.startDate, @JsonKey(unknownEnumValue: Frequency.monthly) this.frequency = Frequency.monthly, this.category, @JsonKey(unknownEnumValue: ReminderMode.both) this.reminderMode = ReminderMode.both, this.cardLastFour, this.paymentMethod, @JsonKey(unknownEnumValue: SubStatus.active) this.status = SubStatus.active, this.note, this.trialEndDate, this.interval = 1, this.remindDaysBefore = 1, this.cancelledAt, this.manageUrl, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.currency, @PriceHistoryConverter()  List<PriceChange> priceHistory = const <PriceChange>[], this.sharedWith = 1, this.autoRenew = true, @PaidChargesConverter()  List<DateTime> paidCharges = const <DateTime>[], this.remindersSnoozedUntil}): _priceHistory = priceHistory,_paidCharges = paidCharges,super._();
  factory _SubSlice.fromJson(Map<String, dynamic> json) => _$SubSliceFromJson(json);

/// Stable identity. Empty only for rows saved before ids existed;
/// `SubsController` fills it on load.
@override@JsonKey() final  String id;
@override final  Brand? brand;
@override final  String name;
@override final  double amount;
@override final  int color;
@override final  DateTime startDate;
@override@JsonKey(unknownEnumValue: Frequency.monthly) final  Frequency frequency;
@override final  String? category;
@override@JsonKey(unknownEnumValue: ReminderMode.both) final  ReminderMode reminderMode;
@override final  String? cardLastFour;
/// Free-text payment method ("Credit card", "PayPal"), grouped on in
/// analytics together with [cardLastFour].
@override final  String? paymentMethod;
@override@JsonKey(unknownEnumValue: SubStatus.active) final  SubStatus status;
@override final  String? note;
@override final  DateTime? trialEndDate;
/// Charges every [interval] periods of [frequency] (e.g. 3 x monthly).
/// Use [period] when computing; it never returns less than 1.
@override@JsonKey() final  int interval;
/// How many days before a charge the "due soon" reminder fires.
@override@JsonKey() final  int remindDaysBefore;
/// When the subscription was cancelled in the app; null if unknown
/// (cancelled before this field existed) or not cancelled.
@override final  DateTime? cancelledAt;
/// User-entered link to manage or cancel the subscription.
@override final  String? manageUrl;
/// Currency this subscription is billed in; null means the main
/// currency from settings. Unknown codes (newer app) fall back to null.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  Currency? currency;
/// Earlier prices, oldest first. Recorded by `SubsController.updateSlice`.
 final  List<PriceChange> _priceHistory;
/// Earlier prices, oldest first. Recorded by `SubsController.updateSlice`.
@override@JsonKey()@PriceHistoryConverter() List<PriceChange> get priceHistory {
  if (_priceHistory is EqualUnmodifiableListView) return _priceHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_priceHistory);
}

/// How many people split the cost, including you. Use [people].
@override@JsonKey() final  int sharedWith;
/// False for subscriptions paid by hand (rent, invoices): each charge is
/// "unpaid" until marked in [paidCharges].
@override@JsonKey() final  bool autoRenew;
/// Charge dates (midnight) marked as paid, oldest first; the most recent
/// [maxPaidCharges] are kept.
 final  List<DateTime> _paidCharges;
/// Charge dates (midnight) marked as paid, oldest first; the most recent
/// [maxPaidCharges] are kept.
@override@JsonKey()@PaidChargesConverter() List<DateTime> get paidCharges {
  if (_paidCharges is EqualUnmodifiableListView) return _paidCharges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paidCharges);
}

/// No reminders for this subscription before this time (snoozed).
@override final  DateTime? remindersSnoozedUntil;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubSlice&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.category, category) || other.category == category)&&(identical(other.reminderMode, reminderMode) || other.reminderMode == reminderMode)&&(identical(other.cardLastFour, cardLastFour) || other.cardLastFour == cardLastFour)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.trialEndDate, trialEndDate) || other.trialEndDate == trialEndDate)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.remindDaysBefore, remindDaysBefore) || other.remindDaysBefore == remindDaysBefore)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.manageUrl, manageUrl) || other.manageUrl == manageUrl)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.priceHistory, _priceHistory)&&(identical(other.sharedWith, sharedWith) || other.sharedWith == sharedWith)&&(identical(other.autoRenew, autoRenew) || other.autoRenew == autoRenew)&&const DeepCollectionEquality().equals(other.paidCharges, _paidCharges)&&(identical(other.remindersSnoozedUntil, remindersSnoozedUntil) || other.remindersSnoozedUntil == remindersSnoozedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,brand,name,amount,color,startDate,frequency,category,reminderMode,cardLastFour,paymentMethod,status,note,trialEndDate,interval,remindDaysBefore,cancelledAt,manageUrl,currency,const DeepCollectionEquality().hash(_priceHistory),sharedWith,autoRenew,const DeepCollectionEquality().hash(_paidCharges),remindersSnoozedUntil]);
}

@override
String toString() {
    return 'SubSlice(id: $id, brand: $brand, name: $name, amount: $amount, color: $color, startDate: $startDate, frequency: $frequency, category: $category, reminderMode: $reminderMode, cardLastFour: $cardLastFour, paymentMethod: $paymentMethod, status: $status, note: $note, trialEndDate: $trialEndDate, interval: $interval, remindDaysBefore: $remindDaysBefore, cancelledAt: $cancelledAt, manageUrl: $manageUrl, currency: $currency, priceHistory: $priceHistory, sharedWith: $sharedWith, autoRenew: $autoRenew, paidCharges: $paidCharges, remindersSnoozedUntil: $remindersSnoozedUntil)';
}


}

/// @nodoc
abstract mixin class _$SubSliceCopyWith<$Res> implements $SubSliceCopyWith<$Res> {
  factory _$SubSliceCopyWith(_SubSlice value, $Res Function(_SubSlice) _then) = __$SubSliceCopyWithImpl;
@override @useResult
$Res call({
 String id, Brand? brand, String name, double amount, int color, DateTime startDate,@JsonKey(unknownEnumValue: Frequency.monthly) Frequency frequency, String? category,@JsonKey(unknownEnumValue: ReminderMode.both) ReminderMode reminderMode, String? cardLastFour, String? paymentMethod,@JsonKey(unknownEnumValue: SubStatus.active) SubStatus status, String? note, DateTime? trialEndDate, int interval, int remindDaysBefore, DateTime? cancelledAt, String? manageUrl,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) Currency? currency,@PriceHistoryConverter() List<PriceChange> priceHistory, int sharedWith, bool autoRenew,@PaidChargesConverter() List<DateTime> paidCharges, DateTime? remindersSnoozedUntil
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? brand = freezed,Object? name = null,Object? amount = null,Object? color = null,Object? startDate = null,Object? frequency = null,Object? category = freezed,Object? reminderMode = null,Object? cardLastFour = freezed,Object? paymentMethod = freezed,Object? status = null,Object? note = freezed,Object? trialEndDate = freezed,Object? interval = null,Object? remindDaysBefore = null,Object? cancelledAt = freezed,Object? manageUrl = freezed,Object? currency = freezed,Object? priceHistory = null,Object? sharedWith = null,Object? autoRenew = null,Object? paidCharges = null,Object? remindersSnoozedUntil = freezed,}) {
  return _then(_SubSlice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as Brand?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,reminderMode: null == reminderMode ? _self.reminderMode : reminderMode // ignore: cast_nullable_to_non_nullable
as ReminderMode,cardLastFour: freezed == cardLastFour ? _self.cardLastFour : cardLastFour // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubStatus,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,trialEndDate: freezed == trialEndDate ? _self.trialEndDate : trialEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,remindDaysBefore: null == remindDaysBefore ? _self.remindDaysBefore : remindDaysBefore // ignore: cast_nullable_to_non_nullable
as int,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,manageUrl: freezed == manageUrl ? _self.manageUrl : manageUrl // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency?,priceHistory: null == priceHistory ? _self._priceHistory : priceHistory // ignore: cast_nullable_to_non_nullable
as List<PriceChange>,sharedWith: null == sharedWith ? _self.sharedWith : sharedWith // ignore: cast_nullable_to_non_nullable
as int,autoRenew: null == autoRenew ? _self.autoRenew : autoRenew // ignore: cast_nullable_to_non_nullable
as bool,paidCharges: null == paidCharges ? _self._paidCharges : paidCharges // ignore: cast_nullable_to_non_nullable
as List<DateTime>,remindersSnoozedUntil: freezed == remindersSnoozedUntil ? _self.remindersSnoozedUntil : remindersSnoozedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
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
