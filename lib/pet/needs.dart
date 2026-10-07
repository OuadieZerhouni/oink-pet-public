import 'package:flutter/foundation.dart';

/// The four things a piglet needs. Each is 0 (empty) … 100 (full).
enum Need { tummy, clean, fun, energy }

/// Per-hour change rates. Negative = drains over time.
///
/// Tunable from remote config through [DecayRates.scaled], never invented
/// there: the defaults below are a complete, shippable balance on their own.
@immutable
class DecayRates {
  const DecayRates({
    this.tummy = -6,
    this.clean = -3,
    this.fun = -5,
    this.energyAwake = -4,
    this.energyAsleep = 15,
  });

  final double tummy;
  final double clean;
  final double fun;
  final double energyAwake;
  final double energyAsleep;

  static const standard = DecayRates();

  /// Multiplies every drain by [drain] (0.2…3) and the sleep refill by [rest].
  DecayRates scaled({double drain = 1, double rest = 1}) {
    final d = drain.clamp(0.2, 3.0);
    final r = rest.clamp(0.2, 3.0);
    return DecayRates(
      tummy: tummy * d,
      clean: clean * d,
      fun: fun * d,
      energyAwake: energyAwake * d,
      energyAsleep: energyAsleep * r,
    );
  }
}

/// Immutable snapshot of the four needs.
@immutable
class Needs {
  const Needs({this.tummy = 80, this.clean = 90, this.fun = 75, this.energy = 85});

  /// A pet never fully empties: below this, decay stops. A neglected piglet
  /// is sad and dirty, never "dead" — this is a comfort app.
  static const double floor = 5;
  static const double max = 100;

  /// Below this a need counts as urgent (sad face, speech bubble, meter pulse).
  static const double low = 25;

  final double tummy;
  final double clean;
  final double fun;
  final double energy;

  double operator [](Need n) => switch (n) {
    Need.tummy => tummy,
    Need.clean => clean,
    Need.fun => fun,
    Need.energy => energy,
  };

  Needs copyWith({double? tummy, double? clean, double? fun, double? energy}) => Needs(
    tummy: _clamp(tummy ?? this.tummy),
    clean: _clamp(clean ?? this.clean),
    fun: _clamp(fun ?? this.fun),
    energy: _clamp(energy ?? this.energy),
  );

  Needs withNeed(Need n, double v) => switch (n) {
    Need.tummy => copyWith(tummy: v),
    Need.clean => copyWith(clean: v),
    Need.fun => copyWith(fun: v),
    Need.energy => copyWith(energy: v),
  };

  Needs add(Need n, double delta) => withNeed(n, this[n] + delta);

  /// Applies [hours] of real time. Drains stop at [floor] (never lower a value
  /// that is already below it), refills stop at [max].
  Needs elapse(double hours, {required bool asleep, DecayRates rates = DecayRates.standard}) {
    if (hours <= 0 || hours.isNaN) return this;
    double drain(double v, double perHour) {
      if (perHour >= 0) return _clamp(v + perHour * hours);
      if (v <= floor) return v;
      return (v + perHour * hours).clamp(floor, max);
    }

    return Needs(
      tummy: drain(tummy, rates.tummy),
      clean: drain(clean, rates.clean),
      fun: drain(fun, rates.fun),
      energy: drain(energy, asleep ? rates.energyAsleep : rates.energyAwake),
    );
  }

  /// The most urgent need, or null when everything is fine.
  Need? get mostUrgent {
    Need? worst;
    var worstValue = low;
    for (final n in Need.values) {
      if (this[n] < worstValue) {
        worst = n;
        worstValue = this[n];
      }
    }
    return worst;
  }

  /// 0…1 overall wellbeing, weighted toward the lowest need so one neglected
  /// need is visible even when the others are full.
  double get wellbeing {
    final vals = Need.values.map((n) => this[n]).toList()..sort();
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    return ((avg * 0.6 + vals.first * 0.4) / max).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {'tummy': tummy, 'clean': clean, 'fun': fun, 'energy': energy};

  factory Needs.fromJson(Object? j) {
    if (j is! Map) return const Needs();
    double read(String k, double d) {
      final v = j[k];
      return v is num && v.isFinite ? _clamp(v.toDouble()) : d;
    }

    const d = Needs();
    return Needs(
      tummy: read('tummy', d.tummy),
      clean: read('clean', d.clean),
      fun: read('fun', d.fun),
      energy: read('energy', d.energy),
    );
  }

  static double _clamp(double v) => v.isNaN ? floor : v.clamp(0.0, max);

  @override
  bool operator ==(Object other) =>
      other is Needs && other.tummy == tummy && other.clean == clean && other.fun == fun && other.energy == energy;

  @override
  int get hashCode => Object.hash(tummy, clean, fun, energy);

  @override
  String toString() =>
      'Needs(tummy ${tummy.toStringAsFixed(1)}, clean ${clean.toStringAsFixed(1)}, fun ${fun.toStringAsFixed(1)}, energy ${energy.toStringAsFixed(1)})';
}
