// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DailyMetricsTable extends DailyMetrics
    with TableInfo<$DailyMetricsTable, DailyMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chargeMeta = const VerificationMeta('charge');
  @override
  late final GeneratedColumn<double> charge = GeneratedColumn<double>(
    'charge',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<double> effort = GeneratedColumn<double>(
    'effort',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dayStrainMeta = const VerificationMeta(
    'dayStrain',
  );
  @override
  late final GeneratedColumn<double> dayStrain = GeneratedColumn<double>(
    'day_strain',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restMeta = const VerificationMeta('rest');
  @override
  late final GeneratedColumn<double> rest = GeneratedColumn<double>(
    'rest',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stressMeta = const VerificationMeta('stress');
  @override
  late final GeneratedColumn<double> stress = GeneratedColumn<double>(
    'stress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hrvMeta = const VerificationMeta('hrv');
  @override
  late final GeneratedColumn<double> hrv = GeneratedColumn<double>(
    'hrv',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rhrMeta = const VerificationMeta('rhr');
  @override
  late final GeneratedColumn<double> rhr = GeneratedColumn<double>(
    'rhr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _respiratoryRateMeta = const VerificationMeta(
    'respiratoryRate',
  );
  @override
  late final GeneratedColumn<double> respiratoryRate = GeneratedColumn<double>(
    'respiratory_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skinTempDeltaMeta = const VerificationMeta(
    'skinTempDelta',
  );
  @override
  late final GeneratedColumn<double> skinTempDelta = GeneratedColumn<double>(
    'skin_temp_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _spo2Meta = const VerificationMeta('spo2');
  @override
  late final GeneratedColumn<double> spo2 = GeneratedColumn<double>(
    'spo2',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kilojoulesMeta = const VerificationMeta(
    'kilojoules',
  );
  @override
  late final GeneratedColumn<double> kilojoules = GeneratedColumn<double>(
    'kilojoules',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrZone13SecMeta = const VerificationMeta(
    'hrZone13Sec',
  );
  @override
  late final GeneratedColumn<int> hrZone13Sec = GeneratedColumn<int>(
    'hr_zone13_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrZone45SecMeta = const VerificationMeta(
    'hrZone45Sec',
  );
  @override
  late final GeneratedColumn<int> hrZone45Sec = GeneratedColumn<int>(
    'hr_zone45_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strengthActivitySecMeta =
      const VerificationMeta('strengthActivitySec');
  @override
  late final GeneratedColumn<int> strengthActivitySec = GeneratedColumn<int>(
    'strength_activity_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrvBaselineMeta = const VerificationMeta(
    'hrvBaseline',
  );
  @override
  late final GeneratedColumn<double> hrvBaseline = GeneratedColumn<double>(
    'hrv_baseline',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rhrBaselineMeta = const VerificationMeta(
    'rhrBaseline',
  );
  @override
  late final GeneratedColumn<double> rhrBaseline = GeneratedColumn<double>(
    'rhr_baseline',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _respRateBaselineMeta = const VerificationMeta(
    'respRateBaseline',
  );
  @override
  late final GeneratedColumn<double> respRateBaseline = GeneratedColumn<double>(
    'resp_rate_baseline',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsBaselineMeta = const VerificationMeta(
    'stepsBaseline',
  );
  @override
  late final GeneratedColumn<int> stepsBaseline = GeneratedColumn<int>(
    'steps_baseline',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fitnessAgeMeta = const VerificationMeta(
    'fitnessAge',
  );
  @override
  late final GeneratedColumn<int> fitnessAge = GeneratedColumn<int>(
    'fitness_age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vitalityMeta = const VerificationMeta(
    'vitality',
  );
  @override
  late final GeneratedColumn<int> vitality = GeneratedColumn<int>(
    'vitality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hydrationMeta = const VerificationMeta(
    'hydration',
  );
  @override
  late final GeneratedColumn<double> hydration = GeneratedColumn<double>(
    'hydration',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    cycleId,
    charge,
    effort,
    dayStrain,
    rest,
    stress,
    hrv,
    rhr,
    respiratoryRate,
    skinTempDelta,
    spo2,
    steps,
    calories,
    kilojoules,
    hrZone13Sec,
    hrZone45Sec,
    strengthActivitySec,
    hrvBaseline,
    rhrBaseline,
    respRateBaseline,
    stepsBaseline,
    fitnessAge,
    vitality,
    hydration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyMetric> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    }
    if (data.containsKey('charge')) {
      context.handle(
        _chargeMeta,
        charge.isAcceptableOrUnknown(data['charge']!, _chargeMeta),
      );
    }
    if (data.containsKey('effort')) {
      context.handle(
        _effortMeta,
        effort.isAcceptableOrUnknown(data['effort']!, _effortMeta),
      );
    }
    if (data.containsKey('day_strain')) {
      context.handle(
        _dayStrainMeta,
        dayStrain.isAcceptableOrUnknown(data['day_strain']!, _dayStrainMeta),
      );
    }
    if (data.containsKey('rest')) {
      context.handle(
        _restMeta,
        rest.isAcceptableOrUnknown(data['rest']!, _restMeta),
      );
    }
    if (data.containsKey('stress')) {
      context.handle(
        _stressMeta,
        stress.isAcceptableOrUnknown(data['stress']!, _stressMeta),
      );
    }
    if (data.containsKey('hrv')) {
      context.handle(
        _hrvMeta,
        hrv.isAcceptableOrUnknown(data['hrv']!, _hrvMeta),
      );
    }
    if (data.containsKey('rhr')) {
      context.handle(
        _rhrMeta,
        rhr.isAcceptableOrUnknown(data['rhr']!, _rhrMeta),
      );
    }
    if (data.containsKey('respiratory_rate')) {
      context.handle(
        _respiratoryRateMeta,
        respiratoryRate.isAcceptableOrUnknown(
          data['respiratory_rate']!,
          _respiratoryRateMeta,
        ),
      );
    }
    if (data.containsKey('skin_temp_delta')) {
      context.handle(
        _skinTempDeltaMeta,
        skinTempDelta.isAcceptableOrUnknown(
          data['skin_temp_delta']!,
          _skinTempDeltaMeta,
        ),
      );
    }
    if (data.containsKey('spo2')) {
      context.handle(
        _spo2Meta,
        spo2.isAcceptableOrUnknown(data['spo2']!, _spo2Meta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('kilojoules')) {
      context.handle(
        _kilojoulesMeta,
        kilojoules.isAcceptableOrUnknown(data['kilojoules']!, _kilojoulesMeta),
      );
    }
    if (data.containsKey('hr_zone13_sec')) {
      context.handle(
        _hrZone13SecMeta,
        hrZone13Sec.isAcceptableOrUnknown(
          data['hr_zone13_sec']!,
          _hrZone13SecMeta,
        ),
      );
    }
    if (data.containsKey('hr_zone45_sec')) {
      context.handle(
        _hrZone45SecMeta,
        hrZone45Sec.isAcceptableOrUnknown(
          data['hr_zone45_sec']!,
          _hrZone45SecMeta,
        ),
      );
    }
    if (data.containsKey('strength_activity_sec')) {
      context.handle(
        _strengthActivitySecMeta,
        strengthActivitySec.isAcceptableOrUnknown(
          data['strength_activity_sec']!,
          _strengthActivitySecMeta,
        ),
      );
    }
    if (data.containsKey('hrv_baseline')) {
      context.handle(
        _hrvBaselineMeta,
        hrvBaseline.isAcceptableOrUnknown(
          data['hrv_baseline']!,
          _hrvBaselineMeta,
        ),
      );
    }
    if (data.containsKey('rhr_baseline')) {
      context.handle(
        _rhrBaselineMeta,
        rhrBaseline.isAcceptableOrUnknown(
          data['rhr_baseline']!,
          _rhrBaselineMeta,
        ),
      );
    }
    if (data.containsKey('resp_rate_baseline')) {
      context.handle(
        _respRateBaselineMeta,
        respRateBaseline.isAcceptableOrUnknown(
          data['resp_rate_baseline']!,
          _respRateBaselineMeta,
        ),
      );
    }
    if (data.containsKey('steps_baseline')) {
      context.handle(
        _stepsBaselineMeta,
        stepsBaseline.isAcceptableOrUnknown(
          data['steps_baseline']!,
          _stepsBaselineMeta,
        ),
      );
    }
    if (data.containsKey('fitness_age')) {
      context.handle(
        _fitnessAgeMeta,
        fitnessAge.isAcceptableOrUnknown(data['fitness_age']!, _fitnessAgeMeta),
      );
    }
    if (data.containsKey('vitality')) {
      context.handle(
        _vitalityMeta,
        vitality.isAcceptableOrUnknown(data['vitality']!, _vitalityMeta),
      );
    }
    if (data.containsKey('hydration')) {
      context.handle(
        _hydrationMeta,
        hydration.isAcceptableOrUnknown(data['hydration']!, _hydrationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DailyMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyMetric(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      ),
      charge: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}charge'],
      )!,
      effort: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effort'],
      )!,
      dayStrain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}day_strain'],
      ),
      rest: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rest'],
      )!,
      stress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stress'],
      )!,
      hrv: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hrv'],
      )!,
      rhr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rhr'],
      )!,
      respiratoryRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}respiratory_rate'],
      )!,
      skinTempDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}skin_temp_delta'],
      )!,
      spo2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}spo2'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      kilojoules: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kilojoules'],
      ),
      hrZone13Sec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_zone13_sec'],
      ),
      hrZone45Sec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_zone45_sec'],
      ),
      strengthActivitySec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}strength_activity_sec'],
      ),
      hrvBaseline: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hrv_baseline'],
      ),
      rhrBaseline: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rhr_baseline'],
      ),
      respRateBaseline: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}resp_rate_baseline'],
      ),
      stepsBaseline: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps_baseline'],
      ),
      fitnessAge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fitness_age'],
      )!,
      vitality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vitality'],
      )!,
      hydration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hydration'],
      )!,
    );
  }

  @override
  $DailyMetricsTable createAlias(String alias) {
    return $DailyMetricsTable(attachedDatabase, alias);
  }
}

class DailyMetric extends DataClass implements Insertable<DailyMetric> {
  final String day;
  final String? cycleId;
  final double charge;
  final double effort;
  final double? dayStrain;
  final double rest;
  final double stress;
  final double hrv;
  final double rhr;
  final double respiratoryRate;
  final double skinTempDelta;
  final double spo2;
  final int steps;
  final int calories;
  final double? kilojoules;
  final int? hrZone13Sec;
  final int? hrZone45Sec;
  final int? strengthActivitySec;
  final double? hrvBaseline;
  final double? rhrBaseline;
  final double? respRateBaseline;
  final int? stepsBaseline;
  final int fitnessAge;
  final int vitality;
  final double hydration;
  const DailyMetric({
    required this.day,
    this.cycleId,
    required this.charge,
    required this.effort,
    this.dayStrain,
    required this.rest,
    required this.stress,
    required this.hrv,
    required this.rhr,
    required this.respiratoryRate,
    required this.skinTempDelta,
    required this.spo2,
    required this.steps,
    required this.calories,
    this.kilojoules,
    this.hrZone13Sec,
    this.hrZone45Sec,
    this.strengthActivitySec,
    this.hrvBaseline,
    this.rhrBaseline,
    this.respRateBaseline,
    this.stepsBaseline,
    required this.fitnessAge,
    required this.vitality,
    required this.hydration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<String>(cycleId);
    }
    map['charge'] = Variable<double>(charge);
    map['effort'] = Variable<double>(effort);
    if (!nullToAbsent || dayStrain != null) {
      map['day_strain'] = Variable<double>(dayStrain);
    }
    map['rest'] = Variable<double>(rest);
    map['stress'] = Variable<double>(stress);
    map['hrv'] = Variable<double>(hrv);
    map['rhr'] = Variable<double>(rhr);
    map['respiratory_rate'] = Variable<double>(respiratoryRate);
    map['skin_temp_delta'] = Variable<double>(skinTempDelta);
    map['spo2'] = Variable<double>(spo2);
    map['steps'] = Variable<int>(steps);
    map['calories'] = Variable<int>(calories);
    if (!nullToAbsent || kilojoules != null) {
      map['kilojoules'] = Variable<double>(kilojoules);
    }
    if (!nullToAbsent || hrZone13Sec != null) {
      map['hr_zone13_sec'] = Variable<int>(hrZone13Sec);
    }
    if (!nullToAbsent || hrZone45Sec != null) {
      map['hr_zone45_sec'] = Variable<int>(hrZone45Sec);
    }
    if (!nullToAbsent || strengthActivitySec != null) {
      map['strength_activity_sec'] = Variable<int>(strengthActivitySec);
    }
    if (!nullToAbsent || hrvBaseline != null) {
      map['hrv_baseline'] = Variable<double>(hrvBaseline);
    }
    if (!nullToAbsent || rhrBaseline != null) {
      map['rhr_baseline'] = Variable<double>(rhrBaseline);
    }
    if (!nullToAbsent || respRateBaseline != null) {
      map['resp_rate_baseline'] = Variable<double>(respRateBaseline);
    }
    if (!nullToAbsent || stepsBaseline != null) {
      map['steps_baseline'] = Variable<int>(stepsBaseline);
    }
    map['fitness_age'] = Variable<int>(fitnessAge);
    map['vitality'] = Variable<int>(vitality);
    map['hydration'] = Variable<double>(hydration);
    return map;
  }

  DailyMetricsCompanion toCompanion(bool nullToAbsent) {
    return DailyMetricsCompanion(
      day: Value(day),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
      charge: Value(charge),
      effort: Value(effort),
      dayStrain: dayStrain == null && nullToAbsent
          ? const Value.absent()
          : Value(dayStrain),
      rest: Value(rest),
      stress: Value(stress),
      hrv: Value(hrv),
      rhr: Value(rhr),
      respiratoryRate: Value(respiratoryRate),
      skinTempDelta: Value(skinTempDelta),
      spo2: Value(spo2),
      steps: Value(steps),
      calories: Value(calories),
      kilojoules: kilojoules == null && nullToAbsent
          ? const Value.absent()
          : Value(kilojoules),
      hrZone13Sec: hrZone13Sec == null && nullToAbsent
          ? const Value.absent()
          : Value(hrZone13Sec),
      hrZone45Sec: hrZone45Sec == null && nullToAbsent
          ? const Value.absent()
          : Value(hrZone45Sec),
      strengthActivitySec: strengthActivitySec == null && nullToAbsent
          ? const Value.absent()
          : Value(strengthActivitySec),
      hrvBaseline: hrvBaseline == null && nullToAbsent
          ? const Value.absent()
          : Value(hrvBaseline),
      rhrBaseline: rhrBaseline == null && nullToAbsent
          ? const Value.absent()
          : Value(rhrBaseline),
      respRateBaseline: respRateBaseline == null && nullToAbsent
          ? const Value.absent()
          : Value(respRateBaseline),
      stepsBaseline: stepsBaseline == null && nullToAbsent
          ? const Value.absent()
          : Value(stepsBaseline),
      fitnessAge: Value(fitnessAge),
      vitality: Value(vitality),
      hydration: Value(hydration),
    );
  }

  factory DailyMetric.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyMetric(
      day: serializer.fromJson<String>(json['day']),
      cycleId: serializer.fromJson<String?>(json['cycleId']),
      charge: serializer.fromJson<double>(json['charge']),
      effort: serializer.fromJson<double>(json['effort']),
      dayStrain: serializer.fromJson<double?>(json['dayStrain']),
      rest: serializer.fromJson<double>(json['rest']),
      stress: serializer.fromJson<double>(json['stress']),
      hrv: serializer.fromJson<double>(json['hrv']),
      rhr: serializer.fromJson<double>(json['rhr']),
      respiratoryRate: serializer.fromJson<double>(json['respiratoryRate']),
      skinTempDelta: serializer.fromJson<double>(json['skinTempDelta']),
      spo2: serializer.fromJson<double>(json['spo2']),
      steps: serializer.fromJson<int>(json['steps']),
      calories: serializer.fromJson<int>(json['calories']),
      kilojoules: serializer.fromJson<double?>(json['kilojoules']),
      hrZone13Sec: serializer.fromJson<int?>(json['hrZone13Sec']),
      hrZone45Sec: serializer.fromJson<int?>(json['hrZone45Sec']),
      strengthActivitySec: serializer.fromJson<int?>(
        json['strengthActivitySec'],
      ),
      hrvBaseline: serializer.fromJson<double?>(json['hrvBaseline']),
      rhrBaseline: serializer.fromJson<double?>(json['rhrBaseline']),
      respRateBaseline: serializer.fromJson<double?>(json['respRateBaseline']),
      stepsBaseline: serializer.fromJson<int?>(json['stepsBaseline']),
      fitnessAge: serializer.fromJson<int>(json['fitnessAge']),
      vitality: serializer.fromJson<int>(json['vitality']),
      hydration: serializer.fromJson<double>(json['hydration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'cycleId': serializer.toJson<String?>(cycleId),
      'charge': serializer.toJson<double>(charge),
      'effort': serializer.toJson<double>(effort),
      'dayStrain': serializer.toJson<double?>(dayStrain),
      'rest': serializer.toJson<double>(rest),
      'stress': serializer.toJson<double>(stress),
      'hrv': serializer.toJson<double>(hrv),
      'rhr': serializer.toJson<double>(rhr),
      'respiratoryRate': serializer.toJson<double>(respiratoryRate),
      'skinTempDelta': serializer.toJson<double>(skinTempDelta),
      'spo2': serializer.toJson<double>(spo2),
      'steps': serializer.toJson<int>(steps),
      'calories': serializer.toJson<int>(calories),
      'kilojoules': serializer.toJson<double?>(kilojoules),
      'hrZone13Sec': serializer.toJson<int?>(hrZone13Sec),
      'hrZone45Sec': serializer.toJson<int?>(hrZone45Sec),
      'strengthActivitySec': serializer.toJson<int?>(strengthActivitySec),
      'hrvBaseline': serializer.toJson<double?>(hrvBaseline),
      'rhrBaseline': serializer.toJson<double?>(rhrBaseline),
      'respRateBaseline': serializer.toJson<double?>(respRateBaseline),
      'stepsBaseline': serializer.toJson<int?>(stepsBaseline),
      'fitnessAge': serializer.toJson<int>(fitnessAge),
      'vitality': serializer.toJson<int>(vitality),
      'hydration': serializer.toJson<double>(hydration),
    };
  }

  DailyMetric copyWith({
    String? day,
    Value<String?> cycleId = const Value.absent(),
    double? charge,
    double? effort,
    Value<double?> dayStrain = const Value.absent(),
    double? rest,
    double? stress,
    double? hrv,
    double? rhr,
    double? respiratoryRate,
    double? skinTempDelta,
    double? spo2,
    int? steps,
    int? calories,
    Value<double?> kilojoules = const Value.absent(),
    Value<int?> hrZone13Sec = const Value.absent(),
    Value<int?> hrZone45Sec = const Value.absent(),
    Value<int?> strengthActivitySec = const Value.absent(),
    Value<double?> hrvBaseline = const Value.absent(),
    Value<double?> rhrBaseline = const Value.absent(),
    Value<double?> respRateBaseline = const Value.absent(),
    Value<int?> stepsBaseline = const Value.absent(),
    int? fitnessAge,
    int? vitality,
    double? hydration,
  }) => DailyMetric(
    day: day ?? this.day,
    cycleId: cycleId.present ? cycleId.value : this.cycleId,
    charge: charge ?? this.charge,
    effort: effort ?? this.effort,
    dayStrain: dayStrain.present ? dayStrain.value : this.dayStrain,
    rest: rest ?? this.rest,
    stress: stress ?? this.stress,
    hrv: hrv ?? this.hrv,
    rhr: rhr ?? this.rhr,
    respiratoryRate: respiratoryRate ?? this.respiratoryRate,
    skinTempDelta: skinTempDelta ?? this.skinTempDelta,
    spo2: spo2 ?? this.spo2,
    steps: steps ?? this.steps,
    calories: calories ?? this.calories,
    kilojoules: kilojoules.present ? kilojoules.value : this.kilojoules,
    hrZone13Sec: hrZone13Sec.present ? hrZone13Sec.value : this.hrZone13Sec,
    hrZone45Sec: hrZone45Sec.present ? hrZone45Sec.value : this.hrZone45Sec,
    strengthActivitySec: strengthActivitySec.present
        ? strengthActivitySec.value
        : this.strengthActivitySec,
    hrvBaseline: hrvBaseline.present ? hrvBaseline.value : this.hrvBaseline,
    rhrBaseline: rhrBaseline.present ? rhrBaseline.value : this.rhrBaseline,
    respRateBaseline: respRateBaseline.present
        ? respRateBaseline.value
        : this.respRateBaseline,
    stepsBaseline: stepsBaseline.present
        ? stepsBaseline.value
        : this.stepsBaseline,
    fitnessAge: fitnessAge ?? this.fitnessAge,
    vitality: vitality ?? this.vitality,
    hydration: hydration ?? this.hydration,
  );
  DailyMetric copyWithCompanion(DailyMetricsCompanion data) {
    return DailyMetric(
      day: data.day.present ? data.day.value : this.day,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      charge: data.charge.present ? data.charge.value : this.charge,
      effort: data.effort.present ? data.effort.value : this.effort,
      dayStrain: data.dayStrain.present ? data.dayStrain.value : this.dayStrain,
      rest: data.rest.present ? data.rest.value : this.rest,
      stress: data.stress.present ? data.stress.value : this.stress,
      hrv: data.hrv.present ? data.hrv.value : this.hrv,
      rhr: data.rhr.present ? data.rhr.value : this.rhr,
      respiratoryRate: data.respiratoryRate.present
          ? data.respiratoryRate.value
          : this.respiratoryRate,
      skinTempDelta: data.skinTempDelta.present
          ? data.skinTempDelta.value
          : this.skinTempDelta,
      spo2: data.spo2.present ? data.spo2.value : this.spo2,
      steps: data.steps.present ? data.steps.value : this.steps,
      calories: data.calories.present ? data.calories.value : this.calories,
      kilojoules: data.kilojoules.present
          ? data.kilojoules.value
          : this.kilojoules,
      hrZone13Sec: data.hrZone13Sec.present
          ? data.hrZone13Sec.value
          : this.hrZone13Sec,
      hrZone45Sec: data.hrZone45Sec.present
          ? data.hrZone45Sec.value
          : this.hrZone45Sec,
      strengthActivitySec: data.strengthActivitySec.present
          ? data.strengthActivitySec.value
          : this.strengthActivitySec,
      hrvBaseline: data.hrvBaseline.present
          ? data.hrvBaseline.value
          : this.hrvBaseline,
      rhrBaseline: data.rhrBaseline.present
          ? data.rhrBaseline.value
          : this.rhrBaseline,
      respRateBaseline: data.respRateBaseline.present
          ? data.respRateBaseline.value
          : this.respRateBaseline,
      stepsBaseline: data.stepsBaseline.present
          ? data.stepsBaseline.value
          : this.stepsBaseline,
      fitnessAge: data.fitnessAge.present
          ? data.fitnessAge.value
          : this.fitnessAge,
      vitality: data.vitality.present ? data.vitality.value : this.vitality,
      hydration: data.hydration.present ? data.hydration.value : this.hydration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyMetric(')
          ..write('day: $day, ')
          ..write('cycleId: $cycleId, ')
          ..write('charge: $charge, ')
          ..write('effort: $effort, ')
          ..write('dayStrain: $dayStrain, ')
          ..write('rest: $rest, ')
          ..write('stress: $stress, ')
          ..write('hrv: $hrv, ')
          ..write('rhr: $rhr, ')
          ..write('respiratoryRate: $respiratoryRate, ')
          ..write('skinTempDelta: $skinTempDelta, ')
          ..write('spo2: $spo2, ')
          ..write('steps: $steps, ')
          ..write('calories: $calories, ')
          ..write('kilojoules: $kilojoules, ')
          ..write('hrZone13Sec: $hrZone13Sec, ')
          ..write('hrZone45Sec: $hrZone45Sec, ')
          ..write('strengthActivitySec: $strengthActivitySec, ')
          ..write('hrvBaseline: $hrvBaseline, ')
          ..write('rhrBaseline: $rhrBaseline, ')
          ..write('respRateBaseline: $respRateBaseline, ')
          ..write('stepsBaseline: $stepsBaseline, ')
          ..write('fitnessAge: $fitnessAge, ')
          ..write('vitality: $vitality, ')
          ..write('hydration: $hydration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    day,
    cycleId,
    charge,
    effort,
    dayStrain,
    rest,
    stress,
    hrv,
    rhr,
    respiratoryRate,
    skinTempDelta,
    spo2,
    steps,
    calories,
    kilojoules,
    hrZone13Sec,
    hrZone45Sec,
    strengthActivitySec,
    hrvBaseline,
    rhrBaseline,
    respRateBaseline,
    stepsBaseline,
    fitnessAge,
    vitality,
    hydration,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyMetric &&
          other.day == this.day &&
          other.cycleId == this.cycleId &&
          other.charge == this.charge &&
          other.effort == this.effort &&
          other.dayStrain == this.dayStrain &&
          other.rest == this.rest &&
          other.stress == this.stress &&
          other.hrv == this.hrv &&
          other.rhr == this.rhr &&
          other.respiratoryRate == this.respiratoryRate &&
          other.skinTempDelta == this.skinTempDelta &&
          other.spo2 == this.spo2 &&
          other.steps == this.steps &&
          other.calories == this.calories &&
          other.kilojoules == this.kilojoules &&
          other.hrZone13Sec == this.hrZone13Sec &&
          other.hrZone45Sec == this.hrZone45Sec &&
          other.strengthActivitySec == this.strengthActivitySec &&
          other.hrvBaseline == this.hrvBaseline &&
          other.rhrBaseline == this.rhrBaseline &&
          other.respRateBaseline == this.respRateBaseline &&
          other.stepsBaseline == this.stepsBaseline &&
          other.fitnessAge == this.fitnessAge &&
          other.vitality == this.vitality &&
          other.hydration == this.hydration);
}

class DailyMetricsCompanion extends UpdateCompanion<DailyMetric> {
  final Value<String> day;
  final Value<String?> cycleId;
  final Value<double> charge;
  final Value<double> effort;
  final Value<double?> dayStrain;
  final Value<double> rest;
  final Value<double> stress;
  final Value<double> hrv;
  final Value<double> rhr;
  final Value<double> respiratoryRate;
  final Value<double> skinTempDelta;
  final Value<double> spo2;
  final Value<int> steps;
  final Value<int> calories;
  final Value<double?> kilojoules;
  final Value<int?> hrZone13Sec;
  final Value<int?> hrZone45Sec;
  final Value<int?> strengthActivitySec;
  final Value<double?> hrvBaseline;
  final Value<double?> rhrBaseline;
  final Value<double?> respRateBaseline;
  final Value<int?> stepsBaseline;
  final Value<int> fitnessAge;
  final Value<int> vitality;
  final Value<double> hydration;
  final Value<int> rowid;
  const DailyMetricsCompanion({
    this.day = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.charge = const Value.absent(),
    this.effort = const Value.absent(),
    this.dayStrain = const Value.absent(),
    this.rest = const Value.absent(),
    this.stress = const Value.absent(),
    this.hrv = const Value.absent(),
    this.rhr = const Value.absent(),
    this.respiratoryRate = const Value.absent(),
    this.skinTempDelta = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.steps = const Value.absent(),
    this.calories = const Value.absent(),
    this.kilojoules = const Value.absent(),
    this.hrZone13Sec = const Value.absent(),
    this.hrZone45Sec = const Value.absent(),
    this.strengthActivitySec = const Value.absent(),
    this.hrvBaseline = const Value.absent(),
    this.rhrBaseline = const Value.absent(),
    this.respRateBaseline = const Value.absent(),
    this.stepsBaseline = const Value.absent(),
    this.fitnessAge = const Value.absent(),
    this.vitality = const Value.absent(),
    this.hydration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyMetricsCompanion.insert({
    required String day,
    this.cycleId = const Value.absent(),
    this.charge = const Value.absent(),
    this.effort = const Value.absent(),
    this.dayStrain = const Value.absent(),
    this.rest = const Value.absent(),
    this.stress = const Value.absent(),
    this.hrv = const Value.absent(),
    this.rhr = const Value.absent(),
    this.respiratoryRate = const Value.absent(),
    this.skinTempDelta = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.steps = const Value.absent(),
    this.calories = const Value.absent(),
    this.kilojoules = const Value.absent(),
    this.hrZone13Sec = const Value.absent(),
    this.hrZone45Sec = const Value.absent(),
    this.strengthActivitySec = const Value.absent(),
    this.hrvBaseline = const Value.absent(),
    this.rhrBaseline = const Value.absent(),
    this.respRateBaseline = const Value.absent(),
    this.stepsBaseline = const Value.absent(),
    this.fitnessAge = const Value.absent(),
    this.vitality = const Value.absent(),
    this.hydration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<DailyMetric> custom({
    Expression<String>? day,
    Expression<String>? cycleId,
    Expression<double>? charge,
    Expression<double>? effort,
    Expression<double>? dayStrain,
    Expression<double>? rest,
    Expression<double>? stress,
    Expression<double>? hrv,
    Expression<double>? rhr,
    Expression<double>? respiratoryRate,
    Expression<double>? skinTempDelta,
    Expression<double>? spo2,
    Expression<int>? steps,
    Expression<int>? calories,
    Expression<double>? kilojoules,
    Expression<int>? hrZone13Sec,
    Expression<int>? hrZone45Sec,
    Expression<int>? strengthActivitySec,
    Expression<double>? hrvBaseline,
    Expression<double>? rhrBaseline,
    Expression<double>? respRateBaseline,
    Expression<int>? stepsBaseline,
    Expression<int>? fitnessAge,
    Expression<int>? vitality,
    Expression<double>? hydration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (cycleId != null) 'cycle_id': cycleId,
      if (charge != null) 'charge': charge,
      if (effort != null) 'effort': effort,
      if (dayStrain != null) 'day_strain': dayStrain,
      if (rest != null) 'rest': rest,
      if (stress != null) 'stress': stress,
      if (hrv != null) 'hrv': hrv,
      if (rhr != null) 'rhr': rhr,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (skinTempDelta != null) 'skin_temp_delta': skinTempDelta,
      if (spo2 != null) 'spo2': spo2,
      if (steps != null) 'steps': steps,
      if (calories != null) 'calories': calories,
      if (kilojoules != null) 'kilojoules': kilojoules,
      if (hrZone13Sec != null) 'hr_zone13_sec': hrZone13Sec,
      if (hrZone45Sec != null) 'hr_zone45_sec': hrZone45Sec,
      if (strengthActivitySec != null)
        'strength_activity_sec': strengthActivitySec,
      if (hrvBaseline != null) 'hrv_baseline': hrvBaseline,
      if (rhrBaseline != null) 'rhr_baseline': rhrBaseline,
      if (respRateBaseline != null) 'resp_rate_baseline': respRateBaseline,
      if (stepsBaseline != null) 'steps_baseline': stepsBaseline,
      if (fitnessAge != null) 'fitness_age': fitnessAge,
      if (vitality != null) 'vitality': vitality,
      if (hydration != null) 'hydration': hydration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyMetricsCompanion copyWith({
    Value<String>? day,
    Value<String?>? cycleId,
    Value<double>? charge,
    Value<double>? effort,
    Value<double?>? dayStrain,
    Value<double>? rest,
    Value<double>? stress,
    Value<double>? hrv,
    Value<double>? rhr,
    Value<double>? respiratoryRate,
    Value<double>? skinTempDelta,
    Value<double>? spo2,
    Value<int>? steps,
    Value<int>? calories,
    Value<double?>? kilojoules,
    Value<int?>? hrZone13Sec,
    Value<int?>? hrZone45Sec,
    Value<int?>? strengthActivitySec,
    Value<double?>? hrvBaseline,
    Value<double?>? rhrBaseline,
    Value<double?>? respRateBaseline,
    Value<int?>? stepsBaseline,
    Value<int>? fitnessAge,
    Value<int>? vitality,
    Value<double>? hydration,
    Value<int>? rowid,
  }) {
    return DailyMetricsCompanion(
      day: day ?? this.day,
      cycleId: cycleId ?? this.cycleId,
      charge: charge ?? this.charge,
      effort: effort ?? this.effort,
      dayStrain: dayStrain ?? this.dayStrain,
      rest: rest ?? this.rest,
      stress: stress ?? this.stress,
      hrv: hrv ?? this.hrv,
      rhr: rhr ?? this.rhr,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      skinTempDelta: skinTempDelta ?? this.skinTempDelta,
      spo2: spo2 ?? this.spo2,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      kilojoules: kilojoules ?? this.kilojoules,
      hrZone13Sec: hrZone13Sec ?? this.hrZone13Sec,
      hrZone45Sec: hrZone45Sec ?? this.hrZone45Sec,
      strengthActivitySec: strengthActivitySec ?? this.strengthActivitySec,
      hrvBaseline: hrvBaseline ?? this.hrvBaseline,
      rhrBaseline: rhrBaseline ?? this.rhrBaseline,
      respRateBaseline: respRateBaseline ?? this.respRateBaseline,
      stepsBaseline: stepsBaseline ?? this.stepsBaseline,
      fitnessAge: fitnessAge ?? this.fitnessAge,
      vitality: vitality ?? this.vitality,
      hydration: hydration ?? this.hydration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (charge.present) {
      map['charge'] = Variable<double>(charge.value);
    }
    if (effort.present) {
      map['effort'] = Variable<double>(effort.value);
    }
    if (dayStrain.present) {
      map['day_strain'] = Variable<double>(dayStrain.value);
    }
    if (rest.present) {
      map['rest'] = Variable<double>(rest.value);
    }
    if (stress.present) {
      map['stress'] = Variable<double>(stress.value);
    }
    if (hrv.present) {
      map['hrv'] = Variable<double>(hrv.value);
    }
    if (rhr.present) {
      map['rhr'] = Variable<double>(rhr.value);
    }
    if (respiratoryRate.present) {
      map['respiratory_rate'] = Variable<double>(respiratoryRate.value);
    }
    if (skinTempDelta.present) {
      map['skin_temp_delta'] = Variable<double>(skinTempDelta.value);
    }
    if (spo2.present) {
      map['spo2'] = Variable<double>(spo2.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (kilojoules.present) {
      map['kilojoules'] = Variable<double>(kilojoules.value);
    }
    if (hrZone13Sec.present) {
      map['hr_zone13_sec'] = Variable<int>(hrZone13Sec.value);
    }
    if (hrZone45Sec.present) {
      map['hr_zone45_sec'] = Variable<int>(hrZone45Sec.value);
    }
    if (strengthActivitySec.present) {
      map['strength_activity_sec'] = Variable<int>(strengthActivitySec.value);
    }
    if (hrvBaseline.present) {
      map['hrv_baseline'] = Variable<double>(hrvBaseline.value);
    }
    if (rhrBaseline.present) {
      map['rhr_baseline'] = Variable<double>(rhrBaseline.value);
    }
    if (respRateBaseline.present) {
      map['resp_rate_baseline'] = Variable<double>(respRateBaseline.value);
    }
    if (stepsBaseline.present) {
      map['steps_baseline'] = Variable<int>(stepsBaseline.value);
    }
    if (fitnessAge.present) {
      map['fitness_age'] = Variable<int>(fitnessAge.value);
    }
    if (vitality.present) {
      map['vitality'] = Variable<int>(vitality.value);
    }
    if (hydration.present) {
      map['hydration'] = Variable<double>(hydration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyMetricsCompanion(')
          ..write('day: $day, ')
          ..write('cycleId: $cycleId, ')
          ..write('charge: $charge, ')
          ..write('effort: $effort, ')
          ..write('dayStrain: $dayStrain, ')
          ..write('rest: $rest, ')
          ..write('stress: $stress, ')
          ..write('hrv: $hrv, ')
          ..write('rhr: $rhr, ')
          ..write('respiratoryRate: $respiratoryRate, ')
          ..write('skinTempDelta: $skinTempDelta, ')
          ..write('spo2: $spo2, ')
          ..write('steps: $steps, ')
          ..write('calories: $calories, ')
          ..write('kilojoules: $kilojoules, ')
          ..write('hrZone13Sec: $hrZone13Sec, ')
          ..write('hrZone45Sec: $hrZone45Sec, ')
          ..write('strengthActivitySec: $strengthActivitySec, ')
          ..write('hrvBaseline: $hrvBaseline, ')
          ..write('rhrBaseline: $rhrBaseline, ')
          ..write('respRateBaseline: $respRateBaseline, ')
          ..write('stepsBaseline: $stepsBaseline, ')
          ..write('fitnessAge: $fitnessAge, ')
          ..write('vitality: $vitality, ')
          ..write('hydration: $hydration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CyclesTable extends Cycles with TableInfo<$CyclesTable, Cycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTsMeta = const VerificationMeta(
    'startTs',
  );
  @override
  late final GeneratedColumn<int> startTs = GeneratedColumn<int>(
    'start_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTsMeta = const VerificationMeta('endTs');
  @override
  late final GeneratedColumn<int> endTs = GeneratedColumn<int>(
    'end_ts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMultiDayMeta = const VerificationMeta(
    'isMultiDay',
  );
  @override
  late final GeneratedColumn<bool> isMultiDay = GeneratedColumn<bool>(
    'is_multi_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_multi_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDayZeroMeta = const VerificationMeta(
    'isDayZero',
  );
  @override
  late final GeneratedColumn<bool> isDayZero = GeneratedColumn<bool>(
    'is_day_zero',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_day_zero" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sleepStateMeta = const VerificationMeta(
    'sleepState',
  );
  @override
  late final GeneratedColumn<String> sleepState = GeneratedColumn<String>(
    'sleep_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTs,
    endTs,
    isMultiDay,
    isDayZero,
    sleepState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_ts')) {
      context.handle(
        _startTsMeta,
        startTs.isAcceptableOrUnknown(data['start_ts']!, _startTsMeta),
      );
    } else if (isInserting) {
      context.missing(_startTsMeta);
    }
    if (data.containsKey('end_ts')) {
      context.handle(
        _endTsMeta,
        endTs.isAcceptableOrUnknown(data['end_ts']!, _endTsMeta),
      );
    }
    if (data.containsKey('is_multi_day')) {
      context.handle(
        _isMultiDayMeta,
        isMultiDay.isAcceptableOrUnknown(
          data['is_multi_day']!,
          _isMultiDayMeta,
        ),
      );
    }
    if (data.containsKey('is_day_zero')) {
      context.handle(
        _isDayZeroMeta,
        isDayZero.isAcceptableOrUnknown(data['is_day_zero']!, _isDayZeroMeta),
      );
    }
    if (data.containsKey('sleep_state')) {
      context.handle(
        _sleepStateMeta,
        sleepState.isAcceptableOrUnknown(data['sleep_state']!, _sleepStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ts'],
      )!,
      endTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ts'],
      ),
      isMultiDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_multi_day'],
      )!,
      isDayZero: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_day_zero'],
      )!,
      sleepState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sleep_state'],
      ),
    );
  }

  @override
  $CyclesTable createAlias(String alias) {
    return $CyclesTable(attachedDatabase, alias);
  }
}

class Cycle extends DataClass implements Insertable<Cycle> {
  final String id;
  final int startTs;
  final int? endTs;
  final bool isMultiDay;
  final bool isDayZero;
  final String? sleepState;
  const Cycle({
    required this.id,
    required this.startTs,
    this.endTs,
    required this.isMultiDay,
    required this.isDayZero,
    this.sleepState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_ts'] = Variable<int>(startTs);
    if (!nullToAbsent || endTs != null) {
      map['end_ts'] = Variable<int>(endTs);
    }
    map['is_multi_day'] = Variable<bool>(isMultiDay);
    map['is_day_zero'] = Variable<bool>(isDayZero);
    if (!nullToAbsent || sleepState != null) {
      map['sleep_state'] = Variable<String>(sleepState);
    }
    return map;
  }

  CyclesCompanion toCompanion(bool nullToAbsent) {
    return CyclesCompanion(
      id: Value(id),
      startTs: Value(startTs),
      endTs: endTs == null && nullToAbsent
          ? const Value.absent()
          : Value(endTs),
      isMultiDay: Value(isMultiDay),
      isDayZero: Value(isDayZero),
      sleepState: sleepState == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepState),
    );
  }

  factory Cycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cycle(
      id: serializer.fromJson<String>(json['id']),
      startTs: serializer.fromJson<int>(json['startTs']),
      endTs: serializer.fromJson<int?>(json['endTs']),
      isMultiDay: serializer.fromJson<bool>(json['isMultiDay']),
      isDayZero: serializer.fromJson<bool>(json['isDayZero']),
      sleepState: serializer.fromJson<String?>(json['sleepState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTs': serializer.toJson<int>(startTs),
      'endTs': serializer.toJson<int?>(endTs),
      'isMultiDay': serializer.toJson<bool>(isMultiDay),
      'isDayZero': serializer.toJson<bool>(isDayZero),
      'sleepState': serializer.toJson<String?>(sleepState),
    };
  }

  Cycle copyWith({
    String? id,
    int? startTs,
    Value<int?> endTs = const Value.absent(),
    bool? isMultiDay,
    bool? isDayZero,
    Value<String?> sleepState = const Value.absent(),
  }) => Cycle(
    id: id ?? this.id,
    startTs: startTs ?? this.startTs,
    endTs: endTs.present ? endTs.value : this.endTs,
    isMultiDay: isMultiDay ?? this.isMultiDay,
    isDayZero: isDayZero ?? this.isDayZero,
    sleepState: sleepState.present ? sleepState.value : this.sleepState,
  );
  Cycle copyWithCompanion(CyclesCompanion data) {
    return Cycle(
      id: data.id.present ? data.id.value : this.id,
      startTs: data.startTs.present ? data.startTs.value : this.startTs,
      endTs: data.endTs.present ? data.endTs.value : this.endTs,
      isMultiDay: data.isMultiDay.present
          ? data.isMultiDay.value
          : this.isMultiDay,
      isDayZero: data.isDayZero.present ? data.isDayZero.value : this.isDayZero,
      sleepState: data.sleepState.present
          ? data.sleepState.value
          : this.sleepState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cycle(')
          ..write('id: $id, ')
          ..write('startTs: $startTs, ')
          ..write('endTs: $endTs, ')
          ..write('isMultiDay: $isMultiDay, ')
          ..write('isDayZero: $isDayZero, ')
          ..write('sleepState: $sleepState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startTs, endTs, isMultiDay, isDayZero, sleepState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cycle &&
          other.id == this.id &&
          other.startTs == this.startTs &&
          other.endTs == this.endTs &&
          other.isMultiDay == this.isMultiDay &&
          other.isDayZero == this.isDayZero &&
          other.sleepState == this.sleepState);
}

class CyclesCompanion extends UpdateCompanion<Cycle> {
  final Value<String> id;
  final Value<int> startTs;
  final Value<int?> endTs;
  final Value<bool> isMultiDay;
  final Value<bool> isDayZero;
  final Value<String?> sleepState;
  final Value<int> rowid;
  const CyclesCompanion({
    this.id = const Value.absent(),
    this.startTs = const Value.absent(),
    this.endTs = const Value.absent(),
    this.isMultiDay = const Value.absent(),
    this.isDayZero = const Value.absent(),
    this.sleepState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CyclesCompanion.insert({
    required String id,
    required int startTs,
    this.endTs = const Value.absent(),
    this.isMultiDay = const Value.absent(),
    this.isDayZero = const Value.absent(),
    this.sleepState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startTs = Value(startTs);
  static Insertable<Cycle> custom({
    Expression<String>? id,
    Expression<int>? startTs,
    Expression<int>? endTs,
    Expression<bool>? isMultiDay,
    Expression<bool>? isDayZero,
    Expression<String>? sleepState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTs != null) 'start_ts': startTs,
      if (endTs != null) 'end_ts': endTs,
      if (isMultiDay != null) 'is_multi_day': isMultiDay,
      if (isDayZero != null) 'is_day_zero': isDayZero,
      if (sleepState != null) 'sleep_state': sleepState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CyclesCompanion copyWith({
    Value<String>? id,
    Value<int>? startTs,
    Value<int?>? endTs,
    Value<bool>? isMultiDay,
    Value<bool>? isDayZero,
    Value<String?>? sleepState,
    Value<int>? rowid,
  }) {
    return CyclesCompanion(
      id: id ?? this.id,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      isMultiDay: isMultiDay ?? this.isMultiDay,
      isDayZero: isDayZero ?? this.isDayZero,
      sleepState: sleepState ?? this.sleepState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTs.present) {
      map['start_ts'] = Variable<int>(startTs.value);
    }
    if (endTs.present) {
      map['end_ts'] = Variable<int>(endTs.value);
    }
    if (isMultiDay.present) {
      map['is_multi_day'] = Variable<bool>(isMultiDay.value);
    }
    if (isDayZero.present) {
      map['is_day_zero'] = Variable<bool>(isDayZero.value);
    }
    if (sleepState.present) {
      map['sleep_state'] = Variable<String>(sleepState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CyclesCompanion(')
          ..write('id: $id, ')
          ..write('startTs: $startTs, ')
          ..write('endTs: $endTs, ')
          ..write('isMultiDay: $isMultiDay, ')
          ..write('isDayZero: $isDayZero, ')
          ..write('sleepState: $sleepState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SleepSessionsTable extends SleepSessions
    with TableInfo<$SleepSessionsTable, SleepSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bedtimeTsMeta = const VerificationMeta(
    'bedtimeTs',
  );
  @override
  late final GeneratedColumn<int> bedtimeTs = GeneratedColumn<int>(
    'bedtime_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wakeTsMeta = const VerificationMeta('wakeTs');
  @override
  late final GeneratedColumn<int> wakeTs = GeneratedColumn<int>(
    'wake_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inBedSecMeta = const VerificationMeta(
    'inBedSec',
  );
  @override
  late final GeneratedColumn<int> inBedSec = GeneratedColumn<int>(
    'in_bed_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _asleepSecMeta = const VerificationMeta(
    'asleepSec',
  );
  @override
  late final GeneratedColumn<int> asleepSec = GeneratedColumn<int>(
    'asleep_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deepSecMeta = const VerificationMeta(
    'deepSec',
  );
  @override
  late final GeneratedColumn<int> deepSec = GeneratedColumn<int>(
    'deep_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remSecMeta = const VerificationMeta('remSec');
  @override
  late final GeneratedColumn<int> remSec = GeneratedColumn<int>(
    'rem_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lightSecMeta = const VerificationMeta(
    'lightSec',
  );
  @override
  late final GeneratedColumn<int> lightSec = GeneratedColumn<int>(
    'light_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awakeSecMeta = const VerificationMeta(
    'awakeSec',
  );
  @override
  late final GeneratedColumn<int> awakeSec = GeneratedColumn<int>(
    'awake_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _efficiencyMeta = const VerificationMeta(
    'efficiency',
  );
  @override
  late final GeneratedColumn<double> efficiency = GeneratedColumn<double>(
    'efficiency',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needSecMeta = const VerificationMeta(
    'needSec',
  );
  @override
  late final GeneratedColumn<int> needSec = GeneratedColumn<int>(
    'need_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _respiratoryRateMeta = const VerificationMeta(
    'respiratoryRate',
  );
  @override
  late final GeneratedColumn<double> respiratoryRate = GeneratedColumn<double>(
    'respiratory_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _disturbancesMeta = const VerificationMeta(
    'disturbances',
  );
  @override
  late final GeneratedColumn<int> disturbances = GeneratedColumn<int>(
    'disturbances',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _restingHrMeta = const VerificationMeta(
    'restingHr',
  );
  @override
  late final GeneratedColumn<double> restingHr = GeneratedColumn<double>(
    'resting_hr',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgHrvMeta = const VerificationMeta('avgHrv');
  @override
  late final GeneratedColumn<double> avgHrv = GeneratedColumn<double>(
    'avg_hrv',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spo2Meta = const VerificationMeta('spo2');
  @override
  late final GeneratedColumn<double> spo2 = GeneratedColumn<double>(
    'spo2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skinTempDeltaMeta = const VerificationMeta(
    'skinTempDelta',
  );
  @override
  late final GeneratedColumn<double> skinTempDelta = GeneratedColumn<double>(
    'skin_temp_delta',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepPerformancePctMeta =
      const VerificationMeta('sleepPerformancePct');
  @override
  late final GeneratedColumn<int> sleepPerformancePct = GeneratedColumn<int>(
    'sleep_performance_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepConsistencyPctMeta =
      const VerificationMeta('sleepConsistencyPct');
  @override
  late final GeneratedColumn<int> sleepConsistencyPct = GeneratedColumn<int>(
    'sleep_consistency_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hoursVsNeededPctMeta = const VerificationMeta(
    'hoursVsNeededPct',
  );
  @override
  late final GeneratedColumn<int> hoursVsNeededPct = GeneratedColumn<int>(
    'hours_vs_needed_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restorativeSleepSecMeta =
      const VerificationMeta('restorativeSleepSec');
  @override
  late final GeneratedColumn<int> restorativeSleepSec = GeneratedColumn<int>(
    'restorative_sleep_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepLatencySecMeta = const VerificationMeta(
    'sleepLatencySec',
  );
  @override
  late final GeneratedColumn<int> sleepLatencySec = GeneratedColumn<int>(
    'sleep_latency_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wakeEventsCountMeta = const VerificationMeta(
    'wakeEventsCount',
  );
  @override
  late final GeneratedColumn<int> wakeEventsCount = GeneratedColumn<int>(
    'wake_events_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _highSleepStressPctMeta =
      const VerificationMeta('highSleepStressPct');
  @override
  late final GeneratedColumn<int> highSleepStressPct = GeneratedColumn<int>(
    'high_sleep_stress_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noDataSecMeta = const VerificationMeta(
    'noDataSec',
  );
  @override
  late final GeneratedColumn<int> noDataSec = GeneratedColumn<int>(
    'no_data_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepDebtSecMeta = const VerificationMeta(
    'sleepDebtSec',
  );
  @override
  late final GeneratedColumn<int> sleepDebtSec = GeneratedColumn<int>(
    'sleep_debt_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepNeedBaselineSecMeta =
      const VerificationMeta('sleepNeedBaselineSec');
  @override
  late final GeneratedColumn<int> sleepNeedBaselineSec = GeneratedColumn<int>(
    'sleep_need_baseline_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepNeedFromStrainSecMeta =
      const VerificationMeta('sleepNeedFromStrainSec');
  @override
  late final GeneratedColumn<int> sleepNeedFromStrainSec = GeneratedColumn<int>(
    'sleep_need_from_strain_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepNeedFromNapSecMeta =
      const VerificationMeta('sleepNeedFromNapSec');
  @override
  late final GeneratedColumn<int> sleepNeedFromNapSec = GeneratedColumn<int>(
    'sleep_need_from_nap_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('on-device'),
  );
  static const VerificationMeta _isNapMeta = const VerificationMeta('isNap');
  @override
  late final GeneratedColumn<bool> isNap = GeneratedColumn<bool>(
    'is_nap',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_nap" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _userEditedMeta = const VerificationMeta(
    'userEdited',
  );
  @override
  late final GeneratedColumn<bool> userEdited = GeneratedColumn<bool>(
    'user_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startTsAdjustedMeta = const VerificationMeta(
    'startTsAdjusted',
  );
  @override
  late final GeneratedColumn<int> startTsAdjusted = GeneratedColumn<int>(
    'start_ts_adjusted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hypnogramJsonMeta = const VerificationMeta(
    'hypnogramJson',
  );
  @override
  late final GeneratedColumn<String> hypnogramJson = GeneratedColumn<String>(
    'hypnogram_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _restlessnessJsonMeta = const VerificationMeta(
    'restlessnessJson',
  );
  @override
  late final GeneratedColumn<String> restlessnessJson = GeneratedColumn<String>(
    'restlessness_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sleepStateJsonMeta = const VerificationMeta(
    'sleepStateJson',
  );
  @override
  late final GeneratedColumn<String> sleepStateJson = GeneratedColumn<String>(
    'sleep_state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    bedtimeTs,
    wakeTs,
    inBedSec,
    asleepSec,
    deepSec,
    remSec,
    lightSec,
    awakeSec,
    efficiency,
    needSec,
    respiratoryRate,
    disturbances,
    restingHr,
    avgHrv,
    spo2,
    skinTempDelta,
    sleepPerformancePct,
    sleepConsistencyPct,
    hoursVsNeededPct,
    restorativeSleepSec,
    sleepLatencySec,
    wakeEventsCount,
    highSleepStressPct,
    noDataSec,
    sleepDebtSec,
    sleepNeedBaselineSec,
    sleepNeedFromStrainSec,
    sleepNeedFromNapSec,
    activityId,
    cycleId,
    source,
    isNap,
    userEdited,
    startTsAdjusted,
    hypnogramJson,
    restlessnessJson,
    sleepStateJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SleepSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('bedtime_ts')) {
      context.handle(
        _bedtimeTsMeta,
        bedtimeTs.isAcceptableOrUnknown(data['bedtime_ts']!, _bedtimeTsMeta),
      );
    } else if (isInserting) {
      context.missing(_bedtimeTsMeta);
    }
    if (data.containsKey('wake_ts')) {
      context.handle(
        _wakeTsMeta,
        wakeTs.isAcceptableOrUnknown(data['wake_ts']!, _wakeTsMeta),
      );
    } else if (isInserting) {
      context.missing(_wakeTsMeta);
    }
    if (data.containsKey('in_bed_sec')) {
      context.handle(
        _inBedSecMeta,
        inBedSec.isAcceptableOrUnknown(data['in_bed_sec']!, _inBedSecMeta),
      );
    } else if (isInserting) {
      context.missing(_inBedSecMeta);
    }
    if (data.containsKey('asleep_sec')) {
      context.handle(
        _asleepSecMeta,
        asleepSec.isAcceptableOrUnknown(data['asleep_sec']!, _asleepSecMeta),
      );
    } else if (isInserting) {
      context.missing(_asleepSecMeta);
    }
    if (data.containsKey('deep_sec')) {
      context.handle(
        _deepSecMeta,
        deepSec.isAcceptableOrUnknown(data['deep_sec']!, _deepSecMeta),
      );
    } else if (isInserting) {
      context.missing(_deepSecMeta);
    }
    if (data.containsKey('rem_sec')) {
      context.handle(
        _remSecMeta,
        remSec.isAcceptableOrUnknown(data['rem_sec']!, _remSecMeta),
      );
    } else if (isInserting) {
      context.missing(_remSecMeta);
    }
    if (data.containsKey('light_sec')) {
      context.handle(
        _lightSecMeta,
        lightSec.isAcceptableOrUnknown(data['light_sec']!, _lightSecMeta),
      );
    } else if (isInserting) {
      context.missing(_lightSecMeta);
    }
    if (data.containsKey('awake_sec')) {
      context.handle(
        _awakeSecMeta,
        awakeSec.isAcceptableOrUnknown(data['awake_sec']!, _awakeSecMeta),
      );
    } else if (isInserting) {
      context.missing(_awakeSecMeta);
    }
    if (data.containsKey('efficiency')) {
      context.handle(
        _efficiencyMeta,
        efficiency.isAcceptableOrUnknown(data['efficiency']!, _efficiencyMeta),
      );
    } else if (isInserting) {
      context.missing(_efficiencyMeta);
    }
    if (data.containsKey('need_sec')) {
      context.handle(
        _needSecMeta,
        needSec.isAcceptableOrUnknown(data['need_sec']!, _needSecMeta),
      );
    }
    if (data.containsKey('respiratory_rate')) {
      context.handle(
        _respiratoryRateMeta,
        respiratoryRate.isAcceptableOrUnknown(
          data['respiratory_rate']!,
          _respiratoryRateMeta,
        ),
      );
    }
    if (data.containsKey('disturbances')) {
      context.handle(
        _disturbancesMeta,
        disturbances.isAcceptableOrUnknown(
          data['disturbances']!,
          _disturbancesMeta,
        ),
      );
    }
    if (data.containsKey('resting_hr')) {
      context.handle(
        _restingHrMeta,
        restingHr.isAcceptableOrUnknown(data['resting_hr']!, _restingHrMeta),
      );
    }
    if (data.containsKey('avg_hrv')) {
      context.handle(
        _avgHrvMeta,
        avgHrv.isAcceptableOrUnknown(data['avg_hrv']!, _avgHrvMeta),
      );
    }
    if (data.containsKey('spo2')) {
      context.handle(
        _spo2Meta,
        spo2.isAcceptableOrUnknown(data['spo2']!, _spo2Meta),
      );
    }
    if (data.containsKey('skin_temp_delta')) {
      context.handle(
        _skinTempDeltaMeta,
        skinTempDelta.isAcceptableOrUnknown(
          data['skin_temp_delta']!,
          _skinTempDeltaMeta,
        ),
      );
    }
    if (data.containsKey('sleep_performance_pct')) {
      context.handle(
        _sleepPerformancePctMeta,
        sleepPerformancePct.isAcceptableOrUnknown(
          data['sleep_performance_pct']!,
          _sleepPerformancePctMeta,
        ),
      );
    }
    if (data.containsKey('sleep_consistency_pct')) {
      context.handle(
        _sleepConsistencyPctMeta,
        sleepConsistencyPct.isAcceptableOrUnknown(
          data['sleep_consistency_pct']!,
          _sleepConsistencyPctMeta,
        ),
      );
    }
    if (data.containsKey('hours_vs_needed_pct')) {
      context.handle(
        _hoursVsNeededPctMeta,
        hoursVsNeededPct.isAcceptableOrUnknown(
          data['hours_vs_needed_pct']!,
          _hoursVsNeededPctMeta,
        ),
      );
    }
    if (data.containsKey('restorative_sleep_sec')) {
      context.handle(
        _restorativeSleepSecMeta,
        restorativeSleepSec.isAcceptableOrUnknown(
          data['restorative_sleep_sec']!,
          _restorativeSleepSecMeta,
        ),
      );
    }
    if (data.containsKey('sleep_latency_sec')) {
      context.handle(
        _sleepLatencySecMeta,
        sleepLatencySec.isAcceptableOrUnknown(
          data['sleep_latency_sec']!,
          _sleepLatencySecMeta,
        ),
      );
    }
    if (data.containsKey('wake_events_count')) {
      context.handle(
        _wakeEventsCountMeta,
        wakeEventsCount.isAcceptableOrUnknown(
          data['wake_events_count']!,
          _wakeEventsCountMeta,
        ),
      );
    }
    if (data.containsKey('high_sleep_stress_pct')) {
      context.handle(
        _highSleepStressPctMeta,
        highSleepStressPct.isAcceptableOrUnknown(
          data['high_sleep_stress_pct']!,
          _highSleepStressPctMeta,
        ),
      );
    }
    if (data.containsKey('no_data_sec')) {
      context.handle(
        _noDataSecMeta,
        noDataSec.isAcceptableOrUnknown(data['no_data_sec']!, _noDataSecMeta),
      );
    }
    if (data.containsKey('sleep_debt_sec')) {
      context.handle(
        _sleepDebtSecMeta,
        sleepDebtSec.isAcceptableOrUnknown(
          data['sleep_debt_sec']!,
          _sleepDebtSecMeta,
        ),
      );
    }
    if (data.containsKey('sleep_need_baseline_sec')) {
      context.handle(
        _sleepNeedBaselineSecMeta,
        sleepNeedBaselineSec.isAcceptableOrUnknown(
          data['sleep_need_baseline_sec']!,
          _sleepNeedBaselineSecMeta,
        ),
      );
    }
    if (data.containsKey('sleep_need_from_strain_sec')) {
      context.handle(
        _sleepNeedFromStrainSecMeta,
        sleepNeedFromStrainSec.isAcceptableOrUnknown(
          data['sleep_need_from_strain_sec']!,
          _sleepNeedFromStrainSecMeta,
        ),
      );
    }
    if (data.containsKey('sleep_need_from_nap_sec')) {
      context.handle(
        _sleepNeedFromNapSecMeta,
        sleepNeedFromNapSec.isAcceptableOrUnknown(
          data['sleep_need_from_nap_sec']!,
          _sleepNeedFromNapSecMeta,
        ),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('is_nap')) {
      context.handle(
        _isNapMeta,
        isNap.isAcceptableOrUnknown(data['is_nap']!, _isNapMeta),
      );
    }
    if (data.containsKey('user_edited')) {
      context.handle(
        _userEditedMeta,
        userEdited.isAcceptableOrUnknown(data['user_edited']!, _userEditedMeta),
      );
    }
    if (data.containsKey('start_ts_adjusted')) {
      context.handle(
        _startTsAdjustedMeta,
        startTsAdjusted.isAcceptableOrUnknown(
          data['start_ts_adjusted']!,
          _startTsAdjustedMeta,
        ),
      );
    }
    if (data.containsKey('hypnogram_json')) {
      context.handle(
        _hypnogramJsonMeta,
        hypnogramJson.isAcceptableOrUnknown(
          data['hypnogram_json']!,
          _hypnogramJsonMeta,
        ),
      );
    }
    if (data.containsKey('restlessness_json')) {
      context.handle(
        _restlessnessJsonMeta,
        restlessnessJson.isAcceptableOrUnknown(
          data['restlessness_json']!,
          _restlessnessJsonMeta,
        ),
      );
    }
    if (data.containsKey('sleep_state_json')) {
      context.handle(
        _sleepStateJsonMeta,
        sleepStateJson.isAcceptableOrUnknown(
          data['sleep_state_json']!,
          _sleepStateJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  SleepSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepSession(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      bedtimeTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_ts'],
      )!,
      wakeTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_ts'],
      )!,
      inBedSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}in_bed_sec'],
      )!,
      asleepSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asleep_sec'],
      )!,
      deepSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deep_sec'],
      )!,
      remSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rem_sec'],
      )!,
      lightSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}light_sec'],
      )!,
      awakeSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}awake_sec'],
      )!,
      efficiency: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}efficiency'],
      )!,
      needSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}need_sec'],
      )!,
      respiratoryRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}respiratory_rate'],
      )!,
      disturbances: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disturbances'],
      )!,
      restingHr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}resting_hr'],
      ),
      avgHrv: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_hrv'],
      ),
      spo2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}spo2'],
      ),
      skinTempDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}skin_temp_delta'],
      ),
      sleepPerformancePct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_performance_pct'],
      ),
      sleepConsistencyPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_consistency_pct'],
      ),
      hoursVsNeededPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hours_vs_needed_pct'],
      ),
      restorativeSleepSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}restorative_sleep_sec'],
      ),
      sleepLatencySec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_latency_sec'],
      ),
      wakeEventsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_events_count'],
      ),
      highSleepStressPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}high_sleep_stress_pct'],
      ),
      noDataSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_data_sec'],
      ),
      sleepDebtSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_debt_sec'],
      ),
      sleepNeedBaselineSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_need_baseline_sec'],
      ),
      sleepNeedFromStrainSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_need_from_strain_sec'],
      ),
      sleepNeedFromNapSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_need_from_nap_sec'],
      ),
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      isNap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_nap'],
      )!,
      userEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_edited'],
      )!,
      startTsAdjusted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ts_adjusted'],
      ),
      hypnogramJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hypnogram_json'],
      )!,
      restlessnessJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}restlessness_json'],
      )!,
      sleepStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sleep_state_json'],
      )!,
    );
  }

  @override
  $SleepSessionsTable createAlias(String alias) {
    return $SleepSessionsTable(attachedDatabase, alias);
  }
}

class SleepSession extends DataClass implements Insertable<SleepSession> {
  final String day;
  final int bedtimeTs;
  final int wakeTs;
  final int inBedSec;
  final int asleepSec;
  final int deepSec;
  final int remSec;
  final int lightSec;
  final int awakeSec;
  final double efficiency;
  final int needSec;
  final double respiratoryRate;
  final int disturbances;
  final double? restingHr;
  final double? avgHrv;
  final double? spo2;
  final double? skinTempDelta;
  final int? sleepPerformancePct;
  final int? sleepConsistencyPct;
  final int? hoursVsNeededPct;
  final int? restorativeSleepSec;
  final int? sleepLatencySec;
  final int? wakeEventsCount;
  final int? highSleepStressPct;
  final int? noDataSec;
  final int? sleepDebtSec;
  final int? sleepNeedBaselineSec;
  final int? sleepNeedFromStrainSec;
  final int? sleepNeedFromNapSec;
  final String? activityId;
  final String? cycleId;
  final String source;
  final bool isNap;
  final bool userEdited;
  final int? startTsAdjusted;
  final String hypnogramJson;
  final String restlessnessJson;
  final String sleepStateJson;
  const SleepSession({
    required this.day,
    required this.bedtimeTs,
    required this.wakeTs,
    required this.inBedSec,
    required this.asleepSec,
    required this.deepSec,
    required this.remSec,
    required this.lightSec,
    required this.awakeSec,
    required this.efficiency,
    required this.needSec,
    required this.respiratoryRate,
    required this.disturbances,
    this.restingHr,
    this.avgHrv,
    this.spo2,
    this.skinTempDelta,
    this.sleepPerformancePct,
    this.sleepConsistencyPct,
    this.hoursVsNeededPct,
    this.restorativeSleepSec,
    this.sleepLatencySec,
    this.wakeEventsCount,
    this.highSleepStressPct,
    this.noDataSec,
    this.sleepDebtSec,
    this.sleepNeedBaselineSec,
    this.sleepNeedFromStrainSec,
    this.sleepNeedFromNapSec,
    this.activityId,
    this.cycleId,
    required this.source,
    required this.isNap,
    required this.userEdited,
    this.startTsAdjusted,
    required this.hypnogramJson,
    required this.restlessnessJson,
    required this.sleepStateJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['bedtime_ts'] = Variable<int>(bedtimeTs);
    map['wake_ts'] = Variable<int>(wakeTs);
    map['in_bed_sec'] = Variable<int>(inBedSec);
    map['asleep_sec'] = Variable<int>(asleepSec);
    map['deep_sec'] = Variable<int>(deepSec);
    map['rem_sec'] = Variable<int>(remSec);
    map['light_sec'] = Variable<int>(lightSec);
    map['awake_sec'] = Variable<int>(awakeSec);
    map['efficiency'] = Variable<double>(efficiency);
    map['need_sec'] = Variable<int>(needSec);
    map['respiratory_rate'] = Variable<double>(respiratoryRate);
    map['disturbances'] = Variable<int>(disturbances);
    if (!nullToAbsent || restingHr != null) {
      map['resting_hr'] = Variable<double>(restingHr);
    }
    if (!nullToAbsent || avgHrv != null) {
      map['avg_hrv'] = Variable<double>(avgHrv);
    }
    if (!nullToAbsent || spo2 != null) {
      map['spo2'] = Variable<double>(spo2);
    }
    if (!nullToAbsent || skinTempDelta != null) {
      map['skin_temp_delta'] = Variable<double>(skinTempDelta);
    }
    if (!nullToAbsent || sleepPerformancePct != null) {
      map['sleep_performance_pct'] = Variable<int>(sleepPerformancePct);
    }
    if (!nullToAbsent || sleepConsistencyPct != null) {
      map['sleep_consistency_pct'] = Variable<int>(sleepConsistencyPct);
    }
    if (!nullToAbsent || hoursVsNeededPct != null) {
      map['hours_vs_needed_pct'] = Variable<int>(hoursVsNeededPct);
    }
    if (!nullToAbsent || restorativeSleepSec != null) {
      map['restorative_sleep_sec'] = Variable<int>(restorativeSleepSec);
    }
    if (!nullToAbsent || sleepLatencySec != null) {
      map['sleep_latency_sec'] = Variable<int>(sleepLatencySec);
    }
    if (!nullToAbsent || wakeEventsCount != null) {
      map['wake_events_count'] = Variable<int>(wakeEventsCount);
    }
    if (!nullToAbsent || highSleepStressPct != null) {
      map['high_sleep_stress_pct'] = Variable<int>(highSleepStressPct);
    }
    if (!nullToAbsent || noDataSec != null) {
      map['no_data_sec'] = Variable<int>(noDataSec);
    }
    if (!nullToAbsent || sleepDebtSec != null) {
      map['sleep_debt_sec'] = Variable<int>(sleepDebtSec);
    }
    if (!nullToAbsent || sleepNeedBaselineSec != null) {
      map['sleep_need_baseline_sec'] = Variable<int>(sleepNeedBaselineSec);
    }
    if (!nullToAbsent || sleepNeedFromStrainSec != null) {
      map['sleep_need_from_strain_sec'] = Variable<int>(sleepNeedFromStrainSec);
    }
    if (!nullToAbsent || sleepNeedFromNapSec != null) {
      map['sleep_need_from_nap_sec'] = Variable<int>(sleepNeedFromNapSec);
    }
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<String>(cycleId);
    }
    map['source'] = Variable<String>(source);
    map['is_nap'] = Variable<bool>(isNap);
    map['user_edited'] = Variable<bool>(userEdited);
    if (!nullToAbsent || startTsAdjusted != null) {
      map['start_ts_adjusted'] = Variable<int>(startTsAdjusted);
    }
    map['hypnogram_json'] = Variable<String>(hypnogramJson);
    map['restlessness_json'] = Variable<String>(restlessnessJson);
    map['sleep_state_json'] = Variable<String>(sleepStateJson);
    return map;
  }

  SleepSessionsCompanion toCompanion(bool nullToAbsent) {
    return SleepSessionsCompanion(
      day: Value(day),
      bedtimeTs: Value(bedtimeTs),
      wakeTs: Value(wakeTs),
      inBedSec: Value(inBedSec),
      asleepSec: Value(asleepSec),
      deepSec: Value(deepSec),
      remSec: Value(remSec),
      lightSec: Value(lightSec),
      awakeSec: Value(awakeSec),
      efficiency: Value(efficiency),
      needSec: Value(needSec),
      respiratoryRate: Value(respiratoryRate),
      disturbances: Value(disturbances),
      restingHr: restingHr == null && nullToAbsent
          ? const Value.absent()
          : Value(restingHr),
      avgHrv: avgHrv == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHrv),
      spo2: spo2 == null && nullToAbsent ? const Value.absent() : Value(spo2),
      skinTempDelta: skinTempDelta == null && nullToAbsent
          ? const Value.absent()
          : Value(skinTempDelta),
      sleepPerformancePct: sleepPerformancePct == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepPerformancePct),
      sleepConsistencyPct: sleepConsistencyPct == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepConsistencyPct),
      hoursVsNeededPct: hoursVsNeededPct == null && nullToAbsent
          ? const Value.absent()
          : Value(hoursVsNeededPct),
      restorativeSleepSec: restorativeSleepSec == null && nullToAbsent
          ? const Value.absent()
          : Value(restorativeSleepSec),
      sleepLatencySec: sleepLatencySec == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepLatencySec),
      wakeEventsCount: wakeEventsCount == null && nullToAbsent
          ? const Value.absent()
          : Value(wakeEventsCount),
      highSleepStressPct: highSleepStressPct == null && nullToAbsent
          ? const Value.absent()
          : Value(highSleepStressPct),
      noDataSec: noDataSec == null && nullToAbsent
          ? const Value.absent()
          : Value(noDataSec),
      sleepDebtSec: sleepDebtSec == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepDebtSec),
      sleepNeedBaselineSec: sleepNeedBaselineSec == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepNeedBaselineSec),
      sleepNeedFromStrainSec: sleepNeedFromStrainSec == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepNeedFromStrainSec),
      sleepNeedFromNapSec: sleepNeedFromNapSec == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepNeedFromNapSec),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
      source: Value(source),
      isNap: Value(isNap),
      userEdited: Value(userEdited),
      startTsAdjusted: startTsAdjusted == null && nullToAbsent
          ? const Value.absent()
          : Value(startTsAdjusted),
      hypnogramJson: Value(hypnogramJson),
      restlessnessJson: Value(restlessnessJson),
      sleepStateJson: Value(sleepStateJson),
    );
  }

  factory SleepSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepSession(
      day: serializer.fromJson<String>(json['day']),
      bedtimeTs: serializer.fromJson<int>(json['bedtimeTs']),
      wakeTs: serializer.fromJson<int>(json['wakeTs']),
      inBedSec: serializer.fromJson<int>(json['inBedSec']),
      asleepSec: serializer.fromJson<int>(json['asleepSec']),
      deepSec: serializer.fromJson<int>(json['deepSec']),
      remSec: serializer.fromJson<int>(json['remSec']),
      lightSec: serializer.fromJson<int>(json['lightSec']),
      awakeSec: serializer.fromJson<int>(json['awakeSec']),
      efficiency: serializer.fromJson<double>(json['efficiency']),
      needSec: serializer.fromJson<int>(json['needSec']),
      respiratoryRate: serializer.fromJson<double>(json['respiratoryRate']),
      disturbances: serializer.fromJson<int>(json['disturbances']),
      restingHr: serializer.fromJson<double?>(json['restingHr']),
      avgHrv: serializer.fromJson<double?>(json['avgHrv']),
      spo2: serializer.fromJson<double?>(json['spo2']),
      skinTempDelta: serializer.fromJson<double?>(json['skinTempDelta']),
      sleepPerformancePct: serializer.fromJson<int?>(
        json['sleepPerformancePct'],
      ),
      sleepConsistencyPct: serializer.fromJson<int?>(
        json['sleepConsistencyPct'],
      ),
      hoursVsNeededPct: serializer.fromJson<int?>(json['hoursVsNeededPct']),
      restorativeSleepSec: serializer.fromJson<int?>(
        json['restorativeSleepSec'],
      ),
      sleepLatencySec: serializer.fromJson<int?>(json['sleepLatencySec']),
      wakeEventsCount: serializer.fromJson<int?>(json['wakeEventsCount']),
      highSleepStressPct: serializer.fromJson<int?>(json['highSleepStressPct']),
      noDataSec: serializer.fromJson<int?>(json['noDataSec']),
      sleepDebtSec: serializer.fromJson<int?>(json['sleepDebtSec']),
      sleepNeedBaselineSec: serializer.fromJson<int?>(
        json['sleepNeedBaselineSec'],
      ),
      sleepNeedFromStrainSec: serializer.fromJson<int?>(
        json['sleepNeedFromStrainSec'],
      ),
      sleepNeedFromNapSec: serializer.fromJson<int?>(
        json['sleepNeedFromNapSec'],
      ),
      activityId: serializer.fromJson<String?>(json['activityId']),
      cycleId: serializer.fromJson<String?>(json['cycleId']),
      source: serializer.fromJson<String>(json['source']),
      isNap: serializer.fromJson<bool>(json['isNap']),
      userEdited: serializer.fromJson<bool>(json['userEdited']),
      startTsAdjusted: serializer.fromJson<int?>(json['startTsAdjusted']),
      hypnogramJson: serializer.fromJson<String>(json['hypnogramJson']),
      restlessnessJson: serializer.fromJson<String>(json['restlessnessJson']),
      sleepStateJson: serializer.fromJson<String>(json['sleepStateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'bedtimeTs': serializer.toJson<int>(bedtimeTs),
      'wakeTs': serializer.toJson<int>(wakeTs),
      'inBedSec': serializer.toJson<int>(inBedSec),
      'asleepSec': serializer.toJson<int>(asleepSec),
      'deepSec': serializer.toJson<int>(deepSec),
      'remSec': serializer.toJson<int>(remSec),
      'lightSec': serializer.toJson<int>(lightSec),
      'awakeSec': serializer.toJson<int>(awakeSec),
      'efficiency': serializer.toJson<double>(efficiency),
      'needSec': serializer.toJson<int>(needSec),
      'respiratoryRate': serializer.toJson<double>(respiratoryRate),
      'disturbances': serializer.toJson<int>(disturbances),
      'restingHr': serializer.toJson<double?>(restingHr),
      'avgHrv': serializer.toJson<double?>(avgHrv),
      'spo2': serializer.toJson<double?>(spo2),
      'skinTempDelta': serializer.toJson<double?>(skinTempDelta),
      'sleepPerformancePct': serializer.toJson<int?>(sleepPerformancePct),
      'sleepConsistencyPct': serializer.toJson<int?>(sleepConsistencyPct),
      'hoursVsNeededPct': serializer.toJson<int?>(hoursVsNeededPct),
      'restorativeSleepSec': serializer.toJson<int?>(restorativeSleepSec),
      'sleepLatencySec': serializer.toJson<int?>(sleepLatencySec),
      'wakeEventsCount': serializer.toJson<int?>(wakeEventsCount),
      'highSleepStressPct': serializer.toJson<int?>(highSleepStressPct),
      'noDataSec': serializer.toJson<int?>(noDataSec),
      'sleepDebtSec': serializer.toJson<int?>(sleepDebtSec),
      'sleepNeedBaselineSec': serializer.toJson<int?>(sleepNeedBaselineSec),
      'sleepNeedFromStrainSec': serializer.toJson<int?>(sleepNeedFromStrainSec),
      'sleepNeedFromNapSec': serializer.toJson<int?>(sleepNeedFromNapSec),
      'activityId': serializer.toJson<String?>(activityId),
      'cycleId': serializer.toJson<String?>(cycleId),
      'source': serializer.toJson<String>(source),
      'isNap': serializer.toJson<bool>(isNap),
      'userEdited': serializer.toJson<bool>(userEdited),
      'startTsAdjusted': serializer.toJson<int?>(startTsAdjusted),
      'hypnogramJson': serializer.toJson<String>(hypnogramJson),
      'restlessnessJson': serializer.toJson<String>(restlessnessJson),
      'sleepStateJson': serializer.toJson<String>(sleepStateJson),
    };
  }

  SleepSession copyWith({
    String? day,
    int? bedtimeTs,
    int? wakeTs,
    int? inBedSec,
    int? asleepSec,
    int? deepSec,
    int? remSec,
    int? lightSec,
    int? awakeSec,
    double? efficiency,
    int? needSec,
    double? respiratoryRate,
    int? disturbances,
    Value<double?> restingHr = const Value.absent(),
    Value<double?> avgHrv = const Value.absent(),
    Value<double?> spo2 = const Value.absent(),
    Value<double?> skinTempDelta = const Value.absent(),
    Value<int?> sleepPerformancePct = const Value.absent(),
    Value<int?> sleepConsistencyPct = const Value.absent(),
    Value<int?> hoursVsNeededPct = const Value.absent(),
    Value<int?> restorativeSleepSec = const Value.absent(),
    Value<int?> sleepLatencySec = const Value.absent(),
    Value<int?> wakeEventsCount = const Value.absent(),
    Value<int?> highSleepStressPct = const Value.absent(),
    Value<int?> noDataSec = const Value.absent(),
    Value<int?> sleepDebtSec = const Value.absent(),
    Value<int?> sleepNeedBaselineSec = const Value.absent(),
    Value<int?> sleepNeedFromStrainSec = const Value.absent(),
    Value<int?> sleepNeedFromNapSec = const Value.absent(),
    Value<String?> activityId = const Value.absent(),
    Value<String?> cycleId = const Value.absent(),
    String? source,
    bool? isNap,
    bool? userEdited,
    Value<int?> startTsAdjusted = const Value.absent(),
    String? hypnogramJson,
    String? restlessnessJson,
    String? sleepStateJson,
  }) => SleepSession(
    day: day ?? this.day,
    bedtimeTs: bedtimeTs ?? this.bedtimeTs,
    wakeTs: wakeTs ?? this.wakeTs,
    inBedSec: inBedSec ?? this.inBedSec,
    asleepSec: asleepSec ?? this.asleepSec,
    deepSec: deepSec ?? this.deepSec,
    remSec: remSec ?? this.remSec,
    lightSec: lightSec ?? this.lightSec,
    awakeSec: awakeSec ?? this.awakeSec,
    efficiency: efficiency ?? this.efficiency,
    needSec: needSec ?? this.needSec,
    respiratoryRate: respiratoryRate ?? this.respiratoryRate,
    disturbances: disturbances ?? this.disturbances,
    restingHr: restingHr.present ? restingHr.value : this.restingHr,
    avgHrv: avgHrv.present ? avgHrv.value : this.avgHrv,
    spo2: spo2.present ? spo2.value : this.spo2,
    skinTempDelta: skinTempDelta.present
        ? skinTempDelta.value
        : this.skinTempDelta,
    sleepPerformancePct: sleepPerformancePct.present
        ? sleepPerformancePct.value
        : this.sleepPerformancePct,
    sleepConsistencyPct: sleepConsistencyPct.present
        ? sleepConsistencyPct.value
        : this.sleepConsistencyPct,
    hoursVsNeededPct: hoursVsNeededPct.present
        ? hoursVsNeededPct.value
        : this.hoursVsNeededPct,
    restorativeSleepSec: restorativeSleepSec.present
        ? restorativeSleepSec.value
        : this.restorativeSleepSec,
    sleepLatencySec: sleepLatencySec.present
        ? sleepLatencySec.value
        : this.sleepLatencySec,
    wakeEventsCount: wakeEventsCount.present
        ? wakeEventsCount.value
        : this.wakeEventsCount,
    highSleepStressPct: highSleepStressPct.present
        ? highSleepStressPct.value
        : this.highSleepStressPct,
    noDataSec: noDataSec.present ? noDataSec.value : this.noDataSec,
    sleepDebtSec: sleepDebtSec.present ? sleepDebtSec.value : this.sleepDebtSec,
    sleepNeedBaselineSec: sleepNeedBaselineSec.present
        ? sleepNeedBaselineSec.value
        : this.sleepNeedBaselineSec,
    sleepNeedFromStrainSec: sleepNeedFromStrainSec.present
        ? sleepNeedFromStrainSec.value
        : this.sleepNeedFromStrainSec,
    sleepNeedFromNapSec: sleepNeedFromNapSec.present
        ? sleepNeedFromNapSec.value
        : this.sleepNeedFromNapSec,
    activityId: activityId.present ? activityId.value : this.activityId,
    cycleId: cycleId.present ? cycleId.value : this.cycleId,
    source: source ?? this.source,
    isNap: isNap ?? this.isNap,
    userEdited: userEdited ?? this.userEdited,
    startTsAdjusted: startTsAdjusted.present
        ? startTsAdjusted.value
        : this.startTsAdjusted,
    hypnogramJson: hypnogramJson ?? this.hypnogramJson,
    restlessnessJson: restlessnessJson ?? this.restlessnessJson,
    sleepStateJson: sleepStateJson ?? this.sleepStateJson,
  );
  SleepSession copyWithCompanion(SleepSessionsCompanion data) {
    return SleepSession(
      day: data.day.present ? data.day.value : this.day,
      bedtimeTs: data.bedtimeTs.present ? data.bedtimeTs.value : this.bedtimeTs,
      wakeTs: data.wakeTs.present ? data.wakeTs.value : this.wakeTs,
      inBedSec: data.inBedSec.present ? data.inBedSec.value : this.inBedSec,
      asleepSec: data.asleepSec.present ? data.asleepSec.value : this.asleepSec,
      deepSec: data.deepSec.present ? data.deepSec.value : this.deepSec,
      remSec: data.remSec.present ? data.remSec.value : this.remSec,
      lightSec: data.lightSec.present ? data.lightSec.value : this.lightSec,
      awakeSec: data.awakeSec.present ? data.awakeSec.value : this.awakeSec,
      efficiency: data.efficiency.present
          ? data.efficiency.value
          : this.efficiency,
      needSec: data.needSec.present ? data.needSec.value : this.needSec,
      respiratoryRate: data.respiratoryRate.present
          ? data.respiratoryRate.value
          : this.respiratoryRate,
      disturbances: data.disturbances.present
          ? data.disturbances.value
          : this.disturbances,
      restingHr: data.restingHr.present ? data.restingHr.value : this.restingHr,
      avgHrv: data.avgHrv.present ? data.avgHrv.value : this.avgHrv,
      spo2: data.spo2.present ? data.spo2.value : this.spo2,
      skinTempDelta: data.skinTempDelta.present
          ? data.skinTempDelta.value
          : this.skinTempDelta,
      sleepPerformancePct: data.sleepPerformancePct.present
          ? data.sleepPerformancePct.value
          : this.sleepPerformancePct,
      sleepConsistencyPct: data.sleepConsistencyPct.present
          ? data.sleepConsistencyPct.value
          : this.sleepConsistencyPct,
      hoursVsNeededPct: data.hoursVsNeededPct.present
          ? data.hoursVsNeededPct.value
          : this.hoursVsNeededPct,
      restorativeSleepSec: data.restorativeSleepSec.present
          ? data.restorativeSleepSec.value
          : this.restorativeSleepSec,
      sleepLatencySec: data.sleepLatencySec.present
          ? data.sleepLatencySec.value
          : this.sleepLatencySec,
      wakeEventsCount: data.wakeEventsCount.present
          ? data.wakeEventsCount.value
          : this.wakeEventsCount,
      highSleepStressPct: data.highSleepStressPct.present
          ? data.highSleepStressPct.value
          : this.highSleepStressPct,
      noDataSec: data.noDataSec.present ? data.noDataSec.value : this.noDataSec,
      sleepDebtSec: data.sleepDebtSec.present
          ? data.sleepDebtSec.value
          : this.sleepDebtSec,
      sleepNeedBaselineSec: data.sleepNeedBaselineSec.present
          ? data.sleepNeedBaselineSec.value
          : this.sleepNeedBaselineSec,
      sleepNeedFromStrainSec: data.sleepNeedFromStrainSec.present
          ? data.sleepNeedFromStrainSec.value
          : this.sleepNeedFromStrainSec,
      sleepNeedFromNapSec: data.sleepNeedFromNapSec.present
          ? data.sleepNeedFromNapSec.value
          : this.sleepNeedFromNapSec,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      source: data.source.present ? data.source.value : this.source,
      isNap: data.isNap.present ? data.isNap.value : this.isNap,
      userEdited: data.userEdited.present
          ? data.userEdited.value
          : this.userEdited,
      startTsAdjusted: data.startTsAdjusted.present
          ? data.startTsAdjusted.value
          : this.startTsAdjusted,
      hypnogramJson: data.hypnogramJson.present
          ? data.hypnogramJson.value
          : this.hypnogramJson,
      restlessnessJson: data.restlessnessJson.present
          ? data.restlessnessJson.value
          : this.restlessnessJson,
      sleepStateJson: data.sleepStateJson.present
          ? data.sleepStateJson.value
          : this.sleepStateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepSession(')
          ..write('day: $day, ')
          ..write('bedtimeTs: $bedtimeTs, ')
          ..write('wakeTs: $wakeTs, ')
          ..write('inBedSec: $inBedSec, ')
          ..write('asleepSec: $asleepSec, ')
          ..write('deepSec: $deepSec, ')
          ..write('remSec: $remSec, ')
          ..write('lightSec: $lightSec, ')
          ..write('awakeSec: $awakeSec, ')
          ..write('efficiency: $efficiency, ')
          ..write('needSec: $needSec, ')
          ..write('respiratoryRate: $respiratoryRate, ')
          ..write('disturbances: $disturbances, ')
          ..write('restingHr: $restingHr, ')
          ..write('avgHrv: $avgHrv, ')
          ..write('spo2: $spo2, ')
          ..write('skinTempDelta: $skinTempDelta, ')
          ..write('sleepPerformancePct: $sleepPerformancePct, ')
          ..write('sleepConsistencyPct: $sleepConsistencyPct, ')
          ..write('hoursVsNeededPct: $hoursVsNeededPct, ')
          ..write('restorativeSleepSec: $restorativeSleepSec, ')
          ..write('sleepLatencySec: $sleepLatencySec, ')
          ..write('wakeEventsCount: $wakeEventsCount, ')
          ..write('highSleepStressPct: $highSleepStressPct, ')
          ..write('noDataSec: $noDataSec, ')
          ..write('sleepDebtSec: $sleepDebtSec, ')
          ..write('sleepNeedBaselineSec: $sleepNeedBaselineSec, ')
          ..write('sleepNeedFromStrainSec: $sleepNeedFromStrainSec, ')
          ..write('sleepNeedFromNapSec: $sleepNeedFromNapSec, ')
          ..write('activityId: $activityId, ')
          ..write('cycleId: $cycleId, ')
          ..write('source: $source, ')
          ..write('isNap: $isNap, ')
          ..write('userEdited: $userEdited, ')
          ..write('startTsAdjusted: $startTsAdjusted, ')
          ..write('hypnogramJson: $hypnogramJson, ')
          ..write('restlessnessJson: $restlessnessJson, ')
          ..write('sleepStateJson: $sleepStateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    day,
    bedtimeTs,
    wakeTs,
    inBedSec,
    asleepSec,
    deepSec,
    remSec,
    lightSec,
    awakeSec,
    efficiency,
    needSec,
    respiratoryRate,
    disturbances,
    restingHr,
    avgHrv,
    spo2,
    skinTempDelta,
    sleepPerformancePct,
    sleepConsistencyPct,
    hoursVsNeededPct,
    restorativeSleepSec,
    sleepLatencySec,
    wakeEventsCount,
    highSleepStressPct,
    noDataSec,
    sleepDebtSec,
    sleepNeedBaselineSec,
    sleepNeedFromStrainSec,
    sleepNeedFromNapSec,
    activityId,
    cycleId,
    source,
    isNap,
    userEdited,
    startTsAdjusted,
    hypnogramJson,
    restlessnessJson,
    sleepStateJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepSession &&
          other.day == this.day &&
          other.bedtimeTs == this.bedtimeTs &&
          other.wakeTs == this.wakeTs &&
          other.inBedSec == this.inBedSec &&
          other.asleepSec == this.asleepSec &&
          other.deepSec == this.deepSec &&
          other.remSec == this.remSec &&
          other.lightSec == this.lightSec &&
          other.awakeSec == this.awakeSec &&
          other.efficiency == this.efficiency &&
          other.needSec == this.needSec &&
          other.respiratoryRate == this.respiratoryRate &&
          other.disturbances == this.disturbances &&
          other.restingHr == this.restingHr &&
          other.avgHrv == this.avgHrv &&
          other.spo2 == this.spo2 &&
          other.skinTempDelta == this.skinTempDelta &&
          other.sleepPerformancePct == this.sleepPerformancePct &&
          other.sleepConsistencyPct == this.sleepConsistencyPct &&
          other.hoursVsNeededPct == this.hoursVsNeededPct &&
          other.restorativeSleepSec == this.restorativeSleepSec &&
          other.sleepLatencySec == this.sleepLatencySec &&
          other.wakeEventsCount == this.wakeEventsCount &&
          other.highSleepStressPct == this.highSleepStressPct &&
          other.noDataSec == this.noDataSec &&
          other.sleepDebtSec == this.sleepDebtSec &&
          other.sleepNeedBaselineSec == this.sleepNeedBaselineSec &&
          other.sleepNeedFromStrainSec == this.sleepNeedFromStrainSec &&
          other.sleepNeedFromNapSec == this.sleepNeedFromNapSec &&
          other.activityId == this.activityId &&
          other.cycleId == this.cycleId &&
          other.source == this.source &&
          other.isNap == this.isNap &&
          other.userEdited == this.userEdited &&
          other.startTsAdjusted == this.startTsAdjusted &&
          other.hypnogramJson == this.hypnogramJson &&
          other.restlessnessJson == this.restlessnessJson &&
          other.sleepStateJson == this.sleepStateJson);
}

class SleepSessionsCompanion extends UpdateCompanion<SleepSession> {
  final Value<String> day;
  final Value<int> bedtimeTs;
  final Value<int> wakeTs;
  final Value<int> inBedSec;
  final Value<int> asleepSec;
  final Value<int> deepSec;
  final Value<int> remSec;
  final Value<int> lightSec;
  final Value<int> awakeSec;
  final Value<double> efficiency;
  final Value<int> needSec;
  final Value<double> respiratoryRate;
  final Value<int> disturbances;
  final Value<double?> restingHr;
  final Value<double?> avgHrv;
  final Value<double?> spo2;
  final Value<double?> skinTempDelta;
  final Value<int?> sleepPerformancePct;
  final Value<int?> sleepConsistencyPct;
  final Value<int?> hoursVsNeededPct;
  final Value<int?> restorativeSleepSec;
  final Value<int?> sleepLatencySec;
  final Value<int?> wakeEventsCount;
  final Value<int?> highSleepStressPct;
  final Value<int?> noDataSec;
  final Value<int?> sleepDebtSec;
  final Value<int?> sleepNeedBaselineSec;
  final Value<int?> sleepNeedFromStrainSec;
  final Value<int?> sleepNeedFromNapSec;
  final Value<String?> activityId;
  final Value<String?> cycleId;
  final Value<String> source;
  final Value<bool> isNap;
  final Value<bool> userEdited;
  final Value<int?> startTsAdjusted;
  final Value<String> hypnogramJson;
  final Value<String> restlessnessJson;
  final Value<String> sleepStateJson;
  final Value<int> rowid;
  const SleepSessionsCompanion({
    this.day = const Value.absent(),
    this.bedtimeTs = const Value.absent(),
    this.wakeTs = const Value.absent(),
    this.inBedSec = const Value.absent(),
    this.asleepSec = const Value.absent(),
    this.deepSec = const Value.absent(),
    this.remSec = const Value.absent(),
    this.lightSec = const Value.absent(),
    this.awakeSec = const Value.absent(),
    this.efficiency = const Value.absent(),
    this.needSec = const Value.absent(),
    this.respiratoryRate = const Value.absent(),
    this.disturbances = const Value.absent(),
    this.restingHr = const Value.absent(),
    this.avgHrv = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.skinTempDelta = const Value.absent(),
    this.sleepPerformancePct = const Value.absent(),
    this.sleepConsistencyPct = const Value.absent(),
    this.hoursVsNeededPct = const Value.absent(),
    this.restorativeSleepSec = const Value.absent(),
    this.sleepLatencySec = const Value.absent(),
    this.wakeEventsCount = const Value.absent(),
    this.highSleepStressPct = const Value.absent(),
    this.noDataSec = const Value.absent(),
    this.sleepDebtSec = const Value.absent(),
    this.sleepNeedBaselineSec = const Value.absent(),
    this.sleepNeedFromStrainSec = const Value.absent(),
    this.sleepNeedFromNapSec = const Value.absent(),
    this.activityId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.source = const Value.absent(),
    this.isNap = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.startTsAdjusted = const Value.absent(),
    this.hypnogramJson = const Value.absent(),
    this.restlessnessJson = const Value.absent(),
    this.sleepStateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SleepSessionsCompanion.insert({
    required String day,
    required int bedtimeTs,
    required int wakeTs,
    required int inBedSec,
    required int asleepSec,
    required int deepSec,
    required int remSec,
    required int lightSec,
    required int awakeSec,
    required double efficiency,
    this.needSec = const Value.absent(),
    this.respiratoryRate = const Value.absent(),
    this.disturbances = const Value.absent(),
    this.restingHr = const Value.absent(),
    this.avgHrv = const Value.absent(),
    this.spo2 = const Value.absent(),
    this.skinTempDelta = const Value.absent(),
    this.sleepPerformancePct = const Value.absent(),
    this.sleepConsistencyPct = const Value.absent(),
    this.hoursVsNeededPct = const Value.absent(),
    this.restorativeSleepSec = const Value.absent(),
    this.sleepLatencySec = const Value.absent(),
    this.wakeEventsCount = const Value.absent(),
    this.highSleepStressPct = const Value.absent(),
    this.noDataSec = const Value.absent(),
    this.sleepDebtSec = const Value.absent(),
    this.sleepNeedBaselineSec = const Value.absent(),
    this.sleepNeedFromStrainSec = const Value.absent(),
    this.sleepNeedFromNapSec = const Value.absent(),
    this.activityId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.source = const Value.absent(),
    this.isNap = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.startTsAdjusted = const Value.absent(),
    this.hypnogramJson = const Value.absent(),
    this.restlessnessJson = const Value.absent(),
    this.sleepStateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       bedtimeTs = Value(bedtimeTs),
       wakeTs = Value(wakeTs),
       inBedSec = Value(inBedSec),
       asleepSec = Value(asleepSec),
       deepSec = Value(deepSec),
       remSec = Value(remSec),
       lightSec = Value(lightSec),
       awakeSec = Value(awakeSec),
       efficiency = Value(efficiency);
  static Insertable<SleepSession> custom({
    Expression<String>? day,
    Expression<int>? bedtimeTs,
    Expression<int>? wakeTs,
    Expression<int>? inBedSec,
    Expression<int>? asleepSec,
    Expression<int>? deepSec,
    Expression<int>? remSec,
    Expression<int>? lightSec,
    Expression<int>? awakeSec,
    Expression<double>? efficiency,
    Expression<int>? needSec,
    Expression<double>? respiratoryRate,
    Expression<int>? disturbances,
    Expression<double>? restingHr,
    Expression<double>? avgHrv,
    Expression<double>? spo2,
    Expression<double>? skinTempDelta,
    Expression<int>? sleepPerformancePct,
    Expression<int>? sleepConsistencyPct,
    Expression<int>? hoursVsNeededPct,
    Expression<int>? restorativeSleepSec,
    Expression<int>? sleepLatencySec,
    Expression<int>? wakeEventsCount,
    Expression<int>? highSleepStressPct,
    Expression<int>? noDataSec,
    Expression<int>? sleepDebtSec,
    Expression<int>? sleepNeedBaselineSec,
    Expression<int>? sleepNeedFromStrainSec,
    Expression<int>? sleepNeedFromNapSec,
    Expression<String>? activityId,
    Expression<String>? cycleId,
    Expression<String>? source,
    Expression<bool>? isNap,
    Expression<bool>? userEdited,
    Expression<int>? startTsAdjusted,
    Expression<String>? hypnogramJson,
    Expression<String>? restlessnessJson,
    Expression<String>? sleepStateJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (bedtimeTs != null) 'bedtime_ts': bedtimeTs,
      if (wakeTs != null) 'wake_ts': wakeTs,
      if (inBedSec != null) 'in_bed_sec': inBedSec,
      if (asleepSec != null) 'asleep_sec': asleepSec,
      if (deepSec != null) 'deep_sec': deepSec,
      if (remSec != null) 'rem_sec': remSec,
      if (lightSec != null) 'light_sec': lightSec,
      if (awakeSec != null) 'awake_sec': awakeSec,
      if (efficiency != null) 'efficiency': efficiency,
      if (needSec != null) 'need_sec': needSec,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (disturbances != null) 'disturbances': disturbances,
      if (restingHr != null) 'resting_hr': restingHr,
      if (avgHrv != null) 'avg_hrv': avgHrv,
      if (spo2 != null) 'spo2': spo2,
      if (skinTempDelta != null) 'skin_temp_delta': skinTempDelta,
      if (sleepPerformancePct != null)
        'sleep_performance_pct': sleepPerformancePct,
      if (sleepConsistencyPct != null)
        'sleep_consistency_pct': sleepConsistencyPct,
      if (hoursVsNeededPct != null) 'hours_vs_needed_pct': hoursVsNeededPct,
      if (restorativeSleepSec != null)
        'restorative_sleep_sec': restorativeSleepSec,
      if (sleepLatencySec != null) 'sleep_latency_sec': sleepLatencySec,
      if (wakeEventsCount != null) 'wake_events_count': wakeEventsCount,
      if (highSleepStressPct != null)
        'high_sleep_stress_pct': highSleepStressPct,
      if (noDataSec != null) 'no_data_sec': noDataSec,
      if (sleepDebtSec != null) 'sleep_debt_sec': sleepDebtSec,
      if (sleepNeedBaselineSec != null)
        'sleep_need_baseline_sec': sleepNeedBaselineSec,
      if (sleepNeedFromStrainSec != null)
        'sleep_need_from_strain_sec': sleepNeedFromStrainSec,
      if (sleepNeedFromNapSec != null)
        'sleep_need_from_nap_sec': sleepNeedFromNapSec,
      if (activityId != null) 'activity_id': activityId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (source != null) 'source': source,
      if (isNap != null) 'is_nap': isNap,
      if (userEdited != null) 'user_edited': userEdited,
      if (startTsAdjusted != null) 'start_ts_adjusted': startTsAdjusted,
      if (hypnogramJson != null) 'hypnogram_json': hypnogramJson,
      if (restlessnessJson != null) 'restlessness_json': restlessnessJson,
      if (sleepStateJson != null) 'sleep_state_json': sleepStateJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SleepSessionsCompanion copyWith({
    Value<String>? day,
    Value<int>? bedtimeTs,
    Value<int>? wakeTs,
    Value<int>? inBedSec,
    Value<int>? asleepSec,
    Value<int>? deepSec,
    Value<int>? remSec,
    Value<int>? lightSec,
    Value<int>? awakeSec,
    Value<double>? efficiency,
    Value<int>? needSec,
    Value<double>? respiratoryRate,
    Value<int>? disturbances,
    Value<double?>? restingHr,
    Value<double?>? avgHrv,
    Value<double?>? spo2,
    Value<double?>? skinTempDelta,
    Value<int?>? sleepPerformancePct,
    Value<int?>? sleepConsistencyPct,
    Value<int?>? hoursVsNeededPct,
    Value<int?>? restorativeSleepSec,
    Value<int?>? sleepLatencySec,
    Value<int?>? wakeEventsCount,
    Value<int?>? highSleepStressPct,
    Value<int?>? noDataSec,
    Value<int?>? sleepDebtSec,
    Value<int?>? sleepNeedBaselineSec,
    Value<int?>? sleepNeedFromStrainSec,
    Value<int?>? sleepNeedFromNapSec,
    Value<String?>? activityId,
    Value<String?>? cycleId,
    Value<String>? source,
    Value<bool>? isNap,
    Value<bool>? userEdited,
    Value<int?>? startTsAdjusted,
    Value<String>? hypnogramJson,
    Value<String>? restlessnessJson,
    Value<String>? sleepStateJson,
    Value<int>? rowid,
  }) {
    return SleepSessionsCompanion(
      day: day ?? this.day,
      bedtimeTs: bedtimeTs ?? this.bedtimeTs,
      wakeTs: wakeTs ?? this.wakeTs,
      inBedSec: inBedSec ?? this.inBedSec,
      asleepSec: asleepSec ?? this.asleepSec,
      deepSec: deepSec ?? this.deepSec,
      remSec: remSec ?? this.remSec,
      lightSec: lightSec ?? this.lightSec,
      awakeSec: awakeSec ?? this.awakeSec,
      efficiency: efficiency ?? this.efficiency,
      needSec: needSec ?? this.needSec,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      disturbances: disturbances ?? this.disturbances,
      restingHr: restingHr ?? this.restingHr,
      avgHrv: avgHrv ?? this.avgHrv,
      spo2: spo2 ?? this.spo2,
      skinTempDelta: skinTempDelta ?? this.skinTempDelta,
      sleepPerformancePct: sleepPerformancePct ?? this.sleepPerformancePct,
      sleepConsistencyPct: sleepConsistencyPct ?? this.sleepConsistencyPct,
      hoursVsNeededPct: hoursVsNeededPct ?? this.hoursVsNeededPct,
      restorativeSleepSec: restorativeSleepSec ?? this.restorativeSleepSec,
      sleepLatencySec: sleepLatencySec ?? this.sleepLatencySec,
      wakeEventsCount: wakeEventsCount ?? this.wakeEventsCount,
      highSleepStressPct: highSleepStressPct ?? this.highSleepStressPct,
      noDataSec: noDataSec ?? this.noDataSec,
      sleepDebtSec: sleepDebtSec ?? this.sleepDebtSec,
      sleepNeedBaselineSec: sleepNeedBaselineSec ?? this.sleepNeedBaselineSec,
      sleepNeedFromStrainSec:
          sleepNeedFromStrainSec ?? this.sleepNeedFromStrainSec,
      sleepNeedFromNapSec: sleepNeedFromNapSec ?? this.sleepNeedFromNapSec,
      activityId: activityId ?? this.activityId,
      cycleId: cycleId ?? this.cycleId,
      source: source ?? this.source,
      isNap: isNap ?? this.isNap,
      userEdited: userEdited ?? this.userEdited,
      startTsAdjusted: startTsAdjusted ?? this.startTsAdjusted,
      hypnogramJson: hypnogramJson ?? this.hypnogramJson,
      restlessnessJson: restlessnessJson ?? this.restlessnessJson,
      sleepStateJson: sleepStateJson ?? this.sleepStateJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (bedtimeTs.present) {
      map['bedtime_ts'] = Variable<int>(bedtimeTs.value);
    }
    if (wakeTs.present) {
      map['wake_ts'] = Variable<int>(wakeTs.value);
    }
    if (inBedSec.present) {
      map['in_bed_sec'] = Variable<int>(inBedSec.value);
    }
    if (asleepSec.present) {
      map['asleep_sec'] = Variable<int>(asleepSec.value);
    }
    if (deepSec.present) {
      map['deep_sec'] = Variable<int>(deepSec.value);
    }
    if (remSec.present) {
      map['rem_sec'] = Variable<int>(remSec.value);
    }
    if (lightSec.present) {
      map['light_sec'] = Variable<int>(lightSec.value);
    }
    if (awakeSec.present) {
      map['awake_sec'] = Variable<int>(awakeSec.value);
    }
    if (efficiency.present) {
      map['efficiency'] = Variable<double>(efficiency.value);
    }
    if (needSec.present) {
      map['need_sec'] = Variable<int>(needSec.value);
    }
    if (respiratoryRate.present) {
      map['respiratory_rate'] = Variable<double>(respiratoryRate.value);
    }
    if (disturbances.present) {
      map['disturbances'] = Variable<int>(disturbances.value);
    }
    if (restingHr.present) {
      map['resting_hr'] = Variable<double>(restingHr.value);
    }
    if (avgHrv.present) {
      map['avg_hrv'] = Variable<double>(avgHrv.value);
    }
    if (spo2.present) {
      map['spo2'] = Variable<double>(spo2.value);
    }
    if (skinTempDelta.present) {
      map['skin_temp_delta'] = Variable<double>(skinTempDelta.value);
    }
    if (sleepPerformancePct.present) {
      map['sleep_performance_pct'] = Variable<int>(sleepPerformancePct.value);
    }
    if (sleepConsistencyPct.present) {
      map['sleep_consistency_pct'] = Variable<int>(sleepConsistencyPct.value);
    }
    if (hoursVsNeededPct.present) {
      map['hours_vs_needed_pct'] = Variable<int>(hoursVsNeededPct.value);
    }
    if (restorativeSleepSec.present) {
      map['restorative_sleep_sec'] = Variable<int>(restorativeSleepSec.value);
    }
    if (sleepLatencySec.present) {
      map['sleep_latency_sec'] = Variable<int>(sleepLatencySec.value);
    }
    if (wakeEventsCount.present) {
      map['wake_events_count'] = Variable<int>(wakeEventsCount.value);
    }
    if (highSleepStressPct.present) {
      map['high_sleep_stress_pct'] = Variable<int>(highSleepStressPct.value);
    }
    if (noDataSec.present) {
      map['no_data_sec'] = Variable<int>(noDataSec.value);
    }
    if (sleepDebtSec.present) {
      map['sleep_debt_sec'] = Variable<int>(sleepDebtSec.value);
    }
    if (sleepNeedBaselineSec.present) {
      map['sleep_need_baseline_sec'] = Variable<int>(
        sleepNeedBaselineSec.value,
      );
    }
    if (sleepNeedFromStrainSec.present) {
      map['sleep_need_from_strain_sec'] = Variable<int>(
        sleepNeedFromStrainSec.value,
      );
    }
    if (sleepNeedFromNapSec.present) {
      map['sleep_need_from_nap_sec'] = Variable<int>(sleepNeedFromNapSec.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isNap.present) {
      map['is_nap'] = Variable<bool>(isNap.value);
    }
    if (userEdited.present) {
      map['user_edited'] = Variable<bool>(userEdited.value);
    }
    if (startTsAdjusted.present) {
      map['start_ts_adjusted'] = Variable<int>(startTsAdjusted.value);
    }
    if (hypnogramJson.present) {
      map['hypnogram_json'] = Variable<String>(hypnogramJson.value);
    }
    if (restlessnessJson.present) {
      map['restlessness_json'] = Variable<String>(restlessnessJson.value);
    }
    if (sleepStateJson.present) {
      map['sleep_state_json'] = Variable<String>(sleepStateJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepSessionsCompanion(')
          ..write('day: $day, ')
          ..write('bedtimeTs: $bedtimeTs, ')
          ..write('wakeTs: $wakeTs, ')
          ..write('inBedSec: $inBedSec, ')
          ..write('asleepSec: $asleepSec, ')
          ..write('deepSec: $deepSec, ')
          ..write('remSec: $remSec, ')
          ..write('lightSec: $lightSec, ')
          ..write('awakeSec: $awakeSec, ')
          ..write('efficiency: $efficiency, ')
          ..write('needSec: $needSec, ')
          ..write('respiratoryRate: $respiratoryRate, ')
          ..write('disturbances: $disturbances, ')
          ..write('restingHr: $restingHr, ')
          ..write('avgHrv: $avgHrv, ')
          ..write('spo2: $spo2, ')
          ..write('skinTempDelta: $skinTempDelta, ')
          ..write('sleepPerformancePct: $sleepPerformancePct, ')
          ..write('sleepConsistencyPct: $sleepConsistencyPct, ')
          ..write('hoursVsNeededPct: $hoursVsNeededPct, ')
          ..write('restorativeSleepSec: $restorativeSleepSec, ')
          ..write('sleepLatencySec: $sleepLatencySec, ')
          ..write('wakeEventsCount: $wakeEventsCount, ')
          ..write('highSleepStressPct: $highSleepStressPct, ')
          ..write('noDataSec: $noDataSec, ')
          ..write('sleepDebtSec: $sleepDebtSec, ')
          ..write('sleepNeedBaselineSec: $sleepNeedBaselineSec, ')
          ..write('sleepNeedFromStrainSec: $sleepNeedFromStrainSec, ')
          ..write('sleepNeedFromNapSec: $sleepNeedFromNapSec, ')
          ..write('activityId: $activityId, ')
          ..write('cycleId: $cycleId, ')
          ..write('source: $source, ')
          ..write('isNap: $isNap, ')
          ..write('userEdited: $userEdited, ')
          ..write('startTsAdjusted: $startTsAdjusted, ')
          ..write('hypnogramJson: $hypnogramJson, ')
          ..write('restlessnessJson: $restlessnessJson, ')
          ..write('sleepStateJson: $sleepStateJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SleepStateSamplesTable extends SleepStateSamples
    with TableInfo<$SleepStateSamplesTable, SleepStateSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepStateSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('whoop'),
  );
  @override
  List<GeneratedColumn> get $columns => [ts, state, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_state_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<SleepStateSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ts};
  @override
  SleepStateSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepStateSample(
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $SleepStateSamplesTable createAlias(String alias) {
    return $SleepStateSamplesTable(attachedDatabase, alias);
  }
}

class SleepStateSample extends DataClass
    implements Insertable<SleepStateSample> {
  final int ts;
  final int state;
  final String source;
  const SleepStateSample({
    required this.ts,
    required this.state,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts'] = Variable<int>(ts);
    map['state'] = Variable<int>(state);
    map['source'] = Variable<String>(source);
    return map;
  }

  SleepStateSamplesCompanion toCompanion(bool nullToAbsent) {
    return SleepStateSamplesCompanion(
      ts: Value(ts),
      state: Value(state),
      source: Value(source),
    );
  }

  factory SleepStateSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepStateSample(
      ts: serializer.fromJson<int>(json['ts']),
      state: serializer.fromJson<int>(json['state']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ts': serializer.toJson<int>(ts),
      'state': serializer.toJson<int>(state),
      'source': serializer.toJson<String>(source),
    };
  }

  SleepStateSample copyWith({int? ts, int? state, String? source}) =>
      SleepStateSample(
        ts: ts ?? this.ts,
        state: state ?? this.state,
        source: source ?? this.source,
      );
  SleepStateSample copyWithCompanion(SleepStateSamplesCompanion data) {
    return SleepStateSample(
      ts: data.ts.present ? data.ts.value : this.ts,
      state: data.state.present ? data.state.value : this.state,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepStateSample(')
          ..write('ts: $ts, ')
          ..write('state: $state, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ts, state, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepStateSample &&
          other.ts == this.ts &&
          other.state == this.state &&
          other.source == this.source);
}

class SleepStateSamplesCompanion extends UpdateCompanion<SleepStateSample> {
  final Value<int> ts;
  final Value<int> state;
  final Value<String> source;
  const SleepStateSamplesCompanion({
    this.ts = const Value.absent(),
    this.state = const Value.absent(),
    this.source = const Value.absent(),
  });
  SleepStateSamplesCompanion.insert({
    this.ts = const Value.absent(),
    required int state,
    this.source = const Value.absent(),
  }) : state = Value(state);
  static Insertable<SleepStateSample> custom({
    Expression<int>? ts,
    Expression<int>? state,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (ts != null) 'ts': ts,
      if (state != null) 'state': state,
      if (source != null) 'source': source,
    });
  }

  SleepStateSamplesCompanion copyWith({
    Value<int>? ts,
    Value<int>? state,
    Value<String>? source,
  }) {
    return SleepStateSamplesCompanion(
      ts: ts ?? this.ts,
      state: state ?? this.state,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepStateSamplesCompanion(')
          ..write('ts: $ts, ')
          ..write('state: $state, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sportIdMeta = const VerificationMeta(
    'sportId',
  );
  @override
  late final GeneratedColumn<int> sportId = GeneratedColumn<int>(
    'sport_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTsMeta = const VerificationMeta(
    'startTs',
  );
  @override
  late final GeneratedColumn<int> startTs = GeneratedColumn<int>(
    'start_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<double> avgHr = GeneratedColumn<double>(
    'avg_hr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<double> maxHr = GeneratedColumn<double>(
    'max_hr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<double> effort = GeneratedColumn<double>(
    'effort',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kilojoulesMeta = const VerificationMeta(
    'kilojoules',
  );
  @override
  late final GeneratedColumn<double> kilojoules = GeneratedColumn<double>(
    'kilojoules',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevationGainMMeta = const VerificationMeta(
    'elevationGainM',
  );
  @override
  late final GeneratedColumn<double> elevationGainM = GeneratedColumn<double>(
    'elevation_gain_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('my-whoop'),
  );
  static const VerificationMeta _zonesJsonMeta = const VerificationMeta(
    'zonesJson',
  );
  @override
  late final GeneratedColumn<String> zonesJson = GeneratedColumn<String>(
    'zones_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _gpsRouteJsonMeta = const VerificationMeta(
    'gpsRouteJson',
  );
  @override
  late final GeneratedColumn<String> gpsRouteJson = GeneratedColumn<String>(
    'gps_route_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strainBreakdownJsonMeta =
      const VerificationMeta('strainBreakdownJson');
  @override
  late final GeneratedColumn<String> strainBreakdownJson =
      GeneratedColumn<String>(
        'strain_breakdown_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightliftingDetailsJsonMeta =
      const VerificationMeta('weightliftingDetailsJson');
  @override
  late final GeneratedColumn<String> weightliftingDetailsJson =
      GeneratedColumn<String>(
        'weightlifting_details_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    sport,
    sportId,
    startTs,
    durationSec,
    avgHr,
    maxHr,
    effort,
    calories,
    kilojoules,
    distanceKm,
    elevationGainM,
    source,
    zonesJson,
    gpsRouteJson,
    strainBreakdownJson,
    tagsJson,
    weightliftingDetailsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    } else if (isInserting) {
      context.missing(_sportMeta);
    }
    if (data.containsKey('sport_id')) {
      context.handle(
        _sportIdMeta,
        sportId.isAcceptableOrUnknown(data['sport_id']!, _sportIdMeta),
      );
    }
    if (data.containsKey('start_ts')) {
      context.handle(
        _startTsMeta,
        startTs.isAcceptableOrUnknown(data['start_ts']!, _startTsMeta),
      );
    } else if (isInserting) {
      context.missing(_startTsMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
        _avgHrMeta,
        avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta),
      );
    }
    if (data.containsKey('max_hr')) {
      context.handle(
        _maxHrMeta,
        maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta),
      );
    }
    if (data.containsKey('effort')) {
      context.handle(
        _effortMeta,
        effort.isAcceptableOrUnknown(data['effort']!, _effortMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('kilojoules')) {
      context.handle(
        _kilojoulesMeta,
        kilojoules.isAcceptableOrUnknown(data['kilojoules']!, _kilojoulesMeta),
      );
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    }
    if (data.containsKey('elevation_gain_m')) {
      context.handle(
        _elevationGainMMeta,
        elevationGainM.isAcceptableOrUnknown(
          data['elevation_gain_m']!,
          _elevationGainMMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('zones_json')) {
      context.handle(
        _zonesJsonMeta,
        zonesJson.isAcceptableOrUnknown(data['zones_json']!, _zonesJsonMeta),
      );
    }
    if (data.containsKey('gps_route_json')) {
      context.handle(
        _gpsRouteJsonMeta,
        gpsRouteJson.isAcceptableOrUnknown(
          data['gps_route_json']!,
          _gpsRouteJsonMeta,
        ),
      );
    }
    if (data.containsKey('strain_breakdown_json')) {
      context.handle(
        _strainBreakdownJsonMeta,
        strainBreakdownJson.isAcceptableOrUnknown(
          data['strain_breakdown_json']!,
          _strainBreakdownJsonMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('weightlifting_details_json')) {
      context.handle(
        _weightliftingDetailsJsonMeta,
        weightliftingDetailsJson.isAcceptableOrUnknown(
          data['weightlifting_details_json']!,
          _weightliftingDetailsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      )!,
      sportId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sport_id'],
      ),
      startTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ts'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      avgHr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_hr'],
      )!,
      maxHr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_hr'],
      )!,
      effort: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effort'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      kilojoules: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kilojoules'],
      ),
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      ),
      elevationGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_m'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      zonesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zones_json'],
      )!,
      gpsRouteJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gps_route_json'],
      ),
      strainBreakdownJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strain_breakdown_json'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
      weightliftingDetailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weightlifting_details_json'],
      ),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final String id;
  final String? activityId;
  final String sport;
  final int? sportId;
  final int startTs;
  final int durationSec;
  final double avgHr;
  final double maxHr;
  final double effort;
  final int calories;
  final double? kilojoules;
  final double? distanceKm;
  final double? elevationGainM;
  final String source;
  final String zonesJson;
  final String? gpsRouteJson;
  final String? strainBreakdownJson;
  final String? tagsJson;
  final String? weightliftingDetailsJson;
  const Workout({
    required this.id,
    this.activityId,
    required this.sport,
    this.sportId,
    required this.startTs,
    required this.durationSec,
    required this.avgHr,
    required this.maxHr,
    required this.effort,
    required this.calories,
    this.kilojoules,
    this.distanceKm,
    this.elevationGainM,
    required this.source,
    required this.zonesJson,
    this.gpsRouteJson,
    this.strainBreakdownJson,
    this.tagsJson,
    this.weightliftingDetailsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    map['sport'] = Variable<String>(sport);
    if (!nullToAbsent || sportId != null) {
      map['sport_id'] = Variable<int>(sportId);
    }
    map['start_ts'] = Variable<int>(startTs);
    map['duration_sec'] = Variable<int>(durationSec);
    map['avg_hr'] = Variable<double>(avgHr);
    map['max_hr'] = Variable<double>(maxHr);
    map['effort'] = Variable<double>(effort);
    map['calories'] = Variable<int>(calories);
    if (!nullToAbsent || kilojoules != null) {
      map['kilojoules'] = Variable<double>(kilojoules);
    }
    if (!nullToAbsent || distanceKm != null) {
      map['distance_km'] = Variable<double>(distanceKm);
    }
    if (!nullToAbsent || elevationGainM != null) {
      map['elevation_gain_m'] = Variable<double>(elevationGainM);
    }
    map['source'] = Variable<String>(source);
    map['zones_json'] = Variable<String>(zonesJson);
    if (!nullToAbsent || gpsRouteJson != null) {
      map['gps_route_json'] = Variable<String>(gpsRouteJson);
    }
    if (!nullToAbsent || strainBreakdownJson != null) {
      map['strain_breakdown_json'] = Variable<String>(strainBreakdownJson);
    }
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    if (!nullToAbsent || weightliftingDetailsJson != null) {
      map['weightlifting_details_json'] = Variable<String>(
        weightliftingDetailsJson,
      );
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      sport: Value(sport),
      sportId: sportId == null && nullToAbsent
          ? const Value.absent()
          : Value(sportId),
      startTs: Value(startTs),
      durationSec: Value(durationSec),
      avgHr: Value(avgHr),
      maxHr: Value(maxHr),
      effort: Value(effort),
      calories: Value(calories),
      kilojoules: kilojoules == null && nullToAbsent
          ? const Value.absent()
          : Value(kilojoules),
      distanceKm: distanceKm == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceKm),
      elevationGainM: elevationGainM == null && nullToAbsent
          ? const Value.absent()
          : Value(elevationGainM),
      source: Value(source),
      zonesJson: Value(zonesJson),
      gpsRouteJson: gpsRouteJson == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsRouteJson),
      strainBreakdownJson: strainBreakdownJson == null && nullToAbsent
          ? const Value.absent()
          : Value(strainBreakdownJson),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
      weightliftingDetailsJson: weightliftingDetailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(weightliftingDetailsJson),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      sport: serializer.fromJson<String>(json['sport']),
      sportId: serializer.fromJson<int?>(json['sportId']),
      startTs: serializer.fromJson<int>(json['startTs']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      avgHr: serializer.fromJson<double>(json['avgHr']),
      maxHr: serializer.fromJson<double>(json['maxHr']),
      effort: serializer.fromJson<double>(json['effort']),
      calories: serializer.fromJson<int>(json['calories']),
      kilojoules: serializer.fromJson<double?>(json['kilojoules']),
      distanceKm: serializer.fromJson<double?>(json['distanceKm']),
      elevationGainM: serializer.fromJson<double?>(json['elevationGainM']),
      source: serializer.fromJson<String>(json['source']),
      zonesJson: serializer.fromJson<String>(json['zonesJson']),
      gpsRouteJson: serializer.fromJson<String?>(json['gpsRouteJson']),
      strainBreakdownJson: serializer.fromJson<String?>(
        json['strainBreakdownJson'],
      ),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
      weightliftingDetailsJson: serializer.fromJson<String?>(
        json['weightliftingDetailsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String?>(activityId),
      'sport': serializer.toJson<String>(sport),
      'sportId': serializer.toJson<int?>(sportId),
      'startTs': serializer.toJson<int>(startTs),
      'durationSec': serializer.toJson<int>(durationSec),
      'avgHr': serializer.toJson<double>(avgHr),
      'maxHr': serializer.toJson<double>(maxHr),
      'effort': serializer.toJson<double>(effort),
      'calories': serializer.toJson<int>(calories),
      'kilojoules': serializer.toJson<double?>(kilojoules),
      'distanceKm': serializer.toJson<double?>(distanceKm),
      'elevationGainM': serializer.toJson<double?>(elevationGainM),
      'source': serializer.toJson<String>(source),
      'zonesJson': serializer.toJson<String>(zonesJson),
      'gpsRouteJson': serializer.toJson<String?>(gpsRouteJson),
      'strainBreakdownJson': serializer.toJson<String?>(strainBreakdownJson),
      'tagsJson': serializer.toJson<String?>(tagsJson),
      'weightliftingDetailsJson': serializer.toJson<String?>(
        weightliftingDetailsJson,
      ),
    };
  }

  Workout copyWith({
    String? id,
    Value<String?> activityId = const Value.absent(),
    String? sport,
    Value<int?> sportId = const Value.absent(),
    int? startTs,
    int? durationSec,
    double? avgHr,
    double? maxHr,
    double? effort,
    int? calories,
    Value<double?> kilojoules = const Value.absent(),
    Value<double?> distanceKm = const Value.absent(),
    Value<double?> elevationGainM = const Value.absent(),
    String? source,
    String? zonesJson,
    Value<String?> gpsRouteJson = const Value.absent(),
    Value<String?> strainBreakdownJson = const Value.absent(),
    Value<String?> tagsJson = const Value.absent(),
    Value<String?> weightliftingDetailsJson = const Value.absent(),
  }) => Workout(
    id: id ?? this.id,
    activityId: activityId.present ? activityId.value : this.activityId,
    sport: sport ?? this.sport,
    sportId: sportId.present ? sportId.value : this.sportId,
    startTs: startTs ?? this.startTs,
    durationSec: durationSec ?? this.durationSec,
    avgHr: avgHr ?? this.avgHr,
    maxHr: maxHr ?? this.maxHr,
    effort: effort ?? this.effort,
    calories: calories ?? this.calories,
    kilojoules: kilojoules.present ? kilojoules.value : this.kilojoules,
    distanceKm: distanceKm.present ? distanceKm.value : this.distanceKm,
    elevationGainM: elevationGainM.present
        ? elevationGainM.value
        : this.elevationGainM,
    source: source ?? this.source,
    zonesJson: zonesJson ?? this.zonesJson,
    gpsRouteJson: gpsRouteJson.present ? gpsRouteJson.value : this.gpsRouteJson,
    strainBreakdownJson: strainBreakdownJson.present
        ? strainBreakdownJson.value
        : this.strainBreakdownJson,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
    weightliftingDetailsJson: weightliftingDetailsJson.present
        ? weightliftingDetailsJson.value
        : this.weightliftingDetailsJson,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      sport: data.sport.present ? data.sport.value : this.sport,
      sportId: data.sportId.present ? data.sportId.value : this.sportId,
      startTs: data.startTs.present ? data.startTs.value : this.startTs,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      effort: data.effort.present ? data.effort.value : this.effort,
      calories: data.calories.present ? data.calories.value : this.calories,
      kilojoules: data.kilojoules.present
          ? data.kilojoules.value
          : this.kilojoules,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      elevationGainM: data.elevationGainM.present
          ? data.elevationGainM.value
          : this.elevationGainM,
      source: data.source.present ? data.source.value : this.source,
      zonesJson: data.zonesJson.present ? data.zonesJson.value : this.zonesJson,
      gpsRouteJson: data.gpsRouteJson.present
          ? data.gpsRouteJson.value
          : this.gpsRouteJson,
      strainBreakdownJson: data.strainBreakdownJson.present
          ? data.strainBreakdownJson.value
          : this.strainBreakdownJson,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      weightliftingDetailsJson: data.weightliftingDetailsJson.present
          ? data.weightliftingDetailsJson.value
          : this.weightliftingDetailsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('sport: $sport, ')
          ..write('sportId: $sportId, ')
          ..write('startTs: $startTs, ')
          ..write('durationSec: $durationSec, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('effort: $effort, ')
          ..write('calories: $calories, ')
          ..write('kilojoules: $kilojoules, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('source: $source, ')
          ..write('zonesJson: $zonesJson, ')
          ..write('gpsRouteJson: $gpsRouteJson, ')
          ..write('strainBreakdownJson: $strainBreakdownJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('weightliftingDetailsJson: $weightliftingDetailsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    sport,
    sportId,
    startTs,
    durationSec,
    avgHr,
    maxHr,
    effort,
    calories,
    kilojoules,
    distanceKm,
    elevationGainM,
    source,
    zonesJson,
    gpsRouteJson,
    strainBreakdownJson,
    tagsJson,
    weightliftingDetailsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.sport == this.sport &&
          other.sportId == this.sportId &&
          other.startTs == this.startTs &&
          other.durationSec == this.durationSec &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr &&
          other.effort == this.effort &&
          other.calories == this.calories &&
          other.kilojoules == this.kilojoules &&
          other.distanceKm == this.distanceKm &&
          other.elevationGainM == this.elevationGainM &&
          other.source == this.source &&
          other.zonesJson == this.zonesJson &&
          other.gpsRouteJson == this.gpsRouteJson &&
          other.strainBreakdownJson == this.strainBreakdownJson &&
          other.tagsJson == this.tagsJson &&
          other.weightliftingDetailsJson == this.weightliftingDetailsJson);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<String> id;
  final Value<String?> activityId;
  final Value<String> sport;
  final Value<int?> sportId;
  final Value<int> startTs;
  final Value<int> durationSec;
  final Value<double> avgHr;
  final Value<double> maxHr;
  final Value<double> effort;
  final Value<int> calories;
  final Value<double?> kilojoules;
  final Value<double?> distanceKm;
  final Value<double?> elevationGainM;
  final Value<String> source;
  final Value<String> zonesJson;
  final Value<String?> gpsRouteJson;
  final Value<String?> strainBreakdownJson;
  final Value<String?> tagsJson;
  final Value<String?> weightliftingDetailsJson;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.sport = const Value.absent(),
    this.sportId = const Value.absent(),
    this.startTs = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.effort = const Value.absent(),
    this.calories = const Value.absent(),
    this.kilojoules = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.source = const Value.absent(),
    this.zonesJson = const Value.absent(),
    this.gpsRouteJson = const Value.absent(),
    this.strainBreakdownJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.weightliftingDetailsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    required String id,
    this.activityId = const Value.absent(),
    required String sport,
    this.sportId = const Value.absent(),
    required int startTs,
    required int durationSec,
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.effort = const Value.absent(),
    this.calories = const Value.absent(),
    this.kilojoules = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.source = const Value.absent(),
    this.zonesJson = const Value.absent(),
    this.gpsRouteJson = const Value.absent(),
    this.strainBreakdownJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.weightliftingDetailsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sport = Value(sport),
       startTs = Value(startTs),
       durationSec = Value(durationSec);
  static Insertable<Workout> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<String>? sport,
    Expression<int>? sportId,
    Expression<int>? startTs,
    Expression<int>? durationSec,
    Expression<double>? avgHr,
    Expression<double>? maxHr,
    Expression<double>? effort,
    Expression<int>? calories,
    Expression<double>? kilojoules,
    Expression<double>? distanceKm,
    Expression<double>? elevationGainM,
    Expression<String>? source,
    Expression<String>? zonesJson,
    Expression<String>? gpsRouteJson,
    Expression<String>? strainBreakdownJson,
    Expression<String>? tagsJson,
    Expression<String>? weightliftingDetailsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (sport != null) 'sport': sport,
      if (sportId != null) 'sport_id': sportId,
      if (startTs != null) 'start_ts': startTs,
      if (durationSec != null) 'duration_sec': durationSec,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (effort != null) 'effort': effort,
      if (calories != null) 'calories': calories,
      if (kilojoules != null) 'kilojoules': kilojoules,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
      if (source != null) 'source': source,
      if (zonesJson != null) 'zones_json': zonesJson,
      if (gpsRouteJson != null) 'gps_route_json': gpsRouteJson,
      if (strainBreakdownJson != null)
        'strain_breakdown_json': strainBreakdownJson,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (weightliftingDetailsJson != null)
        'weightlifting_details_json': weightliftingDetailsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith({
    Value<String>? id,
    Value<String?>? activityId,
    Value<String>? sport,
    Value<int?>? sportId,
    Value<int>? startTs,
    Value<int>? durationSec,
    Value<double>? avgHr,
    Value<double>? maxHr,
    Value<double>? effort,
    Value<int>? calories,
    Value<double?>? kilojoules,
    Value<double?>? distanceKm,
    Value<double?>? elevationGainM,
    Value<String>? source,
    Value<String>? zonesJson,
    Value<String?>? gpsRouteJson,
    Value<String?>? strainBreakdownJson,
    Value<String?>? tagsJson,
    Value<String?>? weightliftingDetailsJson,
    Value<int>? rowid,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      sport: sport ?? this.sport,
      sportId: sportId ?? this.sportId,
      startTs: startTs ?? this.startTs,
      durationSec: durationSec ?? this.durationSec,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      effort: effort ?? this.effort,
      calories: calories ?? this.calories,
      kilojoules: kilojoules ?? this.kilojoules,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      source: source ?? this.source,
      zonesJson: zonesJson ?? this.zonesJson,
      gpsRouteJson: gpsRouteJson ?? this.gpsRouteJson,
      strainBreakdownJson: strainBreakdownJson ?? this.strainBreakdownJson,
      tagsJson: tagsJson ?? this.tagsJson,
      weightliftingDetailsJson:
          weightliftingDetailsJson ?? this.weightliftingDetailsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (sportId.present) {
      map['sport_id'] = Variable<int>(sportId.value);
    }
    if (startTs.present) {
      map['start_ts'] = Variable<int>(startTs.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<double>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<double>(maxHr.value);
    }
    if (effort.present) {
      map['effort'] = Variable<double>(effort.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (kilojoules.present) {
      map['kilojoules'] = Variable<double>(kilojoules.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (elevationGainM.present) {
      map['elevation_gain_m'] = Variable<double>(elevationGainM.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (zonesJson.present) {
      map['zones_json'] = Variable<String>(zonesJson.value);
    }
    if (gpsRouteJson.present) {
      map['gps_route_json'] = Variable<String>(gpsRouteJson.value);
    }
    if (strainBreakdownJson.present) {
      map['strain_breakdown_json'] = Variable<String>(
        strainBreakdownJson.value,
      );
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (weightliftingDetailsJson.present) {
      map['weightlifting_details_json'] = Variable<String>(
        weightliftingDetailsJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('sport: $sport, ')
          ..write('sportId: $sportId, ')
          ..write('startTs: $startTs, ')
          ..write('durationSec: $durationSec, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('effort: $effort, ')
          ..write('calories: $calories, ')
          ..write('kilojoules: $kilojoules, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('source: $source, ')
          ..write('zonesJson: $zonesJson, ')
          ..write('gpsRouteJson: $gpsRouteJson, ')
          ..write('strainBreakdownJson: $strainBreakdownJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('weightliftingDetailsJson: $weightliftingDetailsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HrSamplesTable extends HrSamples
    with TableInfo<$HrSamplesTable, HrSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HrSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<double> bpm = GeneratedColumn<double>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ts, bpm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hr_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<HrSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ts};
  @override
  HrSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HrSample(
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bpm'],
      )!,
    );
  }

  @override
  $HrSamplesTable createAlias(String alias) {
    return $HrSamplesTable(attachedDatabase, alias);
  }
}

class HrSample extends DataClass implements Insertable<HrSample> {
  final int ts;
  final double bpm;
  const HrSample({required this.ts, required this.bpm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts'] = Variable<int>(ts);
    map['bpm'] = Variable<double>(bpm);
    return map;
  }

  HrSamplesCompanion toCompanion(bool nullToAbsent) {
    return HrSamplesCompanion(ts: Value(ts), bpm: Value(bpm));
  }

  factory HrSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HrSample(
      ts: serializer.fromJson<int>(json['ts']),
      bpm: serializer.fromJson<double>(json['bpm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ts': serializer.toJson<int>(ts),
      'bpm': serializer.toJson<double>(bpm),
    };
  }

  HrSample copyWith({int? ts, double? bpm}) =>
      HrSample(ts: ts ?? this.ts, bpm: bpm ?? this.bpm);
  HrSample copyWithCompanion(HrSamplesCompanion data) {
    return HrSample(
      ts: data.ts.present ? data.ts.value : this.ts,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HrSample(')
          ..write('ts: $ts, ')
          ..write('bpm: $bpm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ts, bpm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HrSample && other.ts == this.ts && other.bpm == this.bpm);
}

class HrSamplesCompanion extends UpdateCompanion<HrSample> {
  final Value<int> ts;
  final Value<double> bpm;
  const HrSamplesCompanion({
    this.ts = const Value.absent(),
    this.bpm = const Value.absent(),
  });
  HrSamplesCompanion.insert({
    this.ts = const Value.absent(),
    required double bpm,
  }) : bpm = Value(bpm);
  static Insertable<HrSample> custom({
    Expression<int>? ts,
    Expression<double>? bpm,
  }) {
    return RawValuesInsertable({
      if (ts != null) 'ts': ts,
      if (bpm != null) 'bpm': bpm,
    });
  }

  HrSamplesCompanion copyWith({Value<int>? ts, Value<double>? bpm}) {
    return HrSamplesCompanion(ts: ts ?? this.ts, bpm: bpm ?? this.bpm);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<double>(bpm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HrSamplesCompanion(')
          ..write('ts: $ts, ')
          ..write('bpm: $bpm')
          ..write(')'))
        .toString();
  }
}

class $RrSamplesTable extends RrSamples
    with TableInfo<$RrSamplesTable, RrSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RrSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMsMeta = const VerificationMeta('tsMs');
  @override
  late final GeneratedColumn<int> tsMs = GeneratedColumn<int>(
    'ts_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rrIndexMeta = const VerificationMeta(
    'rrIndex',
  );
  @override
  late final GeneratedColumn<int> rrIndex = GeneratedColumn<int>(
    'rr_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rrMsMeta = const VerificationMeta('rrMs');
  @override
  late final GeneratedColumn<int> rrMs = GeneratedColumn<int>(
    'rr_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrBpmMeta = const VerificationMeta('hrBpm');
  @override
  late final GeneratedColumn<int> hrBpm = GeneratedColumn<int>(
    'hr_bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [tsMs, rrIndex, rrMs, hrBpm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rr_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<RrSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts_ms')) {
      context.handle(
        _tsMsMeta,
        tsMs.isAcceptableOrUnknown(data['ts_ms']!, _tsMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tsMsMeta);
    }
    if (data.containsKey('rr_index')) {
      context.handle(
        _rrIndexMeta,
        rrIndex.isAcceptableOrUnknown(data['rr_index']!, _rrIndexMeta),
      );
    }
    if (data.containsKey('rr_ms')) {
      context.handle(
        _rrMsMeta,
        rrMs.isAcceptableOrUnknown(data['rr_ms']!, _rrMsMeta),
      );
    } else if (isInserting) {
      context.missing(_rrMsMeta);
    }
    if (data.containsKey('hr_bpm')) {
      context.handle(
        _hrBpmMeta,
        hrBpm.isAcceptableOrUnknown(data['hr_bpm']!, _hrBpmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tsMs, rrIndex};
  @override
  RrSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RrSample(
      tsMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts_ms'],
      )!,
      rrIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rr_index'],
      )!,
      rrMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rr_ms'],
      )!,
      hrBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_bpm'],
      ),
    );
  }

  @override
  $RrSamplesTable createAlias(String alias) {
    return $RrSamplesTable(attachedDatabase, alias);
  }
}

class RrSample extends DataClass implements Insertable<RrSample> {
  final int tsMs;
  final int rrIndex;
  final int rrMs;
  final int? hrBpm;
  const RrSample({
    required this.tsMs,
    required this.rrIndex,
    required this.rrMs,
    this.hrBpm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts_ms'] = Variable<int>(tsMs);
    map['rr_index'] = Variable<int>(rrIndex);
    map['rr_ms'] = Variable<int>(rrMs);
    if (!nullToAbsent || hrBpm != null) {
      map['hr_bpm'] = Variable<int>(hrBpm);
    }
    return map;
  }

  RrSamplesCompanion toCompanion(bool nullToAbsent) {
    return RrSamplesCompanion(
      tsMs: Value(tsMs),
      rrIndex: Value(rrIndex),
      rrMs: Value(rrMs),
      hrBpm: hrBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(hrBpm),
    );
  }

  factory RrSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RrSample(
      tsMs: serializer.fromJson<int>(json['tsMs']),
      rrIndex: serializer.fromJson<int>(json['rrIndex']),
      rrMs: serializer.fromJson<int>(json['rrMs']),
      hrBpm: serializer.fromJson<int?>(json['hrBpm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tsMs': serializer.toJson<int>(tsMs),
      'rrIndex': serializer.toJson<int>(rrIndex),
      'rrMs': serializer.toJson<int>(rrMs),
      'hrBpm': serializer.toJson<int?>(hrBpm),
    };
  }

  RrSample copyWith({
    int? tsMs,
    int? rrIndex,
    int? rrMs,
    Value<int?> hrBpm = const Value.absent(),
  }) => RrSample(
    tsMs: tsMs ?? this.tsMs,
    rrIndex: rrIndex ?? this.rrIndex,
    rrMs: rrMs ?? this.rrMs,
    hrBpm: hrBpm.present ? hrBpm.value : this.hrBpm,
  );
  RrSample copyWithCompanion(RrSamplesCompanion data) {
    return RrSample(
      tsMs: data.tsMs.present ? data.tsMs.value : this.tsMs,
      rrIndex: data.rrIndex.present ? data.rrIndex.value : this.rrIndex,
      rrMs: data.rrMs.present ? data.rrMs.value : this.rrMs,
      hrBpm: data.hrBpm.present ? data.hrBpm.value : this.hrBpm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RrSample(')
          ..write('tsMs: $tsMs, ')
          ..write('rrIndex: $rrIndex, ')
          ..write('rrMs: $rrMs, ')
          ..write('hrBpm: $hrBpm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tsMs, rrIndex, rrMs, hrBpm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RrSample &&
          other.tsMs == this.tsMs &&
          other.rrIndex == this.rrIndex &&
          other.rrMs == this.rrMs &&
          other.hrBpm == this.hrBpm);
}

class RrSamplesCompanion extends UpdateCompanion<RrSample> {
  final Value<int> tsMs;
  final Value<int> rrIndex;
  final Value<int> rrMs;
  final Value<int?> hrBpm;
  final Value<int> rowid;
  const RrSamplesCompanion({
    this.tsMs = const Value.absent(),
    this.rrIndex = const Value.absent(),
    this.rrMs = const Value.absent(),
    this.hrBpm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RrSamplesCompanion.insert({
    required int tsMs,
    this.rrIndex = const Value.absent(),
    required int rrMs,
    this.hrBpm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tsMs = Value(tsMs),
       rrMs = Value(rrMs);
  static Insertable<RrSample> custom({
    Expression<int>? tsMs,
    Expression<int>? rrIndex,
    Expression<int>? rrMs,
    Expression<int>? hrBpm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tsMs != null) 'ts_ms': tsMs,
      if (rrIndex != null) 'rr_index': rrIndex,
      if (rrMs != null) 'rr_ms': rrMs,
      if (hrBpm != null) 'hr_bpm': hrBpm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RrSamplesCompanion copyWith({
    Value<int>? tsMs,
    Value<int>? rrIndex,
    Value<int>? rrMs,
    Value<int?>? hrBpm,
    Value<int>? rowid,
  }) {
    return RrSamplesCompanion(
      tsMs: tsMs ?? this.tsMs,
      rrIndex: rrIndex ?? this.rrIndex,
      rrMs: rrMs ?? this.rrMs,
      hrBpm: hrBpm ?? this.hrBpm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tsMs.present) {
      map['ts_ms'] = Variable<int>(tsMs.value);
    }
    if (rrIndex.present) {
      map['rr_index'] = Variable<int>(rrIndex.value);
    }
    if (rrMs.present) {
      map['rr_ms'] = Variable<int>(rrMs.value);
    }
    if (hrBpm.present) {
      map['hr_bpm'] = Variable<int>(hrBpm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RrSamplesCompanion(')
          ..write('tsMs: $tsMs, ')
          ..write('rrIndex: $rrIndex, ')
          ..write('rrMs: $rrMs, ')
          ..write('hrBpm: $hrBpm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccelSamplesTable extends AccelSamples
    with TableInfo<$AccelSamplesTable, AccelSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccelSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zMeta = const VerificationMeta('z');
  @override
  late final GeneratedColumn<double> z = GeneratedColumn<double>(
    'z',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gyroMeta = const VerificationMeta('gyro');
  @override
  late final GeneratedColumn<double> gyro = GeneratedColumn<double>(
    'gyro',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [ts, x, y, z, gyro];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accel_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccelSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('z')) {
      context.handle(_zMeta, z.isAcceptableOrUnknown(data['z']!, _zMeta));
    } else if (isInserting) {
      context.missing(_zMeta);
    }
    if (data.containsKey('gyro')) {
      context.handle(
        _gyroMeta,
        gyro.isAcceptableOrUnknown(data['gyro']!, _gyroMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ts};
  @override
  AccelSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccelSample(
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      z: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}z'],
      )!,
      gyro: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gyro'],
      ),
    );
  }

  @override
  $AccelSamplesTable createAlias(String alias) {
    return $AccelSamplesTable(attachedDatabase, alias);
  }
}

class AccelSample extends DataClass implements Insertable<AccelSample> {
  final int ts;
  final double x;
  final double y;
  final double z;
  final double? gyro;
  const AccelSample({
    required this.ts,
    required this.x,
    required this.y,
    required this.z,
    this.gyro,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts'] = Variable<int>(ts);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['z'] = Variable<double>(z);
    if (!nullToAbsent || gyro != null) {
      map['gyro'] = Variable<double>(gyro);
    }
    return map;
  }

  AccelSamplesCompanion toCompanion(bool nullToAbsent) {
    return AccelSamplesCompanion(
      ts: Value(ts),
      x: Value(x),
      y: Value(y),
      z: Value(z),
      gyro: gyro == null && nullToAbsent ? const Value.absent() : Value(gyro),
    );
  }

  factory AccelSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccelSample(
      ts: serializer.fromJson<int>(json['ts']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      z: serializer.fromJson<double>(json['z']),
      gyro: serializer.fromJson<double?>(json['gyro']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ts': serializer.toJson<int>(ts),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'z': serializer.toJson<double>(z),
      'gyro': serializer.toJson<double?>(gyro),
    };
  }

  AccelSample copyWith({
    int? ts,
    double? x,
    double? y,
    double? z,
    Value<double?> gyro = const Value.absent(),
  }) => AccelSample(
    ts: ts ?? this.ts,
    x: x ?? this.x,
    y: y ?? this.y,
    z: z ?? this.z,
    gyro: gyro.present ? gyro.value : this.gyro,
  );
  AccelSample copyWithCompanion(AccelSamplesCompanion data) {
    return AccelSample(
      ts: data.ts.present ? data.ts.value : this.ts,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      z: data.z.present ? data.z.value : this.z,
      gyro: data.gyro.present ? data.gyro.value : this.gyro,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccelSample(')
          ..write('ts: $ts, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('z: $z, ')
          ..write('gyro: $gyro')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ts, x, y, z, gyro);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccelSample &&
          other.ts == this.ts &&
          other.x == this.x &&
          other.y == this.y &&
          other.z == this.z &&
          other.gyro == this.gyro);
}

class AccelSamplesCompanion extends UpdateCompanion<AccelSample> {
  final Value<int> ts;
  final Value<double> x;
  final Value<double> y;
  final Value<double> z;
  final Value<double?> gyro;
  const AccelSamplesCompanion({
    this.ts = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.z = const Value.absent(),
    this.gyro = const Value.absent(),
  });
  AccelSamplesCompanion.insert({
    this.ts = const Value.absent(),
    required double x,
    required double y,
    required double z,
    this.gyro = const Value.absent(),
  }) : x = Value(x),
       y = Value(y),
       z = Value(z);
  static Insertable<AccelSample> custom({
    Expression<int>? ts,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? z,
    Expression<double>? gyro,
  }) {
    return RawValuesInsertable({
      if (ts != null) 'ts': ts,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (z != null) 'z': z,
      if (gyro != null) 'gyro': gyro,
    });
  }

  AccelSamplesCompanion copyWith({
    Value<int>? ts,
    Value<double>? x,
    Value<double>? y,
    Value<double>? z,
    Value<double?>? gyro,
  }) {
    return AccelSamplesCompanion(
      ts: ts ?? this.ts,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      gyro: gyro ?? this.gyro,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (z.present) {
      map['z'] = Variable<double>(z.value);
    }
    if (gyro.present) {
      map['gyro'] = Variable<double>(gyro.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccelSamplesCompanion(')
          ..write('ts: $ts, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('z: $z, ')
          ..write('gyro: $gyro')
          ..write(')'))
        .toString();
  }
}

class $RawSensorArchiveTable extends RawSensorArchive
    with TableInfo<$RawSensorArchiveTable, RawSensorArchiveData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawSensorArchiveTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _capturedAtMsMeta = const VerificationMeta(
    'capturedAtMs',
  );
  @override
  late final GeneratedColumn<int> capturedAtMs = GeneratedColumn<int>(
    'captured_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characteristicMeta = const VerificationMeta(
    'characteristic',
  );
  @override
  late final GeneratedColumn<String> characteristic = GeneratedColumn<String>(
    'characteristic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packetTypeMeta = const VerificationMeta(
    'packetType',
  );
  @override
  late final GeneratedColumn<int> packetType = GeneratedColumn<int>(
    'packet_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spo2RawAdcMeta = const VerificationMeta(
    'spo2RawAdc',
  );
  @override
  late final GeneratedColumn<int> spo2RawAdc = GeneratedColumn<int>(
    'spo2_raw_adc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawHexMeta = const VerificationMeta('rawHex');
  @override
  late final GeneratedColumn<String> rawHex = GeneratedColumn<String>(
    'raw_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trimCursorMeta = const VerificationMeta(
    'trimCursor',
  );
  @override
  late final GeneratedColumn<int> trimCursor = GeneratedColumn<int>(
    'trim_cursor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _familyMeta = const VerificationMeta('family');
  @override
  late final GeneratedColumn<String> family = GeneratedColumn<String>(
    'family',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    capturedAtMs,
    characteristic,
    packetType,
    spo2RawAdc,
    rawHex,
    trimCursor,
    family,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_sensor_archive';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawSensorArchiveData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('captured_at_ms')) {
      context.handle(
        _capturedAtMsMeta,
        capturedAtMs.isAcceptableOrUnknown(
          data['captured_at_ms']!,
          _capturedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMsMeta);
    }
    if (data.containsKey('characteristic')) {
      context.handle(
        _characteristicMeta,
        characteristic.isAcceptableOrUnknown(
          data['characteristic']!,
          _characteristicMeta,
        ),
      );
    }
    if (data.containsKey('packet_type')) {
      context.handle(
        _packetTypeMeta,
        packetType.isAcceptableOrUnknown(data['packet_type']!, _packetTypeMeta),
      );
    }
    if (data.containsKey('spo2_raw_adc')) {
      context.handle(
        _spo2RawAdcMeta,
        spo2RawAdc.isAcceptableOrUnknown(
          data['spo2_raw_adc']!,
          _spo2RawAdcMeta,
        ),
      );
    }
    if (data.containsKey('raw_hex')) {
      context.handle(
        _rawHexMeta,
        rawHex.isAcceptableOrUnknown(data['raw_hex']!, _rawHexMeta),
      );
    } else if (isInserting) {
      context.missing(_rawHexMeta);
    }
    if (data.containsKey('trim_cursor')) {
      context.handle(
        _trimCursorMeta,
        trimCursor.isAcceptableOrUnknown(data['trim_cursor']!, _trimCursorMeta),
      );
    }
    if (data.containsKey('family')) {
      context.handle(
        _familyMeta,
        family.isAcceptableOrUnknown(data['family']!, _familyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RawSensorArchiveData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawSensorArchiveData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      capturedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at_ms'],
      )!,
      characteristic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}characteristic'],
      ),
      packetType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}packet_type'],
      ),
      spo2RawAdc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spo2_raw_adc'],
      ),
      rawHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_hex'],
      )!,
      trimCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trim_cursor'],
      ),
      family: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family'],
      ),
    );
  }

  @override
  $RawSensorArchiveTable createAlias(String alias) {
    return $RawSensorArchiveTable(attachedDatabase, alias);
  }
}

class RawSensorArchiveData extends DataClass
    implements Insertable<RawSensorArchiveData> {
  final int id;
  final int capturedAtMs;
  final String? characteristic;
  final int? packetType;
  final int? spo2RawAdc;
  final String rawHex;
  final int? trimCursor;
  final String? family;
  const RawSensorArchiveData({
    required this.id,
    required this.capturedAtMs,
    this.characteristic,
    this.packetType,
    this.spo2RawAdc,
    required this.rawHex,
    this.trimCursor,
    this.family,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['captured_at_ms'] = Variable<int>(capturedAtMs);
    if (!nullToAbsent || characteristic != null) {
      map['characteristic'] = Variable<String>(characteristic);
    }
    if (!nullToAbsent || packetType != null) {
      map['packet_type'] = Variable<int>(packetType);
    }
    if (!nullToAbsent || spo2RawAdc != null) {
      map['spo2_raw_adc'] = Variable<int>(spo2RawAdc);
    }
    map['raw_hex'] = Variable<String>(rawHex);
    if (!nullToAbsent || trimCursor != null) {
      map['trim_cursor'] = Variable<int>(trimCursor);
    }
    if (!nullToAbsent || family != null) {
      map['family'] = Variable<String>(family);
    }
    return map;
  }

  RawSensorArchiveCompanion toCompanion(bool nullToAbsent) {
    return RawSensorArchiveCompanion(
      id: Value(id),
      capturedAtMs: Value(capturedAtMs),
      characteristic: characteristic == null && nullToAbsent
          ? const Value.absent()
          : Value(characteristic),
      packetType: packetType == null && nullToAbsent
          ? const Value.absent()
          : Value(packetType),
      spo2RawAdc: spo2RawAdc == null && nullToAbsent
          ? const Value.absent()
          : Value(spo2RawAdc),
      rawHex: Value(rawHex),
      trimCursor: trimCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(trimCursor),
      family: family == null && nullToAbsent
          ? const Value.absent()
          : Value(family),
    );
  }

  factory RawSensorArchiveData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawSensorArchiveData(
      id: serializer.fromJson<int>(json['id']),
      capturedAtMs: serializer.fromJson<int>(json['capturedAtMs']),
      characteristic: serializer.fromJson<String?>(json['characteristic']),
      packetType: serializer.fromJson<int?>(json['packetType']),
      spo2RawAdc: serializer.fromJson<int?>(json['spo2RawAdc']),
      rawHex: serializer.fromJson<String>(json['rawHex']),
      trimCursor: serializer.fromJson<int?>(json['trimCursor']),
      family: serializer.fromJson<String?>(json['family']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'capturedAtMs': serializer.toJson<int>(capturedAtMs),
      'characteristic': serializer.toJson<String?>(characteristic),
      'packetType': serializer.toJson<int?>(packetType),
      'spo2RawAdc': serializer.toJson<int?>(spo2RawAdc),
      'rawHex': serializer.toJson<String>(rawHex),
      'trimCursor': serializer.toJson<int?>(trimCursor),
      'family': serializer.toJson<String?>(family),
    };
  }

  RawSensorArchiveData copyWith({
    int? id,
    int? capturedAtMs,
    Value<String?> characteristic = const Value.absent(),
    Value<int?> packetType = const Value.absent(),
    Value<int?> spo2RawAdc = const Value.absent(),
    String? rawHex,
    Value<int?> trimCursor = const Value.absent(),
    Value<String?> family = const Value.absent(),
  }) => RawSensorArchiveData(
    id: id ?? this.id,
    capturedAtMs: capturedAtMs ?? this.capturedAtMs,
    characteristic: characteristic.present
        ? characteristic.value
        : this.characteristic,
    packetType: packetType.present ? packetType.value : this.packetType,
    spo2RawAdc: spo2RawAdc.present ? spo2RawAdc.value : this.spo2RawAdc,
    rawHex: rawHex ?? this.rawHex,
    trimCursor: trimCursor.present ? trimCursor.value : this.trimCursor,
    family: family.present ? family.value : this.family,
  );
  RawSensorArchiveData copyWithCompanion(RawSensorArchiveCompanion data) {
    return RawSensorArchiveData(
      id: data.id.present ? data.id.value : this.id,
      capturedAtMs: data.capturedAtMs.present
          ? data.capturedAtMs.value
          : this.capturedAtMs,
      characteristic: data.characteristic.present
          ? data.characteristic.value
          : this.characteristic,
      packetType: data.packetType.present
          ? data.packetType.value
          : this.packetType,
      spo2RawAdc: data.spo2RawAdc.present
          ? data.spo2RawAdc.value
          : this.spo2RawAdc,
      rawHex: data.rawHex.present ? data.rawHex.value : this.rawHex,
      trimCursor: data.trimCursor.present
          ? data.trimCursor.value
          : this.trimCursor,
      family: data.family.present ? data.family.value : this.family,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawSensorArchiveData(')
          ..write('id: $id, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('characteristic: $characteristic, ')
          ..write('packetType: $packetType, ')
          ..write('spo2RawAdc: $spo2RawAdc, ')
          ..write('rawHex: $rawHex, ')
          ..write('trimCursor: $trimCursor, ')
          ..write('family: $family')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    capturedAtMs,
    characteristic,
    packetType,
    spo2RawAdc,
    rawHex,
    trimCursor,
    family,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawSensorArchiveData &&
          other.id == this.id &&
          other.capturedAtMs == this.capturedAtMs &&
          other.characteristic == this.characteristic &&
          other.packetType == this.packetType &&
          other.spo2RawAdc == this.spo2RawAdc &&
          other.rawHex == this.rawHex &&
          other.trimCursor == this.trimCursor &&
          other.family == this.family);
}

class RawSensorArchiveCompanion extends UpdateCompanion<RawSensorArchiveData> {
  final Value<int> id;
  final Value<int> capturedAtMs;
  final Value<String?> characteristic;
  final Value<int?> packetType;
  final Value<int?> spo2RawAdc;
  final Value<String> rawHex;
  final Value<int?> trimCursor;
  final Value<String?> family;
  const RawSensorArchiveCompanion({
    this.id = const Value.absent(),
    this.capturedAtMs = const Value.absent(),
    this.characteristic = const Value.absent(),
    this.packetType = const Value.absent(),
    this.spo2RawAdc = const Value.absent(),
    this.rawHex = const Value.absent(),
    this.trimCursor = const Value.absent(),
    this.family = const Value.absent(),
  });
  RawSensorArchiveCompanion.insert({
    this.id = const Value.absent(),
    required int capturedAtMs,
    this.characteristic = const Value.absent(),
    this.packetType = const Value.absent(),
    this.spo2RawAdc = const Value.absent(),
    required String rawHex,
    this.trimCursor = const Value.absent(),
    this.family = const Value.absent(),
  }) : capturedAtMs = Value(capturedAtMs),
       rawHex = Value(rawHex);
  static Insertable<RawSensorArchiveData> custom({
    Expression<int>? id,
    Expression<int>? capturedAtMs,
    Expression<String>? characteristic,
    Expression<int>? packetType,
    Expression<int>? spo2RawAdc,
    Expression<String>? rawHex,
    Expression<int>? trimCursor,
    Expression<String>? family,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (capturedAtMs != null) 'captured_at_ms': capturedAtMs,
      if (characteristic != null) 'characteristic': characteristic,
      if (packetType != null) 'packet_type': packetType,
      if (spo2RawAdc != null) 'spo2_raw_adc': spo2RawAdc,
      if (rawHex != null) 'raw_hex': rawHex,
      if (trimCursor != null) 'trim_cursor': trimCursor,
      if (family != null) 'family': family,
    });
  }

  RawSensorArchiveCompanion copyWith({
    Value<int>? id,
    Value<int>? capturedAtMs,
    Value<String?>? characteristic,
    Value<int?>? packetType,
    Value<int?>? spo2RawAdc,
    Value<String>? rawHex,
    Value<int?>? trimCursor,
    Value<String?>? family,
  }) {
    return RawSensorArchiveCompanion(
      id: id ?? this.id,
      capturedAtMs: capturedAtMs ?? this.capturedAtMs,
      characteristic: characteristic ?? this.characteristic,
      packetType: packetType ?? this.packetType,
      spo2RawAdc: spo2RawAdc ?? this.spo2RawAdc,
      rawHex: rawHex ?? this.rawHex,
      trimCursor: trimCursor ?? this.trimCursor,
      family: family ?? this.family,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (capturedAtMs.present) {
      map['captured_at_ms'] = Variable<int>(capturedAtMs.value);
    }
    if (characteristic.present) {
      map['characteristic'] = Variable<String>(characteristic.value);
    }
    if (packetType.present) {
      map['packet_type'] = Variable<int>(packetType.value);
    }
    if (spo2RawAdc.present) {
      map['spo2_raw_adc'] = Variable<int>(spo2RawAdc.value);
    }
    if (rawHex.present) {
      map['raw_hex'] = Variable<String>(rawHex.value);
    }
    if (trimCursor.present) {
      map['trim_cursor'] = Variable<int>(trimCursor.value);
    }
    if (family.present) {
      map['family'] = Variable<String>(family.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawSensorArchiveCompanion(')
          ..write('id: $id, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('characteristic: $characteristic, ')
          ..write('packetType: $packetType, ')
          ..write('spo2RawAdc: $spo2RawAdc, ')
          ..write('rawHex: $rawHex, ')
          ..write('trimCursor: $trimCursor, ')
          ..write('family: $family')
          ..write(')'))
        .toString();
  }
}

class $BatteryLogTable extends BatteryLog
    with TableInfo<$BatteryLogTable, BatteryLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatteryLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _socMeta = const VerificationMeta('soc');
  @override
  late final GeneratedColumn<int> soc = GeneratedColumn<int>(
    'soc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chargingMeta = const VerificationMeta(
    'charging',
  );
  @override
  late final GeneratedColumn<bool> charging = GeneratedColumn<bool>(
    'charging',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("charging" IN (0, 1))',
    ),
  );
  static const VerificationMeta _mvMeta = const VerificationMeta('mv');
  @override
  late final GeneratedColumn<int> mv = GeneratedColumn<int>(
    'mv',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [ts, soc, charging, mv];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'battery_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatteryLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('soc')) {
      context.handle(
        _socMeta,
        soc.isAcceptableOrUnknown(data['soc']!, _socMeta),
      );
    } else if (isInserting) {
      context.missing(_socMeta);
    }
    if (data.containsKey('charging')) {
      context.handle(
        _chargingMeta,
        charging.isAcceptableOrUnknown(data['charging']!, _chargingMeta),
      );
    }
    if (data.containsKey('mv')) {
      context.handle(_mvMeta, mv.isAcceptableOrUnknown(data['mv']!, _mvMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ts};
  @override
  BatteryLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatteryLogData(
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      soc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}soc'],
      )!,
      charging: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}charging'],
      ),
      mv: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mv'],
      ),
    );
  }

  @override
  $BatteryLogTable createAlias(String alias) {
    return $BatteryLogTable(attachedDatabase, alias);
  }
}

class BatteryLogData extends DataClass implements Insertable<BatteryLogData> {
  final int ts;
  final int soc;
  final bool? charging;
  final int? mv;
  const BatteryLogData({
    required this.ts,
    required this.soc,
    this.charging,
    this.mv,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts'] = Variable<int>(ts);
    map['soc'] = Variable<int>(soc);
    if (!nullToAbsent || charging != null) {
      map['charging'] = Variable<bool>(charging);
    }
    if (!nullToAbsent || mv != null) {
      map['mv'] = Variable<int>(mv);
    }
    return map;
  }

  BatteryLogCompanion toCompanion(bool nullToAbsent) {
    return BatteryLogCompanion(
      ts: Value(ts),
      soc: Value(soc),
      charging: charging == null && nullToAbsent
          ? const Value.absent()
          : Value(charging),
      mv: mv == null && nullToAbsent ? const Value.absent() : Value(mv),
    );
  }

  factory BatteryLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatteryLogData(
      ts: serializer.fromJson<int>(json['ts']),
      soc: serializer.fromJson<int>(json['soc']),
      charging: serializer.fromJson<bool?>(json['charging']),
      mv: serializer.fromJson<int?>(json['mv']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ts': serializer.toJson<int>(ts),
      'soc': serializer.toJson<int>(soc),
      'charging': serializer.toJson<bool?>(charging),
      'mv': serializer.toJson<int?>(mv),
    };
  }

  BatteryLogData copyWith({
    int? ts,
    int? soc,
    Value<bool?> charging = const Value.absent(),
    Value<int?> mv = const Value.absent(),
  }) => BatteryLogData(
    ts: ts ?? this.ts,
    soc: soc ?? this.soc,
    charging: charging.present ? charging.value : this.charging,
    mv: mv.present ? mv.value : this.mv,
  );
  BatteryLogData copyWithCompanion(BatteryLogCompanion data) {
    return BatteryLogData(
      ts: data.ts.present ? data.ts.value : this.ts,
      soc: data.soc.present ? data.soc.value : this.soc,
      charging: data.charging.present ? data.charging.value : this.charging,
      mv: data.mv.present ? data.mv.value : this.mv,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatteryLogData(')
          ..write('ts: $ts, ')
          ..write('soc: $soc, ')
          ..write('charging: $charging, ')
          ..write('mv: $mv')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ts, soc, charging, mv);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatteryLogData &&
          other.ts == this.ts &&
          other.soc == this.soc &&
          other.charging == this.charging &&
          other.mv == this.mv);
}

class BatteryLogCompanion extends UpdateCompanion<BatteryLogData> {
  final Value<int> ts;
  final Value<int> soc;
  final Value<bool?> charging;
  final Value<int?> mv;
  const BatteryLogCompanion({
    this.ts = const Value.absent(),
    this.soc = const Value.absent(),
    this.charging = const Value.absent(),
    this.mv = const Value.absent(),
  });
  BatteryLogCompanion.insert({
    this.ts = const Value.absent(),
    required int soc,
    this.charging = const Value.absent(),
    this.mv = const Value.absent(),
  }) : soc = Value(soc);
  static Insertable<BatteryLogData> custom({
    Expression<int>? ts,
    Expression<int>? soc,
    Expression<bool>? charging,
    Expression<int>? mv,
  }) {
    return RawValuesInsertable({
      if (ts != null) 'ts': ts,
      if (soc != null) 'soc': soc,
      if (charging != null) 'charging': charging,
      if (mv != null) 'mv': mv,
    });
  }

  BatteryLogCompanion copyWith({
    Value<int>? ts,
    Value<int>? soc,
    Value<bool?>? charging,
    Value<int?>? mv,
  }) {
    return BatteryLogCompanion(
      ts: ts ?? this.ts,
      soc: soc ?? this.soc,
      charging: charging ?? this.charging,
      mv: mv ?? this.mv,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (soc.present) {
      map['soc'] = Variable<int>(soc.value);
    }
    if (charging.present) {
      map['charging'] = Variable<bool>(charging.value);
    }
    if (mv.present) {
      map['mv'] = Variable<int>(mv.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatteryLogCompanion(')
          ..write('ts: $ts, ')
          ..write('soc: $soc, ')
          ..write('charging: $charging, ')
          ..write('mv: $mv')
          ..write(')'))
        .toString();
  }
}

class $DeviceInfoTable extends DeviceInfo
    with TableInfo<$DeviceInfoTable, DeviceInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<String> serial = GeneratedColumn<String>(
    'serial',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _macMeta = const VerificationMeta('mac');
  @override
  late final GeneratedColumn<String> mac = GeneratedColumn<String>(
    'mac',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hwVersionMeta = const VerificationMeta(
    'hwVersion',
  );
  @override
  late final GeneratedColumn<String> hwVersion = GeneratedColumn<String>(
    'hw_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fwVersionMeta = const VerificationMeta(
    'fwVersion',
  );
  @override
  late final GeneratedColumn<String> fwVersion = GeneratedColumn<String>(
    'fw_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dspVersionMeta = const VerificationMeta(
    'dspVersion',
  );
  @override
  late final GeneratedColumn<String> dspVersion = GeneratedColumn<String>(
    'dsp_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenTsMeta = const VerificationMeta(
    'lastSeenTs',
  );
  @override
  late final GeneratedColumn<int> lastSeenTs = GeneratedColumn<int>(
    'last_seen_ts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serial,
    mac,
    model,
    name,
    hwVersion,
    fwVersion,
    dspVersion,
    lastSeenTs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_info';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceInfoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('serial')) {
      context.handle(
        _serialMeta,
        serial.isAcceptableOrUnknown(data['serial']!, _serialMeta),
      );
    }
    if (data.containsKey('mac')) {
      context.handle(
        _macMeta,
        mac.isAcceptableOrUnknown(data['mac']!, _macMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('hw_version')) {
      context.handle(
        _hwVersionMeta,
        hwVersion.isAcceptableOrUnknown(data['hw_version']!, _hwVersionMeta),
      );
    }
    if (data.containsKey('fw_version')) {
      context.handle(
        _fwVersionMeta,
        fwVersion.isAcceptableOrUnknown(data['fw_version']!, _fwVersionMeta),
      );
    }
    if (data.containsKey('dsp_version')) {
      context.handle(
        _dspVersionMeta,
        dspVersion.isAcceptableOrUnknown(data['dsp_version']!, _dspVersionMeta),
      );
    }
    if (data.containsKey('last_seen_ts')) {
      context.handle(
        _lastSeenTsMeta,
        lastSeenTs.isAcceptableOrUnknown(
          data['last_seen_ts']!,
          _lastSeenTsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceInfoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial'],
      ),
      mac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      hwVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hw_version'],
      ),
      fwVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fw_version'],
      ),
      dspVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dsp_version'],
      ),
      lastSeenTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_ts'],
      ),
    );
  }

  @override
  $DeviceInfoTable createAlias(String alias) {
    return $DeviceInfoTable(attachedDatabase, alias);
  }
}

class DeviceInfoData extends DataClass implements Insertable<DeviceInfoData> {
  final String id;
  final String? serial;
  final String? mac;
  final String? model;
  final String? name;
  final String? hwVersion;
  final String? fwVersion;
  final String? dspVersion;
  final int? lastSeenTs;
  const DeviceInfoData({
    required this.id,
    this.serial,
    this.mac,
    this.model,
    this.name,
    this.hwVersion,
    this.fwVersion,
    this.dspVersion,
    this.lastSeenTs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serial != null) {
      map['serial'] = Variable<String>(serial);
    }
    if (!nullToAbsent || mac != null) {
      map['mac'] = Variable<String>(mac);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || hwVersion != null) {
      map['hw_version'] = Variable<String>(hwVersion);
    }
    if (!nullToAbsent || fwVersion != null) {
      map['fw_version'] = Variable<String>(fwVersion);
    }
    if (!nullToAbsent || dspVersion != null) {
      map['dsp_version'] = Variable<String>(dspVersion);
    }
    if (!nullToAbsent || lastSeenTs != null) {
      map['last_seen_ts'] = Variable<int>(lastSeenTs);
    }
    return map;
  }

  DeviceInfoCompanion toCompanion(bool nullToAbsent) {
    return DeviceInfoCompanion(
      id: Value(id),
      serial: serial == null && nullToAbsent
          ? const Value.absent()
          : Value(serial),
      mac: mac == null && nullToAbsent ? const Value.absent() : Value(mac),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      hwVersion: hwVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(hwVersion),
      fwVersion: fwVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(fwVersion),
      dspVersion: dspVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(dspVersion),
      lastSeenTs: lastSeenTs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenTs),
    );
  }

  factory DeviceInfoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceInfoData(
      id: serializer.fromJson<String>(json['id']),
      serial: serializer.fromJson<String?>(json['serial']),
      mac: serializer.fromJson<String?>(json['mac']),
      model: serializer.fromJson<String?>(json['model']),
      name: serializer.fromJson<String?>(json['name']),
      hwVersion: serializer.fromJson<String?>(json['hwVersion']),
      fwVersion: serializer.fromJson<String?>(json['fwVersion']),
      dspVersion: serializer.fromJson<String?>(json['dspVersion']),
      lastSeenTs: serializer.fromJson<int?>(json['lastSeenTs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serial': serializer.toJson<String?>(serial),
      'mac': serializer.toJson<String?>(mac),
      'model': serializer.toJson<String?>(model),
      'name': serializer.toJson<String?>(name),
      'hwVersion': serializer.toJson<String?>(hwVersion),
      'fwVersion': serializer.toJson<String?>(fwVersion),
      'dspVersion': serializer.toJson<String?>(dspVersion),
      'lastSeenTs': serializer.toJson<int?>(lastSeenTs),
    };
  }

  DeviceInfoData copyWith({
    String? id,
    Value<String?> serial = const Value.absent(),
    Value<String?> mac = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> hwVersion = const Value.absent(),
    Value<String?> fwVersion = const Value.absent(),
    Value<String?> dspVersion = const Value.absent(),
    Value<int?> lastSeenTs = const Value.absent(),
  }) => DeviceInfoData(
    id: id ?? this.id,
    serial: serial.present ? serial.value : this.serial,
    mac: mac.present ? mac.value : this.mac,
    model: model.present ? model.value : this.model,
    name: name.present ? name.value : this.name,
    hwVersion: hwVersion.present ? hwVersion.value : this.hwVersion,
    fwVersion: fwVersion.present ? fwVersion.value : this.fwVersion,
    dspVersion: dspVersion.present ? dspVersion.value : this.dspVersion,
    lastSeenTs: lastSeenTs.present ? lastSeenTs.value : this.lastSeenTs,
  );
  DeviceInfoData copyWithCompanion(DeviceInfoCompanion data) {
    return DeviceInfoData(
      id: data.id.present ? data.id.value : this.id,
      serial: data.serial.present ? data.serial.value : this.serial,
      mac: data.mac.present ? data.mac.value : this.mac,
      model: data.model.present ? data.model.value : this.model,
      name: data.name.present ? data.name.value : this.name,
      hwVersion: data.hwVersion.present ? data.hwVersion.value : this.hwVersion,
      fwVersion: data.fwVersion.present ? data.fwVersion.value : this.fwVersion,
      dspVersion: data.dspVersion.present
          ? data.dspVersion.value
          : this.dspVersion,
      lastSeenTs: data.lastSeenTs.present
          ? data.lastSeenTs.value
          : this.lastSeenTs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceInfoData(')
          ..write('id: $id, ')
          ..write('serial: $serial, ')
          ..write('mac: $mac, ')
          ..write('model: $model, ')
          ..write('name: $name, ')
          ..write('hwVersion: $hwVersion, ')
          ..write('fwVersion: $fwVersion, ')
          ..write('dspVersion: $dspVersion, ')
          ..write('lastSeenTs: $lastSeenTs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serial,
    mac,
    model,
    name,
    hwVersion,
    fwVersion,
    dspVersion,
    lastSeenTs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceInfoData &&
          other.id == this.id &&
          other.serial == this.serial &&
          other.mac == this.mac &&
          other.model == this.model &&
          other.name == this.name &&
          other.hwVersion == this.hwVersion &&
          other.fwVersion == this.fwVersion &&
          other.dspVersion == this.dspVersion &&
          other.lastSeenTs == this.lastSeenTs);
}

class DeviceInfoCompanion extends UpdateCompanion<DeviceInfoData> {
  final Value<String> id;
  final Value<String?> serial;
  final Value<String?> mac;
  final Value<String?> model;
  final Value<String?> name;
  final Value<String?> hwVersion;
  final Value<String?> fwVersion;
  final Value<String?> dspVersion;
  final Value<int?> lastSeenTs;
  final Value<int> rowid;
  const DeviceInfoCompanion({
    this.id = const Value.absent(),
    this.serial = const Value.absent(),
    this.mac = const Value.absent(),
    this.model = const Value.absent(),
    this.name = const Value.absent(),
    this.hwVersion = const Value.absent(),
    this.fwVersion = const Value.absent(),
    this.dspVersion = const Value.absent(),
    this.lastSeenTs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceInfoCompanion.insert({
    required String id,
    this.serial = const Value.absent(),
    this.mac = const Value.absent(),
    this.model = const Value.absent(),
    this.name = const Value.absent(),
    this.hwVersion = const Value.absent(),
    this.fwVersion = const Value.absent(),
    this.dspVersion = const Value.absent(),
    this.lastSeenTs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<DeviceInfoData> custom({
    Expression<String>? id,
    Expression<String>? serial,
    Expression<String>? mac,
    Expression<String>? model,
    Expression<String>? name,
    Expression<String>? hwVersion,
    Expression<String>? fwVersion,
    Expression<String>? dspVersion,
    Expression<int>? lastSeenTs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serial != null) 'serial': serial,
      if (mac != null) 'mac': mac,
      if (model != null) 'model': model,
      if (name != null) 'name': name,
      if (hwVersion != null) 'hw_version': hwVersion,
      if (fwVersion != null) 'fw_version': fwVersion,
      if (dspVersion != null) 'dsp_version': dspVersion,
      if (lastSeenTs != null) 'last_seen_ts': lastSeenTs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceInfoCompanion copyWith({
    Value<String>? id,
    Value<String?>? serial,
    Value<String?>? mac,
    Value<String?>? model,
    Value<String?>? name,
    Value<String?>? hwVersion,
    Value<String?>? fwVersion,
    Value<String?>? dspVersion,
    Value<int?>? lastSeenTs,
    Value<int>? rowid,
  }) {
    return DeviceInfoCompanion(
      id: id ?? this.id,
      serial: serial ?? this.serial,
      mac: mac ?? this.mac,
      model: model ?? this.model,
      name: name ?? this.name,
      hwVersion: hwVersion ?? this.hwVersion,
      fwVersion: fwVersion ?? this.fwVersion,
      dspVersion: dspVersion ?? this.dspVersion,
      lastSeenTs: lastSeenTs ?? this.lastSeenTs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serial.present) {
      map['serial'] = Variable<String>(serial.value);
    }
    if (mac.present) {
      map['mac'] = Variable<String>(mac.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hwVersion.present) {
      map['hw_version'] = Variable<String>(hwVersion.value);
    }
    if (fwVersion.present) {
      map['fw_version'] = Variable<String>(fwVersion.value);
    }
    if (dspVersion.present) {
      map['dsp_version'] = Variable<String>(dspVersion.value);
    }
    if (lastSeenTs.present) {
      map['last_seen_ts'] = Variable<int>(lastSeenTs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceInfoCompanion(')
          ..write('id: $id, ')
          ..write('serial: $serial, ')
          ..write('mac: $mac, ')
          ..write('model: $model, ')
          ..write('name: $name, ')
          ..write('hwVersion: $hwVersion, ')
          ..write('fwVersion: $fwVersion, ')
          ..write('dspVersion: $dspVersion, ')
          ..write('lastSeenTs: $lastSeenTs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StressSamplesTable extends StressSamples
    with TableInfo<$StressSamplesTable, StressSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StressSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ts, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stress_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<StressSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ts};
  @override
  StressSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StressSample(
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $StressSamplesTable createAlias(String alias) {
    return $StressSamplesTable(attachedDatabase, alias);
  }
}

class StressSample extends DataClass implements Insertable<StressSample> {
  final int ts;
  final double value;
  const StressSample({required this.ts, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts'] = Variable<int>(ts);
    map['value'] = Variable<double>(value);
    return map;
  }

  StressSamplesCompanion toCompanion(bool nullToAbsent) {
    return StressSamplesCompanion(ts: Value(ts), value: Value(value));
  }

  factory StressSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StressSample(
      ts: serializer.fromJson<int>(json['ts']),
      value: serializer.fromJson<double>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ts': serializer.toJson<int>(ts),
      'value': serializer.toJson<double>(value),
    };
  }

  StressSample copyWith({int? ts, double? value}) =>
      StressSample(ts: ts ?? this.ts, value: value ?? this.value);
  StressSample copyWithCompanion(StressSamplesCompanion data) {
    return StressSample(
      ts: data.ts.present ? data.ts.value : this.ts,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StressSample(')
          ..write('ts: $ts, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ts, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StressSample &&
          other.ts == this.ts &&
          other.value == this.value);
}

class StressSamplesCompanion extends UpdateCompanion<StressSample> {
  final Value<int> ts;
  final Value<double> value;
  const StressSamplesCompanion({
    this.ts = const Value.absent(),
    this.value = const Value.absent(),
  });
  StressSamplesCompanion.insert({
    this.ts = const Value.absent(),
    required double value,
  }) : value = Value(value);
  static Insertable<StressSample> custom({
    Expression<int>? ts,
    Expression<double>? value,
  }) {
    return RawValuesInsertable({
      if (ts != null) 'ts': ts,
      if (value != null) 'value': value,
    });
  }

  StressSamplesCompanion copyWith({Value<int>? ts, Value<double>? value}) {
    return StressSamplesCompanion(
      ts: ts ?? this.ts,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StressSamplesCompanion(')
          ..write('ts: $ts, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [ts, kind, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ts, kind};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int ts;
  final String kind;
  final String? payloadJson;
  const Event({required this.ts, required this.kind, this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ts'] = Variable<int>(ts);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      ts: Value(ts),
      kind: Value(kind),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      ts: serializer.fromJson<int>(json['ts']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ts': serializer.toJson<int>(ts),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String?>(payloadJson),
    };
  }

  Event copyWith({
    int? ts,
    String? kind,
    Value<String?> payloadJson = const Value.absent(),
  }) => Event(
    ts: ts ?? this.ts,
    kind: kind ?? this.kind,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      ts: data.ts.present ? data.ts.value : this.ts,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('ts: $ts, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ts, kind, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.ts == this.ts &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> ts;
  final Value<String> kind;
  final Value<String?> payloadJson;
  final Value<int> rowid;
  const EventsCompanion({
    this.ts = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required int ts,
    required String kind,
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ts = Value(ts),
       kind = Value(kind);
  static Insertable<Event> custom({
    Expression<int>? ts,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ts != null) 'ts': ts,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<int>? ts,
    Value<String>? kind,
    Value<String?>? payloadJson,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      ts: ts ?? this.ts,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('ts: $ts, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<int> maxHr = GeneratedColumn<int>(
    'max_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [day, heightCm, weightKg, maxHr];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('max_hr')) {
      context.handle(
        _maxHrMeta,
        maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      maxHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_hr'],
      ),
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final String day;
  final double? heightCm;
  final double? weightKg;
  final int? maxHr;
  const BodyMeasurement({
    required this.day,
    this.heightCm,
    this.weightKg,
    this.maxHr,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<int>(maxHr);
    }
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      day: Value(day),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      maxHr: maxHr == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHr),
    );
  }

  factory BodyMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      day: serializer.fromJson<String>(json['day']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      maxHr: serializer.fromJson<int?>(json['maxHr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'maxHr': serializer.toJson<int?>(maxHr),
    };
  }

  BodyMeasurement copyWith({
    String? day,
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<int?> maxHr = const Value.absent(),
  }) => BodyMeasurement(
    day: day ?? this.day,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    maxHr: maxHr.present ? maxHr.value : this.maxHr,
  );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      day: data.day.present ? data.day.value : this.day,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('day: $day, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('maxHr: $maxHr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, heightCm, weightKg, maxHr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.day == this.day &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.maxHr == this.maxHr);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<String> day;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<int?> maxHr;
  final Value<int> rowid;
  const BodyMeasurementsCompanion({
    this.day = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    required String day,
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<BodyMeasurement> custom({
    Expression<String>? day,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<int>? maxHr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (maxHr != null) 'max_hr': maxHr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<String>? day,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<int?>? maxHr,
    Value<int>? rowid,
  }) {
    return BodyMeasurementsCompanion(
      day: day ?? this.day,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      maxHr: maxHr ?? this.maxHr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<int>(maxHr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('day: $day, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('maxHr: $maxHr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredYesMeta = const VerificationMeta(
    'answeredYes',
  );
  @override
  late final GeneratedColumn<bool> answeredYes = GeneratedColumn<bool>(
    'answered_yes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("answered_yes" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _numericValueMeta = const VerificationMeta(
    'numericValue',
  );
  @override
  late final GeneratedColumn<double> numericValue = GeneratedColumn<double>(
    'numeric_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeLabelMeta = const VerificationMeta(
    'timeLabel',
  );
  @override
  late final GeneratedColumn<String> timeLabel = GeneratedColumn<String>(
    'time_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    questionId,
    answeredYes,
    numericValue,
    unit,
    timeLabel,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('answered_yes')) {
      context.handle(
        _answeredYesMeta,
        answeredYes.isAcceptableOrUnknown(
          data['answered_yes']!,
          _answeredYesMeta,
        ),
      );
    }
    if (data.containsKey('numeric_value')) {
      context.handle(
        _numericValueMeta,
        numericValue.isAcceptableOrUnknown(
          data['numeric_value']!,
          _numericValueMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('time_label')) {
      context.handle(
        _timeLabelMeta,
        timeLabel.isAcceptableOrUnknown(data['time_label']!, _timeLabelMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, questionId};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      answeredYes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}answered_yes'],
      )!,
      numericValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}numeric_value'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      timeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_label'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntry extends DataClass implements Insertable<JournalEntry> {
  final String day;
  final String questionId;
  final bool answeredYes;
  final double? numericValue;
  final String? unit;
  final String? timeLabel;
  final String? notes;
  const JournalEntry({
    required this.day,
    required this.questionId,
    required this.answeredYes,
    this.numericValue,
    this.unit,
    this.timeLabel,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['question_id'] = Variable<String>(questionId);
    map['answered_yes'] = Variable<bool>(answeredYes);
    if (!nullToAbsent || numericValue != null) {
      map['numeric_value'] = Variable<double>(numericValue);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || timeLabel != null) {
      map['time_label'] = Variable<String>(timeLabel);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      day: Value(day),
      questionId: Value(questionId),
      answeredYes: Value(answeredYes),
      numericValue: numericValue == null && nullToAbsent
          ? const Value.absent()
          : Value(numericValue),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      timeLabel: timeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(timeLabel),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory JournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntry(
      day: serializer.fromJson<String>(json['day']),
      questionId: serializer.fromJson<String>(json['questionId']),
      answeredYes: serializer.fromJson<bool>(json['answeredYes']),
      numericValue: serializer.fromJson<double?>(json['numericValue']),
      unit: serializer.fromJson<String?>(json['unit']),
      timeLabel: serializer.fromJson<String?>(json['timeLabel']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'questionId': serializer.toJson<String>(questionId),
      'answeredYes': serializer.toJson<bool>(answeredYes),
      'numericValue': serializer.toJson<double?>(numericValue),
      'unit': serializer.toJson<String?>(unit),
      'timeLabel': serializer.toJson<String?>(timeLabel),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  JournalEntry copyWith({
    String? day,
    String? questionId,
    bool? answeredYes,
    Value<double?> numericValue = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> timeLabel = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => JournalEntry(
    day: day ?? this.day,
    questionId: questionId ?? this.questionId,
    answeredYes: answeredYes ?? this.answeredYes,
    numericValue: numericValue.present ? numericValue.value : this.numericValue,
    unit: unit.present ? unit.value : this.unit,
    timeLabel: timeLabel.present ? timeLabel.value : this.timeLabel,
    notes: notes.present ? notes.value : this.notes,
  );
  JournalEntry copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntry(
      day: data.day.present ? data.day.value : this.day,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      answeredYes: data.answeredYes.present
          ? data.answeredYes.value
          : this.answeredYes,
      numericValue: data.numericValue.present
          ? data.numericValue.value
          : this.numericValue,
      unit: data.unit.present ? data.unit.value : this.unit,
      timeLabel: data.timeLabel.present ? data.timeLabel.value : this.timeLabel,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntry(')
          ..write('day: $day, ')
          ..write('questionId: $questionId, ')
          ..write('answeredYes: $answeredYes, ')
          ..write('numericValue: $numericValue, ')
          ..write('unit: $unit, ')
          ..write('timeLabel: $timeLabel, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    day,
    questionId,
    answeredYes,
    numericValue,
    unit,
    timeLabel,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntry &&
          other.day == this.day &&
          other.questionId == this.questionId &&
          other.answeredYes == this.answeredYes &&
          other.numericValue == this.numericValue &&
          other.unit == this.unit &&
          other.timeLabel == this.timeLabel &&
          other.notes == this.notes);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<String> day;
  final Value<String> questionId;
  final Value<bool> answeredYes;
  final Value<double?> numericValue;
  final Value<String?> unit;
  final Value<String?> timeLabel;
  final Value<String?> notes;
  final Value<int> rowid;
  const JournalEntriesCompanion({
    this.day = const Value.absent(),
    this.questionId = const Value.absent(),
    this.answeredYes = const Value.absent(),
    this.numericValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.timeLabel = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    required String day,
    required String questionId,
    this.answeredYes = const Value.absent(),
    this.numericValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.timeLabel = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       questionId = Value(questionId);
  static Insertable<JournalEntry> custom({
    Expression<String>? day,
    Expression<String>? questionId,
    Expression<bool>? answeredYes,
    Expression<double>? numericValue,
    Expression<String>? unit,
    Expression<String>? timeLabel,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (questionId != null) 'question_id': questionId,
      if (answeredYes != null) 'answered_yes': answeredYes,
      if (numericValue != null) 'numeric_value': numericValue,
      if (unit != null) 'unit': unit,
      if (timeLabel != null) 'time_label': timeLabel,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<String>? day,
    Value<String>? questionId,
    Value<bool>? answeredYes,
    Value<double?>? numericValue,
    Value<String?>? unit,
    Value<String?>? timeLabel,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return JournalEntriesCompanion(
      day: day ?? this.day,
      questionId: questionId ?? this.questionId,
      answeredYes: answeredYes ?? this.answeredYes,
      numericValue: numericValue ?? this.numericValue,
      unit: unit ?? this.unit,
      timeLabel: timeLabel ?? this.timeLabel,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (answeredYes.present) {
      map['answered_yes'] = Variable<bool>(answeredYes.value);
    }
    if (numericValue.present) {
      map['numeric_value'] = Variable<double>(numericValue.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (timeLabel.present) {
      map['time_label'] = Variable<String>(timeLabel.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('day: $day, ')
          ..write('questionId: $questionId, ')
          ..write('answeredYes: $answeredYes, ')
          ..write('numericValue: $numericValue, ')
          ..write('unit: $unit, ')
          ..write('timeLabel: $timeLabel, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalQuestionsTable extends JournalQuestions
    with TableInfo<$JournalQuestionsTable, JournalQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionTextMeta = const VerificationMeta(
    'questionText',
  );
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
    'question_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _questionTypeMeta = const VerificationMeta(
    'questionType',
  );
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
    'question_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('binary'),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minValMeta = const VerificationMeta('minVal');
  @override
  late final GeneratedColumn<double> minVal = GeneratedColumn<double>(
    'min_val',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxValMeta = const VerificationMeta('maxVal');
  @override
  late final GeneratedColumn<double> maxVal = GeneratedColumn<double>(
    'max_val',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<double> interval = GeneratedColumn<double>(
    'interval',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _choicesJsonMeta = const VerificationMeta(
    'choicesJson',
  );
  @override
  late final GeneratedColumn<String> choicesJson = GeneratedColumn<String>(
    'choices_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deprecatedMeta = const VerificationMeta(
    'deprecated',
  );
  @override
  late final GeneratedColumn<bool> deprecated = GeneratedColumn<bool>(
    'deprecated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deprecated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    category,
    title,
    questionText,
    questionType,
    unit,
    minVal,
    maxVal,
    interval,
    choicesJson,
    deprecated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('question_text')) {
      context.handle(
        _questionTextMeta,
        questionText.isAcceptableOrUnknown(
          data['question_text']!,
          _questionTextMeta,
        ),
      );
    }
    if (data.containsKey('question_type')) {
      context.handle(
        _questionTypeMeta,
        questionType.isAcceptableOrUnknown(
          data['question_type']!,
          _questionTypeMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('min_val')) {
      context.handle(
        _minValMeta,
        minVal.isAcceptableOrUnknown(data['min_val']!, _minValMeta),
      );
    }
    if (data.containsKey('max_val')) {
      context.handle(
        _maxValMeta,
        maxVal.isAcceptableOrUnknown(data['max_val']!, _maxValMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('choices_json')) {
      context.handle(
        _choicesJsonMeta,
        choicesJson.isAcceptableOrUnknown(
          data['choices_json']!,
          _choicesJsonMeta,
        ),
      );
    }
    if (data.containsKey('deprecated')) {
      context.handle(
        _deprecatedMeta,
        deprecated.isAcceptableOrUnknown(data['deprecated']!, _deprecatedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  JournalQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalQuestion(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      questionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_text'],
      ),
      questionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      minVal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_val'],
      ),
      maxVal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_val'],
      ),
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval'],
      ),
      choicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choices_json'],
      ),
      deprecated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deprecated'],
      )!,
    );
  }

  @override
  $JournalQuestionsTable createAlias(String alias) {
    return $JournalQuestionsTable(attachedDatabase, alias);
  }
}

class JournalQuestion extends DataClass implements Insertable<JournalQuestion> {
  final String questionId;
  final String? category;
  final String title;
  final String? questionText;
  final String questionType;
  final String? unit;
  final double? minVal;
  final double? maxVal;
  final double? interval;
  final String? choicesJson;
  final bool deprecated;
  const JournalQuestion({
    required this.questionId,
    this.category,
    required this.title,
    this.questionText,
    required this.questionType,
    this.unit,
    this.minVal,
    this.maxVal,
    this.interval,
    this.choicesJson,
    required this.deprecated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || questionText != null) {
      map['question_text'] = Variable<String>(questionText);
    }
    map['question_type'] = Variable<String>(questionType);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || minVal != null) {
      map['min_val'] = Variable<double>(minVal);
    }
    if (!nullToAbsent || maxVal != null) {
      map['max_val'] = Variable<double>(maxVal);
    }
    if (!nullToAbsent || interval != null) {
      map['interval'] = Variable<double>(interval);
    }
    if (!nullToAbsent || choicesJson != null) {
      map['choices_json'] = Variable<String>(choicesJson);
    }
    map['deprecated'] = Variable<bool>(deprecated);
    return map;
  }

  JournalQuestionsCompanion toCompanion(bool nullToAbsent) {
    return JournalQuestionsCompanion(
      questionId: Value(questionId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      title: Value(title),
      questionText: questionText == null && nullToAbsent
          ? const Value.absent()
          : Value(questionText),
      questionType: Value(questionType),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      minVal: minVal == null && nullToAbsent
          ? const Value.absent()
          : Value(minVal),
      maxVal: maxVal == null && nullToAbsent
          ? const Value.absent()
          : Value(maxVal),
      interval: interval == null && nullToAbsent
          ? const Value.absent()
          : Value(interval),
      choicesJson: choicesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(choicesJson),
      deprecated: Value(deprecated),
    );
  }

  factory JournalQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalQuestion(
      questionId: serializer.fromJson<String>(json['questionId']),
      category: serializer.fromJson<String?>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      questionText: serializer.fromJson<String?>(json['questionText']),
      questionType: serializer.fromJson<String>(json['questionType']),
      unit: serializer.fromJson<String?>(json['unit']),
      minVal: serializer.fromJson<double?>(json['minVal']),
      maxVal: serializer.fromJson<double?>(json['maxVal']),
      interval: serializer.fromJson<double?>(json['interval']),
      choicesJson: serializer.fromJson<String?>(json['choicesJson']),
      deprecated: serializer.fromJson<bool>(json['deprecated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'category': serializer.toJson<String?>(category),
      'title': serializer.toJson<String>(title),
      'questionText': serializer.toJson<String?>(questionText),
      'questionType': serializer.toJson<String>(questionType),
      'unit': serializer.toJson<String?>(unit),
      'minVal': serializer.toJson<double?>(minVal),
      'maxVal': serializer.toJson<double?>(maxVal),
      'interval': serializer.toJson<double?>(interval),
      'choicesJson': serializer.toJson<String?>(choicesJson),
      'deprecated': serializer.toJson<bool>(deprecated),
    };
  }

  JournalQuestion copyWith({
    String? questionId,
    Value<String?> category = const Value.absent(),
    String? title,
    Value<String?> questionText = const Value.absent(),
    String? questionType,
    Value<String?> unit = const Value.absent(),
    Value<double?> minVal = const Value.absent(),
    Value<double?> maxVal = const Value.absent(),
    Value<double?> interval = const Value.absent(),
    Value<String?> choicesJson = const Value.absent(),
    bool? deprecated,
  }) => JournalQuestion(
    questionId: questionId ?? this.questionId,
    category: category.present ? category.value : this.category,
    title: title ?? this.title,
    questionText: questionText.present ? questionText.value : this.questionText,
    questionType: questionType ?? this.questionType,
    unit: unit.present ? unit.value : this.unit,
    minVal: minVal.present ? minVal.value : this.minVal,
    maxVal: maxVal.present ? maxVal.value : this.maxVal,
    interval: interval.present ? interval.value : this.interval,
    choicesJson: choicesJson.present ? choicesJson.value : this.choicesJson,
    deprecated: deprecated ?? this.deprecated,
  );
  JournalQuestion copyWithCompanion(JournalQuestionsCompanion data) {
    return JournalQuestion(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      unit: data.unit.present ? data.unit.value : this.unit,
      minVal: data.minVal.present ? data.minVal.value : this.minVal,
      maxVal: data.maxVal.present ? data.maxVal.value : this.maxVal,
      interval: data.interval.present ? data.interval.value : this.interval,
      choicesJson: data.choicesJson.present
          ? data.choicesJson.value
          : this.choicesJson,
      deprecated: data.deprecated.present
          ? data.deprecated.value
          : this.deprecated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalQuestion(')
          ..write('questionId: $questionId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('questionText: $questionText, ')
          ..write('questionType: $questionType, ')
          ..write('unit: $unit, ')
          ..write('minVal: $minVal, ')
          ..write('maxVal: $maxVal, ')
          ..write('interval: $interval, ')
          ..write('choicesJson: $choicesJson, ')
          ..write('deprecated: $deprecated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    category,
    title,
    questionText,
    questionType,
    unit,
    minVal,
    maxVal,
    interval,
    choicesJson,
    deprecated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalQuestion &&
          other.questionId == this.questionId &&
          other.category == this.category &&
          other.title == this.title &&
          other.questionText == this.questionText &&
          other.questionType == this.questionType &&
          other.unit == this.unit &&
          other.minVal == this.minVal &&
          other.maxVal == this.maxVal &&
          other.interval == this.interval &&
          other.choicesJson == this.choicesJson &&
          other.deprecated == this.deprecated);
}

class JournalQuestionsCompanion extends UpdateCompanion<JournalQuestion> {
  final Value<String> questionId;
  final Value<String?> category;
  final Value<String> title;
  final Value<String?> questionText;
  final Value<String> questionType;
  final Value<String?> unit;
  final Value<double?> minVal;
  final Value<double?> maxVal;
  final Value<double?> interval;
  final Value<String?> choicesJson;
  final Value<bool> deprecated;
  final Value<int> rowid;
  const JournalQuestionsCompanion({
    this.questionId = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.questionText = const Value.absent(),
    this.questionType = const Value.absent(),
    this.unit = const Value.absent(),
    this.minVal = const Value.absent(),
    this.maxVal = const Value.absent(),
    this.interval = const Value.absent(),
    this.choicesJson = const Value.absent(),
    this.deprecated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalQuestionsCompanion.insert({
    required String questionId,
    this.category = const Value.absent(),
    required String title,
    this.questionText = const Value.absent(),
    this.questionType = const Value.absent(),
    this.unit = const Value.absent(),
    this.minVal = const Value.absent(),
    this.maxVal = const Value.absent(),
    this.interval = const Value.absent(),
    this.choicesJson = const Value.absent(),
    this.deprecated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       title = Value(title);
  static Insertable<JournalQuestion> custom({
    Expression<String>? questionId,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? questionText,
    Expression<String>? questionType,
    Expression<String>? unit,
    Expression<double>? minVal,
    Expression<double>? maxVal,
    Expression<double>? interval,
    Expression<String>? choicesJson,
    Expression<bool>? deprecated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (questionText != null) 'question_text': questionText,
      if (questionType != null) 'question_type': questionType,
      if (unit != null) 'unit': unit,
      if (minVal != null) 'min_val': minVal,
      if (maxVal != null) 'max_val': maxVal,
      if (interval != null) 'interval': interval,
      if (choicesJson != null) 'choices_json': choicesJson,
      if (deprecated != null) 'deprecated': deprecated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalQuestionsCompanion copyWith({
    Value<String>? questionId,
    Value<String?>? category,
    Value<String>? title,
    Value<String?>? questionText,
    Value<String>? questionType,
    Value<String?>? unit,
    Value<double?>? minVal,
    Value<double?>? maxVal,
    Value<double?>? interval,
    Value<String?>? choicesJson,
    Value<bool>? deprecated,
    Value<int>? rowid,
  }) {
    return JournalQuestionsCompanion(
      questionId: questionId ?? this.questionId,
      category: category ?? this.category,
      title: title ?? this.title,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      unit: unit ?? this.unit,
      minVal: minVal ?? this.minVal,
      maxVal: maxVal ?? this.maxVal,
      interval: interval ?? this.interval,
      choicesJson: choicesJson ?? this.choicesJson,
      deprecated: deprecated ?? this.deprecated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (minVal.present) {
      map['min_val'] = Variable<double>(minVal.value);
    }
    if (maxVal.present) {
      map['max_val'] = Variable<double>(maxVal.value);
    }
    if (interval.present) {
      map['interval'] = Variable<double>(interval.value);
    }
    if (choicesJson.present) {
      map['choices_json'] = Variable<String>(choicesJson.value);
    }
    if (deprecated.present) {
      map['deprecated'] = Variable<bool>(deprecated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalQuestionsCompanion(')
          ..write('questionId: $questionId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('questionText: $questionText, ')
          ..write('questionType: $questionType, ')
          ..write('unit: $unit, ')
          ..write('minVal: $minVal, ')
          ..write('maxVal: $maxVal, ')
          ..write('interval: $interval, ')
          ..write('choicesJson: $choicesJson, ')
          ..write('deprecated: $deprecated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightLogTable extends WeightLog
    with TableInfo<$WeightLogTable, WeightLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, kg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  WeightLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightLogData(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
    );
  }

  @override
  $WeightLogTable createAlias(String alias) {
    return $WeightLogTable(attachedDatabase, alias);
  }
}

class WeightLogData extends DataClass implements Insertable<WeightLogData> {
  final String day;
  final double kg;
  const WeightLogData({required this.day, required this.kg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['kg'] = Variable<double>(kg);
    return map;
  }

  WeightLogCompanion toCompanion(bool nullToAbsent) {
    return WeightLogCompanion(day: Value(day), kg: Value(kg));
  }

  factory WeightLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightLogData(
      day: serializer.fromJson<String>(json['day']),
      kg: serializer.fromJson<double>(json['kg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'kg': serializer.toJson<double>(kg),
    };
  }

  WeightLogData copyWith({String? day, double? kg}) =>
      WeightLogData(day: day ?? this.day, kg: kg ?? this.kg);
  WeightLogData copyWithCompanion(WeightLogCompanion data) {
    return WeightLogData(
      day: data.day.present ? data.day.value : this.day,
      kg: data.kg.present ? data.kg.value : this.kg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogData(')
          ..write('day: $day, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, kg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightLogData && other.day == this.day && other.kg == this.kg);
}

class WeightLogCompanion extends UpdateCompanion<WeightLogData> {
  final Value<String> day;
  final Value<double> kg;
  final Value<int> rowid;
  const WeightLogCompanion({
    this.day = const Value.absent(),
    this.kg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightLogCompanion.insert({
    required String day,
    required double kg,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       kg = Value(kg);
  static Insertable<WeightLogData> custom({
    Expression<String>? day,
    Expression<double>? kg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (kg != null) 'kg': kg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightLogCompanion copyWith({
    Value<String>? day,
    Value<double>? kg,
    Value<int>? rowid,
  }) {
    return WeightLogCompanion(
      day: day ?? this.day,
      kg: kg ?? this.kg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogCompanion(')
          ..write('day: $day, ')
          ..write('kg: $kg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaterLogTable extends WaterLog
    with TableInfo<$WaterLogTable, WaterLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<double> ml = GeneratedColumn<double>(
    'ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, ml];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  WaterLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterLogData(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      ml: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ml'],
      )!,
    );
  }

  @override
  $WaterLogTable createAlias(String alias) {
    return $WaterLogTable(attachedDatabase, alias);
  }
}

class WaterLogData extends DataClass implements Insertable<WaterLogData> {
  final String day;
  final double ml;
  const WaterLogData({required this.day, required this.ml});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['ml'] = Variable<double>(ml);
    return map;
  }

  WaterLogCompanion toCompanion(bool nullToAbsent) {
    return WaterLogCompanion(day: Value(day), ml: Value(ml));
  }

  factory WaterLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterLogData(
      day: serializer.fromJson<String>(json['day']),
      ml: serializer.fromJson<double>(json['ml']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'ml': serializer.toJson<double>(ml),
    };
  }

  WaterLogData copyWith({String? day, double? ml}) =>
      WaterLogData(day: day ?? this.day, ml: ml ?? this.ml);
  WaterLogData copyWithCompanion(WaterLogCompanion data) {
    return WaterLogData(
      day: data.day.present ? data.day.value : this.day,
      ml: data.ml.present ? data.ml.value : this.ml,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogData(')
          ..write('day: $day, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, ml);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterLogData && other.day == this.day && other.ml == this.ml);
}

class WaterLogCompanion extends UpdateCompanion<WaterLogData> {
  final Value<String> day;
  final Value<double> ml;
  final Value<int> rowid;
  const WaterLogCompanion({
    this.day = const Value.absent(),
    this.ml = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterLogCompanion.insert({
    required String day,
    required double ml,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       ml = Value(ml);
  static Insertable<WaterLogData> custom({
    Expression<String>? day,
    Expression<double>? ml,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (ml != null) 'ml': ml,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterLogCompanion copyWith({
    Value<String>? day,
    Value<double>? ml,
    Value<int>? rowid,
  }) {
    return WaterLogCompanion(
      day: day ?? this.day,
      ml: ml ?? this.ml,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (ml.present) {
      map['ml'] = Variable<double>(ml.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogCompanion(')
          ..write('day: $day, ')
          ..write('ml: $ml, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, Alarm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _daysMaskMeta = const VerificationMeta(
    'daysMask',
  );
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  static const VerificationMeta _lastArmedTsMeta = const VerificationMeta(
    'lastArmedTs',
  );
  @override
  late final GeneratedColumn<int> lastArmedTs = GeneratedColumn<int>(
    'last_armed_ts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hour,
    minute,
    enabled,
    daysMask,
    status,
    lastArmedTs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alarm> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('days_mask')) {
      context.handle(
        _daysMaskMeta,
        daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_armed_ts')) {
      context.handle(
        _lastArmedTsMeta,
        lastArmedTs.isAcceptableOrUnknown(
          data['last_armed_ts']!,
          _lastArmedTsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alarm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alarm(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      daysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_mask'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastArmedTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_armed_ts'],
      ),
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }
}

class Alarm extends DataClass implements Insertable<Alarm> {
  final String id;
  final int hour;
  final int minute;
  final bool enabled;
  final int daysMask;
  final String status;
  final int? lastArmedTs;
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.daysMask,
    required this.status,
    this.lastArmedTs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['enabled'] = Variable<bool>(enabled);
    map['days_mask'] = Variable<int>(daysMask);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastArmedTs != null) {
      map['last_armed_ts'] = Variable<int>(lastArmedTs);
    }
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      hour: Value(hour),
      minute: Value(minute),
      enabled: Value(enabled),
      daysMask: Value(daysMask),
      status: Value(status),
      lastArmedTs: lastArmedTs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastArmedTs),
    );
  }

  factory Alarm.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alarm(
      id: serializer.fromJson<String>(json['id']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      status: serializer.fromJson<String>(json['status']),
      lastArmedTs: serializer.fromJson<int?>(json['lastArmedTs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'enabled': serializer.toJson<bool>(enabled),
      'daysMask': serializer.toJson<int>(daysMask),
      'status': serializer.toJson<String>(status),
      'lastArmedTs': serializer.toJson<int?>(lastArmedTs),
    };
  }

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? enabled,
    int? daysMask,
    String? status,
    Value<int?> lastArmedTs = const Value.absent(),
  }) => Alarm(
    id: id ?? this.id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    enabled: enabled ?? this.enabled,
    daysMask: daysMask ?? this.daysMask,
    status: status ?? this.status,
    lastArmedTs: lastArmedTs.present ? lastArmedTs.value : this.lastArmedTs,
  );
  Alarm copyWithCompanion(AlarmsCompanion data) {
    return Alarm(
      id: data.id.present ? data.id.value : this.id,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      status: data.status.present ? data.status.value : this.status,
      lastArmedTs: data.lastArmedTs.present
          ? data.lastArmedTs.value
          : this.lastArmedTs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alarm(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled, ')
          ..write('daysMask: $daysMask, ')
          ..write('status: $status, ')
          ..write('lastArmedTs: $lastArmedTs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hour, minute, enabled, daysMask, status, lastArmedTs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alarm &&
          other.id == this.id &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.enabled == this.enabled &&
          other.daysMask == this.daysMask &&
          other.status == this.status &&
          other.lastArmedTs == this.lastArmedTs);
}

class AlarmsCompanion extends UpdateCompanion<Alarm> {
  final Value<String> id;
  final Value<int> hour;
  final Value<int> minute;
  final Value<bool> enabled;
  final Value<int> daysMask;
  final Value<String> status;
  final Value<int?> lastArmedTs;
  final Value<int> rowid;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.enabled = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.status = const Value.absent(),
    this.lastArmedTs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsCompanion.insert({
    required String id,
    required int hour,
    required int minute,
    this.enabled = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.status = const Value.absent(),
    this.lastArmedTs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hour = Value(hour),
       minute = Value(minute);
  static Insertable<Alarm> custom({
    Expression<String>? id,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<bool>? enabled,
    Expression<int>? daysMask,
    Expression<String>? status,
    Expression<int>? lastArmedTs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (enabled != null) 'enabled': enabled,
      if (daysMask != null) 'days_mask': daysMask,
      if (status != null) 'status': status,
      if (lastArmedTs != null) 'last_armed_ts': lastArmedTs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsCompanion copyWith({
    Value<String>? id,
    Value<int>? hour,
    Value<int>? minute,
    Value<bool>? enabled,
    Value<int>? daysMask,
    Value<String>? status,
    Value<int?>? lastArmedTs,
    Value<int>? rowid,
  }) {
    return AlarmsCompanion(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      daysMask: daysMask ?? this.daysMask,
      status: status ?? this.status,
      lastArmedTs: lastArmedTs ?? this.lastArmedTs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastArmedTs.present) {
      map['last_armed_ts'] = Variable<int>(lastArmedTs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled, ')
          ..write('daysMask: $daysMask, ')
          ..write('status: $status, ')
          ..write('lastArmedTs: $lastArmedTs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetricSamplesTable extends MetricSamples
    with TableInfo<$MetricSamplesTable, MetricSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [day, key, value, unit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metric_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, key};
  @override
  MetricSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricSample(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
    );
  }

  @override
  $MetricSamplesTable createAlias(String alias) {
    return $MetricSamplesTable(attachedDatabase, alias);
  }
}

class MetricSample extends DataClass implements Insertable<MetricSample> {
  final String day;
  final String key;
  final double value;
  final String? unit;
  const MetricSample({
    required this.day,
    required this.key,
    required this.value,
    this.unit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    return map;
  }

  MetricSamplesCompanion toCompanion(bool nullToAbsent) {
    return MetricSamplesCompanion(
      day: Value(day),
      key: Value(key),
      value: Value(value),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
    );
  }

  factory MetricSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricSample(
      day: serializer.fromJson<String>(json['day']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String?>(json['unit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String?>(unit),
    };
  }

  MetricSample copyWith({
    String? day,
    String? key,
    double? value,
    Value<String?> unit = const Value.absent(),
  }) => MetricSample(
    day: day ?? this.day,
    key: key ?? this.key,
    value: value ?? this.value,
    unit: unit.present ? unit.value : this.unit,
  );
  MetricSample copyWithCompanion(MetricSamplesCompanion data) {
    return MetricSample(
      day: data.day.present ? data.day.value : this.day,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricSample(')
          ..write('day: $day, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, key, value, unit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricSample &&
          other.day == this.day &&
          other.key == this.key &&
          other.value == this.value &&
          other.unit == this.unit);
}

class MetricSamplesCompanion extends UpdateCompanion<MetricSample> {
  final Value<String> day;
  final Value<String> key;
  final Value<double> value;
  final Value<String?> unit;
  final Value<int> rowid;
  const MetricSamplesCompanion({
    this.day = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetricSamplesCompanion.insert({
    required String day,
    required String key,
    required double value,
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       key = Value(key),
       value = Value(value);
  static Insertable<MetricSample> custom({
    Expression<String>? day,
    Expression<String>? key,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetricSamplesCompanion copyWith({
    Value<String>? day,
    Value<String>? key,
    Value<double>? value,
    Value<String?>? unit,
    Value<int>? rowid,
  }) {
    return MetricSamplesCompanion(
      day: day ?? this.day,
      key: key ?? this.key,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricSamplesCompanion(')
          ..write('day: $day, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodItemsTable extends FoodItems
    with TableInfo<$FoodItemsTable, FoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingSizeRawMeta = const VerificationMeta(
    'servingSizeRaw',
  );
  @override
  late final GeneratedColumn<String> servingSizeRaw = GeneratedColumn<String>(
    'serving_size_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingGramsMeta = const VerificationMeta(
    'servingGrams',
  );
  @override
  late final GeneratedColumn<double> servingGrams = GeneratedColumn<double>(
    'serving_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcal100Meta = const VerificationMeta(
    'kcal100',
  );
  @override
  late final GeneratedColumn<double> kcal100 = GeneratedColumn<double>(
    'kcal100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbs100Meta = const VerificationMeta(
    'carbs100',
  );
  @override
  late final GeneratedColumn<double> carbs100 = GeneratedColumn<double>(
    'carbs100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _protein100Meta = const VerificationMeta(
    'protein100',
  );
  @override
  late final GeneratedColumn<double> protein100 = GeneratedColumn<double>(
    'protein100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fat100Meta = const VerificationMeta('fat100');
  @override
  late final GeneratedColumn<double> fat100 = GeneratedColumn<double>(
    'fat100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sugar100Meta = const VerificationMeta(
    'sugar100',
  );
  @override
  late final GeneratedColumn<double> sugar100 = GeneratedColumn<double>(
    'sugar100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiber100Meta = const VerificationMeta(
    'fiber100',
  );
  @override
  late final GeneratedColumn<double> fiber100 = GeneratedColumn<double>(
    'fiber100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salt100Meta = const VerificationMeta(
    'salt100',
  );
  @override
  late final GeneratedColumn<double> salt100 = GeneratedColumn<double>(
    'salt100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('off'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    imageUrl,
    servingSizeRaw,
    servingGrams,
    kcal100,
    carbs100,
    protein100,
    fat100,
    sugar100,
    fiber100,
    salt100,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('serving_size_raw')) {
      context.handle(
        _servingSizeRawMeta,
        servingSizeRaw.isAcceptableOrUnknown(
          data['serving_size_raw']!,
          _servingSizeRawMeta,
        ),
      );
    }
    if (data.containsKey('serving_grams')) {
      context.handle(
        _servingGramsMeta,
        servingGrams.isAcceptableOrUnknown(
          data['serving_grams']!,
          _servingGramsMeta,
        ),
      );
    }
    if (data.containsKey('kcal100')) {
      context.handle(
        _kcal100Meta,
        kcal100.isAcceptableOrUnknown(data['kcal100']!, _kcal100Meta),
      );
    }
    if (data.containsKey('carbs100')) {
      context.handle(
        _carbs100Meta,
        carbs100.isAcceptableOrUnknown(data['carbs100']!, _carbs100Meta),
      );
    }
    if (data.containsKey('protein100')) {
      context.handle(
        _protein100Meta,
        protein100.isAcceptableOrUnknown(data['protein100']!, _protein100Meta),
      );
    }
    if (data.containsKey('fat100')) {
      context.handle(
        _fat100Meta,
        fat100.isAcceptableOrUnknown(data['fat100']!, _fat100Meta),
      );
    }
    if (data.containsKey('sugar100')) {
      context.handle(
        _sugar100Meta,
        sugar100.isAcceptableOrUnknown(data['sugar100']!, _sugar100Meta),
      );
    }
    if (data.containsKey('fiber100')) {
      context.handle(
        _fiber100Meta,
        fiber100.isAcceptableOrUnknown(data['fiber100']!, _fiber100Meta),
      );
    }
    if (data.containsKey('salt100')) {
      context.handle(
        _salt100Meta,
        salt100.isAcceptableOrUnknown(data['salt100']!, _salt100Meta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      servingSizeRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_size_raw'],
      ),
      servingGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_grams'],
      ),
      kcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100'],
      ),
      carbs100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs100'],
      ),
      protein100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100'],
      ),
      fat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100'],
      ),
      sugar100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar100'],
      ),
      fiber100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber100'],
      ),
      salt100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salt100'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $FoodItemsTable createAlias(String alias) {
    return $FoodItemsTable(attachedDatabase, alias);
  }
}

class FoodItem extends DataClass implements Insertable<FoodItem> {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? servingSizeRaw;
  final double? servingGrams;
  final double? kcal100;
  final double? carbs100;
  final double? protein100;
  final double? fat100;
  final double? sugar100;
  final double? fiber100;
  final double? salt100;
  final String source;
  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    this.servingSizeRaw,
    this.servingGrams,
    this.kcal100,
    this.carbs100,
    this.protein100,
    this.fat100,
    this.sugar100,
    this.fiber100,
    this.salt100,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || servingSizeRaw != null) {
      map['serving_size_raw'] = Variable<String>(servingSizeRaw);
    }
    if (!nullToAbsent || servingGrams != null) {
      map['serving_grams'] = Variable<double>(servingGrams);
    }
    if (!nullToAbsent || kcal100 != null) {
      map['kcal100'] = Variable<double>(kcal100);
    }
    if (!nullToAbsent || carbs100 != null) {
      map['carbs100'] = Variable<double>(carbs100);
    }
    if (!nullToAbsent || protein100 != null) {
      map['protein100'] = Variable<double>(protein100);
    }
    if (!nullToAbsent || fat100 != null) {
      map['fat100'] = Variable<double>(fat100);
    }
    if (!nullToAbsent || sugar100 != null) {
      map['sugar100'] = Variable<double>(sugar100);
    }
    if (!nullToAbsent || fiber100 != null) {
      map['fiber100'] = Variable<double>(fiber100);
    }
    if (!nullToAbsent || salt100 != null) {
      map['salt100'] = Variable<double>(salt100);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  FoodItemsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      servingSizeRaw: servingSizeRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(servingSizeRaw),
      servingGrams: servingGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(servingGrams),
      kcal100: kcal100 == null && nullToAbsent
          ? const Value.absent()
          : Value(kcal100),
      carbs100: carbs100 == null && nullToAbsent
          ? const Value.absent()
          : Value(carbs100),
      protein100: protein100 == null && nullToAbsent
          ? const Value.absent()
          : Value(protein100),
      fat100: fat100 == null && nullToAbsent
          ? const Value.absent()
          : Value(fat100),
      sugar100: sugar100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sugar100),
      fiber100: fiber100 == null && nullToAbsent
          ? const Value.absent()
          : Value(fiber100),
      salt100: salt100 == null && nullToAbsent
          ? const Value.absent()
          : Value(salt100),
      source: Value(source),
    );
  }

  factory FoodItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItem(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      servingSizeRaw: serializer.fromJson<String?>(json['servingSizeRaw']),
      servingGrams: serializer.fromJson<double?>(json['servingGrams']),
      kcal100: serializer.fromJson<double?>(json['kcal100']),
      carbs100: serializer.fromJson<double?>(json['carbs100']),
      protein100: serializer.fromJson<double?>(json['protein100']),
      fat100: serializer.fromJson<double?>(json['fat100']),
      sugar100: serializer.fromJson<double?>(json['sugar100']),
      fiber100: serializer.fromJson<double?>(json['fiber100']),
      salt100: serializer.fromJson<double?>(json['salt100']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'servingSizeRaw': serializer.toJson<String?>(servingSizeRaw),
      'servingGrams': serializer.toJson<double?>(servingGrams),
      'kcal100': serializer.toJson<double?>(kcal100),
      'carbs100': serializer.toJson<double?>(carbs100),
      'protein100': serializer.toJson<double?>(protein100),
      'fat100': serializer.toJson<double?>(fat100),
      'sugar100': serializer.toJson<double?>(sugar100),
      'fiber100': serializer.toJson<double?>(fiber100),
      'salt100': serializer.toJson<double?>(salt100),
      'source': serializer.toJson<String>(source),
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> servingSizeRaw = const Value.absent(),
    Value<double?> servingGrams = const Value.absent(),
    Value<double?> kcal100 = const Value.absent(),
    Value<double?> carbs100 = const Value.absent(),
    Value<double?> protein100 = const Value.absent(),
    Value<double?> fat100 = const Value.absent(),
    Value<double?> sugar100 = const Value.absent(),
    Value<double?> fiber100 = const Value.absent(),
    Value<double?> salt100 = const Value.absent(),
    String? source,
  }) => FoodItem(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    servingSizeRaw: servingSizeRaw.present
        ? servingSizeRaw.value
        : this.servingSizeRaw,
    servingGrams: servingGrams.present ? servingGrams.value : this.servingGrams,
    kcal100: kcal100.present ? kcal100.value : this.kcal100,
    carbs100: carbs100.present ? carbs100.value : this.carbs100,
    protein100: protein100.present ? protein100.value : this.protein100,
    fat100: fat100.present ? fat100.value : this.fat100,
    sugar100: sugar100.present ? sugar100.value : this.sugar100,
    fiber100: fiber100.present ? fiber100.value : this.fiber100,
    salt100: salt100.present ? salt100.value : this.salt100,
    source: source ?? this.source,
  );
  FoodItem copyWithCompanion(FoodItemsCompanion data) {
    return FoodItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      servingSizeRaw: data.servingSizeRaw.present
          ? data.servingSizeRaw.value
          : this.servingSizeRaw,
      servingGrams: data.servingGrams.present
          ? data.servingGrams.value
          : this.servingGrams,
      kcal100: data.kcal100.present ? data.kcal100.value : this.kcal100,
      carbs100: data.carbs100.present ? data.carbs100.value : this.carbs100,
      protein100: data.protein100.present
          ? data.protein100.value
          : this.protein100,
      fat100: data.fat100.present ? data.fat100.value : this.fat100,
      sugar100: data.sugar100.present ? data.sugar100.value : this.sugar100,
      fiber100: data.fiber100.present ? data.fiber100.value : this.fiber100,
      salt100: data.salt100.present ? data.salt100.value : this.salt100,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('servingSizeRaw: $servingSizeRaw, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('kcal100: $kcal100, ')
          ..write('carbs100: $carbs100, ')
          ..write('protein100: $protein100, ')
          ..write('fat100: $fat100, ')
          ..write('sugar100: $sugar100, ')
          ..write('fiber100: $fiber100, ')
          ..write('salt100: $salt100, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    imageUrl,
    servingSizeRaw,
    servingGrams,
    kcal100,
    carbs100,
    protein100,
    fat100,
    sugar100,
    fiber100,
    salt100,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.imageUrl == this.imageUrl &&
          other.servingSizeRaw == this.servingSizeRaw &&
          other.servingGrams == this.servingGrams &&
          other.kcal100 == this.kcal100 &&
          other.carbs100 == this.carbs100 &&
          other.protein100 == this.protein100 &&
          other.fat100 == this.fat100 &&
          other.sugar100 == this.sugar100 &&
          other.fiber100 == this.fiber100 &&
          other.salt100 == this.salt100 &&
          other.source == this.source);
}

class FoodItemsCompanion extends UpdateCompanion<FoodItem> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> imageUrl;
  final Value<String?> servingSizeRaw;
  final Value<double?> servingGrams;
  final Value<double?> kcal100;
  final Value<double?> carbs100;
  final Value<double?> protein100;
  final Value<double?> fat100;
  final Value<double?> sugar100;
  final Value<double?> fiber100;
  final Value<double?> salt100;
  final Value<String> source;
  final Value<int> rowid;
  const FoodItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.servingSizeRaw = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.carbs100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.sugar100 = const Value.absent(),
    this.fiber100 = const Value.absent(),
    this.salt100 = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodItemsCompanion.insert({
    required String id,
    required String name,
    this.brand = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.servingSizeRaw = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.carbs100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.sugar100 = const Value.absent(),
    this.fiber100 = const Value.absent(),
    this.salt100 = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<FoodItem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? imageUrl,
    Expression<String>? servingSizeRaw,
    Expression<double>? servingGrams,
    Expression<double>? kcal100,
    Expression<double>? carbs100,
    Expression<double>? protein100,
    Expression<double>? fat100,
    Expression<double>? sugar100,
    Expression<double>? fiber100,
    Expression<double>? salt100,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (imageUrl != null) 'image_url': imageUrl,
      if (servingSizeRaw != null) 'serving_size_raw': servingSizeRaw,
      if (servingGrams != null) 'serving_grams': servingGrams,
      if (kcal100 != null) 'kcal100': kcal100,
      if (carbs100 != null) 'carbs100': carbs100,
      if (protein100 != null) 'protein100': protein100,
      if (fat100 != null) 'fat100': fat100,
      if (sugar100 != null) 'sugar100': sugar100,
      if (fiber100 != null) 'fiber100': fiber100,
      if (salt100 != null) 'salt100': salt100,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? imageUrl,
    Value<String?>? servingSizeRaw,
    Value<double?>? servingGrams,
    Value<double?>? kcal100,
    Value<double?>? carbs100,
    Value<double?>? protein100,
    Value<double?>? fat100,
    Value<double?>? sugar100,
    Value<double?>? fiber100,
    Value<double?>? salt100,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return FoodItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      servingSizeRaw: servingSizeRaw ?? this.servingSizeRaw,
      servingGrams: servingGrams ?? this.servingGrams,
      kcal100: kcal100 ?? this.kcal100,
      carbs100: carbs100 ?? this.carbs100,
      protein100: protein100 ?? this.protein100,
      fat100: fat100 ?? this.fat100,
      sugar100: sugar100 ?? this.sugar100,
      fiber100: fiber100 ?? this.fiber100,
      salt100: salt100 ?? this.salt100,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (servingSizeRaw.present) {
      map['serving_size_raw'] = Variable<String>(servingSizeRaw.value);
    }
    if (servingGrams.present) {
      map['serving_grams'] = Variable<double>(servingGrams.value);
    }
    if (kcal100.present) {
      map['kcal100'] = Variable<double>(kcal100.value);
    }
    if (carbs100.present) {
      map['carbs100'] = Variable<double>(carbs100.value);
    }
    if (protein100.present) {
      map['protein100'] = Variable<double>(protein100.value);
    }
    if (fat100.present) {
      map['fat100'] = Variable<double>(fat100.value);
    }
    if (sugar100.present) {
      map['sugar100'] = Variable<double>(sugar100.value);
    }
    if (fiber100.present) {
      map['fiber100'] = Variable<double>(fiber100.value);
    }
    if (salt100.present) {
      map['salt100'] = Variable<double>(salt100.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('servingSizeRaw: $servingSizeRaw, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('kcal100: $kcal100, ')
          ..write('carbs100: $carbs100, ')
          ..write('protein100: $protein100, ')
          ..write('fat100: $fat100, ')
          ..write('sugar100: $sugar100, ')
          ..write('fiber100: $fiber100, ')
          ..write('salt100: $salt100, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdTsMeta = const VerificationMeta(
    'createdTs',
  );
  @override
  late final GeneratedColumn<int> createdTs = GeneratedColumn<int>(
    'created_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, type, createdTs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_ts')) {
      context.handle(
        _createdTsMeta,
        createdTs.isAcceptableOrUnknown(data['created_ts']!, _createdTsMeta),
      );
    } else if (isInserting) {
      context.missing(_createdTsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_ts'],
      )!,
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final String id;
  final String day;
  final String type;
  final int createdTs;
  const Meal({
    required this.id,
    required this.day,
    required this.type,
    required this.createdTs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['type'] = Variable<String>(type);
    map['created_ts'] = Variable<int>(createdTs);
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      day: Value(day),
      type: Value(type),
      createdTs: Value(createdTs),
    );
  }

  factory Meal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      type: serializer.fromJson<String>(json['type']),
      createdTs: serializer.fromJson<int>(json['createdTs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'type': serializer.toJson<String>(type),
      'createdTs': serializer.toJson<int>(createdTs),
    };
  }

  Meal copyWith({String? id, String? day, String? type, int? createdTs}) =>
      Meal(
        id: id ?? this.id,
        day: day ?? this.day,
        type: type ?? this.type,
        createdTs: createdTs ?? this.createdTs,
      );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      type: data.type.present ? data.type.value : this.type,
      createdTs: data.createdTs.present ? data.createdTs.value : this.createdTs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('type: $type, ')
          ..write('createdTs: $createdTs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, type, createdTs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.day == this.day &&
          other.type == this.type &&
          other.createdTs == this.createdTs);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<String> id;
  final Value<String> day;
  final Value<String> type;
  final Value<int> createdTs;
  final Value<int> rowid;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.type = const Value.absent(),
    this.createdTs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealsCompanion.insert({
    required String id,
    required String day,
    required String type,
    required int createdTs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       type = Value(type),
       createdTs = Value(createdTs);
  static Insertable<Meal> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<String>? type,
    Expression<int>? createdTs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (type != null) 'type': type,
      if (createdTs != null) 'created_ts': createdTs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealsCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<String>? type,
    Value<int>? createdTs,
    Value<int>? rowid,
  }) {
    return MealsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      type: type ?? this.type,
      createdTs: createdTs ?? this.createdTs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdTs.present) {
      map['created_ts'] = Variable<int>(createdTs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('type: $type, ')
          ..write('createdTs: $createdTs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodEntriesTable extends FoodEntries
    with TableInfo<$FoodEntriesTable, FoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _foodItemIdMeta = const VerificationMeta(
    'foodItemId',
  );
  @override
  late final GeneratedColumn<String> foodItemId = GeneratedColumn<String>(
    'food_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mealId,
    foodItemId,
    name,
    grams,
    kcal,
    carbs,
    protein,
    fat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('food_item_id')) {
      context.handle(
        _foodItemIdMeta,
        foodItemId.isAcceptableOrUnknown(
          data['food_item_id']!,
          _foodItemIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      foodItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_item_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      )!,
    );
  }

  @override
  $FoodEntriesTable createAlias(String alias) {
    return $FoodEntriesTable(attachedDatabase, alias);
  }
}

class FoodEntry extends DataClass implements Insertable<FoodEntry> {
  final String id;
  final String mealId;
  final String? foodItemId;
  final String name;
  final double grams;
  final double kcal;
  final double carbs;
  final double protein;
  final double fat;
  const FoodEntry({
    required this.id,
    required this.mealId,
    this.foodItemId,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meal_id'] = Variable<String>(mealId);
    if (!nullToAbsent || foodItemId != null) {
      map['food_item_id'] = Variable<String>(foodItemId);
    }
    map['name'] = Variable<String>(name);
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['carbs'] = Variable<double>(carbs);
    map['protein'] = Variable<double>(protein);
    map['fat'] = Variable<double>(fat);
    return map;
  }

  FoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodEntriesCompanion(
      id: Value(id),
      mealId: Value(mealId),
      foodItemId: foodItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodItemId),
      name: Value(name),
      grams: Value(grams),
      kcal: Value(kcal),
      carbs: Value(carbs),
      protein: Value(protein),
      fat: Value(fat),
    );
  }

  factory FoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodEntry(
      id: serializer.fromJson<String>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      foodItemId: serializer.fromJson<String?>(json['foodItemId']),
      name: serializer.fromJson<String>(json['name']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      carbs: serializer.fromJson<double>(json['carbs']),
      protein: serializer.fromJson<double>(json['protein']),
      fat: serializer.fromJson<double>(json['fat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mealId': serializer.toJson<String>(mealId),
      'foodItemId': serializer.toJson<String?>(foodItemId),
      'name': serializer.toJson<String>(name),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'carbs': serializer.toJson<double>(carbs),
      'protein': serializer.toJson<double>(protein),
      'fat': serializer.toJson<double>(fat),
    };
  }

  FoodEntry copyWith({
    String? id,
    String? mealId,
    Value<String?> foodItemId = const Value.absent(),
    String? name,
    double? grams,
    double? kcal,
    double? carbs,
    double? protein,
    double? fat,
  }) => FoodEntry(
    id: id ?? this.id,
    mealId: mealId ?? this.mealId,
    foodItemId: foodItemId.present ? foodItemId.value : this.foodItemId,
    name: name ?? this.name,
    grams: grams ?? this.grams,
    kcal: kcal ?? this.kcal,
    carbs: carbs ?? this.carbs,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
  );
  FoodEntry copyWithCompanion(FoodEntriesCompanion data) {
    return FoodEntry(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      foodItemId: data.foodItemId.present
          ? data.foodItemId.value
          : this.foodItemId,
      name: data.name.present ? data.name.value : this.name,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      protein: data.protein.present ? data.protein.value : this.protein,
      fat: data.fat.present ? data.fat.value : this.fat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntry(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('carbs: $carbs, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mealId,
    foodItemId,
    name,
    grams,
    kcal,
    carbs,
    protein,
    fat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodEntry &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.foodItemId == this.foodItemId &&
          other.name == this.name &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.carbs == this.carbs &&
          other.protein == this.protein &&
          other.fat == this.fat);
}

class FoodEntriesCompanion extends UpdateCompanion<FoodEntry> {
  final Value<String> id;
  final Value<String> mealId;
  final Value<String?> foodItemId;
  final Value<String> name;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> carbs;
  final Value<double> protein;
  final Value<double> fat;
  final Value<int> rowid;
  const FoodEntriesCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.foodItemId = const Value.absent(),
    this.name = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.carbs = const Value.absent(),
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodEntriesCompanion.insert({
    required String id,
    required String mealId,
    this.foodItemId = const Value.absent(),
    required String name,
    required double grams,
    required double kcal,
    this.carbs = const Value.absent(),
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mealId = Value(mealId),
       name = Value(name),
       grams = Value(grams),
       kcal = Value(kcal);
  static Insertable<FoodEntry> custom({
    Expression<String>? id,
    Expression<String>? mealId,
    Expression<String>? foodItemId,
    Expression<String>? name,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? carbs,
    Expression<double>? protein,
    Expression<double>? fat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (foodItemId != null) 'food_item_id': foodItemId,
      if (name != null) 'name': name,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (carbs != null) 'carbs': carbs,
      if (protein != null) 'protein': protein,
      if (fat != null) 'fat': fat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? mealId,
    Value<String?>? foodItemId,
    Value<String>? name,
    Value<double>? grams,
    Value<double>? kcal,
    Value<double>? carbs,
    Value<double>? protein,
    Value<double>? fat,
    Value<int>? rowid,
  }) {
    return FoodEntriesCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      foodItemId: foodItemId ?? this.foodItemId,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (foodItemId.present) {
      map['food_item_id'] = Variable<String>(foodItemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('foodItemId: $foodItemId, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('carbs: $carbs, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopHrSamplesTable extends WhoopHrSamples
    with TableInfo<$WhoopHrSamplesTable, WhoopHrSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopHrSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrFixed88Meta = const VerificationMeta(
    'hrFixed88',
  );
  @override
  late final GeneratedColumn<int> hrFixed88 = GeneratedColumn<int>(
    'hr_fixed88',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onwristMeta = const VerificationMeta(
    'onwrist',
  );
  @override
  late final GeneratedColumn<int> onwrist = GeneratedColumn<int>(
    'onwrist',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    ts,
    bpm,
    hrFixed88,
    onwrist,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hrSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopHrSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    if (data.containsKey('hr_fixed88')) {
      context.handle(
        _hrFixed88Meta,
        hrFixed88.isAcceptableOrUnknown(data['hr_fixed88']!, _hrFixed88Meta),
      );
    }
    if (data.containsKey('onwrist')) {
      context.handle(
        _onwristMeta,
        onwrist.isAcceptableOrUnknown(data['onwrist']!, _onwristMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopHrSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopHrSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      hrFixed88: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_fixed88'],
      ),
      onwrist: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onwrist'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopHrSamplesTable createAlias(String alias) {
    return $WhoopHrSamplesTable(attachedDatabase, alias);
  }
}

class WhoopHrSample extends DataClass implements Insertable<WhoopHrSample> {
  final String deviceId;
  final int ts;
  final int bpm;
  final int? hrFixed88;
  final int? onwrist;
  final int synced;
  const WhoopHrSample({
    required this.deviceId,
    required this.ts,
    required this.bpm,
    this.hrFixed88,
    this.onwrist,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['bpm'] = Variable<int>(bpm);
    if (!nullToAbsent || hrFixed88 != null) {
      map['hr_fixed88'] = Variable<int>(hrFixed88);
    }
    if (!nullToAbsent || onwrist != null) {
      map['onwrist'] = Variable<int>(onwrist);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopHrSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopHrSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      bpm: Value(bpm),
      hrFixed88: hrFixed88 == null && nullToAbsent
          ? const Value.absent()
          : Value(hrFixed88),
      onwrist: onwrist == null && nullToAbsent
          ? const Value.absent()
          : Value(onwrist),
      synced: Value(synced),
    );
  }

  factory WhoopHrSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopHrSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      bpm: serializer.fromJson<int>(json['bpm']),
      hrFixed88: serializer.fromJson<int?>(json['hrFixed88']),
      onwrist: serializer.fromJson<int?>(json['onwrist']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'bpm': serializer.toJson<int>(bpm),
      'hrFixed88': serializer.toJson<int?>(hrFixed88),
      'onwrist': serializer.toJson<int?>(onwrist),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopHrSample copyWith({
    String? deviceId,
    int? ts,
    int? bpm,
    Value<int?> hrFixed88 = const Value.absent(),
    Value<int?> onwrist = const Value.absent(),
    int? synced,
  }) => WhoopHrSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    bpm: bpm ?? this.bpm,
    hrFixed88: hrFixed88.present ? hrFixed88.value : this.hrFixed88,
    onwrist: onwrist.present ? onwrist.value : this.onwrist,
    synced: synced ?? this.synced,
  );
  WhoopHrSample copyWithCompanion(WhoopHrSamplesCompanion data) {
    return WhoopHrSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      hrFixed88: data.hrFixed88.present ? data.hrFixed88.value : this.hrFixed88,
      onwrist: data.onwrist.present ? data.onwrist.value : this.onwrist,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopHrSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('bpm: $bpm, ')
          ..write('hrFixed88: $hrFixed88, ')
          ..write('onwrist: $onwrist, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, ts, bpm, hrFixed88, onwrist, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopHrSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.bpm == this.bpm &&
          other.hrFixed88 == this.hrFixed88 &&
          other.onwrist == this.onwrist &&
          other.synced == this.synced);
}

class WhoopHrSamplesCompanion extends UpdateCompanion<WhoopHrSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> bpm;
  final Value<int?> hrFixed88;
  final Value<int?> onwrist;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopHrSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.bpm = const Value.absent(),
    this.hrFixed88 = const Value.absent(),
    this.onwrist = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopHrSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int bpm,
    this.hrFixed88 = const Value.absent(),
    this.onwrist = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       bpm = Value(bpm);
  static Insertable<WhoopHrSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? bpm,
    Expression<int>? hrFixed88,
    Expression<int>? onwrist,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (bpm != null) 'bpm': bpm,
      if (hrFixed88 != null) 'hr_fixed88': hrFixed88,
      if (onwrist != null) 'onwrist': onwrist,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopHrSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? bpm,
    Value<int?>? hrFixed88,
    Value<int?>? onwrist,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopHrSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      bpm: bpm ?? this.bpm,
      hrFixed88: hrFixed88 ?? this.hrFixed88,
      onwrist: onwrist ?? this.onwrist,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (hrFixed88.present) {
      map['hr_fixed88'] = Variable<int>(hrFixed88.value);
    }
    if (onwrist.present) {
      map['onwrist'] = Variable<int>(onwrist.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopHrSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('bpm: $bpm, ')
          ..write('hrFixed88: $hrFixed88, ')
          ..write('onwrist: $onwrist, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopPpgHrSamplesTable extends WhoopPpgHrSamples
    with TableInfo<$WhoopPpgHrSamplesTable, WhoopPpgHrSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopPpgHrSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confMeta = const VerificationMeta('conf');
  @override
  late final GeneratedColumn<double> conf = GeneratedColumn<double>(
    'conf',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, bpm, conf, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ppgHrSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopPpgHrSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    if (data.containsKey('conf')) {
      context.handle(
        _confMeta,
        conf.isAcceptableOrUnknown(data['conf']!, _confMeta),
      );
    } else if (isInserting) {
      context.missing(_confMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopPpgHrSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopPpgHrSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      conf: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}conf'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopPpgHrSamplesTable createAlias(String alias) {
    return $WhoopPpgHrSamplesTable(attachedDatabase, alias);
  }
}

class WhoopPpgHrSample extends DataClass
    implements Insertable<WhoopPpgHrSample> {
  final String deviceId;
  final int ts;
  final int bpm;
  final double conf;
  final int synced;
  const WhoopPpgHrSample({
    required this.deviceId,
    required this.ts,
    required this.bpm,
    required this.conf,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['bpm'] = Variable<int>(bpm);
    map['conf'] = Variable<double>(conf);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopPpgHrSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopPpgHrSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      bpm: Value(bpm),
      conf: Value(conf),
      synced: Value(synced),
    );
  }

  factory WhoopPpgHrSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopPpgHrSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      bpm: serializer.fromJson<int>(json['bpm']),
      conf: serializer.fromJson<double>(json['conf']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'bpm': serializer.toJson<int>(bpm),
      'conf': serializer.toJson<double>(conf),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopPpgHrSample copyWith({
    String? deviceId,
    int? ts,
    int? bpm,
    double? conf,
    int? synced,
  }) => WhoopPpgHrSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    bpm: bpm ?? this.bpm,
    conf: conf ?? this.conf,
    synced: synced ?? this.synced,
  );
  WhoopPpgHrSample copyWithCompanion(WhoopPpgHrSamplesCompanion data) {
    return WhoopPpgHrSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      conf: data.conf.present ? data.conf.value : this.conf,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopPpgHrSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('bpm: $bpm, ')
          ..write('conf: $conf, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, bpm, conf, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopPpgHrSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.bpm == this.bpm &&
          other.conf == this.conf &&
          other.synced == this.synced);
}

class WhoopPpgHrSamplesCompanion extends UpdateCompanion<WhoopPpgHrSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> bpm;
  final Value<double> conf;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopPpgHrSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.bpm = const Value.absent(),
    this.conf = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopPpgHrSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int bpm,
    required double conf,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       bpm = Value(bpm),
       conf = Value(conf);
  static Insertable<WhoopPpgHrSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? bpm,
    Expression<double>? conf,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (bpm != null) 'bpm': bpm,
      if (conf != null) 'conf': conf,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopPpgHrSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? bpm,
    Value<double>? conf,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopPpgHrSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      bpm: bpm ?? this.bpm,
      conf: conf ?? this.conf,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (conf.present) {
      map['conf'] = Variable<double>(conf.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopPpgHrSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('bpm: $bpm, ')
          ..write('conf: $conf, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopPpgRawSamplesTable extends WhoopPpgRawSamples
    with TableInfo<$WhoopPpgRawSamplesTable, WhoopPpgRawSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopPpgRawSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _samplesMeta = const VerificationMeta(
    'samples',
  );
  @override
  late final GeneratedColumn<Uint8List> samples = GeneratedColumn<Uint8List>(
    'samples',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, sampleCount, samples];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ppgRawSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopPpgRawSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleCountMeta);
    }
    if (data.containsKey('samples')) {
      context.handle(
        _samplesMeta,
        samples.isAcceptableOrUnknown(data['samples']!, _samplesMeta),
      );
    } else if (isInserting) {
      context.missing(_samplesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopPpgRawSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopPpgRawSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      samples: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}samples'],
      )!,
    );
  }

  @override
  $WhoopPpgRawSamplesTable createAlias(String alias) {
    return $WhoopPpgRawSamplesTable(attachedDatabase, alias);
  }
}

class WhoopPpgRawSample extends DataClass
    implements Insertable<WhoopPpgRawSample> {
  final String deviceId;
  final int ts;
  final int sampleCount;
  final Uint8List samples;
  const WhoopPpgRawSample({
    required this.deviceId,
    required this.ts,
    required this.sampleCount,
    required this.samples,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['sample_count'] = Variable<int>(sampleCount);
    map['samples'] = Variable<Uint8List>(samples);
    return map;
  }

  WhoopPpgRawSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopPpgRawSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      sampleCount: Value(sampleCount),
      samples: Value(samples),
    );
  }

  factory WhoopPpgRawSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopPpgRawSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      samples: serializer.fromJson<Uint8List>(json['samples']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'samples': serializer.toJson<Uint8List>(samples),
    };
  }

  WhoopPpgRawSample copyWith({
    String? deviceId,
    int? ts,
    int? sampleCount,
    Uint8List? samples,
  }) => WhoopPpgRawSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    sampleCount: sampleCount ?? this.sampleCount,
    samples: samples ?? this.samples,
  );
  WhoopPpgRawSample copyWithCompanion(WhoopPpgRawSamplesCompanion data) {
    return WhoopPpgRawSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      samples: data.samples.present ? data.samples.value : this.samples,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopPpgRawSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('samples: $samples')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, ts, sampleCount, $driftBlobEquality.hash(samples));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopPpgRawSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.sampleCount == this.sampleCount &&
          $driftBlobEquality.equals(other.samples, this.samples));
}

class WhoopPpgRawSamplesCompanion extends UpdateCompanion<WhoopPpgRawSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> sampleCount;
  final Value<Uint8List> samples;
  final Value<int> rowid;
  const WhoopPpgRawSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.samples = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopPpgRawSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int sampleCount,
    required Uint8List samples,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       sampleCount = Value(sampleCount),
       samples = Value(samples);
  static Insertable<WhoopPpgRawSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? sampleCount,
    Expression<Uint8List>? samples,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (samples != null) 'samples': samples,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopPpgRawSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? sampleCount,
    Value<Uint8List>? samples,
    Value<int>? rowid,
  }) {
    return WhoopPpgRawSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      sampleCount: sampleCount ?? this.sampleCount,
      samples: samples ?? this.samples,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (samples.present) {
      map['samples'] = Variable<Uint8List>(samples.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopPpgRawSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('samples: $samples, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopRrIntervalsTable extends WhoopRrIntervals
    with TableInfo<$WhoopRrIntervalsTable, WhoopRrInterval> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopRrIntervalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rrMsMeta = const VerificationMeta('rrMs');
  @override
  late final GeneratedColumn<int> rrMs = GeneratedColumn<int>(
    'rr_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, rrMs, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rrInterval';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopRrInterval> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('rr_ms')) {
      context.handle(
        _rrMsMeta,
        rrMs.isAcceptableOrUnknown(data['rr_ms']!, _rrMsMeta),
      );
    } else if (isInserting) {
      context.missing(_rrMsMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts, rrMs};
  @override
  WhoopRrInterval map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopRrInterval(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      rrMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rr_ms'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopRrIntervalsTable createAlias(String alias) {
    return $WhoopRrIntervalsTable(attachedDatabase, alias);
  }
}

class WhoopRrInterval extends DataClass implements Insertable<WhoopRrInterval> {
  final String deviceId;
  final int ts;
  final int rrMs;
  final int synced;
  const WhoopRrInterval({
    required this.deviceId,
    required this.ts,
    required this.rrMs,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['rr_ms'] = Variable<int>(rrMs);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopRrIntervalsCompanion toCompanion(bool nullToAbsent) {
    return WhoopRrIntervalsCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      rrMs: Value(rrMs),
      synced: Value(synced),
    );
  }

  factory WhoopRrInterval.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopRrInterval(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      rrMs: serializer.fromJson<int>(json['rrMs']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'rrMs': serializer.toJson<int>(rrMs),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopRrInterval copyWith({
    String? deviceId,
    int? ts,
    int? rrMs,
    int? synced,
  }) => WhoopRrInterval(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    rrMs: rrMs ?? this.rrMs,
    synced: synced ?? this.synced,
  );
  WhoopRrInterval copyWithCompanion(WhoopRrIntervalsCompanion data) {
    return WhoopRrInterval(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      rrMs: data.rrMs.present ? data.rrMs.value : this.rrMs,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopRrInterval(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('rrMs: $rrMs, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, rrMs, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopRrInterval &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.rrMs == this.rrMs &&
          other.synced == this.synced);
}

class WhoopRrIntervalsCompanion extends UpdateCompanion<WhoopRrInterval> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> rrMs;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopRrIntervalsCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.rrMs = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopRrIntervalsCompanion.insert({
    required String deviceId,
    required int ts,
    required int rrMs,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       rrMs = Value(rrMs);
  static Insertable<WhoopRrInterval> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? rrMs,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (rrMs != null) 'rr_ms': rrMs,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopRrIntervalsCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? rrMs,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopRrIntervalsCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      rrMs: rrMs ?? this.rrMs,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (rrMs.present) {
      map['rr_ms'] = Variable<int>(rrMs.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopRrIntervalsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('rrMs: $rrMs, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopEventsTable extends WhoopEvents
    with TableInfo<$WhoopEventsTable, WhoopEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    ts,
    kind,
    payloadJson,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts, kind};
  @override
  WhoopEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopEvent(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopEventsTable createAlias(String alias) {
    return $WhoopEventsTable(attachedDatabase, alias);
  }
}

class WhoopEvent extends DataClass implements Insertable<WhoopEvent> {
  final String deviceId;
  final int ts;
  final String kind;
  final String payloadJson;
  final int synced;
  const WhoopEvent({
    required this.deviceId,
    required this.ts,
    required this.kind,
    required this.payloadJson,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopEventsCompanion toCompanion(bool nullToAbsent) {
    return WhoopEventsCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      synced: Value(synced),
    );
  }

  factory WhoopEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopEvent(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopEvent copyWith({
    String? deviceId,
    int? ts,
    String? kind,
    String? payloadJson,
    int? synced,
  }) => WhoopEvent(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
    synced: synced ?? this.synced,
  );
  WhoopEvent copyWithCompanion(WhoopEventsCompanion data) {
    return WhoopEvent(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopEvent(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, kind, payloadJson, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopEvent &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.synced == this.synced);
}

class WhoopEventsCompanion extends UpdateCompanion<WhoopEvent> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopEventsCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopEventsCompanion.insert({
    required String deviceId,
    required int ts,
    required String kind,
    required String payloadJson,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       kind = Value(kind),
       payloadJson = Value(payloadJson);
  static Insertable<WhoopEvent> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopEventsCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<String>? kind,
    Value<String>? payloadJson,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopEventsCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopEventsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopBatteryTable extends WhoopBattery
    with TableInfo<$WhoopBatteryTable, WhoopBatteryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopBatteryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _socMeta = const VerificationMeta('soc');
  @override
  late final GeneratedColumn<double> soc = GeneratedColumn<double>(
    'soc',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mvMeta = const VerificationMeta('mv');
  @override
  late final GeneratedColumn<int> mv = GeneratedColumn<int>(
    'mv',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chargingMeta = const VerificationMeta(
    'charging',
  );
  @override
  late final GeneratedColumn<bool> charging = GeneratedColumn<bool>(
    'charging',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("charging" IN (0, 1))',
    ),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    ts,
    soc,
    mv,
    charging,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'battery';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopBatteryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('soc')) {
      context.handle(
        _socMeta,
        soc.isAcceptableOrUnknown(data['soc']!, _socMeta),
      );
    }
    if (data.containsKey('mv')) {
      context.handle(_mvMeta, mv.isAcceptableOrUnknown(data['mv']!, _mvMeta));
    }
    if (data.containsKey('charging')) {
      context.handle(
        _chargingMeta,
        charging.isAcceptableOrUnknown(data['charging']!, _chargingMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopBatteryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopBatteryData(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      soc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}soc'],
      ),
      mv: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mv'],
      ),
      charging: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}charging'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopBatteryTable createAlias(String alias) {
    return $WhoopBatteryTable(attachedDatabase, alias);
  }
}

class WhoopBatteryData extends DataClass
    implements Insertable<WhoopBatteryData> {
  final String deviceId;
  final int ts;
  final double? soc;
  final int? mv;
  final bool? charging;
  final int synced;
  const WhoopBatteryData({
    required this.deviceId,
    required this.ts,
    this.soc,
    this.mv,
    this.charging,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    if (!nullToAbsent || soc != null) {
      map['soc'] = Variable<double>(soc);
    }
    if (!nullToAbsent || mv != null) {
      map['mv'] = Variable<int>(mv);
    }
    if (!nullToAbsent || charging != null) {
      map['charging'] = Variable<bool>(charging);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopBatteryCompanion toCompanion(bool nullToAbsent) {
    return WhoopBatteryCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      soc: soc == null && nullToAbsent ? const Value.absent() : Value(soc),
      mv: mv == null && nullToAbsent ? const Value.absent() : Value(mv),
      charging: charging == null && nullToAbsent
          ? const Value.absent()
          : Value(charging),
      synced: Value(synced),
    );
  }

  factory WhoopBatteryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopBatteryData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      soc: serializer.fromJson<double?>(json['soc']),
      mv: serializer.fromJson<int?>(json['mv']),
      charging: serializer.fromJson<bool?>(json['charging']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'soc': serializer.toJson<double?>(soc),
      'mv': serializer.toJson<int?>(mv),
      'charging': serializer.toJson<bool?>(charging),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopBatteryData copyWith({
    String? deviceId,
    int? ts,
    Value<double?> soc = const Value.absent(),
    Value<int?> mv = const Value.absent(),
    Value<bool?> charging = const Value.absent(),
    int? synced,
  }) => WhoopBatteryData(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    soc: soc.present ? soc.value : this.soc,
    mv: mv.present ? mv.value : this.mv,
    charging: charging.present ? charging.value : this.charging,
    synced: synced ?? this.synced,
  );
  WhoopBatteryData copyWithCompanion(WhoopBatteryCompanion data) {
    return WhoopBatteryData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      soc: data.soc.present ? data.soc.value : this.soc,
      mv: data.mv.present ? data.mv.value : this.mv,
      charging: data.charging.present ? data.charging.value : this.charging,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopBatteryData(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('soc: $soc, ')
          ..write('mv: $mv, ')
          ..write('charging: $charging, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, soc, mv, charging, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopBatteryData &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.soc == this.soc &&
          other.mv == this.mv &&
          other.charging == this.charging &&
          other.synced == this.synced);
}

class WhoopBatteryCompanion extends UpdateCompanion<WhoopBatteryData> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<double?> soc;
  final Value<int?> mv;
  final Value<bool?> charging;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopBatteryCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.soc = const Value.absent(),
    this.mv = const Value.absent(),
    this.charging = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopBatteryCompanion.insert({
    required String deviceId,
    required int ts,
    this.soc = const Value.absent(),
    this.mv = const Value.absent(),
    this.charging = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts);
  static Insertable<WhoopBatteryData> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<double>? soc,
    Expression<int>? mv,
    Expression<bool>? charging,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (soc != null) 'soc': soc,
      if (mv != null) 'mv': mv,
      if (charging != null) 'charging': charging,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopBatteryCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<double?>? soc,
    Value<int?>? mv,
    Value<bool?>? charging,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopBatteryCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      soc: soc ?? this.soc,
      mv: mv ?? this.mv,
      charging: charging ?? this.charging,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (soc.present) {
      map['soc'] = Variable<double>(soc.value);
    }
    if (mv.present) {
      map['mv'] = Variable<int>(mv.value);
    }
    if (charging.present) {
      map['charging'] = Variable<bool>(charging.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopBatteryCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('soc: $soc, ')
          ..write('mv: $mv, ')
          ..write('charging: $charging, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopSpo2SamplesTable extends WhoopSpo2Samples
    with TableInfo<$WhoopSpo2SamplesTable, WhoopSpo2Sample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopSpo2SamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _redMeta = const VerificationMeta('red');
  @override
  late final GeneratedColumn<int> red = GeneratedColumn<int>(
    'red',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _irMeta = const VerificationMeta('ir');
  @override
  late final GeneratedColumn<int> ir = GeneratedColumn<int>(
    'ir',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, red, ir, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spo2Sample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopSpo2Sample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('red')) {
      context.handle(
        _redMeta,
        red.isAcceptableOrUnknown(data['red']!, _redMeta),
      );
    } else if (isInserting) {
      context.missing(_redMeta);
    }
    if (data.containsKey('ir')) {
      context.handle(_irMeta, ir.isAcceptableOrUnknown(data['ir']!, _irMeta));
    } else if (isInserting) {
      context.missing(_irMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopSpo2Sample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopSpo2Sample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      red: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}red'],
      )!,
      ir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ir'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopSpo2SamplesTable createAlias(String alias) {
    return $WhoopSpo2SamplesTable(attachedDatabase, alias);
  }
}

class WhoopSpo2Sample extends DataClass implements Insertable<WhoopSpo2Sample> {
  final String deviceId;
  final int ts;
  final int red;
  final int ir;
  final int synced;
  const WhoopSpo2Sample({
    required this.deviceId,
    required this.ts,
    required this.red,
    required this.ir,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['red'] = Variable<int>(red);
    map['ir'] = Variable<int>(ir);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopSpo2SamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopSpo2SamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      red: Value(red),
      ir: Value(ir),
      synced: Value(synced),
    );
  }

  factory WhoopSpo2Sample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopSpo2Sample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      red: serializer.fromJson<int>(json['red']),
      ir: serializer.fromJson<int>(json['ir']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'red': serializer.toJson<int>(red),
      'ir': serializer.toJson<int>(ir),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopSpo2Sample copyWith({
    String? deviceId,
    int? ts,
    int? red,
    int? ir,
    int? synced,
  }) => WhoopSpo2Sample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    red: red ?? this.red,
    ir: ir ?? this.ir,
    synced: synced ?? this.synced,
  );
  WhoopSpo2Sample copyWithCompanion(WhoopSpo2SamplesCompanion data) {
    return WhoopSpo2Sample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      red: data.red.present ? data.red.value : this.red,
      ir: data.ir.present ? data.ir.value : this.ir,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopSpo2Sample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('red: $red, ')
          ..write('ir: $ir, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, red, ir, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopSpo2Sample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.red == this.red &&
          other.ir == this.ir &&
          other.synced == this.synced);
}

class WhoopSpo2SamplesCompanion extends UpdateCompanion<WhoopSpo2Sample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> red;
  final Value<int> ir;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopSpo2SamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.red = const Value.absent(),
    this.ir = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopSpo2SamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int red,
    required int ir,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       red = Value(red),
       ir = Value(ir);
  static Insertable<WhoopSpo2Sample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? red,
    Expression<int>? ir,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (red != null) 'red': red,
      if (ir != null) 'ir': ir,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopSpo2SamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? red,
    Value<int>? ir,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopSpo2SamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      red: red ?? this.red,
      ir: ir ?? this.ir,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (red.present) {
      map['red'] = Variable<int>(red.value);
    }
    if (ir.present) {
      map['ir'] = Variable<int>(ir.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopSpo2SamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('red: $red, ')
          ..write('ir: $ir, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopSkinTempSamplesTable extends WhoopSkinTempSamples
    with TableInfo<$WhoopSkinTempSamplesTable, WhoopSkinTempSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopSkinTempSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<int> raw = GeneratedColumn<int>(
    'raw',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, raw, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skinTempSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopSkinTempSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopSkinTempSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopSkinTempSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopSkinTempSamplesTable createAlias(String alias) {
    return $WhoopSkinTempSamplesTable(attachedDatabase, alias);
  }
}

class WhoopSkinTempSample extends DataClass
    implements Insertable<WhoopSkinTempSample> {
  final String deviceId;
  final int ts;
  final int raw;
  final int synced;
  const WhoopSkinTempSample({
    required this.deviceId,
    required this.ts,
    required this.raw,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['raw'] = Variable<int>(raw);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopSkinTempSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopSkinTempSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      raw: Value(raw),
      synced: Value(synced),
    );
  }

  factory WhoopSkinTempSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopSkinTempSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      raw: serializer.fromJson<int>(json['raw']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'raw': serializer.toJson<int>(raw),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopSkinTempSample copyWith({
    String? deviceId,
    int? ts,
    int? raw,
    int? synced,
  }) => WhoopSkinTempSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    raw: raw ?? this.raw,
    synced: synced ?? this.synced,
  );
  WhoopSkinTempSample copyWithCompanion(WhoopSkinTempSamplesCompanion data) {
    return WhoopSkinTempSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      raw: data.raw.present ? data.raw.value : this.raw,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopSkinTempSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('raw: $raw, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, raw, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopSkinTempSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.raw == this.raw &&
          other.synced == this.synced);
}

class WhoopSkinTempSamplesCompanion
    extends UpdateCompanion<WhoopSkinTempSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> raw;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopSkinTempSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.raw = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopSkinTempSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int raw,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       raw = Value(raw);
  static Insertable<WhoopSkinTempSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? raw,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (raw != null) 'raw': raw,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopSkinTempSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? raw,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopSkinTempSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      raw: raw ?? this.raw,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (raw.present) {
      map['raw'] = Variable<int>(raw.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopSkinTempSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('raw: $raw, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopStepSamplesTable extends WhoopStepSamples
    with TableInfo<$WhoopStepSamplesTable, WhoopStepSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopStepSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterMeta = const VerificationMeta(
    'counter',
  );
  @override
  late final GeneratedColumn<int> counter = GeneratedColumn<int>(
    'counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityClassMeta = const VerificationMeta(
    'activityClass',
  );
  @override
  late final GeneratedColumn<int> activityClass = GeneratedColumn<int>(
    'activity_class',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    ts,
    counter,
    activityClass,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stepSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopStepSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('counter')) {
      context.handle(
        _counterMeta,
        counter.isAcceptableOrUnknown(data['counter']!, _counterMeta),
      );
    } else if (isInserting) {
      context.missing(_counterMeta);
    }
    if (data.containsKey('activity_class')) {
      context.handle(
        _activityClassMeta,
        activityClass.isAcceptableOrUnknown(
          data['activity_class']!,
          _activityClassMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopStepSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopStepSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      counter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counter'],
      )!,
      activityClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_class'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopStepSamplesTable createAlias(String alias) {
    return $WhoopStepSamplesTable(attachedDatabase, alias);
  }
}

class WhoopStepSample extends DataClass implements Insertable<WhoopStepSample> {
  final String deviceId;
  final int ts;
  final int counter;
  final int? activityClass;
  final int synced;
  const WhoopStepSample({
    required this.deviceId,
    required this.ts,
    required this.counter,
    this.activityClass,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['counter'] = Variable<int>(counter);
    if (!nullToAbsent || activityClass != null) {
      map['activity_class'] = Variable<int>(activityClass);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopStepSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopStepSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      counter: Value(counter),
      activityClass: activityClass == null && nullToAbsent
          ? const Value.absent()
          : Value(activityClass),
      synced: Value(synced),
    );
  }

  factory WhoopStepSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopStepSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      counter: serializer.fromJson<int>(json['counter']),
      activityClass: serializer.fromJson<int?>(json['activityClass']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'counter': serializer.toJson<int>(counter),
      'activityClass': serializer.toJson<int?>(activityClass),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopStepSample copyWith({
    String? deviceId,
    int? ts,
    int? counter,
    Value<int?> activityClass = const Value.absent(),
    int? synced,
  }) => WhoopStepSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    counter: counter ?? this.counter,
    activityClass: activityClass.present
        ? activityClass.value
        : this.activityClass,
    synced: synced ?? this.synced,
  );
  WhoopStepSample copyWithCompanion(WhoopStepSamplesCompanion data) {
    return WhoopStepSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      counter: data.counter.present ? data.counter.value : this.counter,
      activityClass: data.activityClass.present
          ? data.activityClass.value
          : this.activityClass,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopStepSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('counter: $counter, ')
          ..write('activityClass: $activityClass, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, counter, activityClass, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopStepSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.counter == this.counter &&
          other.activityClass == this.activityClass &&
          other.synced == this.synced);
}

class WhoopStepSamplesCompanion extends UpdateCompanion<WhoopStepSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> counter;
  final Value<int?> activityClass;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopStepSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.counter = const Value.absent(),
    this.activityClass = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopStepSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int counter,
    this.activityClass = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       counter = Value(counter);
  static Insertable<WhoopStepSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? counter,
    Expression<int>? activityClass,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (counter != null) 'counter': counter,
      if (activityClass != null) 'activity_class': activityClass,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopStepSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? counter,
    Value<int?>? activityClass,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopStepSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      counter: counter ?? this.counter,
      activityClass: activityClass ?? this.activityClass,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (counter.present) {
      map['counter'] = Variable<int>(counter.value);
    }
    if (activityClass.present) {
      map['activity_class'] = Variable<int>(activityClass.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopStepSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('counter: $counter, ')
          ..write('activityClass: $activityClass, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopSleepStateSamplesTable extends WhoopSleepStateSamples
    with TableInfo<$WhoopSleepStateSamplesTable, WhoopSleepStateSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopSleepStateSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleepStateSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopSleepStateSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopSleepStateSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopSleepStateSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $WhoopSleepStateSamplesTable createAlias(String alias) {
    return $WhoopSleepStateSamplesTable(attachedDatabase, alias);
  }
}

class WhoopSleepStateSample extends DataClass
    implements Insertable<WhoopSleepStateSample> {
  final String deviceId;
  final int ts;
  final int state;
  const WhoopSleepStateSample({
    required this.deviceId,
    required this.ts,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['state'] = Variable<int>(state);
    return map;
  }

  WhoopSleepStateSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopSleepStateSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      state: Value(state),
    );
  }

  factory WhoopSleepStateSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopSleepStateSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      state: serializer.fromJson<int>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'state': serializer.toJson<int>(state),
    };
  }

  WhoopSleepStateSample copyWith({String? deviceId, int? ts, int? state}) =>
      WhoopSleepStateSample(
        deviceId: deviceId ?? this.deviceId,
        ts: ts ?? this.ts,
        state: state ?? this.state,
      );
  WhoopSleepStateSample copyWithCompanion(
    WhoopSleepStateSamplesCompanion data,
  ) {
    return WhoopSleepStateSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopSleepStateSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopSleepStateSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.state == this.state);
}

class WhoopSleepStateSamplesCompanion
    extends UpdateCompanion<WhoopSleepStateSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> state;
  final Value<int> rowid;
  const WhoopSleepStateSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopSleepStateSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int state,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       state = Value(state);
  static Insertable<WhoopSleepStateSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopSleepStateSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? state,
    Value<int>? rowid,
  }) {
    return WhoopSleepStateSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopSleepStateSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopRespSamplesTable extends WhoopRespSamples
    with TableInfo<$WhoopRespSamplesTable, WhoopRespSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopRespSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<int> raw = GeneratedColumn<int>(
    'raw',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, ts, raw, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'respSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopRespSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopRespSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopRespSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopRespSamplesTable createAlias(String alias) {
    return $WhoopRespSamplesTable(attachedDatabase, alias);
  }
}

class WhoopRespSample extends DataClass implements Insertable<WhoopRespSample> {
  final String deviceId;
  final int ts;
  final int raw;
  final int synced;
  const WhoopRespSample({
    required this.deviceId,
    required this.ts,
    required this.raw,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['raw'] = Variable<int>(raw);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopRespSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopRespSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      raw: Value(raw),
      synced: Value(synced),
    );
  }

  factory WhoopRespSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopRespSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      raw: serializer.fromJson<int>(json['raw']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'raw': serializer.toJson<int>(raw),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopRespSample copyWith({
    String? deviceId,
    int? ts,
    int? raw,
    int? synced,
  }) => WhoopRespSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    raw: raw ?? this.raw,
    synced: synced ?? this.synced,
  );
  WhoopRespSample copyWithCompanion(WhoopRespSamplesCompanion data) {
    return WhoopRespSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      raw: data.raw.present ? data.raw.value : this.raw,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopRespSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('raw: $raw, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, raw, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopRespSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.raw == this.raw &&
          other.synced == this.synced);
}

class WhoopRespSamplesCompanion extends UpdateCompanion<WhoopRespSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<int> raw;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopRespSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.raw = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopRespSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required int raw,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       raw = Value(raw);
  static Insertable<WhoopRespSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<int>? raw,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (raw != null) 'raw': raw,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopRespSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<int>? raw,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopRespSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      raw: raw ?? this.raw,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (raw.present) {
      map['raw'] = Variable<int>(raw.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopRespSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('raw: $raw, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopGravitySamplesTable extends WhoopGravitySamples
    with TableInfo<$WhoopGravitySamplesTable, WhoopGravitySample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopGravitySamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zMeta = const VerificationMeta('z');
  @override
  late final GeneratedColumn<double> z = GeneratedColumn<double>(
    'z',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dynamicAccelMeta = const VerificationMeta(
    'dynamicAccel',
  );
  @override
  late final GeneratedColumn<double> dynamicAccel = GeneratedColumn<double>(
    'dynamic_accel',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    ts,
    x,
    y,
    z,
    dynamicAccel,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gravitySample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopGravitySample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('z')) {
      context.handle(_zMeta, z.isAcceptableOrUnknown(data['z']!, _zMeta));
    } else if (isInserting) {
      context.missing(_zMeta);
    }
    if (data.containsKey('dynamic_accel')) {
      context.handle(
        _dynamicAccelMeta,
        dynamicAccel.isAcceptableOrUnknown(
          data['dynamic_accel']!,
          _dynamicAccelMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts};
  @override
  WhoopGravitySample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopGravitySample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      z: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}z'],
      )!,
      dynamicAccel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dynamic_accel'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $WhoopGravitySamplesTable createAlias(String alias) {
    return $WhoopGravitySamplesTable(attachedDatabase, alias);
  }
}

class WhoopGravitySample extends DataClass
    implements Insertable<WhoopGravitySample> {
  final String deviceId;
  final int ts;
  final double x;
  final double y;
  final double z;
  final double? dynamicAccel;
  final int synced;
  const WhoopGravitySample({
    required this.deviceId,
    required this.ts,
    required this.x,
    required this.y,
    required this.z,
    this.dynamicAccel,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['z'] = Variable<double>(z);
    if (!nullToAbsent || dynamicAccel != null) {
      map['dynamic_accel'] = Variable<double>(dynamicAccel);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  WhoopGravitySamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopGravitySamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      x: Value(x),
      y: Value(y),
      z: Value(z),
      dynamicAccel: dynamicAccel == null && nullToAbsent
          ? const Value.absent()
          : Value(dynamicAccel),
      synced: Value(synced),
    );
  }

  factory WhoopGravitySample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopGravitySample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      z: serializer.fromJson<double>(json['z']),
      dynamicAccel: serializer.fromJson<double?>(json['dynamicAccel']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'z': serializer.toJson<double>(z),
      'dynamicAccel': serializer.toJson<double?>(dynamicAccel),
      'synced': serializer.toJson<int>(synced),
    };
  }

  WhoopGravitySample copyWith({
    String? deviceId,
    int? ts,
    double? x,
    double? y,
    double? z,
    Value<double?> dynamicAccel = const Value.absent(),
    int? synced,
  }) => WhoopGravitySample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    x: x ?? this.x,
    y: y ?? this.y,
    z: z ?? this.z,
    dynamicAccel: dynamicAccel.present ? dynamicAccel.value : this.dynamicAccel,
    synced: synced ?? this.synced,
  );
  WhoopGravitySample copyWithCompanion(WhoopGravitySamplesCompanion data) {
    return WhoopGravitySample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      z: data.z.present ? data.z.value : this.z,
      dynamicAccel: data.dynamicAccel.present
          ? data.dynamicAccel.value
          : this.dynamicAccel,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopGravitySample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('z: $z, ')
          ..write('dynamicAccel: $dynamicAccel, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, x, y, z, dynamicAccel, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopGravitySample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.x == this.x &&
          other.y == this.y &&
          other.z == this.z &&
          other.dynamicAccel == this.dynamicAccel &&
          other.synced == this.synced);
}

class WhoopGravitySamplesCompanion extends UpdateCompanion<WhoopGravitySample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<double> x;
  final Value<double> y;
  final Value<double> z;
  final Value<double?> dynamicAccel;
  final Value<int> synced;
  final Value<int> rowid;
  const WhoopGravitySamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.z = const Value.absent(),
    this.dynamicAccel = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopGravitySamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required double x,
    required double y,
    required double z,
    this.dynamicAccel = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       x = Value(x),
       y = Value(y),
       z = Value(z);
  static Insertable<WhoopGravitySample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? z,
    Expression<double>? dynamicAccel,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (z != null) 'z': z,
      if (dynamicAccel != null) 'dynamic_accel': dynamicAccel,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopGravitySamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<double>? x,
    Value<double>? y,
    Value<double>? z,
    Value<double?>? dynamicAccel,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return WhoopGravitySamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      dynamicAccel: dynamicAccel ?? this.dynamicAccel,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (z.present) {
      map['z'] = Variable<double>(z.value);
    }
    if (dynamicAccel.present) {
      map['dynamic_accel'] = Variable<double>(dynamicAccel.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopGravitySamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('z: $z, ')
          ..write('dynamicAccel: $dynamicAccel, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhoopRawFieldSamplesTable extends WhoopRawFieldSamples
    with TableInfo<$WhoopRawFieldSamplesTable, WhoopRawFieldSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhoopRawFieldSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intValueMeta = const VerificationMeta(
    'intValue',
  );
  @override
  late final GeneratedColumn<int> intValue = GeneratedColumn<int>(
    'int_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _realValueMeta = const VerificationMeta(
    'realValue',
  );
  @override
  late final GeneratedColumn<double> realValue = GeneratedColumn<double>(
    'real_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    ts,
    key,
    intValue,
    realValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rawFieldSample';
  @override
  VerificationContext validateIntegrity(
    Insertable<WhoopRawFieldSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('int_value')) {
      context.handle(
        _intValueMeta,
        intValue.isAcceptableOrUnknown(data['int_value']!, _intValueMeta),
      );
    }
    if (data.containsKey('real_value')) {
      context.handle(
        _realValueMeta,
        realValue.isAcceptableOrUnknown(data['real_value']!, _realValueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, ts, key};
  @override
  WhoopRawFieldSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhoopRawFieldSample(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      intValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}int_value'],
      ),
      realValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}real_value'],
      ),
    );
  }

  @override
  $WhoopRawFieldSamplesTable createAlias(String alias) {
    return $WhoopRawFieldSamplesTable(attachedDatabase, alias);
  }
}

class WhoopRawFieldSample extends DataClass
    implements Insertable<WhoopRawFieldSample> {
  final String deviceId;
  final int ts;
  final String key;
  final int? intValue;
  final double? realValue;
  const WhoopRawFieldSample({
    required this.deviceId,
    required this.ts,
    required this.key,
    this.intValue,
    this.realValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['ts'] = Variable<int>(ts);
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || intValue != null) {
      map['int_value'] = Variable<int>(intValue);
    }
    if (!nullToAbsent || realValue != null) {
      map['real_value'] = Variable<double>(realValue);
    }
    return map;
  }

  WhoopRawFieldSamplesCompanion toCompanion(bool nullToAbsent) {
    return WhoopRawFieldSamplesCompanion(
      deviceId: Value(deviceId),
      ts: Value(ts),
      key: Value(key),
      intValue: intValue == null && nullToAbsent
          ? const Value.absent()
          : Value(intValue),
      realValue: realValue == null && nullToAbsent
          ? const Value.absent()
          : Value(realValue),
    );
  }

  factory WhoopRawFieldSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhoopRawFieldSample(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      ts: serializer.fromJson<int>(json['ts']),
      key: serializer.fromJson<String>(json['key']),
      intValue: serializer.fromJson<int?>(json['intValue']),
      realValue: serializer.fromJson<double?>(json['realValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'ts': serializer.toJson<int>(ts),
      'key': serializer.toJson<String>(key),
      'intValue': serializer.toJson<int?>(intValue),
      'realValue': serializer.toJson<double?>(realValue),
    };
  }

  WhoopRawFieldSample copyWith({
    String? deviceId,
    int? ts,
    String? key,
    Value<int?> intValue = const Value.absent(),
    Value<double?> realValue = const Value.absent(),
  }) => WhoopRawFieldSample(
    deviceId: deviceId ?? this.deviceId,
    ts: ts ?? this.ts,
    key: key ?? this.key,
    intValue: intValue.present ? intValue.value : this.intValue,
    realValue: realValue.present ? realValue.value : this.realValue,
  );
  WhoopRawFieldSample copyWithCompanion(WhoopRawFieldSamplesCompanion data) {
    return WhoopRawFieldSample(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ts: data.ts.present ? data.ts.value : this.ts,
      key: data.key.present ? data.key.value : this.key,
      intValue: data.intValue.present ? data.intValue.value : this.intValue,
      realValue: data.realValue.present ? data.realValue.value : this.realValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WhoopRawFieldSample(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('key: $key, ')
          ..write('intValue: $intValue, ')
          ..write('realValue: $realValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, ts, key, intValue, realValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhoopRawFieldSample &&
          other.deviceId == this.deviceId &&
          other.ts == this.ts &&
          other.key == this.key &&
          other.intValue == this.intValue &&
          other.realValue == this.realValue);
}

class WhoopRawFieldSamplesCompanion
    extends UpdateCompanion<WhoopRawFieldSample> {
  final Value<String> deviceId;
  final Value<int> ts;
  final Value<String> key;
  final Value<int?> intValue;
  final Value<double?> realValue;
  final Value<int> rowid;
  const WhoopRawFieldSamplesCompanion({
    this.deviceId = const Value.absent(),
    this.ts = const Value.absent(),
    this.key = const Value.absent(),
    this.intValue = const Value.absent(),
    this.realValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhoopRawFieldSamplesCompanion.insert({
    required String deviceId,
    required int ts,
    required String key,
    this.intValue = const Value.absent(),
    this.realValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       ts = Value(ts),
       key = Value(key);
  static Insertable<WhoopRawFieldSample> custom({
    Expression<String>? deviceId,
    Expression<int>? ts,
    Expression<String>? key,
    Expression<int>? intValue,
    Expression<double>? realValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (ts != null) 'ts': ts,
      if (key != null) 'key': key,
      if (intValue != null) 'int_value': intValue,
      if (realValue != null) 'real_value': realValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhoopRawFieldSamplesCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? ts,
    Value<String>? key,
    Value<int?>? intValue,
    Value<double?>? realValue,
    Value<int>? rowid,
  }) {
    return WhoopRawFieldSamplesCompanion(
      deviceId: deviceId ?? this.deviceId,
      ts: ts ?? this.ts,
      key: key ?? this.key,
      intValue: intValue ?? this.intValue,
      realValue: realValue ?? this.realValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (intValue.present) {
      map['int_value'] = Variable<int>(intValue.value);
    }
    if (realValue.present) {
      map['real_value'] = Variable<double>(realValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhoopRawFieldSamplesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('ts: $ts, ')
          ..write('key: $key, ')
          ..write('intValue: $intValue, ')
          ..write('realValue: $realValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syncCursor';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String name;
  final int value;
  const SyncCursor({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<int>(value);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(name: Value(name), value: Value(value));
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<int>(value),
    };
  }

  SyncCursor copyWith({String? name, int? value}) =>
      SyncCursor(name: name ?? this.name, value: value ?? this.value);
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.name == this.name &&
          other.value == this.value);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> name;
  final Value<int> value;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String name,
    required int value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<SyncCursor> custom({
    Expression<String>? name,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? name,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyMetricsTable dailyMetrics = $DailyMetricsTable(this);
  late final $CyclesTable cycles = $CyclesTable(this);
  late final $SleepSessionsTable sleepSessions = $SleepSessionsTable(this);
  late final $SleepStateSamplesTable sleepStateSamples =
      $SleepStateSamplesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $HrSamplesTable hrSamples = $HrSamplesTable(this);
  late final $RrSamplesTable rrSamples = $RrSamplesTable(this);
  late final $AccelSamplesTable accelSamples = $AccelSamplesTable(this);
  late final $RawSensorArchiveTable rawSensorArchive = $RawSensorArchiveTable(
    this,
  );
  late final $BatteryLogTable batteryLog = $BatteryLogTable(this);
  late final $DeviceInfoTable deviceInfo = $DeviceInfoTable(this);
  late final $StressSamplesTable stressSamples = $StressSamplesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(
    this,
  );
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $JournalQuestionsTable journalQuestions = $JournalQuestionsTable(
    this,
  );
  late final $WeightLogTable weightLog = $WeightLogTable(this);
  late final $WaterLogTable waterLog = $WaterLogTable(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  late final $MetricSamplesTable metricSamples = $MetricSamplesTable(this);
  late final $FoodItemsTable foodItems = $FoodItemsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $WhoopHrSamplesTable whoopHrSamples = $WhoopHrSamplesTable(this);
  late final $WhoopPpgHrSamplesTable whoopPpgHrSamples =
      $WhoopPpgHrSamplesTable(this);
  late final $WhoopPpgRawSamplesTable whoopPpgRawSamples =
      $WhoopPpgRawSamplesTable(this);
  late final $WhoopRrIntervalsTable whoopRrIntervals = $WhoopRrIntervalsTable(
    this,
  );
  late final $WhoopEventsTable whoopEvents = $WhoopEventsTable(this);
  late final $WhoopBatteryTable whoopBattery = $WhoopBatteryTable(this);
  late final $WhoopSpo2SamplesTable whoopSpo2Samples = $WhoopSpo2SamplesTable(
    this,
  );
  late final $WhoopSkinTempSamplesTable whoopSkinTempSamples =
      $WhoopSkinTempSamplesTable(this);
  late final $WhoopStepSamplesTable whoopStepSamples = $WhoopStepSamplesTable(
    this,
  );
  late final $WhoopSleepStateSamplesTable whoopSleepStateSamples =
      $WhoopSleepStateSamplesTable(this);
  late final $WhoopRespSamplesTable whoopRespSamples = $WhoopRespSamplesTable(
    this,
  );
  late final $WhoopGravitySamplesTable whoopGravitySamples =
      $WhoopGravitySamplesTable(this);
  late final $WhoopRawFieldSamplesTable whoopRawFieldSamples =
      $WhoopRawFieldSamplesTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyMetrics,
    cycles,
    sleepSessions,
    sleepStateSamples,
    workouts,
    hrSamples,
    rrSamples,
    accelSamples,
    rawSensorArchive,
    batteryLog,
    deviceInfo,
    stressSamples,
    events,
    bodyMeasurements,
    journalEntries,
    journalQuestions,
    weightLog,
    waterLog,
    alarms,
    metricSamples,
    foodItems,
    meals,
    foodEntries,
    whoopHrSamples,
    whoopPpgHrSamples,
    whoopPpgRawSamples,
    whoopRrIntervals,
    whoopEvents,
    whoopBattery,
    whoopSpo2Samples,
    whoopSkinTempSamples,
    whoopStepSamples,
    whoopSleepStateSamples,
    whoopRespSamples,
    whoopGravitySamples,
    whoopRawFieldSamples,
    syncCursors,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('food_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DailyMetricsTableCreateCompanionBuilder =
    DailyMetricsCompanion Function({
      required String day,
      Value<String?> cycleId,
      Value<double> charge,
      Value<double> effort,
      Value<double?> dayStrain,
      Value<double> rest,
      Value<double> stress,
      Value<double> hrv,
      Value<double> rhr,
      Value<double> respiratoryRate,
      Value<double> skinTempDelta,
      Value<double> spo2,
      Value<int> steps,
      Value<int> calories,
      Value<double?> kilojoules,
      Value<int?> hrZone13Sec,
      Value<int?> hrZone45Sec,
      Value<int?> strengthActivitySec,
      Value<double?> hrvBaseline,
      Value<double?> rhrBaseline,
      Value<double?> respRateBaseline,
      Value<int?> stepsBaseline,
      Value<int> fitnessAge,
      Value<int> vitality,
      Value<double> hydration,
      Value<int> rowid,
    });
typedef $$DailyMetricsTableUpdateCompanionBuilder =
    DailyMetricsCompanion Function({
      Value<String> day,
      Value<String?> cycleId,
      Value<double> charge,
      Value<double> effort,
      Value<double?> dayStrain,
      Value<double> rest,
      Value<double> stress,
      Value<double> hrv,
      Value<double> rhr,
      Value<double> respiratoryRate,
      Value<double> skinTempDelta,
      Value<double> spo2,
      Value<int> steps,
      Value<int> calories,
      Value<double?> kilojoules,
      Value<int?> hrZone13Sec,
      Value<int?> hrZone45Sec,
      Value<int?> strengthActivitySec,
      Value<double?> hrvBaseline,
      Value<double?> rhrBaseline,
      Value<double?> respRateBaseline,
      Value<int?> stepsBaseline,
      Value<int> fitnessAge,
      Value<int> vitality,
      Value<double> hydration,
      Value<int> rowid,
    });

class $$DailyMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyMetricsTable> {
  $$DailyMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get charge => $composableBuilder(
    column: $table.charge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dayStrain => $composableBuilder(
    column: $table.dayStrain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rest => $composableBuilder(
    column: $table.rest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stress => $composableBuilder(
    column: $table.stress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hrv => $composableBuilder(
    column: $table.hrv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rhr => $composableBuilder(
    column: $table.rhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get respiratoryRate => $composableBuilder(
    column: $table.respiratoryRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get skinTempDelta => $composableBuilder(
    column: $table.skinTempDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get spo2 => $composableBuilder(
    column: $table.spo2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kilojoules => $composableBuilder(
    column: $table.kilojoules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrZone13Sec => $composableBuilder(
    column: $table.hrZone13Sec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrZone45Sec => $composableBuilder(
    column: $table.hrZone45Sec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strengthActivitySec => $composableBuilder(
    column: $table.strengthActivitySec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hrvBaseline => $composableBuilder(
    column: $table.hrvBaseline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rhrBaseline => $composableBuilder(
    column: $table.rhrBaseline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get respRateBaseline => $composableBuilder(
    column: $table.respRateBaseline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepsBaseline => $composableBuilder(
    column: $table.stepsBaseline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fitnessAge => $composableBuilder(
    column: $table.fitnessAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vitality => $composableBuilder(
    column: $table.vitality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hydration => $composableBuilder(
    column: $table.hydration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyMetricsTable> {
  $$DailyMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get charge => $composableBuilder(
    column: $table.charge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dayStrain => $composableBuilder(
    column: $table.dayStrain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rest => $composableBuilder(
    column: $table.rest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stress => $composableBuilder(
    column: $table.stress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hrv => $composableBuilder(
    column: $table.hrv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rhr => $composableBuilder(
    column: $table.rhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get respiratoryRate => $composableBuilder(
    column: $table.respiratoryRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get skinTempDelta => $composableBuilder(
    column: $table.skinTempDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get spo2 => $composableBuilder(
    column: $table.spo2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kilojoules => $composableBuilder(
    column: $table.kilojoules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrZone13Sec => $composableBuilder(
    column: $table.hrZone13Sec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrZone45Sec => $composableBuilder(
    column: $table.hrZone45Sec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strengthActivitySec => $composableBuilder(
    column: $table.strengthActivitySec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hrvBaseline => $composableBuilder(
    column: $table.hrvBaseline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rhrBaseline => $composableBuilder(
    column: $table.rhrBaseline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get respRateBaseline => $composableBuilder(
    column: $table.respRateBaseline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepsBaseline => $composableBuilder(
    column: $table.stepsBaseline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fitnessAge => $composableBuilder(
    column: $table.fitnessAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vitality => $composableBuilder(
    column: $table.vitality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hydration => $composableBuilder(
    column: $table.hydration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyMetricsTable> {
  $$DailyMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get cycleId =>
      $composableBuilder(column: $table.cycleId, builder: (column) => column);

  GeneratedColumn<double> get charge =>
      $composableBuilder(column: $table.charge, builder: (column) => column);

  GeneratedColumn<double> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => column);

  GeneratedColumn<double> get dayStrain =>
      $composableBuilder(column: $table.dayStrain, builder: (column) => column);

  GeneratedColumn<double> get rest =>
      $composableBuilder(column: $table.rest, builder: (column) => column);

  GeneratedColumn<double> get stress =>
      $composableBuilder(column: $table.stress, builder: (column) => column);

  GeneratedColumn<double> get hrv =>
      $composableBuilder(column: $table.hrv, builder: (column) => column);

  GeneratedColumn<double> get rhr =>
      $composableBuilder(column: $table.rhr, builder: (column) => column);

  GeneratedColumn<double> get respiratoryRate => $composableBuilder(
    column: $table.respiratoryRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get skinTempDelta => $composableBuilder(
    column: $table.skinTempDelta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get spo2 =>
      $composableBuilder(column: $table.spo2, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get kilojoules => $composableBuilder(
    column: $table.kilojoules,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hrZone13Sec => $composableBuilder(
    column: $table.hrZone13Sec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hrZone45Sec => $composableBuilder(
    column: $table.hrZone45Sec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get strengthActivitySec => $composableBuilder(
    column: $table.strengthActivitySec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hrvBaseline => $composableBuilder(
    column: $table.hrvBaseline,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rhrBaseline => $composableBuilder(
    column: $table.rhrBaseline,
    builder: (column) => column,
  );

  GeneratedColumn<double> get respRateBaseline => $composableBuilder(
    column: $table.respRateBaseline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stepsBaseline => $composableBuilder(
    column: $table.stepsBaseline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fitnessAge => $composableBuilder(
    column: $table.fitnessAge,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vitality =>
      $composableBuilder(column: $table.vitality, builder: (column) => column);

  GeneratedColumn<double> get hydration =>
      $composableBuilder(column: $table.hydration, builder: (column) => column);
}

class $$DailyMetricsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyMetricsTable,
          DailyMetric,
          $$DailyMetricsTableFilterComposer,
          $$DailyMetricsTableOrderingComposer,
          $$DailyMetricsTableAnnotationComposer,
          $$DailyMetricsTableCreateCompanionBuilder,
          $$DailyMetricsTableUpdateCompanionBuilder,
          (
            DailyMetric,
            BaseReferences<_$AppDatabase, $DailyMetricsTable, DailyMetric>,
          ),
          DailyMetric,
          PrefetchHooks Function()
        > {
  $$DailyMetricsTableTableManager(_$AppDatabase db, $DailyMetricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String?> cycleId = const Value.absent(),
                Value<double> charge = const Value.absent(),
                Value<double> effort = const Value.absent(),
                Value<double?> dayStrain = const Value.absent(),
                Value<double> rest = const Value.absent(),
                Value<double> stress = const Value.absent(),
                Value<double> hrv = const Value.absent(),
                Value<double> rhr = const Value.absent(),
                Value<double> respiratoryRate = const Value.absent(),
                Value<double> skinTempDelta = const Value.absent(),
                Value<double> spo2 = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<double?> kilojoules = const Value.absent(),
                Value<int?> hrZone13Sec = const Value.absent(),
                Value<int?> hrZone45Sec = const Value.absent(),
                Value<int?> strengthActivitySec = const Value.absent(),
                Value<double?> hrvBaseline = const Value.absent(),
                Value<double?> rhrBaseline = const Value.absent(),
                Value<double?> respRateBaseline = const Value.absent(),
                Value<int?> stepsBaseline = const Value.absent(),
                Value<int> fitnessAge = const Value.absent(),
                Value<int> vitality = const Value.absent(),
                Value<double> hydration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyMetricsCompanion(
                day: day,
                cycleId: cycleId,
                charge: charge,
                effort: effort,
                dayStrain: dayStrain,
                rest: rest,
                stress: stress,
                hrv: hrv,
                rhr: rhr,
                respiratoryRate: respiratoryRate,
                skinTempDelta: skinTempDelta,
                spo2: spo2,
                steps: steps,
                calories: calories,
                kilojoules: kilojoules,
                hrZone13Sec: hrZone13Sec,
                hrZone45Sec: hrZone45Sec,
                strengthActivitySec: strengthActivitySec,
                hrvBaseline: hrvBaseline,
                rhrBaseline: rhrBaseline,
                respRateBaseline: respRateBaseline,
                stepsBaseline: stepsBaseline,
                fitnessAge: fitnessAge,
                vitality: vitality,
                hydration: hydration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                Value<String?> cycleId = const Value.absent(),
                Value<double> charge = const Value.absent(),
                Value<double> effort = const Value.absent(),
                Value<double?> dayStrain = const Value.absent(),
                Value<double> rest = const Value.absent(),
                Value<double> stress = const Value.absent(),
                Value<double> hrv = const Value.absent(),
                Value<double> rhr = const Value.absent(),
                Value<double> respiratoryRate = const Value.absent(),
                Value<double> skinTempDelta = const Value.absent(),
                Value<double> spo2 = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<double?> kilojoules = const Value.absent(),
                Value<int?> hrZone13Sec = const Value.absent(),
                Value<int?> hrZone45Sec = const Value.absent(),
                Value<int?> strengthActivitySec = const Value.absent(),
                Value<double?> hrvBaseline = const Value.absent(),
                Value<double?> rhrBaseline = const Value.absent(),
                Value<double?> respRateBaseline = const Value.absent(),
                Value<int?> stepsBaseline = const Value.absent(),
                Value<int> fitnessAge = const Value.absent(),
                Value<int> vitality = const Value.absent(),
                Value<double> hydration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyMetricsCompanion.insert(
                day: day,
                cycleId: cycleId,
                charge: charge,
                effort: effort,
                dayStrain: dayStrain,
                rest: rest,
                stress: stress,
                hrv: hrv,
                rhr: rhr,
                respiratoryRate: respiratoryRate,
                skinTempDelta: skinTempDelta,
                spo2: spo2,
                steps: steps,
                calories: calories,
                kilojoules: kilojoules,
                hrZone13Sec: hrZone13Sec,
                hrZone45Sec: hrZone45Sec,
                strengthActivitySec: strengthActivitySec,
                hrvBaseline: hrvBaseline,
                rhrBaseline: rhrBaseline,
                respRateBaseline: respRateBaseline,
                stepsBaseline: stepsBaseline,
                fitnessAge: fitnessAge,
                vitality: vitality,
                hydration: hydration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyMetricsTable,
      DailyMetric,
      $$DailyMetricsTableFilterComposer,
      $$DailyMetricsTableOrderingComposer,
      $$DailyMetricsTableAnnotationComposer,
      $$DailyMetricsTableCreateCompanionBuilder,
      $$DailyMetricsTableUpdateCompanionBuilder,
      (
        DailyMetric,
        BaseReferences<_$AppDatabase, $DailyMetricsTable, DailyMetric>,
      ),
      DailyMetric,
      PrefetchHooks Function()
    >;
typedef $$CyclesTableCreateCompanionBuilder =
    CyclesCompanion Function({
      required String id,
      required int startTs,
      Value<int?> endTs,
      Value<bool> isMultiDay,
      Value<bool> isDayZero,
      Value<String?> sleepState,
      Value<int> rowid,
    });
typedef $$CyclesTableUpdateCompanionBuilder =
    CyclesCompanion Function({
      Value<String> id,
      Value<int> startTs,
      Value<int?> endTs,
      Value<bool> isMultiDay,
      Value<bool> isDayZero,
      Value<String?> sleepState,
      Value<int> rowid,
    });

class $$CyclesTableFilterComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTs => $composableBuilder(
    column: $table.startTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTs => $composableBuilder(
    column: $table.endTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMultiDay => $composableBuilder(
    column: $table.isMultiDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDayZero => $composableBuilder(
    column: $table.isDayZero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sleepState => $composableBuilder(
    column: $table.sleepState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTs => $composableBuilder(
    column: $table.startTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTs => $composableBuilder(
    column: $table.endTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMultiDay => $composableBuilder(
    column: $table.isMultiDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDayZero => $composableBuilder(
    column: $table.isDayZero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sleepState => $composableBuilder(
    column: $table.sleepState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startTs =>
      $composableBuilder(column: $table.startTs, builder: (column) => column);

  GeneratedColumn<int> get endTs =>
      $composableBuilder(column: $table.endTs, builder: (column) => column);

  GeneratedColumn<bool> get isMultiDay => $composableBuilder(
    column: $table.isMultiDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDayZero =>
      $composableBuilder(column: $table.isDayZero, builder: (column) => column);

  GeneratedColumn<String> get sleepState => $composableBuilder(
    column: $table.sleepState,
    builder: (column) => column,
  );
}

class $$CyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CyclesTable,
          Cycle,
          $$CyclesTableFilterComposer,
          $$CyclesTableOrderingComposer,
          $$CyclesTableAnnotationComposer,
          $$CyclesTableCreateCompanionBuilder,
          $$CyclesTableUpdateCompanionBuilder,
          (Cycle, BaseReferences<_$AppDatabase, $CyclesTable, Cycle>),
          Cycle,
          PrefetchHooks Function()
        > {
  $$CyclesTableTableManager(_$AppDatabase db, $CyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> startTs = const Value.absent(),
                Value<int?> endTs = const Value.absent(),
                Value<bool> isMultiDay = const Value.absent(),
                Value<bool> isDayZero = const Value.absent(),
                Value<String?> sleepState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CyclesCompanion(
                id: id,
                startTs: startTs,
                endTs: endTs,
                isMultiDay: isMultiDay,
                isDayZero: isDayZero,
                sleepState: sleepState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int startTs,
                Value<int?> endTs = const Value.absent(),
                Value<bool> isMultiDay = const Value.absent(),
                Value<bool> isDayZero = const Value.absent(),
                Value<String?> sleepState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CyclesCompanion.insert(
                id: id,
                startTs: startTs,
                endTs: endTs,
                isMultiDay: isMultiDay,
                isDayZero: isDayZero,
                sleepState: sleepState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CyclesTable,
      Cycle,
      $$CyclesTableFilterComposer,
      $$CyclesTableOrderingComposer,
      $$CyclesTableAnnotationComposer,
      $$CyclesTableCreateCompanionBuilder,
      $$CyclesTableUpdateCompanionBuilder,
      (Cycle, BaseReferences<_$AppDatabase, $CyclesTable, Cycle>),
      Cycle,
      PrefetchHooks Function()
    >;
typedef $$SleepSessionsTableCreateCompanionBuilder =
    SleepSessionsCompanion Function({
      required String day,
      required int bedtimeTs,
      required int wakeTs,
      required int inBedSec,
      required int asleepSec,
      required int deepSec,
      required int remSec,
      required int lightSec,
      required int awakeSec,
      required double efficiency,
      Value<int> needSec,
      Value<double> respiratoryRate,
      Value<int> disturbances,
      Value<double?> restingHr,
      Value<double?> avgHrv,
      Value<double?> spo2,
      Value<double?> skinTempDelta,
      Value<int?> sleepPerformancePct,
      Value<int?> sleepConsistencyPct,
      Value<int?> hoursVsNeededPct,
      Value<int?> restorativeSleepSec,
      Value<int?> sleepLatencySec,
      Value<int?> wakeEventsCount,
      Value<int?> highSleepStressPct,
      Value<int?> noDataSec,
      Value<int?> sleepDebtSec,
      Value<int?> sleepNeedBaselineSec,
      Value<int?> sleepNeedFromStrainSec,
      Value<int?> sleepNeedFromNapSec,
      Value<String?> activityId,
      Value<String?> cycleId,
      Value<String> source,
      Value<bool> isNap,
      Value<bool> userEdited,
      Value<int?> startTsAdjusted,
      Value<String> hypnogramJson,
      Value<String> restlessnessJson,
      Value<String> sleepStateJson,
      Value<int> rowid,
    });
typedef $$SleepSessionsTableUpdateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<String> day,
      Value<int> bedtimeTs,
      Value<int> wakeTs,
      Value<int> inBedSec,
      Value<int> asleepSec,
      Value<int> deepSec,
      Value<int> remSec,
      Value<int> lightSec,
      Value<int> awakeSec,
      Value<double> efficiency,
      Value<int> needSec,
      Value<double> respiratoryRate,
      Value<int> disturbances,
      Value<double?> restingHr,
      Value<double?> avgHrv,
      Value<double?> spo2,
      Value<double?> skinTempDelta,
      Value<int?> sleepPerformancePct,
      Value<int?> sleepConsistencyPct,
      Value<int?> hoursVsNeededPct,
      Value<int?> restorativeSleepSec,
      Value<int?> sleepLatencySec,
      Value<int?> wakeEventsCount,
      Value<int?> highSleepStressPct,
      Value<int?> noDataSec,
      Value<int?> sleepDebtSec,
      Value<int?> sleepNeedBaselineSec,
      Value<int?> sleepNeedFromStrainSec,
      Value<int?> sleepNeedFromNapSec,
      Value<String?> activityId,
      Value<String?> cycleId,
      Value<String> source,
      Value<bool> isNap,
      Value<bool> userEdited,
      Value<int?> startTsAdjusted,
      Value<String> hypnogramJson,
      Value<String> restlessnessJson,
      Value<String> sleepStateJson,
      Value<int> rowid,
    });

class $$SleepSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SleepSessionsTable> {
  $$SleepSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeTs => $composableBuilder(
    column: $table.bedtimeTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeTs => $composableBuilder(
    column: $table.wakeTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inBedSec => $composableBuilder(
    column: $table.inBedSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get asleepSec => $composableBuilder(
    column: $table.asleepSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deepSec => $composableBuilder(
    column: $table.deepSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remSec => $composableBuilder(
    column: $table.remSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lightSec => $composableBuilder(
    column: $table.lightSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awakeSec => $composableBuilder(
    column: $table.awakeSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get efficiency => $composableBuilder(
    column: $table.efficiency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get needSec => $composableBuilder(
    column: $table.needSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get respiratoryRate => $composableBuilder(
    column: $table.respiratoryRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disturbances => $composableBuilder(
    column: $table.disturbances,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get restingHr => $composableBuilder(
    column: $table.restingHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHrv => $composableBuilder(
    column: $table.avgHrv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get spo2 => $composableBuilder(
    column: $table.spo2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get skinTempDelta => $composableBuilder(
    column: $table.skinTempDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepPerformancePct => $composableBuilder(
    column: $table.sleepPerformancePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepConsistencyPct => $composableBuilder(
    column: $table.sleepConsistencyPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hoursVsNeededPct => $composableBuilder(
    column: $table.hoursVsNeededPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restorativeSleepSec => $composableBuilder(
    column: $table.restorativeSleepSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepLatencySec => $composableBuilder(
    column: $table.sleepLatencySec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeEventsCount => $composableBuilder(
    column: $table.wakeEventsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get highSleepStressPct => $composableBuilder(
    column: $table.highSleepStressPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noDataSec => $composableBuilder(
    column: $table.noDataSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepDebtSec => $composableBuilder(
    column: $table.sleepDebtSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepNeedBaselineSec => $composableBuilder(
    column: $table.sleepNeedBaselineSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepNeedFromStrainSec => $composableBuilder(
    column: $table.sleepNeedFromStrainSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepNeedFromNapSec => $composableBuilder(
    column: $table.sleepNeedFromNapSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNap => $composableBuilder(
    column: $table.isNap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTsAdjusted => $composableBuilder(
    column: $table.startTsAdjusted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hypnogramJson => $composableBuilder(
    column: $table.hypnogramJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restlessnessJson => $composableBuilder(
    column: $table.restlessnessJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sleepStateJson => $composableBuilder(
    column: $table.sleepStateJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SleepSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SleepSessionsTable> {
  $$SleepSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeTs => $composableBuilder(
    column: $table.bedtimeTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeTs => $composableBuilder(
    column: $table.wakeTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inBedSec => $composableBuilder(
    column: $table.inBedSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get asleepSec => $composableBuilder(
    column: $table.asleepSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deepSec => $composableBuilder(
    column: $table.deepSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remSec => $composableBuilder(
    column: $table.remSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lightSec => $composableBuilder(
    column: $table.lightSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awakeSec => $composableBuilder(
    column: $table.awakeSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get efficiency => $composableBuilder(
    column: $table.efficiency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get needSec => $composableBuilder(
    column: $table.needSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get respiratoryRate => $composableBuilder(
    column: $table.respiratoryRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disturbances => $composableBuilder(
    column: $table.disturbances,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get restingHr => $composableBuilder(
    column: $table.restingHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHrv => $composableBuilder(
    column: $table.avgHrv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get spo2 => $composableBuilder(
    column: $table.spo2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get skinTempDelta => $composableBuilder(
    column: $table.skinTempDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepPerformancePct => $composableBuilder(
    column: $table.sleepPerformancePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepConsistencyPct => $composableBuilder(
    column: $table.sleepConsistencyPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hoursVsNeededPct => $composableBuilder(
    column: $table.hoursVsNeededPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restorativeSleepSec => $composableBuilder(
    column: $table.restorativeSleepSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepLatencySec => $composableBuilder(
    column: $table.sleepLatencySec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeEventsCount => $composableBuilder(
    column: $table.wakeEventsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get highSleepStressPct => $composableBuilder(
    column: $table.highSleepStressPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noDataSec => $composableBuilder(
    column: $table.noDataSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepDebtSec => $composableBuilder(
    column: $table.sleepDebtSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepNeedBaselineSec => $composableBuilder(
    column: $table.sleepNeedBaselineSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepNeedFromStrainSec => $composableBuilder(
    column: $table.sleepNeedFromStrainSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepNeedFromNapSec => $composableBuilder(
    column: $table.sleepNeedFromNapSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleId => $composableBuilder(
    column: $table.cycleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNap => $composableBuilder(
    column: $table.isNap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTsAdjusted => $composableBuilder(
    column: $table.startTsAdjusted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hypnogramJson => $composableBuilder(
    column: $table.hypnogramJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restlessnessJson => $composableBuilder(
    column: $table.restlessnessJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sleepStateJson => $composableBuilder(
    column: $table.sleepStateJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SleepSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SleepSessionsTable> {
  $$SleepSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get bedtimeTs =>
      $composableBuilder(column: $table.bedtimeTs, builder: (column) => column);

  GeneratedColumn<int> get wakeTs =>
      $composableBuilder(column: $table.wakeTs, builder: (column) => column);

  GeneratedColumn<int> get inBedSec =>
      $composableBuilder(column: $table.inBedSec, builder: (column) => column);

  GeneratedColumn<int> get asleepSec =>
      $composableBuilder(column: $table.asleepSec, builder: (column) => column);

  GeneratedColumn<int> get deepSec =>
      $composableBuilder(column: $table.deepSec, builder: (column) => column);

  GeneratedColumn<int> get remSec =>
      $composableBuilder(column: $table.remSec, builder: (column) => column);

  GeneratedColumn<int> get lightSec =>
      $composableBuilder(column: $table.lightSec, builder: (column) => column);

  GeneratedColumn<int> get awakeSec =>
      $composableBuilder(column: $table.awakeSec, builder: (column) => column);

  GeneratedColumn<double> get efficiency => $composableBuilder(
    column: $table.efficiency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get needSec =>
      $composableBuilder(column: $table.needSec, builder: (column) => column);

  GeneratedColumn<double> get respiratoryRate => $composableBuilder(
    column: $table.respiratoryRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get disturbances => $composableBuilder(
    column: $table.disturbances,
    builder: (column) => column,
  );

  GeneratedColumn<double> get restingHr =>
      $composableBuilder(column: $table.restingHr, builder: (column) => column);

  GeneratedColumn<double> get avgHrv =>
      $composableBuilder(column: $table.avgHrv, builder: (column) => column);

  GeneratedColumn<double> get spo2 =>
      $composableBuilder(column: $table.spo2, builder: (column) => column);

  GeneratedColumn<double> get skinTempDelta => $composableBuilder(
    column: $table.skinTempDelta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepPerformancePct => $composableBuilder(
    column: $table.sleepPerformancePct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepConsistencyPct => $composableBuilder(
    column: $table.sleepConsistencyPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hoursVsNeededPct => $composableBuilder(
    column: $table.hoursVsNeededPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restorativeSleepSec => $composableBuilder(
    column: $table.restorativeSleepSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepLatencySec => $composableBuilder(
    column: $table.sleepLatencySec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeEventsCount => $composableBuilder(
    column: $table.wakeEventsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get highSleepStressPct => $composableBuilder(
    column: $table.highSleepStressPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noDataSec =>
      $composableBuilder(column: $table.noDataSec, builder: (column) => column);

  GeneratedColumn<int> get sleepDebtSec => $composableBuilder(
    column: $table.sleepDebtSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepNeedBaselineSec => $composableBuilder(
    column: $table.sleepNeedBaselineSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepNeedFromStrainSec => $composableBuilder(
    column: $table.sleepNeedFromStrainSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepNeedFromNapSec => $composableBuilder(
    column: $table.sleepNeedFromNapSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cycleId =>
      $composableBuilder(column: $table.cycleId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get isNap =>
      $composableBuilder(column: $table.isNap, builder: (column) => column);

  GeneratedColumn<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startTsAdjusted => $composableBuilder(
    column: $table.startTsAdjusted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hypnogramJson => $composableBuilder(
    column: $table.hypnogramJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get restlessnessJson => $composableBuilder(
    column: $table.restlessnessJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sleepStateJson => $composableBuilder(
    column: $table.sleepStateJson,
    builder: (column) => column,
  );
}

class $$SleepSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepSessionsTable,
          SleepSession,
          $$SleepSessionsTableFilterComposer,
          $$SleepSessionsTableOrderingComposer,
          $$SleepSessionsTableAnnotationComposer,
          $$SleepSessionsTableCreateCompanionBuilder,
          $$SleepSessionsTableUpdateCompanionBuilder,
          (
            SleepSession,
            BaseReferences<_$AppDatabase, $SleepSessionsTable, SleepSession>,
          ),
          SleepSession,
          PrefetchHooks Function()
        > {
  $$SleepSessionsTableTableManager(_$AppDatabase db, $SleepSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int> bedtimeTs = const Value.absent(),
                Value<int> wakeTs = const Value.absent(),
                Value<int> inBedSec = const Value.absent(),
                Value<int> asleepSec = const Value.absent(),
                Value<int> deepSec = const Value.absent(),
                Value<int> remSec = const Value.absent(),
                Value<int> lightSec = const Value.absent(),
                Value<int> awakeSec = const Value.absent(),
                Value<double> efficiency = const Value.absent(),
                Value<int> needSec = const Value.absent(),
                Value<double> respiratoryRate = const Value.absent(),
                Value<int> disturbances = const Value.absent(),
                Value<double?> restingHr = const Value.absent(),
                Value<double?> avgHrv = const Value.absent(),
                Value<double?> spo2 = const Value.absent(),
                Value<double?> skinTempDelta = const Value.absent(),
                Value<int?> sleepPerformancePct = const Value.absent(),
                Value<int?> sleepConsistencyPct = const Value.absent(),
                Value<int?> hoursVsNeededPct = const Value.absent(),
                Value<int?> restorativeSleepSec = const Value.absent(),
                Value<int?> sleepLatencySec = const Value.absent(),
                Value<int?> wakeEventsCount = const Value.absent(),
                Value<int?> highSleepStressPct = const Value.absent(),
                Value<int?> noDataSec = const Value.absent(),
                Value<int?> sleepDebtSec = const Value.absent(),
                Value<int?> sleepNeedBaselineSec = const Value.absent(),
                Value<int?> sleepNeedFromStrainSec = const Value.absent(),
                Value<int?> sleepNeedFromNapSec = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> cycleId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<bool> isNap = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<int?> startTsAdjusted = const Value.absent(),
                Value<String> hypnogramJson = const Value.absent(),
                Value<String> restlessnessJson = const Value.absent(),
                Value<String> sleepStateJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SleepSessionsCompanion(
                day: day,
                bedtimeTs: bedtimeTs,
                wakeTs: wakeTs,
                inBedSec: inBedSec,
                asleepSec: asleepSec,
                deepSec: deepSec,
                remSec: remSec,
                lightSec: lightSec,
                awakeSec: awakeSec,
                efficiency: efficiency,
                needSec: needSec,
                respiratoryRate: respiratoryRate,
                disturbances: disturbances,
                restingHr: restingHr,
                avgHrv: avgHrv,
                spo2: spo2,
                skinTempDelta: skinTempDelta,
                sleepPerformancePct: sleepPerformancePct,
                sleepConsistencyPct: sleepConsistencyPct,
                hoursVsNeededPct: hoursVsNeededPct,
                restorativeSleepSec: restorativeSleepSec,
                sleepLatencySec: sleepLatencySec,
                wakeEventsCount: wakeEventsCount,
                highSleepStressPct: highSleepStressPct,
                noDataSec: noDataSec,
                sleepDebtSec: sleepDebtSec,
                sleepNeedBaselineSec: sleepNeedBaselineSec,
                sleepNeedFromStrainSec: sleepNeedFromStrainSec,
                sleepNeedFromNapSec: sleepNeedFromNapSec,
                activityId: activityId,
                cycleId: cycleId,
                source: source,
                isNap: isNap,
                userEdited: userEdited,
                startTsAdjusted: startTsAdjusted,
                hypnogramJson: hypnogramJson,
                restlessnessJson: restlessnessJson,
                sleepStateJson: sleepStateJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required int bedtimeTs,
                required int wakeTs,
                required int inBedSec,
                required int asleepSec,
                required int deepSec,
                required int remSec,
                required int lightSec,
                required int awakeSec,
                required double efficiency,
                Value<int> needSec = const Value.absent(),
                Value<double> respiratoryRate = const Value.absent(),
                Value<int> disturbances = const Value.absent(),
                Value<double?> restingHr = const Value.absent(),
                Value<double?> avgHrv = const Value.absent(),
                Value<double?> spo2 = const Value.absent(),
                Value<double?> skinTempDelta = const Value.absent(),
                Value<int?> sleepPerformancePct = const Value.absent(),
                Value<int?> sleepConsistencyPct = const Value.absent(),
                Value<int?> hoursVsNeededPct = const Value.absent(),
                Value<int?> restorativeSleepSec = const Value.absent(),
                Value<int?> sleepLatencySec = const Value.absent(),
                Value<int?> wakeEventsCount = const Value.absent(),
                Value<int?> highSleepStressPct = const Value.absent(),
                Value<int?> noDataSec = const Value.absent(),
                Value<int?> sleepDebtSec = const Value.absent(),
                Value<int?> sleepNeedBaselineSec = const Value.absent(),
                Value<int?> sleepNeedFromStrainSec = const Value.absent(),
                Value<int?> sleepNeedFromNapSec = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> cycleId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<bool> isNap = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<int?> startTsAdjusted = const Value.absent(),
                Value<String> hypnogramJson = const Value.absent(),
                Value<String> restlessnessJson = const Value.absent(),
                Value<String> sleepStateJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SleepSessionsCompanion.insert(
                day: day,
                bedtimeTs: bedtimeTs,
                wakeTs: wakeTs,
                inBedSec: inBedSec,
                asleepSec: asleepSec,
                deepSec: deepSec,
                remSec: remSec,
                lightSec: lightSec,
                awakeSec: awakeSec,
                efficiency: efficiency,
                needSec: needSec,
                respiratoryRate: respiratoryRate,
                disturbances: disturbances,
                restingHr: restingHr,
                avgHrv: avgHrv,
                spo2: spo2,
                skinTempDelta: skinTempDelta,
                sleepPerformancePct: sleepPerformancePct,
                sleepConsistencyPct: sleepConsistencyPct,
                hoursVsNeededPct: hoursVsNeededPct,
                restorativeSleepSec: restorativeSleepSec,
                sleepLatencySec: sleepLatencySec,
                wakeEventsCount: wakeEventsCount,
                highSleepStressPct: highSleepStressPct,
                noDataSec: noDataSec,
                sleepDebtSec: sleepDebtSec,
                sleepNeedBaselineSec: sleepNeedBaselineSec,
                sleepNeedFromStrainSec: sleepNeedFromStrainSec,
                sleepNeedFromNapSec: sleepNeedFromNapSec,
                activityId: activityId,
                cycleId: cycleId,
                source: source,
                isNap: isNap,
                userEdited: userEdited,
                startTsAdjusted: startTsAdjusted,
                hypnogramJson: hypnogramJson,
                restlessnessJson: restlessnessJson,
                sleepStateJson: sleepStateJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SleepSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepSessionsTable,
      SleepSession,
      $$SleepSessionsTableFilterComposer,
      $$SleepSessionsTableOrderingComposer,
      $$SleepSessionsTableAnnotationComposer,
      $$SleepSessionsTableCreateCompanionBuilder,
      $$SleepSessionsTableUpdateCompanionBuilder,
      (
        SleepSession,
        BaseReferences<_$AppDatabase, $SleepSessionsTable, SleepSession>,
      ),
      SleepSession,
      PrefetchHooks Function()
    >;
typedef $$SleepStateSamplesTableCreateCompanionBuilder =
    SleepStateSamplesCompanion Function({
      Value<int> ts,
      required int state,
      Value<String> source,
    });
typedef $$SleepStateSamplesTableUpdateCompanionBuilder =
    SleepStateSamplesCompanion Function({
      Value<int> ts,
      Value<int> state,
      Value<String> source,
    });

class $$SleepStateSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $SleepStateSamplesTable> {
  $$SleepStateSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SleepStateSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $SleepStateSamplesTable> {
  $$SleepStateSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SleepStateSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SleepStateSamplesTable> {
  $$SleepStateSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$SleepStateSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepStateSamplesTable,
          SleepStateSample,
          $$SleepStateSamplesTableFilterComposer,
          $$SleepStateSamplesTableOrderingComposer,
          $$SleepStateSamplesTableAnnotationComposer,
          $$SleepStateSamplesTableCreateCompanionBuilder,
          $$SleepStateSamplesTableUpdateCompanionBuilder,
          (
            SleepStateSample,
            BaseReferences<
              _$AppDatabase,
              $SleepStateSamplesTable,
              SleepStateSample
            >,
          ),
          SleepStateSample,
          PrefetchHooks Function()
        > {
  $$SleepStateSamplesTableTableManager(
    _$AppDatabase db,
    $SleepStateSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepStateSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepStateSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepStateSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => SleepStateSamplesCompanion(
                ts: ts,
                state: state,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                required int state,
                Value<String> source = const Value.absent(),
              }) => SleepStateSamplesCompanion.insert(
                ts: ts,
                state: state,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SleepStateSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepStateSamplesTable,
      SleepStateSample,
      $$SleepStateSamplesTableFilterComposer,
      $$SleepStateSamplesTableOrderingComposer,
      $$SleepStateSamplesTableAnnotationComposer,
      $$SleepStateSamplesTableCreateCompanionBuilder,
      $$SleepStateSamplesTableUpdateCompanionBuilder,
      (
        SleepStateSample,
        BaseReferences<
          _$AppDatabase,
          $SleepStateSamplesTable,
          SleepStateSample
        >,
      ),
      SleepStateSample,
      PrefetchHooks Function()
    >;
typedef $$WorkoutsTableCreateCompanionBuilder =
    WorkoutsCompanion Function({
      required String id,
      Value<String?> activityId,
      required String sport,
      Value<int?> sportId,
      required int startTs,
      required int durationSec,
      Value<double> avgHr,
      Value<double> maxHr,
      Value<double> effort,
      Value<int> calories,
      Value<double?> kilojoules,
      Value<double?> distanceKm,
      Value<double?> elevationGainM,
      Value<String> source,
      Value<String> zonesJson,
      Value<String?> gpsRouteJson,
      Value<String?> strainBreakdownJson,
      Value<String?> tagsJson,
      Value<String?> weightliftingDetailsJson,
      Value<int> rowid,
    });
typedef $$WorkoutsTableUpdateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<String> id,
      Value<String?> activityId,
      Value<String> sport,
      Value<int?> sportId,
      Value<int> startTs,
      Value<int> durationSec,
      Value<double> avgHr,
      Value<double> maxHr,
      Value<double> effort,
      Value<int> calories,
      Value<double?> kilojoules,
      Value<double?> distanceKm,
      Value<double?> elevationGainM,
      Value<String> source,
      Value<String> zonesJson,
      Value<String?> gpsRouteJson,
      Value<String?> strainBreakdownJson,
      Value<String?> tagsJson,
      Value<String?> weightliftingDetailsJson,
      Value<int> rowid,
    });

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sportId => $composableBuilder(
    column: $table.sportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTs => $composableBuilder(
    column: $table.startTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHr => $composableBuilder(
    column: $table.avgHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kilojoules => $composableBuilder(
    column: $table.kilojoules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zonesJson => $composableBuilder(
    column: $table.zonesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gpsRouteJson => $composableBuilder(
    column: $table.gpsRouteJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strainBreakdownJson => $composableBuilder(
    column: $table.strainBreakdownJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightliftingDetailsJson => $composableBuilder(
    column: $table.weightliftingDetailsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sportId => $composableBuilder(
    column: $table.sportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTs => $composableBuilder(
    column: $table.startTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHr => $composableBuilder(
    column: $table.avgHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kilojoules => $composableBuilder(
    column: $table.kilojoules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zonesJson => $composableBuilder(
    column: $table.zonesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gpsRouteJson => $composableBuilder(
    column: $table.gpsRouteJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strainBreakdownJson => $composableBuilder(
    column: $table.strainBreakdownJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightliftingDetailsJson => $composableBuilder(
    column: $table.weightliftingDetailsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<int> get sportId =>
      $composableBuilder(column: $table.sportId, builder: (column) => column);

  GeneratedColumn<int> get startTs =>
      $composableBuilder(column: $table.startTs, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<double> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<double> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get kilojoules => $composableBuilder(
    column: $table.kilojoules,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get zonesJson =>
      $composableBuilder(column: $table.zonesJson, builder: (column) => column);

  GeneratedColumn<String> get gpsRouteJson => $composableBuilder(
    column: $table.gpsRouteJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strainBreakdownJson => $composableBuilder(
    column: $table.strainBreakdownJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get weightliftingDetailsJson => $composableBuilder(
    column: $table.weightliftingDetailsJson,
    builder: (column) => column,
  );
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>),
          Workout,
          PrefetchHooks Function()
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String> sport = const Value.absent(),
                Value<int?> sportId = const Value.absent(),
                Value<int> startTs = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<double> avgHr = const Value.absent(),
                Value<double> maxHr = const Value.absent(),
                Value<double> effort = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<double?> kilojoules = const Value.absent(),
                Value<double?> distanceKm = const Value.absent(),
                Value<double?> elevationGainM = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> zonesJson = const Value.absent(),
                Value<String?> gpsRouteJson = const Value.absent(),
                Value<String?> strainBreakdownJson = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<String?> weightliftingDetailsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                activityId: activityId,
                sport: sport,
                sportId: sportId,
                startTs: startTs,
                durationSec: durationSec,
                avgHr: avgHr,
                maxHr: maxHr,
                effort: effort,
                calories: calories,
                kilojoules: kilojoules,
                distanceKm: distanceKm,
                elevationGainM: elevationGainM,
                source: source,
                zonesJson: zonesJson,
                gpsRouteJson: gpsRouteJson,
                strainBreakdownJson: strainBreakdownJson,
                tagsJson: tagsJson,
                weightliftingDetailsJson: weightliftingDetailsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> activityId = const Value.absent(),
                required String sport,
                Value<int?> sportId = const Value.absent(),
                required int startTs,
                required int durationSec,
                Value<double> avgHr = const Value.absent(),
                Value<double> maxHr = const Value.absent(),
                Value<double> effort = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<double?> kilojoules = const Value.absent(),
                Value<double?> distanceKm = const Value.absent(),
                Value<double?> elevationGainM = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> zonesJson = const Value.absent(),
                Value<String?> gpsRouteJson = const Value.absent(),
                Value<String?> strainBreakdownJson = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<String?> weightliftingDetailsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                activityId: activityId,
                sport: sport,
                sportId: sportId,
                startTs: startTs,
                durationSec: durationSec,
                avgHr: avgHr,
                maxHr: maxHr,
                effort: effort,
                calories: calories,
                kilojoules: kilojoules,
                distanceKm: distanceKm,
                elevationGainM: elevationGainM,
                source: source,
                zonesJson: zonesJson,
                gpsRouteJson: gpsRouteJson,
                strainBreakdownJson: strainBreakdownJson,
                tagsJson: tagsJson,
                weightliftingDetailsJson: weightliftingDetailsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>),
      Workout,
      PrefetchHooks Function()
    >;
typedef $$HrSamplesTableCreateCompanionBuilder =
    HrSamplesCompanion Function({Value<int> ts, required double bpm});
typedef $$HrSamplesTableUpdateCompanionBuilder =
    HrSamplesCompanion Function({Value<int> ts, Value<double> bpm});

class $$HrSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $HrSamplesTable> {
  $$HrSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HrSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $HrSamplesTable> {
  $$HrSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HrSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HrSamplesTable> {
  $$HrSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);
}

class $$HrSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HrSamplesTable,
          HrSample,
          $$HrSamplesTableFilterComposer,
          $$HrSamplesTableOrderingComposer,
          $$HrSamplesTableAnnotationComposer,
          $$HrSamplesTableCreateCompanionBuilder,
          $$HrSamplesTableUpdateCompanionBuilder,
          (HrSample, BaseReferences<_$AppDatabase, $HrSamplesTable, HrSample>),
          HrSample,
          PrefetchHooks Function()
        > {
  $$HrSamplesTableTableManager(_$AppDatabase db, $HrSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HrSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HrSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HrSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                Value<double> bpm = const Value.absent(),
              }) => HrSamplesCompanion(ts: ts, bpm: bpm),
          createCompanionCallback:
              ({Value<int> ts = const Value.absent(), required double bpm}) =>
                  HrSamplesCompanion.insert(ts: ts, bpm: bpm),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HrSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HrSamplesTable,
      HrSample,
      $$HrSamplesTableFilterComposer,
      $$HrSamplesTableOrderingComposer,
      $$HrSamplesTableAnnotationComposer,
      $$HrSamplesTableCreateCompanionBuilder,
      $$HrSamplesTableUpdateCompanionBuilder,
      (HrSample, BaseReferences<_$AppDatabase, $HrSamplesTable, HrSample>),
      HrSample,
      PrefetchHooks Function()
    >;
typedef $$RrSamplesTableCreateCompanionBuilder =
    RrSamplesCompanion Function({
      required int tsMs,
      Value<int> rrIndex,
      required int rrMs,
      Value<int?> hrBpm,
      Value<int> rowid,
    });
typedef $$RrSamplesTableUpdateCompanionBuilder =
    RrSamplesCompanion Function({
      Value<int> tsMs,
      Value<int> rrIndex,
      Value<int> rrMs,
      Value<int?> hrBpm,
      Value<int> rowid,
    });

class $$RrSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $RrSamplesTable> {
  $$RrSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tsMs => $composableBuilder(
    column: $table.tsMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rrIndex => $composableBuilder(
    column: $table.rrIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rrMs => $composableBuilder(
    column: $table.rrMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrBpm => $composableBuilder(
    column: $table.hrBpm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RrSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $RrSamplesTable> {
  $$RrSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tsMs => $composableBuilder(
    column: $table.tsMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rrIndex => $composableBuilder(
    column: $table.rrIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rrMs => $composableBuilder(
    column: $table.rrMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrBpm => $composableBuilder(
    column: $table.hrBpm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RrSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RrSamplesTable> {
  $$RrSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tsMs =>
      $composableBuilder(column: $table.tsMs, builder: (column) => column);

  GeneratedColumn<int> get rrIndex =>
      $composableBuilder(column: $table.rrIndex, builder: (column) => column);

  GeneratedColumn<int> get rrMs =>
      $composableBuilder(column: $table.rrMs, builder: (column) => column);

  GeneratedColumn<int> get hrBpm =>
      $composableBuilder(column: $table.hrBpm, builder: (column) => column);
}

class $$RrSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RrSamplesTable,
          RrSample,
          $$RrSamplesTableFilterComposer,
          $$RrSamplesTableOrderingComposer,
          $$RrSamplesTableAnnotationComposer,
          $$RrSamplesTableCreateCompanionBuilder,
          $$RrSamplesTableUpdateCompanionBuilder,
          (RrSample, BaseReferences<_$AppDatabase, $RrSamplesTable, RrSample>),
          RrSample,
          PrefetchHooks Function()
        > {
  $$RrSamplesTableTableManager(_$AppDatabase db, $RrSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RrSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RrSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RrSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tsMs = const Value.absent(),
                Value<int> rrIndex = const Value.absent(),
                Value<int> rrMs = const Value.absent(),
                Value<int?> hrBpm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RrSamplesCompanion(
                tsMs: tsMs,
                rrIndex: rrIndex,
                rrMs: rrMs,
                hrBpm: hrBpm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int tsMs,
                Value<int> rrIndex = const Value.absent(),
                required int rrMs,
                Value<int?> hrBpm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RrSamplesCompanion.insert(
                tsMs: tsMs,
                rrIndex: rrIndex,
                rrMs: rrMs,
                hrBpm: hrBpm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RrSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RrSamplesTable,
      RrSample,
      $$RrSamplesTableFilterComposer,
      $$RrSamplesTableOrderingComposer,
      $$RrSamplesTableAnnotationComposer,
      $$RrSamplesTableCreateCompanionBuilder,
      $$RrSamplesTableUpdateCompanionBuilder,
      (RrSample, BaseReferences<_$AppDatabase, $RrSamplesTable, RrSample>),
      RrSample,
      PrefetchHooks Function()
    >;
typedef $$AccelSamplesTableCreateCompanionBuilder =
    AccelSamplesCompanion Function({
      Value<int> ts,
      required double x,
      required double y,
      required double z,
      Value<double?> gyro,
    });
typedef $$AccelSamplesTableUpdateCompanionBuilder =
    AccelSamplesCompanion Function({
      Value<int> ts,
      Value<double> x,
      Value<double> y,
      Value<double> z,
      Value<double?> gyro,
    });

class $$AccelSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $AccelSamplesTable> {
  $$AccelSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gyro => $composableBuilder(
    column: $table.gyro,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccelSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $AccelSamplesTable> {
  $$AccelSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gyro => $composableBuilder(
    column: $table.gyro,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccelSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccelSamplesTable> {
  $$AccelSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get z =>
      $composableBuilder(column: $table.z, builder: (column) => column);

  GeneratedColumn<double> get gyro =>
      $composableBuilder(column: $table.gyro, builder: (column) => column);
}

class $$AccelSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccelSamplesTable,
          AccelSample,
          $$AccelSamplesTableFilterComposer,
          $$AccelSamplesTableOrderingComposer,
          $$AccelSamplesTableAnnotationComposer,
          $$AccelSamplesTableCreateCompanionBuilder,
          $$AccelSamplesTableUpdateCompanionBuilder,
          (
            AccelSample,
            BaseReferences<_$AppDatabase, $AccelSamplesTable, AccelSample>,
          ),
          AccelSample,
          PrefetchHooks Function()
        > {
  $$AccelSamplesTableTableManager(_$AppDatabase db, $AccelSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccelSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccelSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccelSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> z = const Value.absent(),
                Value<double?> gyro = const Value.absent(),
              }) => AccelSamplesCompanion(ts: ts, x: x, y: y, z: z, gyro: gyro),
          createCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                required double x,
                required double y,
                required double z,
                Value<double?> gyro = const Value.absent(),
              }) => AccelSamplesCompanion.insert(
                ts: ts,
                x: x,
                y: y,
                z: z,
                gyro: gyro,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccelSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccelSamplesTable,
      AccelSample,
      $$AccelSamplesTableFilterComposer,
      $$AccelSamplesTableOrderingComposer,
      $$AccelSamplesTableAnnotationComposer,
      $$AccelSamplesTableCreateCompanionBuilder,
      $$AccelSamplesTableUpdateCompanionBuilder,
      (
        AccelSample,
        BaseReferences<_$AppDatabase, $AccelSamplesTable, AccelSample>,
      ),
      AccelSample,
      PrefetchHooks Function()
    >;
typedef $$RawSensorArchiveTableCreateCompanionBuilder =
    RawSensorArchiveCompanion Function({
      Value<int> id,
      required int capturedAtMs,
      Value<String?> characteristic,
      Value<int?> packetType,
      Value<int?> spo2RawAdc,
      required String rawHex,
      Value<int?> trimCursor,
      Value<String?> family,
    });
typedef $$RawSensorArchiveTableUpdateCompanionBuilder =
    RawSensorArchiveCompanion Function({
      Value<int> id,
      Value<int> capturedAtMs,
      Value<String?> characteristic,
      Value<int?> packetType,
      Value<int?> spo2RawAdc,
      Value<String> rawHex,
      Value<int?> trimCursor,
      Value<String?> family,
    });

class $$RawSensorArchiveTableFilterComposer
    extends Composer<_$AppDatabase, $RawSensorArchiveTable> {
  $$RawSensorArchiveTableFilterComposer({
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

  ColumnFilters<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characteristic => $composableBuilder(
    column: $table.characteristic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get packetType => $composableBuilder(
    column: $table.packetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spo2RawAdc => $composableBuilder(
    column: $table.spo2RawAdc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawHex => $composableBuilder(
    column: $table.rawHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trimCursor => $composableBuilder(
    column: $table.trimCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RawSensorArchiveTableOrderingComposer
    extends Composer<_$AppDatabase, $RawSensorArchiveTable> {
  $$RawSensorArchiveTableOrderingComposer({
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

  ColumnOrderings<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characteristic => $composableBuilder(
    column: $table.characteristic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get packetType => $composableBuilder(
    column: $table.packetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spo2RawAdc => $composableBuilder(
    column: $table.spo2RawAdc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawHex => $composableBuilder(
    column: $table.rawHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trimCursor => $composableBuilder(
    column: $table.trimCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RawSensorArchiveTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawSensorArchiveTable> {
  $$RawSensorArchiveTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get characteristic => $composableBuilder(
    column: $table.characteristic,
    builder: (column) => column,
  );

  GeneratedColumn<int> get packetType => $composableBuilder(
    column: $table.packetType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spo2RawAdc => $composableBuilder(
    column: $table.spo2RawAdc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawHex =>
      $composableBuilder(column: $table.rawHex, builder: (column) => column);

  GeneratedColumn<int> get trimCursor => $composableBuilder(
    column: $table.trimCursor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get family =>
      $composableBuilder(column: $table.family, builder: (column) => column);
}

class $$RawSensorArchiveTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawSensorArchiveTable,
          RawSensorArchiveData,
          $$RawSensorArchiveTableFilterComposer,
          $$RawSensorArchiveTableOrderingComposer,
          $$RawSensorArchiveTableAnnotationComposer,
          $$RawSensorArchiveTableCreateCompanionBuilder,
          $$RawSensorArchiveTableUpdateCompanionBuilder,
          (
            RawSensorArchiveData,
            BaseReferences<
              _$AppDatabase,
              $RawSensorArchiveTable,
              RawSensorArchiveData
            >,
          ),
          RawSensorArchiveData,
          PrefetchHooks Function()
        > {
  $$RawSensorArchiveTableTableManager(
    _$AppDatabase db,
    $RawSensorArchiveTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawSensorArchiveTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawSensorArchiveTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawSensorArchiveTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> capturedAtMs = const Value.absent(),
                Value<String?> characteristic = const Value.absent(),
                Value<int?> packetType = const Value.absent(),
                Value<int?> spo2RawAdc = const Value.absent(),
                Value<String> rawHex = const Value.absent(),
                Value<int?> trimCursor = const Value.absent(),
                Value<String?> family = const Value.absent(),
              }) => RawSensorArchiveCompanion(
                id: id,
                capturedAtMs: capturedAtMs,
                characteristic: characteristic,
                packetType: packetType,
                spo2RawAdc: spo2RawAdc,
                rawHex: rawHex,
                trimCursor: trimCursor,
                family: family,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int capturedAtMs,
                Value<String?> characteristic = const Value.absent(),
                Value<int?> packetType = const Value.absent(),
                Value<int?> spo2RawAdc = const Value.absent(),
                required String rawHex,
                Value<int?> trimCursor = const Value.absent(),
                Value<String?> family = const Value.absent(),
              }) => RawSensorArchiveCompanion.insert(
                id: id,
                capturedAtMs: capturedAtMs,
                characteristic: characteristic,
                packetType: packetType,
                spo2RawAdc: spo2RawAdc,
                rawHex: rawHex,
                trimCursor: trimCursor,
                family: family,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RawSensorArchiveTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawSensorArchiveTable,
      RawSensorArchiveData,
      $$RawSensorArchiveTableFilterComposer,
      $$RawSensorArchiveTableOrderingComposer,
      $$RawSensorArchiveTableAnnotationComposer,
      $$RawSensorArchiveTableCreateCompanionBuilder,
      $$RawSensorArchiveTableUpdateCompanionBuilder,
      (
        RawSensorArchiveData,
        BaseReferences<
          _$AppDatabase,
          $RawSensorArchiveTable,
          RawSensorArchiveData
        >,
      ),
      RawSensorArchiveData,
      PrefetchHooks Function()
    >;
typedef $$BatteryLogTableCreateCompanionBuilder =
    BatteryLogCompanion Function({
      Value<int> ts,
      required int soc,
      Value<bool?> charging,
      Value<int?> mv,
    });
typedef $$BatteryLogTableUpdateCompanionBuilder =
    BatteryLogCompanion Function({
      Value<int> ts,
      Value<int> soc,
      Value<bool?> charging,
      Value<int?> mv,
    });

class $$BatteryLogTableFilterComposer
    extends Composer<_$AppDatabase, $BatteryLogTable> {
  $$BatteryLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soc => $composableBuilder(
    column: $table.soc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get charging => $composableBuilder(
    column: $table.charging,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mv => $composableBuilder(
    column: $table.mv,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatteryLogTableOrderingComposer
    extends Composer<_$AppDatabase, $BatteryLogTable> {
  $$BatteryLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soc => $composableBuilder(
    column: $table.soc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get charging => $composableBuilder(
    column: $table.charging,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mv => $composableBuilder(
    column: $table.mv,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatteryLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatteryLogTable> {
  $$BatteryLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get soc =>
      $composableBuilder(column: $table.soc, builder: (column) => column);

  GeneratedColumn<bool> get charging =>
      $composableBuilder(column: $table.charging, builder: (column) => column);

  GeneratedColumn<int> get mv =>
      $composableBuilder(column: $table.mv, builder: (column) => column);
}

class $$BatteryLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatteryLogTable,
          BatteryLogData,
          $$BatteryLogTableFilterComposer,
          $$BatteryLogTableOrderingComposer,
          $$BatteryLogTableAnnotationComposer,
          $$BatteryLogTableCreateCompanionBuilder,
          $$BatteryLogTableUpdateCompanionBuilder,
          (
            BatteryLogData,
            BaseReferences<_$AppDatabase, $BatteryLogTable, BatteryLogData>,
          ),
          BatteryLogData,
          PrefetchHooks Function()
        > {
  $$BatteryLogTableTableManager(_$AppDatabase db, $BatteryLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatteryLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatteryLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatteryLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                Value<int> soc = const Value.absent(),
                Value<bool?> charging = const Value.absent(),
                Value<int?> mv = const Value.absent(),
              }) => BatteryLogCompanion(
                ts: ts,
                soc: soc,
                charging: charging,
                mv: mv,
              ),
          createCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                required int soc,
                Value<bool?> charging = const Value.absent(),
                Value<int?> mv = const Value.absent(),
              }) => BatteryLogCompanion.insert(
                ts: ts,
                soc: soc,
                charging: charging,
                mv: mv,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatteryLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatteryLogTable,
      BatteryLogData,
      $$BatteryLogTableFilterComposer,
      $$BatteryLogTableOrderingComposer,
      $$BatteryLogTableAnnotationComposer,
      $$BatteryLogTableCreateCompanionBuilder,
      $$BatteryLogTableUpdateCompanionBuilder,
      (
        BatteryLogData,
        BaseReferences<_$AppDatabase, $BatteryLogTable, BatteryLogData>,
      ),
      BatteryLogData,
      PrefetchHooks Function()
    >;
typedef $$DeviceInfoTableCreateCompanionBuilder =
    DeviceInfoCompanion Function({
      required String id,
      Value<String?> serial,
      Value<String?> mac,
      Value<String?> model,
      Value<String?> name,
      Value<String?> hwVersion,
      Value<String?> fwVersion,
      Value<String?> dspVersion,
      Value<int?> lastSeenTs,
      Value<int> rowid,
    });
typedef $$DeviceInfoTableUpdateCompanionBuilder =
    DeviceInfoCompanion Function({
      Value<String> id,
      Value<String?> serial,
      Value<String?> mac,
      Value<String?> model,
      Value<String?> name,
      Value<String?> hwVersion,
      Value<String?> fwVersion,
      Value<String?> dspVersion,
      Value<int?> lastSeenTs,
      Value<int> rowid,
    });

class $$DeviceInfoTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceInfoTable> {
  $$DeviceInfoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mac => $composableBuilder(
    column: $table.mac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hwVersion => $composableBuilder(
    column: $table.hwVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fwVersion => $composableBuilder(
    column: $table.fwVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dspVersion => $composableBuilder(
    column: $table.dspVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenTs => $composableBuilder(
    column: $table.lastSeenTs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceInfoTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceInfoTable> {
  $$DeviceInfoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mac => $composableBuilder(
    column: $table.mac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hwVersion => $composableBuilder(
    column: $table.hwVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fwVersion => $composableBuilder(
    column: $table.fwVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dspVersion => $composableBuilder(
    column: $table.dspVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenTs => $composableBuilder(
    column: $table.lastSeenTs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceInfoTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceInfoTable> {
  $$DeviceInfoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<String> get mac =>
      $composableBuilder(column: $table.mac, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get hwVersion =>
      $composableBuilder(column: $table.hwVersion, builder: (column) => column);

  GeneratedColumn<String> get fwVersion =>
      $composableBuilder(column: $table.fwVersion, builder: (column) => column);

  GeneratedColumn<String> get dspVersion => $composableBuilder(
    column: $table.dspVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeenTs => $composableBuilder(
    column: $table.lastSeenTs,
    builder: (column) => column,
  );
}

class $$DeviceInfoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceInfoTable,
          DeviceInfoData,
          $$DeviceInfoTableFilterComposer,
          $$DeviceInfoTableOrderingComposer,
          $$DeviceInfoTableAnnotationComposer,
          $$DeviceInfoTableCreateCompanionBuilder,
          $$DeviceInfoTableUpdateCompanionBuilder,
          (
            DeviceInfoData,
            BaseReferences<_$AppDatabase, $DeviceInfoTable, DeviceInfoData>,
          ),
          DeviceInfoData,
          PrefetchHooks Function()
        > {
  $$DeviceInfoTableTableManager(_$AppDatabase db, $DeviceInfoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceInfoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceInfoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceInfoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serial = const Value.absent(),
                Value<String?> mac = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> hwVersion = const Value.absent(),
                Value<String?> fwVersion = const Value.absent(),
                Value<String?> dspVersion = const Value.absent(),
                Value<int?> lastSeenTs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceInfoCompanion(
                id: id,
                serial: serial,
                mac: mac,
                model: model,
                name: name,
                hwVersion: hwVersion,
                fwVersion: fwVersion,
                dspVersion: dspVersion,
                lastSeenTs: lastSeenTs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serial = const Value.absent(),
                Value<String?> mac = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> hwVersion = const Value.absent(),
                Value<String?> fwVersion = const Value.absent(),
                Value<String?> dspVersion = const Value.absent(),
                Value<int?> lastSeenTs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceInfoCompanion.insert(
                id: id,
                serial: serial,
                mac: mac,
                model: model,
                name: name,
                hwVersion: hwVersion,
                fwVersion: fwVersion,
                dspVersion: dspVersion,
                lastSeenTs: lastSeenTs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceInfoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceInfoTable,
      DeviceInfoData,
      $$DeviceInfoTableFilterComposer,
      $$DeviceInfoTableOrderingComposer,
      $$DeviceInfoTableAnnotationComposer,
      $$DeviceInfoTableCreateCompanionBuilder,
      $$DeviceInfoTableUpdateCompanionBuilder,
      (
        DeviceInfoData,
        BaseReferences<_$AppDatabase, $DeviceInfoTable, DeviceInfoData>,
      ),
      DeviceInfoData,
      PrefetchHooks Function()
    >;
typedef $$StressSamplesTableCreateCompanionBuilder =
    StressSamplesCompanion Function({Value<int> ts, required double value});
typedef $$StressSamplesTableUpdateCompanionBuilder =
    StressSamplesCompanion Function({Value<int> ts, Value<double> value});

class $$StressSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $StressSamplesTable> {
  $$StressSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StressSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $StressSamplesTable> {
  $$StressSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StressSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StressSamplesTable> {
  $$StressSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$StressSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StressSamplesTable,
          StressSample,
          $$StressSamplesTableFilterComposer,
          $$StressSamplesTableOrderingComposer,
          $$StressSamplesTableAnnotationComposer,
          $$StressSamplesTableCreateCompanionBuilder,
          $$StressSamplesTableUpdateCompanionBuilder,
          (
            StressSample,
            BaseReferences<_$AppDatabase, $StressSamplesTable, StressSample>,
          ),
          StressSample,
          PrefetchHooks Function()
        > {
  $$StressSamplesTableTableManager(_$AppDatabase db, $StressSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StressSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StressSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StressSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                Value<double> value = const Value.absent(),
              }) => StressSamplesCompanion(ts: ts, value: value),
          createCompanionCallback:
              ({Value<int> ts = const Value.absent(), required double value}) =>
                  StressSamplesCompanion.insert(ts: ts, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StressSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StressSamplesTable,
      StressSample,
      $$StressSamplesTableFilterComposer,
      $$StressSamplesTableOrderingComposer,
      $$StressSamplesTableAnnotationComposer,
      $$StressSamplesTableCreateCompanionBuilder,
      $$StressSamplesTableUpdateCompanionBuilder,
      (
        StressSample,
        BaseReferences<_$AppDatabase, $StressSamplesTable, StressSample>,
      ),
      StressSample,
      PrefetchHooks Function()
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      required int ts,
      required String kind,
      Value<String?> payloadJson,
      Value<int> rowid,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> ts,
      Value<String> kind,
      Value<String?> payloadJson,
      Value<int> rowid,
    });

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
          Event,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ts = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                ts: ts,
                kind: kind,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int ts,
                required String kind,
                Value<String?> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                ts: ts,
                kind: kind,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
      Event,
      PrefetchHooks Function()
    >;
typedef $$BodyMeasurementsTableCreateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      required String day,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<int?> maxHr,
      Value<int> rowid,
    });
typedef $$BodyMeasurementsTableUpdateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<String> day,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<int?> maxHr,
      Value<int> rowid,
    });

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurement,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (
            BodyMeasurement,
            BaseReferences<
              _$AppDatabase,
              $BodyMeasurementsTable,
              BodyMeasurement
            >,
          ),
          BodyMeasurement,
          PrefetchHooks Function()
        > {
  $$BodyMeasurementsTableTableManager(
    _$AppDatabase db,
    $BodyMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                day: day,
                heightCm: heightCm,
                weightKg: weightKg,
                maxHr: maxHr,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                day: day,
                heightCm: heightCm,
                weightKg: weightKg,
                maxHr: maxHr,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurement,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (
        BodyMeasurement,
        BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>,
      ),
      BodyMeasurement,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      required String day,
      required String questionId,
      Value<bool> answeredYes,
      Value<double?> numericValue,
      Value<String?> unit,
      Value<String?> timeLabel,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<String> day,
      Value<String> questionId,
      Value<bool> answeredYes,
      Value<double?> numericValue,
      Value<String?> unit,
      Value<String?> timeLabel,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get answeredYes => $composableBuilder(
    column: $table.answeredYes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get numericValue => $composableBuilder(
    column: $table.numericValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeLabel => $composableBuilder(
    column: $table.timeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get answeredYes => $composableBuilder(
    column: $table.answeredYes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get numericValue => $composableBuilder(
    column: $table.numericValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeLabel => $composableBuilder(
    column: $table.timeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get answeredYes => $composableBuilder(
    column: $table.answeredYes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get numericValue => $composableBuilder(
    column: $table.numericValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get timeLabel =>
      $composableBuilder(column: $table.timeLabel, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalEntry,
            BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>,
          ),
          JournalEntry,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<bool> answeredYes = const Value.absent(),
                Value<double?> numericValue = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> timeLabel = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesCompanion(
                day: day,
                questionId: questionId,
                answeredYes: answeredYes,
                numericValue: numericValue,
                unit: unit,
                timeLabel: timeLabel,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required String questionId,
                Value<bool> answeredYes = const Value.absent(),
                Value<double?> numericValue = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> timeLabel = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                day: day,
                questionId: questionId,
                answeredYes: answeredYes,
                numericValue: numericValue,
                unit: unit,
                timeLabel: timeLabel,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalEntry,
        BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>,
      ),
      JournalEntry,
      PrefetchHooks Function()
    >;
typedef $$JournalQuestionsTableCreateCompanionBuilder =
    JournalQuestionsCompanion Function({
      required String questionId,
      Value<String?> category,
      required String title,
      Value<String?> questionText,
      Value<String> questionType,
      Value<String?> unit,
      Value<double?> minVal,
      Value<double?> maxVal,
      Value<double?> interval,
      Value<String?> choicesJson,
      Value<bool> deprecated,
      Value<int> rowid,
    });
typedef $$JournalQuestionsTableUpdateCompanionBuilder =
    JournalQuestionsCompanion Function({
      Value<String> questionId,
      Value<String?> category,
      Value<String> title,
      Value<String?> questionText,
      Value<String> questionType,
      Value<String?> unit,
      Value<double?> minVal,
      Value<double?> maxVal,
      Value<double?> interval,
      Value<String?> choicesJson,
      Value<bool> deprecated,
      Value<int> rowid,
    });

class $$JournalQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $JournalQuestionsTable> {
  $$JournalQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minVal => $composableBuilder(
    column: $table.minVal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxVal => $composableBuilder(
    column: $table.maxVal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choicesJson => $composableBuilder(
    column: $table.choicesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deprecated => $composableBuilder(
    column: $table.deprecated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalQuestionsTable> {
  $$JournalQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minVal => $composableBuilder(
    column: $table.minVal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxVal => $composableBuilder(
    column: $table.maxVal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choicesJson => $composableBuilder(
    column: $table.choicesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deprecated => $composableBuilder(
    column: $table.deprecated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalQuestionsTable> {
  $$JournalQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get minVal =>
      $composableBuilder(column: $table.minVal, builder: (column) => column);

  GeneratedColumn<double> get maxVal =>
      $composableBuilder(column: $table.maxVal, builder: (column) => column);

  GeneratedColumn<double> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<String> get choicesJson => $composableBuilder(
    column: $table.choicesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deprecated => $composableBuilder(
    column: $table.deprecated,
    builder: (column) => column,
  );
}

class $$JournalQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalQuestionsTable,
          JournalQuestion,
          $$JournalQuestionsTableFilterComposer,
          $$JournalQuestionsTableOrderingComposer,
          $$JournalQuestionsTableAnnotationComposer,
          $$JournalQuestionsTableCreateCompanionBuilder,
          $$JournalQuestionsTableUpdateCompanionBuilder,
          (
            JournalQuestion,
            BaseReferences<
              _$AppDatabase,
              $JournalQuestionsTable,
              JournalQuestion
            >,
          ),
          JournalQuestion,
          PrefetchHooks Function()
        > {
  $$JournalQuestionsTableTableManager(
    _$AppDatabase db,
    $JournalQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> questionText = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double?> minVal = const Value.absent(),
                Value<double?> maxVal = const Value.absent(),
                Value<double?> interval = const Value.absent(),
                Value<String?> choicesJson = const Value.absent(),
                Value<bool> deprecated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalQuestionsCompanion(
                questionId: questionId,
                category: category,
                title: title,
                questionText: questionText,
                questionType: questionType,
                unit: unit,
                minVal: minVal,
                maxVal: maxVal,
                interval: interval,
                choicesJson: choicesJson,
                deprecated: deprecated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                Value<String?> category = const Value.absent(),
                required String title,
                Value<String?> questionText = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double?> minVal = const Value.absent(),
                Value<double?> maxVal = const Value.absent(),
                Value<double?> interval = const Value.absent(),
                Value<String?> choicesJson = const Value.absent(),
                Value<bool> deprecated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalQuestionsCompanion.insert(
                questionId: questionId,
                category: category,
                title: title,
                questionText: questionText,
                questionType: questionType,
                unit: unit,
                minVal: minVal,
                maxVal: maxVal,
                interval: interval,
                choicesJson: choicesJson,
                deprecated: deprecated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalQuestionsTable,
      JournalQuestion,
      $$JournalQuestionsTableFilterComposer,
      $$JournalQuestionsTableOrderingComposer,
      $$JournalQuestionsTableAnnotationComposer,
      $$JournalQuestionsTableCreateCompanionBuilder,
      $$JournalQuestionsTableUpdateCompanionBuilder,
      (
        JournalQuestion,
        BaseReferences<_$AppDatabase, $JournalQuestionsTable, JournalQuestion>,
      ),
      JournalQuestion,
      PrefetchHooks Function()
    >;
typedef $$WeightLogTableCreateCompanionBuilder =
    WeightLogCompanion Function({
      required String day,
      required double kg,
      Value<int> rowid,
    });
typedef $$WeightLogTableUpdateCompanionBuilder =
    WeightLogCompanion Function({
      Value<String> day,
      Value<double> kg,
      Value<int> rowid,
    });

class $$WeightLogTableFilterComposer
    extends Composer<_$AppDatabase, $WeightLogTable> {
  $$WeightLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightLogTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightLogTable> {
  $$WeightLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightLogTable> {
  $$WeightLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);
}

class $$WeightLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightLogTable,
          WeightLogData,
          $$WeightLogTableFilterComposer,
          $$WeightLogTableOrderingComposer,
          $$WeightLogTableAnnotationComposer,
          $$WeightLogTableCreateCompanionBuilder,
          $$WeightLogTableUpdateCompanionBuilder,
          (
            WeightLogData,
            BaseReferences<_$AppDatabase, $WeightLogTable, WeightLogData>,
          ),
          WeightLogData,
          PrefetchHooks Function()
        > {
  $$WeightLogTableTableManager(_$AppDatabase db, $WeightLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<double> kg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightLogCompanion(day: day, kg: kg, rowid: rowid),
          createCompanionCallback:
              ({
                required String day,
                required double kg,
                Value<int> rowid = const Value.absent(),
              }) => WeightLogCompanion.insert(day: day, kg: kg, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightLogTable,
      WeightLogData,
      $$WeightLogTableFilterComposer,
      $$WeightLogTableOrderingComposer,
      $$WeightLogTableAnnotationComposer,
      $$WeightLogTableCreateCompanionBuilder,
      $$WeightLogTableUpdateCompanionBuilder,
      (
        WeightLogData,
        BaseReferences<_$AppDatabase, $WeightLogTable, WeightLogData>,
      ),
      WeightLogData,
      PrefetchHooks Function()
    >;
typedef $$WaterLogTableCreateCompanionBuilder =
    WaterLogCompanion Function({
      required String day,
      required double ml,
      Value<int> rowid,
    });
typedef $$WaterLogTableUpdateCompanionBuilder =
    WaterLogCompanion Function({
      Value<String> day,
      Value<double> ml,
      Value<int> rowid,
    });

class $$WaterLogTableFilterComposer
    extends Composer<_$AppDatabase, $WaterLogTable> {
  $$WaterLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterLogTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterLogTable> {
  $$WaterLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterLogTable> {
  $$WaterLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);
}

class $$WaterLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterLogTable,
          WaterLogData,
          $$WaterLogTableFilterComposer,
          $$WaterLogTableOrderingComposer,
          $$WaterLogTableAnnotationComposer,
          $$WaterLogTableCreateCompanionBuilder,
          $$WaterLogTableUpdateCompanionBuilder,
          (
            WaterLogData,
            BaseReferences<_$AppDatabase, $WaterLogTable, WaterLogData>,
          ),
          WaterLogData,
          PrefetchHooks Function()
        > {
  $$WaterLogTableTableManager(_$AppDatabase db, $WaterLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<double> ml = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterLogCompanion(day: day, ml: ml, rowid: rowid),
          createCompanionCallback:
              ({
                required String day,
                required double ml,
                Value<int> rowid = const Value.absent(),
              }) => WaterLogCompanion.insert(day: day, ml: ml, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterLogTable,
      WaterLogData,
      $$WaterLogTableFilterComposer,
      $$WaterLogTableOrderingComposer,
      $$WaterLogTableAnnotationComposer,
      $$WaterLogTableCreateCompanionBuilder,
      $$WaterLogTableUpdateCompanionBuilder,
      (
        WaterLogData,
        BaseReferences<_$AppDatabase, $WaterLogTable, WaterLogData>,
      ),
      WaterLogData,
      PrefetchHooks Function()
    >;
typedef $$AlarmsTableCreateCompanionBuilder =
    AlarmsCompanion Function({
      required String id,
      required int hour,
      required int minute,
      Value<bool> enabled,
      Value<int> daysMask,
      Value<String> status,
      Value<int?> lastArmedTs,
      Value<int> rowid,
    });
typedef $$AlarmsTableUpdateCompanionBuilder =
    AlarmsCompanion Function({
      Value<String> id,
      Value<int> hour,
      Value<int> minute,
      Value<bool> enabled,
      Value<int> daysMask,
      Value<String> status,
      Value<int?> lastArmedTs,
      Value<int> rowid,
    });

class $$AlarmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysMask => $composableBuilder(
    column: $table.daysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastArmedTs => $composableBuilder(
    column: $table.lastArmedTs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysMask => $composableBuilder(
    column: $table.daysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastArmedTs => $composableBuilder(
    column: $table.lastArmedTs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get daysMask =>
      $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get lastArmedTs => $composableBuilder(
    column: $table.lastArmedTs,
    builder: (column) => column,
  );
}

class $$AlarmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmsTable,
          Alarm,
          $$AlarmsTableFilterComposer,
          $$AlarmsTableOrderingComposer,
          $$AlarmsTableAnnotationComposer,
          $$AlarmsTableCreateCompanionBuilder,
          $$AlarmsTableUpdateCompanionBuilder,
          (Alarm, BaseReferences<_$AppDatabase, $AlarmsTable, Alarm>),
          Alarm,
          PrefetchHooks Function()
        > {
  $$AlarmsTableTableManager(_$AppDatabase db, $AlarmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> lastArmedTs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmsCompanion(
                id: id,
                hour: hour,
                minute: minute,
                enabled: enabled,
                daysMask: daysMask,
                status: status,
                lastArmedTs: lastArmedTs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int hour,
                required int minute,
                Value<bool> enabled = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> lastArmedTs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmsCompanion.insert(
                id: id,
                hour: hour,
                minute: minute,
                enabled: enabled,
                daysMask: daysMask,
                status: status,
                lastArmedTs: lastArmedTs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmsTable,
      Alarm,
      $$AlarmsTableFilterComposer,
      $$AlarmsTableOrderingComposer,
      $$AlarmsTableAnnotationComposer,
      $$AlarmsTableCreateCompanionBuilder,
      $$AlarmsTableUpdateCompanionBuilder,
      (Alarm, BaseReferences<_$AppDatabase, $AlarmsTable, Alarm>),
      Alarm,
      PrefetchHooks Function()
    >;
typedef $$MetricSamplesTableCreateCompanionBuilder =
    MetricSamplesCompanion Function({
      required String day,
      required String key,
      required double value,
      Value<String?> unit,
      Value<int> rowid,
    });
typedef $$MetricSamplesTableUpdateCompanionBuilder =
    MetricSamplesCompanion Function({
      Value<String> day,
      Value<String> key,
      Value<double> value,
      Value<String?> unit,
      Value<int> rowid,
    });

class $$MetricSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $MetricSamplesTable> {
  $$MetricSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $MetricSamplesTable> {
  $$MetricSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetricSamplesTable> {
  $$MetricSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);
}

class $$MetricSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricSamplesTable,
          MetricSample,
          $$MetricSamplesTableFilterComposer,
          $$MetricSamplesTableOrderingComposer,
          $$MetricSamplesTableAnnotationComposer,
          $$MetricSamplesTableCreateCompanionBuilder,
          $$MetricSamplesTableUpdateCompanionBuilder,
          (
            MetricSample,
            BaseReferences<_$AppDatabase, $MetricSamplesTable, MetricSample>,
          ),
          MetricSample,
          PrefetchHooks Function()
        > {
  $$MetricSamplesTableTableManager(_$AppDatabase db, $MetricSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricSamplesCompanion(
                day: day,
                key: key,
                value: value,
                unit: unit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required String key,
                required double value,
                Value<String?> unit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricSamplesCompanion.insert(
                day: day,
                key: key,
                value: value,
                unit: unit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricSamplesTable,
      MetricSample,
      $$MetricSamplesTableFilterComposer,
      $$MetricSamplesTableOrderingComposer,
      $$MetricSamplesTableAnnotationComposer,
      $$MetricSamplesTableCreateCompanionBuilder,
      $$MetricSamplesTableUpdateCompanionBuilder,
      (
        MetricSample,
        BaseReferences<_$AppDatabase, $MetricSamplesTable, MetricSample>,
      ),
      MetricSample,
      PrefetchHooks Function()
    >;
typedef $$FoodItemsTableCreateCompanionBuilder =
    FoodItemsCompanion Function({
      required String id,
      required String name,
      Value<String?> brand,
      Value<String?> imageUrl,
      Value<String?> servingSizeRaw,
      Value<double?> servingGrams,
      Value<double?> kcal100,
      Value<double?> carbs100,
      Value<double?> protein100,
      Value<double?> fat100,
      Value<double?> sugar100,
      Value<double?> fiber100,
      Value<double?> salt100,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$FoodItemsTableUpdateCompanionBuilder =
    FoodItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> brand,
      Value<String?> imageUrl,
      Value<String?> servingSizeRaw,
      Value<double?> servingGrams,
      Value<double?> kcal100,
      Value<double?> carbs100,
      Value<double?> protein100,
      Value<double?> fat100,
      Value<double?> sugar100,
      Value<double?> fiber100,
      Value<double?> salt100,
      Value<String> source,
      Value<int> rowid,
    });

class $$FoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingSizeRaw => $composableBuilder(
    column: $table.servingSizeRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiber100 => $composableBuilder(
    column: $table.fiber100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salt100 => $composableBuilder(
    column: $table.salt100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingSizeRaw => $composableBuilder(
    column: $table.servingSizeRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiber100 => $composableBuilder(
    column: $table.fiber100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salt100 => $composableBuilder(
    column: $table.salt100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get servingSizeRaw => $composableBuilder(
    column: $table.servingSizeRaw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kcal100 =>
      $composableBuilder(column: $table.kcal100, builder: (column) => column);

  GeneratedColumn<double> get carbs100 =>
      $composableBuilder(column: $table.carbs100, builder: (column) => column);

  GeneratedColumn<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fat100 =>
      $composableBuilder(column: $table.fat100, builder: (column) => column);

  GeneratedColumn<double> get sugar100 =>
      $composableBuilder(column: $table.sugar100, builder: (column) => column);

  GeneratedColumn<double> get fiber100 =>
      $composableBuilder(column: $table.fiber100, builder: (column) => column);

  GeneratedColumn<double> get salt100 =>
      $composableBuilder(column: $table.salt100, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$FoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodItemsTable,
          FoodItem,
          $$FoodItemsTableFilterComposer,
          $$FoodItemsTableOrderingComposer,
          $$FoodItemsTableAnnotationComposer,
          $$FoodItemsTableCreateCompanionBuilder,
          $$FoodItemsTableUpdateCompanionBuilder,
          (FoodItem, BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>),
          FoodItem,
          PrefetchHooks Function()
        > {
  $$FoodItemsTableTableManager(_$AppDatabase db, $FoodItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> servingSizeRaw = const Value.absent(),
                Value<double?> servingGrams = const Value.absent(),
                Value<double?> kcal100 = const Value.absent(),
                Value<double?> carbs100 = const Value.absent(),
                Value<double?> protein100 = const Value.absent(),
                Value<double?> fat100 = const Value.absent(),
                Value<double?> sugar100 = const Value.absent(),
                Value<double?> fiber100 = const Value.absent(),
                Value<double?> salt100 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion(
                id: id,
                name: name,
                brand: brand,
                imageUrl: imageUrl,
                servingSizeRaw: servingSizeRaw,
                servingGrams: servingGrams,
                kcal100: kcal100,
                carbs100: carbs100,
                protein100: protein100,
                fat100: fat100,
                sugar100: sugar100,
                fiber100: fiber100,
                salt100: salt100,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> servingSizeRaw = const Value.absent(),
                Value<double?> servingGrams = const Value.absent(),
                Value<double?> kcal100 = const Value.absent(),
                Value<double?> carbs100 = const Value.absent(),
                Value<double?> protein100 = const Value.absent(),
                Value<double?> fat100 = const Value.absent(),
                Value<double?> sugar100 = const Value.absent(),
                Value<double?> fiber100 = const Value.absent(),
                Value<double?> salt100 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                imageUrl: imageUrl,
                servingSizeRaw: servingSizeRaw,
                servingGrams: servingGrams,
                kcal100: kcal100,
                carbs100: carbs100,
                protein100: protein100,
                fat100: fat100,
                sugar100: sugar100,
                fiber100: fiber100,
                salt100: salt100,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodItemsTable,
      FoodItem,
      $$FoodItemsTableFilterComposer,
      $$FoodItemsTableOrderingComposer,
      $$FoodItemsTableAnnotationComposer,
      $$FoodItemsTableCreateCompanionBuilder,
      $$FoodItemsTableUpdateCompanionBuilder,
      (FoodItem, BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>),
      FoodItem,
      PrefetchHooks Function()
    >;
typedef $$MealsTableCreateCompanionBuilder =
    MealsCompanion Function({
      required String id,
      required String day,
      required String type,
      required int createdTs,
      Value<int> rowid,
    });
typedef $$MealsTableUpdateCompanionBuilder =
    MealsCompanion Function({
      Value<String> id,
      Value<String> day,
      Value<String> type,
      Value<int> createdTs,
      Value<int> rowid,
    });

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FoodEntriesTable, List<FoodEntry>>
  _foodEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.foodEntries,
    aliasName: 'meals__id__food_entries__meal_id',
  );

  $$FoodEntriesTableProcessedTableManager get foodEntriesRefs {
    final manager = $$FoodEntriesTableTableManager(
      $_db,
      $_db.foodEntries,
    ).filter((f) => f.mealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_foodEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdTs => $composableBuilder(
    column: $table.createdTs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> foodEntriesRefs(
    Expression<bool> Function($$FoodEntriesTableFilterComposer f) f,
  ) {
    final $$FoodEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodEntries,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodEntriesTableFilterComposer(
            $db: $db,
            $table: $db.foodEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdTs => $composableBuilder(
    column: $table.createdTs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createdTs =>
      $composableBuilder(column: $table.createdTs, builder: (column) => column);

  Expression<T> foodEntriesRefs<T extends Object>(
    Expression<T> Function($$FoodEntriesTableAnnotationComposer a) f,
  ) {
    final $$FoodEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodEntries,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.foodEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealsTable,
          Meal,
          $$MealsTableFilterComposer,
          $$MealsTableOrderingComposer,
          $$MealsTableAnnotationComposer,
          $$MealsTableCreateCompanionBuilder,
          $$MealsTableUpdateCompanionBuilder,
          (Meal, $$MealsTableReferences),
          Meal,
          PrefetchHooks Function({bool foodEntriesRefs})
        > {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createdTs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion(
                id: id,
                day: day,
                type: type,
                createdTs: createdTs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required String type,
                required int createdTs,
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion.insert(
                id: id,
                day: day,
                type: type,
                createdTs: createdTs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MealsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({foodEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (foodEntriesRefs) db.foodEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (foodEntriesRefs)
                    await $_getPrefetchedData<Meal, $MealsTable, FoodEntry>(
                      currentTable: table,
                      referencedTable: $$MealsTableReferences
                          ._foodEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MealsTableReferences(db, table, p0).foodEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mealId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealsTable,
      Meal,
      $$MealsTableFilterComposer,
      $$MealsTableOrderingComposer,
      $$MealsTableAnnotationComposer,
      $$MealsTableCreateCompanionBuilder,
      $$MealsTableUpdateCompanionBuilder,
      (Meal, $$MealsTableReferences),
      Meal,
      PrefetchHooks Function({bool foodEntriesRefs})
    >;
typedef $$FoodEntriesTableCreateCompanionBuilder =
    FoodEntriesCompanion Function({
      required String id,
      required String mealId,
      Value<String?> foodItemId,
      required String name,
      required double grams,
      required double kcal,
      Value<double> carbs,
      Value<double> protein,
      Value<double> fat,
      Value<int> rowid,
    });
typedef $$FoodEntriesTableUpdateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<String> id,
      Value<String> mealId,
      Value<String?> foodItemId,
      Value<String> name,
      Value<double> grams,
      Value<double> kcal,
      Value<double> carbs,
      Value<double> protein,
      Value<double> fat,
      Value<int> rowid,
    });

final class $$FoodEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry> {
  $$FoodEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealsTable _mealIdTable(_$AppDatabase db) =>
      db.meals.createAlias('food_entries__meal_id__meals__id');

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<String>('meal_id')!;

    final manager = $$MealsTableTableManager(
      $_db,
      $_db.meals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableFilterComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableOrderingComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get foodItemId => $composableBuilder(
    column: $table.foodItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableAnnotationComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodEntriesTable,
          FoodEntry,
          $$FoodEntriesTableFilterComposer,
          $$FoodEntriesTableOrderingComposer,
          $$FoodEntriesTableAnnotationComposer,
          $$FoodEntriesTableCreateCompanionBuilder,
          $$FoodEntriesTableUpdateCompanionBuilder,
          (FoodEntry, $$FoodEntriesTableReferences),
          FoodEntry,
          PrefetchHooks Function({bool mealId})
        > {
  $$FoodEntriesTableTableManager(_$AppDatabase db, $FoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mealId = const Value.absent(),
                Value<String?> foodItemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodEntriesCompanion(
                id: id,
                mealId: mealId,
                foodItemId: foodItemId,
                name: name,
                grams: grams,
                kcal: kcal,
                carbs: carbs,
                protein: protein,
                fat: fat,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mealId,
                Value<String?> foodItemId = const Value.absent(),
                required String name,
                required double grams,
                required double kcal,
                Value<double> carbs = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodEntriesCompanion.insert(
                id: id,
                mealId: mealId,
                foodItemId: foodItemId,
                name: name,
                grams: grams,
                kcal: kcal,
                carbs: carbs,
                protein: protein,
                fat: fat,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoodEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mealId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mealId,
                                referencedTable: $$FoodEntriesTableReferences
                                    ._mealIdTable(db),
                                referencedColumn: $$FoodEntriesTableReferences
                                    ._mealIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodEntriesTable,
      FoodEntry,
      $$FoodEntriesTableFilterComposer,
      $$FoodEntriesTableOrderingComposer,
      $$FoodEntriesTableAnnotationComposer,
      $$FoodEntriesTableCreateCompanionBuilder,
      $$FoodEntriesTableUpdateCompanionBuilder,
      (FoodEntry, $$FoodEntriesTableReferences),
      FoodEntry,
      PrefetchHooks Function({bool mealId})
    >;
typedef $$WhoopHrSamplesTableCreateCompanionBuilder =
    WhoopHrSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int bpm,
      Value<int?> hrFixed88,
      Value<int?> onwrist,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopHrSamplesTableUpdateCompanionBuilder =
    WhoopHrSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> bpm,
      Value<int?> hrFixed88,
      Value<int?> onwrist,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopHrSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopHrSamplesTable> {
  $$WhoopHrSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrFixed88 => $composableBuilder(
    column: $table.hrFixed88,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onwrist => $composableBuilder(
    column: $table.onwrist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopHrSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopHrSamplesTable> {
  $$WhoopHrSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrFixed88 => $composableBuilder(
    column: $table.hrFixed88,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onwrist => $composableBuilder(
    column: $table.onwrist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopHrSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopHrSamplesTable> {
  $$WhoopHrSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<int> get hrFixed88 =>
      $composableBuilder(column: $table.hrFixed88, builder: (column) => column);

  GeneratedColumn<int> get onwrist =>
      $composableBuilder(column: $table.onwrist, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopHrSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopHrSamplesTable,
          WhoopHrSample,
          $$WhoopHrSamplesTableFilterComposer,
          $$WhoopHrSamplesTableOrderingComposer,
          $$WhoopHrSamplesTableAnnotationComposer,
          $$WhoopHrSamplesTableCreateCompanionBuilder,
          $$WhoopHrSamplesTableUpdateCompanionBuilder,
          (
            WhoopHrSample,
            BaseReferences<_$AppDatabase, $WhoopHrSamplesTable, WhoopHrSample>,
          ),
          WhoopHrSample,
          PrefetchHooks Function()
        > {
  $$WhoopHrSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopHrSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopHrSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopHrSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopHrSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<int?> hrFixed88 = const Value.absent(),
                Value<int?> onwrist = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopHrSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                bpm: bpm,
                hrFixed88: hrFixed88,
                onwrist: onwrist,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int bpm,
                Value<int?> hrFixed88 = const Value.absent(),
                Value<int?> onwrist = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopHrSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                bpm: bpm,
                hrFixed88: hrFixed88,
                onwrist: onwrist,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopHrSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopHrSamplesTable,
      WhoopHrSample,
      $$WhoopHrSamplesTableFilterComposer,
      $$WhoopHrSamplesTableOrderingComposer,
      $$WhoopHrSamplesTableAnnotationComposer,
      $$WhoopHrSamplesTableCreateCompanionBuilder,
      $$WhoopHrSamplesTableUpdateCompanionBuilder,
      (
        WhoopHrSample,
        BaseReferences<_$AppDatabase, $WhoopHrSamplesTable, WhoopHrSample>,
      ),
      WhoopHrSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopPpgHrSamplesTableCreateCompanionBuilder =
    WhoopPpgHrSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int bpm,
      required double conf,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopPpgHrSamplesTableUpdateCompanionBuilder =
    WhoopPpgHrSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> bpm,
      Value<double> conf,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopPpgHrSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopPpgHrSamplesTable> {
  $$WhoopPpgHrSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get conf => $composableBuilder(
    column: $table.conf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopPpgHrSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopPpgHrSamplesTable> {
  $$WhoopPpgHrSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get conf => $composableBuilder(
    column: $table.conf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopPpgHrSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopPpgHrSamplesTable> {
  $$WhoopPpgHrSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<double> get conf =>
      $composableBuilder(column: $table.conf, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopPpgHrSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopPpgHrSamplesTable,
          WhoopPpgHrSample,
          $$WhoopPpgHrSamplesTableFilterComposer,
          $$WhoopPpgHrSamplesTableOrderingComposer,
          $$WhoopPpgHrSamplesTableAnnotationComposer,
          $$WhoopPpgHrSamplesTableCreateCompanionBuilder,
          $$WhoopPpgHrSamplesTableUpdateCompanionBuilder,
          (
            WhoopPpgHrSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopPpgHrSamplesTable,
              WhoopPpgHrSample
            >,
          ),
          WhoopPpgHrSample,
          PrefetchHooks Function()
        > {
  $$WhoopPpgHrSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopPpgHrSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopPpgHrSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopPpgHrSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopPpgHrSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<double> conf = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopPpgHrSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                bpm: bpm,
                conf: conf,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int bpm,
                required double conf,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopPpgHrSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                bpm: bpm,
                conf: conf,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopPpgHrSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopPpgHrSamplesTable,
      WhoopPpgHrSample,
      $$WhoopPpgHrSamplesTableFilterComposer,
      $$WhoopPpgHrSamplesTableOrderingComposer,
      $$WhoopPpgHrSamplesTableAnnotationComposer,
      $$WhoopPpgHrSamplesTableCreateCompanionBuilder,
      $$WhoopPpgHrSamplesTableUpdateCompanionBuilder,
      (
        WhoopPpgHrSample,
        BaseReferences<
          _$AppDatabase,
          $WhoopPpgHrSamplesTable,
          WhoopPpgHrSample
        >,
      ),
      WhoopPpgHrSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopPpgRawSamplesTableCreateCompanionBuilder =
    WhoopPpgRawSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int sampleCount,
      required Uint8List samples,
      Value<int> rowid,
    });
typedef $$WhoopPpgRawSamplesTableUpdateCompanionBuilder =
    WhoopPpgRawSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> sampleCount,
      Value<Uint8List> samples,
      Value<int> rowid,
    });

class $$WhoopPpgRawSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopPpgRawSamplesTable> {
  $$WhoopPpgRawSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get samples => $composableBuilder(
    column: $table.samples,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopPpgRawSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopPpgRawSamplesTable> {
  $$WhoopPpgRawSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get samples => $composableBuilder(
    column: $table.samples,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopPpgRawSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopPpgRawSamplesTable> {
  $$WhoopPpgRawSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get samples =>
      $composableBuilder(column: $table.samples, builder: (column) => column);
}

class $$WhoopPpgRawSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopPpgRawSamplesTable,
          WhoopPpgRawSample,
          $$WhoopPpgRawSamplesTableFilterComposer,
          $$WhoopPpgRawSamplesTableOrderingComposer,
          $$WhoopPpgRawSamplesTableAnnotationComposer,
          $$WhoopPpgRawSamplesTableCreateCompanionBuilder,
          $$WhoopPpgRawSamplesTableUpdateCompanionBuilder,
          (
            WhoopPpgRawSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopPpgRawSamplesTable,
              WhoopPpgRawSample
            >,
          ),
          WhoopPpgRawSample,
          PrefetchHooks Function()
        > {
  $$WhoopPpgRawSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopPpgRawSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopPpgRawSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopPpgRawSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopPpgRawSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<Uint8List> samples = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopPpgRawSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                sampleCount: sampleCount,
                samples: samples,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int sampleCount,
                required Uint8List samples,
                Value<int> rowid = const Value.absent(),
              }) => WhoopPpgRawSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                sampleCount: sampleCount,
                samples: samples,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopPpgRawSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopPpgRawSamplesTable,
      WhoopPpgRawSample,
      $$WhoopPpgRawSamplesTableFilterComposer,
      $$WhoopPpgRawSamplesTableOrderingComposer,
      $$WhoopPpgRawSamplesTableAnnotationComposer,
      $$WhoopPpgRawSamplesTableCreateCompanionBuilder,
      $$WhoopPpgRawSamplesTableUpdateCompanionBuilder,
      (
        WhoopPpgRawSample,
        BaseReferences<
          _$AppDatabase,
          $WhoopPpgRawSamplesTable,
          WhoopPpgRawSample
        >,
      ),
      WhoopPpgRawSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopRrIntervalsTableCreateCompanionBuilder =
    WhoopRrIntervalsCompanion Function({
      required String deviceId,
      required int ts,
      required int rrMs,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopRrIntervalsTableUpdateCompanionBuilder =
    WhoopRrIntervalsCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> rrMs,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopRrIntervalsTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopRrIntervalsTable> {
  $$WhoopRrIntervalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rrMs => $composableBuilder(
    column: $table.rrMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopRrIntervalsTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopRrIntervalsTable> {
  $$WhoopRrIntervalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rrMs => $composableBuilder(
    column: $table.rrMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopRrIntervalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopRrIntervalsTable> {
  $$WhoopRrIntervalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get rrMs =>
      $composableBuilder(column: $table.rrMs, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopRrIntervalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopRrIntervalsTable,
          WhoopRrInterval,
          $$WhoopRrIntervalsTableFilterComposer,
          $$WhoopRrIntervalsTableOrderingComposer,
          $$WhoopRrIntervalsTableAnnotationComposer,
          $$WhoopRrIntervalsTableCreateCompanionBuilder,
          $$WhoopRrIntervalsTableUpdateCompanionBuilder,
          (
            WhoopRrInterval,
            BaseReferences<
              _$AppDatabase,
              $WhoopRrIntervalsTable,
              WhoopRrInterval
            >,
          ),
          WhoopRrInterval,
          PrefetchHooks Function()
        > {
  $$WhoopRrIntervalsTableTableManager(
    _$AppDatabase db,
    $WhoopRrIntervalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopRrIntervalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopRrIntervalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopRrIntervalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> rrMs = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopRrIntervalsCompanion(
                deviceId: deviceId,
                ts: ts,
                rrMs: rrMs,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int rrMs,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopRrIntervalsCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                rrMs: rrMs,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopRrIntervalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopRrIntervalsTable,
      WhoopRrInterval,
      $$WhoopRrIntervalsTableFilterComposer,
      $$WhoopRrIntervalsTableOrderingComposer,
      $$WhoopRrIntervalsTableAnnotationComposer,
      $$WhoopRrIntervalsTableCreateCompanionBuilder,
      $$WhoopRrIntervalsTableUpdateCompanionBuilder,
      (
        WhoopRrInterval,
        BaseReferences<_$AppDatabase, $WhoopRrIntervalsTable, WhoopRrInterval>,
      ),
      WhoopRrInterval,
      PrefetchHooks Function()
    >;
typedef $$WhoopEventsTableCreateCompanionBuilder =
    WhoopEventsCompanion Function({
      required String deviceId,
      required int ts,
      required String kind,
      required String payloadJson,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopEventsTableUpdateCompanionBuilder =
    WhoopEventsCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<String> kind,
      Value<String> payloadJson,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopEventsTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopEventsTable> {
  $$WhoopEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopEventsTable> {
  $$WhoopEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopEventsTable> {
  $$WhoopEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopEventsTable,
          WhoopEvent,
          $$WhoopEventsTableFilterComposer,
          $$WhoopEventsTableOrderingComposer,
          $$WhoopEventsTableAnnotationComposer,
          $$WhoopEventsTableCreateCompanionBuilder,
          $$WhoopEventsTableUpdateCompanionBuilder,
          (
            WhoopEvent,
            BaseReferences<_$AppDatabase, $WhoopEventsTable, WhoopEvent>,
          ),
          WhoopEvent,
          PrefetchHooks Function()
        > {
  $$WhoopEventsTableTableManager(_$AppDatabase db, $WhoopEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopEventsCompanion(
                deviceId: deviceId,
                ts: ts,
                kind: kind,
                payloadJson: payloadJson,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required String kind,
                required String payloadJson,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopEventsCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                kind: kind,
                payloadJson: payloadJson,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopEventsTable,
      WhoopEvent,
      $$WhoopEventsTableFilterComposer,
      $$WhoopEventsTableOrderingComposer,
      $$WhoopEventsTableAnnotationComposer,
      $$WhoopEventsTableCreateCompanionBuilder,
      $$WhoopEventsTableUpdateCompanionBuilder,
      (
        WhoopEvent,
        BaseReferences<_$AppDatabase, $WhoopEventsTable, WhoopEvent>,
      ),
      WhoopEvent,
      PrefetchHooks Function()
    >;
typedef $$WhoopBatteryTableCreateCompanionBuilder =
    WhoopBatteryCompanion Function({
      required String deviceId,
      required int ts,
      Value<double?> soc,
      Value<int?> mv,
      Value<bool?> charging,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopBatteryTableUpdateCompanionBuilder =
    WhoopBatteryCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<double?> soc,
      Value<int?> mv,
      Value<bool?> charging,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopBatteryTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopBatteryTable> {
  $$WhoopBatteryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get soc => $composableBuilder(
    column: $table.soc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mv => $composableBuilder(
    column: $table.mv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get charging => $composableBuilder(
    column: $table.charging,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopBatteryTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopBatteryTable> {
  $$WhoopBatteryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get soc => $composableBuilder(
    column: $table.soc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mv => $composableBuilder(
    column: $table.mv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get charging => $composableBuilder(
    column: $table.charging,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopBatteryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopBatteryTable> {
  $$WhoopBatteryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get soc =>
      $composableBuilder(column: $table.soc, builder: (column) => column);

  GeneratedColumn<int> get mv =>
      $composableBuilder(column: $table.mv, builder: (column) => column);

  GeneratedColumn<bool> get charging =>
      $composableBuilder(column: $table.charging, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopBatteryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopBatteryTable,
          WhoopBatteryData,
          $$WhoopBatteryTableFilterComposer,
          $$WhoopBatteryTableOrderingComposer,
          $$WhoopBatteryTableAnnotationComposer,
          $$WhoopBatteryTableCreateCompanionBuilder,
          $$WhoopBatteryTableUpdateCompanionBuilder,
          (
            WhoopBatteryData,
            BaseReferences<_$AppDatabase, $WhoopBatteryTable, WhoopBatteryData>,
          ),
          WhoopBatteryData,
          PrefetchHooks Function()
        > {
  $$WhoopBatteryTableTableManager(_$AppDatabase db, $WhoopBatteryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopBatteryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopBatteryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopBatteryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<double?> soc = const Value.absent(),
                Value<int?> mv = const Value.absent(),
                Value<bool?> charging = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopBatteryCompanion(
                deviceId: deviceId,
                ts: ts,
                soc: soc,
                mv: mv,
                charging: charging,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                Value<double?> soc = const Value.absent(),
                Value<int?> mv = const Value.absent(),
                Value<bool?> charging = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopBatteryCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                soc: soc,
                mv: mv,
                charging: charging,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopBatteryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopBatteryTable,
      WhoopBatteryData,
      $$WhoopBatteryTableFilterComposer,
      $$WhoopBatteryTableOrderingComposer,
      $$WhoopBatteryTableAnnotationComposer,
      $$WhoopBatteryTableCreateCompanionBuilder,
      $$WhoopBatteryTableUpdateCompanionBuilder,
      (
        WhoopBatteryData,
        BaseReferences<_$AppDatabase, $WhoopBatteryTable, WhoopBatteryData>,
      ),
      WhoopBatteryData,
      PrefetchHooks Function()
    >;
typedef $$WhoopSpo2SamplesTableCreateCompanionBuilder =
    WhoopSpo2SamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int red,
      required int ir,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopSpo2SamplesTableUpdateCompanionBuilder =
    WhoopSpo2SamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> red,
      Value<int> ir,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopSpo2SamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopSpo2SamplesTable> {
  $$WhoopSpo2SamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get red => $composableBuilder(
    column: $table.red,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ir => $composableBuilder(
    column: $table.ir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopSpo2SamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopSpo2SamplesTable> {
  $$WhoopSpo2SamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get red => $composableBuilder(
    column: $table.red,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ir => $composableBuilder(
    column: $table.ir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopSpo2SamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopSpo2SamplesTable> {
  $$WhoopSpo2SamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get red =>
      $composableBuilder(column: $table.red, builder: (column) => column);

  GeneratedColumn<int> get ir =>
      $composableBuilder(column: $table.ir, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopSpo2SamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopSpo2SamplesTable,
          WhoopSpo2Sample,
          $$WhoopSpo2SamplesTableFilterComposer,
          $$WhoopSpo2SamplesTableOrderingComposer,
          $$WhoopSpo2SamplesTableAnnotationComposer,
          $$WhoopSpo2SamplesTableCreateCompanionBuilder,
          $$WhoopSpo2SamplesTableUpdateCompanionBuilder,
          (
            WhoopSpo2Sample,
            BaseReferences<
              _$AppDatabase,
              $WhoopSpo2SamplesTable,
              WhoopSpo2Sample
            >,
          ),
          WhoopSpo2Sample,
          PrefetchHooks Function()
        > {
  $$WhoopSpo2SamplesTableTableManager(
    _$AppDatabase db,
    $WhoopSpo2SamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopSpo2SamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopSpo2SamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopSpo2SamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> red = const Value.absent(),
                Value<int> ir = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopSpo2SamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                red: red,
                ir: ir,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int red,
                required int ir,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopSpo2SamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                red: red,
                ir: ir,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopSpo2SamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopSpo2SamplesTable,
      WhoopSpo2Sample,
      $$WhoopSpo2SamplesTableFilterComposer,
      $$WhoopSpo2SamplesTableOrderingComposer,
      $$WhoopSpo2SamplesTableAnnotationComposer,
      $$WhoopSpo2SamplesTableCreateCompanionBuilder,
      $$WhoopSpo2SamplesTableUpdateCompanionBuilder,
      (
        WhoopSpo2Sample,
        BaseReferences<_$AppDatabase, $WhoopSpo2SamplesTable, WhoopSpo2Sample>,
      ),
      WhoopSpo2Sample,
      PrefetchHooks Function()
    >;
typedef $$WhoopSkinTempSamplesTableCreateCompanionBuilder =
    WhoopSkinTempSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int raw,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopSkinTempSamplesTableUpdateCompanionBuilder =
    WhoopSkinTempSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> raw,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopSkinTempSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopSkinTempSamplesTable> {
  $$WhoopSkinTempSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopSkinTempSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopSkinTempSamplesTable> {
  $$WhoopSkinTempSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopSkinTempSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopSkinTempSamplesTable> {
  $$WhoopSkinTempSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopSkinTempSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopSkinTempSamplesTable,
          WhoopSkinTempSample,
          $$WhoopSkinTempSamplesTableFilterComposer,
          $$WhoopSkinTempSamplesTableOrderingComposer,
          $$WhoopSkinTempSamplesTableAnnotationComposer,
          $$WhoopSkinTempSamplesTableCreateCompanionBuilder,
          $$WhoopSkinTempSamplesTableUpdateCompanionBuilder,
          (
            WhoopSkinTempSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopSkinTempSamplesTable,
              WhoopSkinTempSample
            >,
          ),
          WhoopSkinTempSample,
          PrefetchHooks Function()
        > {
  $$WhoopSkinTempSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopSkinTempSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopSkinTempSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopSkinTempSamplesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WhoopSkinTempSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> raw = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopSkinTempSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                raw: raw,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int raw,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopSkinTempSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                raw: raw,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopSkinTempSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopSkinTempSamplesTable,
      WhoopSkinTempSample,
      $$WhoopSkinTempSamplesTableFilterComposer,
      $$WhoopSkinTempSamplesTableOrderingComposer,
      $$WhoopSkinTempSamplesTableAnnotationComposer,
      $$WhoopSkinTempSamplesTableCreateCompanionBuilder,
      $$WhoopSkinTempSamplesTableUpdateCompanionBuilder,
      (
        WhoopSkinTempSample,
        BaseReferences<
          _$AppDatabase,
          $WhoopSkinTempSamplesTable,
          WhoopSkinTempSample
        >,
      ),
      WhoopSkinTempSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopStepSamplesTableCreateCompanionBuilder =
    WhoopStepSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int counter,
      Value<int?> activityClass,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopStepSamplesTableUpdateCompanionBuilder =
    WhoopStepSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> counter,
      Value<int?> activityClass,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopStepSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopStepSamplesTable> {
  $$WhoopStepSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activityClass => $composableBuilder(
    column: $table.activityClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopStepSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopStepSamplesTable> {
  $$WhoopStepSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activityClass => $composableBuilder(
    column: $table.activityClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopStepSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopStepSamplesTable> {
  $$WhoopStepSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get counter =>
      $composableBuilder(column: $table.counter, builder: (column) => column);

  GeneratedColumn<int> get activityClass => $composableBuilder(
    column: $table.activityClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopStepSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopStepSamplesTable,
          WhoopStepSample,
          $$WhoopStepSamplesTableFilterComposer,
          $$WhoopStepSamplesTableOrderingComposer,
          $$WhoopStepSamplesTableAnnotationComposer,
          $$WhoopStepSamplesTableCreateCompanionBuilder,
          $$WhoopStepSamplesTableUpdateCompanionBuilder,
          (
            WhoopStepSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopStepSamplesTable,
              WhoopStepSample
            >,
          ),
          WhoopStepSample,
          PrefetchHooks Function()
        > {
  $$WhoopStepSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopStepSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopStepSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopStepSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopStepSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> counter = const Value.absent(),
                Value<int?> activityClass = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopStepSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                counter: counter,
                activityClass: activityClass,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int counter,
                Value<int?> activityClass = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopStepSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                counter: counter,
                activityClass: activityClass,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopStepSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopStepSamplesTable,
      WhoopStepSample,
      $$WhoopStepSamplesTableFilterComposer,
      $$WhoopStepSamplesTableOrderingComposer,
      $$WhoopStepSamplesTableAnnotationComposer,
      $$WhoopStepSamplesTableCreateCompanionBuilder,
      $$WhoopStepSamplesTableUpdateCompanionBuilder,
      (
        WhoopStepSample,
        BaseReferences<_$AppDatabase, $WhoopStepSamplesTable, WhoopStepSample>,
      ),
      WhoopStepSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopSleepStateSamplesTableCreateCompanionBuilder =
    WhoopSleepStateSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int state,
      Value<int> rowid,
    });
typedef $$WhoopSleepStateSamplesTableUpdateCompanionBuilder =
    WhoopSleepStateSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> state,
      Value<int> rowid,
    });

class $$WhoopSleepStateSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopSleepStateSamplesTable> {
  $$WhoopSleepStateSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopSleepStateSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopSleepStateSamplesTable> {
  $$WhoopSleepStateSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopSleepStateSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopSleepStateSamplesTable> {
  $$WhoopSleepStateSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$WhoopSleepStateSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopSleepStateSamplesTable,
          WhoopSleepStateSample,
          $$WhoopSleepStateSamplesTableFilterComposer,
          $$WhoopSleepStateSamplesTableOrderingComposer,
          $$WhoopSleepStateSamplesTableAnnotationComposer,
          $$WhoopSleepStateSamplesTableCreateCompanionBuilder,
          $$WhoopSleepStateSamplesTableUpdateCompanionBuilder,
          (
            WhoopSleepStateSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopSleepStateSamplesTable,
              WhoopSleepStateSample
            >,
          ),
          WhoopSleepStateSample,
          PrefetchHooks Function()
        > {
  $$WhoopSleepStateSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopSleepStateSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopSleepStateSamplesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WhoopSleepStateSamplesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WhoopSleepStateSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopSleepStateSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int state,
                Value<int> rowid = const Value.absent(),
              }) => WhoopSleepStateSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopSleepStateSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopSleepStateSamplesTable,
      WhoopSleepStateSample,
      $$WhoopSleepStateSamplesTableFilterComposer,
      $$WhoopSleepStateSamplesTableOrderingComposer,
      $$WhoopSleepStateSamplesTableAnnotationComposer,
      $$WhoopSleepStateSamplesTableCreateCompanionBuilder,
      $$WhoopSleepStateSamplesTableUpdateCompanionBuilder,
      (
        WhoopSleepStateSample,
        BaseReferences<
          _$AppDatabase,
          $WhoopSleepStateSamplesTable,
          WhoopSleepStateSample
        >,
      ),
      WhoopSleepStateSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopRespSamplesTableCreateCompanionBuilder =
    WhoopRespSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required int raw,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopRespSamplesTableUpdateCompanionBuilder =
    WhoopRespSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<int> raw,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopRespSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopRespSamplesTable> {
  $$WhoopRespSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopRespSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopRespSamplesTable> {
  $$WhoopRespSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopRespSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopRespSamplesTable> {
  $$WhoopRespSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopRespSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopRespSamplesTable,
          WhoopRespSample,
          $$WhoopRespSamplesTableFilterComposer,
          $$WhoopRespSamplesTableOrderingComposer,
          $$WhoopRespSamplesTableAnnotationComposer,
          $$WhoopRespSamplesTableCreateCompanionBuilder,
          $$WhoopRespSamplesTableUpdateCompanionBuilder,
          (
            WhoopRespSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopRespSamplesTable,
              WhoopRespSample
            >,
          ),
          WhoopRespSample,
          PrefetchHooks Function()
        > {
  $$WhoopRespSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopRespSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopRespSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopRespSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WhoopRespSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> raw = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopRespSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                raw: raw,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required int raw,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopRespSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                raw: raw,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopRespSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopRespSamplesTable,
      WhoopRespSample,
      $$WhoopRespSamplesTableFilterComposer,
      $$WhoopRespSamplesTableOrderingComposer,
      $$WhoopRespSamplesTableAnnotationComposer,
      $$WhoopRespSamplesTableCreateCompanionBuilder,
      $$WhoopRespSamplesTableUpdateCompanionBuilder,
      (
        WhoopRespSample,
        BaseReferences<_$AppDatabase, $WhoopRespSamplesTable, WhoopRespSample>,
      ),
      WhoopRespSample,
      PrefetchHooks Function()
    >;
typedef $$WhoopGravitySamplesTableCreateCompanionBuilder =
    WhoopGravitySamplesCompanion Function({
      required String deviceId,
      required int ts,
      required double x,
      required double y,
      required double z,
      Value<double?> dynamicAccel,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$WhoopGravitySamplesTableUpdateCompanionBuilder =
    WhoopGravitySamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<double> x,
      Value<double> y,
      Value<double> z,
      Value<double?> dynamicAccel,
      Value<int> synced,
      Value<int> rowid,
    });

class $$WhoopGravitySamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopGravitySamplesTable> {
  $$WhoopGravitySamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dynamicAccel => $composableBuilder(
    column: $table.dynamicAccel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopGravitySamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopGravitySamplesTable> {
  $$WhoopGravitySamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dynamicAccel => $composableBuilder(
    column: $table.dynamicAccel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopGravitySamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopGravitySamplesTable> {
  $$WhoopGravitySamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get z =>
      $composableBuilder(column: $table.z, builder: (column) => column);

  GeneratedColumn<double> get dynamicAccel => $composableBuilder(
    column: $table.dynamicAccel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$WhoopGravitySamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopGravitySamplesTable,
          WhoopGravitySample,
          $$WhoopGravitySamplesTableFilterComposer,
          $$WhoopGravitySamplesTableOrderingComposer,
          $$WhoopGravitySamplesTableAnnotationComposer,
          $$WhoopGravitySamplesTableCreateCompanionBuilder,
          $$WhoopGravitySamplesTableUpdateCompanionBuilder,
          (
            WhoopGravitySample,
            BaseReferences<
              _$AppDatabase,
              $WhoopGravitySamplesTable,
              WhoopGravitySample
            >,
          ),
          WhoopGravitySample,
          PrefetchHooks Function()
        > {
  $$WhoopGravitySamplesTableTableManager(
    _$AppDatabase db,
    $WhoopGravitySamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopGravitySamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopGravitySamplesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WhoopGravitySamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> z = const Value.absent(),
                Value<double?> dynamicAccel = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopGravitySamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                x: x,
                y: y,
                z: z,
                dynamicAccel: dynamicAccel,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required double x,
                required double y,
                required double z,
                Value<double?> dynamicAccel = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopGravitySamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                x: x,
                y: y,
                z: z,
                dynamicAccel: dynamicAccel,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopGravitySamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopGravitySamplesTable,
      WhoopGravitySample,
      $$WhoopGravitySamplesTableFilterComposer,
      $$WhoopGravitySamplesTableOrderingComposer,
      $$WhoopGravitySamplesTableAnnotationComposer,
      $$WhoopGravitySamplesTableCreateCompanionBuilder,
      $$WhoopGravitySamplesTableUpdateCompanionBuilder,
      (
        WhoopGravitySample,
        BaseReferences<
          _$AppDatabase,
          $WhoopGravitySamplesTable,
          WhoopGravitySample
        >,
      ),
      WhoopGravitySample,
      PrefetchHooks Function()
    >;
typedef $$WhoopRawFieldSamplesTableCreateCompanionBuilder =
    WhoopRawFieldSamplesCompanion Function({
      required String deviceId,
      required int ts,
      required String key,
      Value<int?> intValue,
      Value<double?> realValue,
      Value<int> rowid,
    });
typedef $$WhoopRawFieldSamplesTableUpdateCompanionBuilder =
    WhoopRawFieldSamplesCompanion Function({
      Value<String> deviceId,
      Value<int> ts,
      Value<String> key,
      Value<int?> intValue,
      Value<double?> realValue,
      Value<int> rowid,
    });

class $$WhoopRawFieldSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WhoopRawFieldSamplesTable> {
  $$WhoopRawFieldSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intValue => $composableBuilder(
    column: $table.intValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get realValue => $composableBuilder(
    column: $table.realValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WhoopRawFieldSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WhoopRawFieldSamplesTable> {
  $$WhoopRawFieldSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intValue => $composableBuilder(
    column: $table.intValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get realValue => $composableBuilder(
    column: $table.realValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WhoopRawFieldSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WhoopRawFieldSamplesTable> {
  $$WhoopRawFieldSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get intValue =>
      $composableBuilder(column: $table.intValue, builder: (column) => column);

  GeneratedColumn<double> get realValue =>
      $composableBuilder(column: $table.realValue, builder: (column) => column);
}

class $$WhoopRawFieldSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WhoopRawFieldSamplesTable,
          WhoopRawFieldSample,
          $$WhoopRawFieldSamplesTableFilterComposer,
          $$WhoopRawFieldSamplesTableOrderingComposer,
          $$WhoopRawFieldSamplesTableAnnotationComposer,
          $$WhoopRawFieldSamplesTableCreateCompanionBuilder,
          $$WhoopRawFieldSamplesTableUpdateCompanionBuilder,
          (
            WhoopRawFieldSample,
            BaseReferences<
              _$AppDatabase,
              $WhoopRawFieldSamplesTable,
              WhoopRawFieldSample
            >,
          ),
          WhoopRawFieldSample,
          PrefetchHooks Function()
        > {
  $$WhoopRawFieldSamplesTableTableManager(
    _$AppDatabase db,
    $WhoopRawFieldSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WhoopRawFieldSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WhoopRawFieldSamplesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WhoopRawFieldSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<int?> intValue = const Value.absent(),
                Value<double?> realValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopRawFieldSamplesCompanion(
                deviceId: deviceId,
                ts: ts,
                key: key,
                intValue: intValue,
                realValue: realValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int ts,
                required String key,
                Value<int?> intValue = const Value.absent(),
                Value<double?> realValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WhoopRawFieldSamplesCompanion.insert(
                deviceId: deviceId,
                ts: ts,
                key: key,
                intValue: intValue,
                realValue: realValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WhoopRawFieldSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WhoopRawFieldSamplesTable,
      WhoopRawFieldSample,
      $$WhoopRawFieldSamplesTableFilterComposer,
      $$WhoopRawFieldSamplesTableOrderingComposer,
      $$WhoopRawFieldSamplesTableAnnotationComposer,
      $$WhoopRawFieldSamplesTableCreateCompanionBuilder,
      $$WhoopRawFieldSamplesTableUpdateCompanionBuilder,
      (
        WhoopRawFieldSample,
        BaseReferences<
          _$AppDatabase,
          $WhoopRawFieldSamplesTable,
          WhoopRawFieldSample
        >,
      ),
      WhoopRawFieldSample,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String name,
      required int value,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> name,
      Value<int> value,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SyncCursorsCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required int value,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyMetricsTableTableManager get dailyMetrics =>
      $$DailyMetricsTableTableManager(_db, _db.dailyMetrics);
  $$CyclesTableTableManager get cycles =>
      $$CyclesTableTableManager(_db, _db.cycles);
  $$SleepSessionsTableTableManager get sleepSessions =>
      $$SleepSessionsTableTableManager(_db, _db.sleepSessions);
  $$SleepStateSamplesTableTableManager get sleepStateSamples =>
      $$SleepStateSamplesTableTableManager(_db, _db.sleepStateSamples);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$HrSamplesTableTableManager get hrSamples =>
      $$HrSamplesTableTableManager(_db, _db.hrSamples);
  $$RrSamplesTableTableManager get rrSamples =>
      $$RrSamplesTableTableManager(_db, _db.rrSamples);
  $$AccelSamplesTableTableManager get accelSamples =>
      $$AccelSamplesTableTableManager(_db, _db.accelSamples);
  $$RawSensorArchiveTableTableManager get rawSensorArchive =>
      $$RawSensorArchiveTableTableManager(_db, _db.rawSensorArchive);
  $$BatteryLogTableTableManager get batteryLog =>
      $$BatteryLogTableTableManager(_db, _db.batteryLog);
  $$DeviceInfoTableTableManager get deviceInfo =>
      $$DeviceInfoTableTableManager(_db, _db.deviceInfo);
  $$StressSamplesTableTableManager get stressSamples =>
      $$StressSamplesTableTableManager(_db, _db.stressSamples);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$JournalQuestionsTableTableManager get journalQuestions =>
      $$JournalQuestionsTableTableManager(_db, _db.journalQuestions);
  $$WeightLogTableTableManager get weightLog =>
      $$WeightLogTableTableManager(_db, _db.weightLog);
  $$WaterLogTableTableManager get waterLog =>
      $$WaterLogTableTableManager(_db, _db.waterLog);
  $$AlarmsTableTableManager get alarms =>
      $$AlarmsTableTableManager(_db, _db.alarms);
  $$MetricSamplesTableTableManager get metricSamples =>
      $$MetricSamplesTableTableManager(_db, _db.metricSamples);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db, _db.foodItems);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$WhoopHrSamplesTableTableManager get whoopHrSamples =>
      $$WhoopHrSamplesTableTableManager(_db, _db.whoopHrSamples);
  $$WhoopPpgHrSamplesTableTableManager get whoopPpgHrSamples =>
      $$WhoopPpgHrSamplesTableTableManager(_db, _db.whoopPpgHrSamples);
  $$WhoopPpgRawSamplesTableTableManager get whoopPpgRawSamples =>
      $$WhoopPpgRawSamplesTableTableManager(_db, _db.whoopPpgRawSamples);
  $$WhoopRrIntervalsTableTableManager get whoopRrIntervals =>
      $$WhoopRrIntervalsTableTableManager(_db, _db.whoopRrIntervals);
  $$WhoopEventsTableTableManager get whoopEvents =>
      $$WhoopEventsTableTableManager(_db, _db.whoopEvents);
  $$WhoopBatteryTableTableManager get whoopBattery =>
      $$WhoopBatteryTableTableManager(_db, _db.whoopBattery);
  $$WhoopSpo2SamplesTableTableManager get whoopSpo2Samples =>
      $$WhoopSpo2SamplesTableTableManager(_db, _db.whoopSpo2Samples);
  $$WhoopSkinTempSamplesTableTableManager get whoopSkinTempSamples =>
      $$WhoopSkinTempSamplesTableTableManager(_db, _db.whoopSkinTempSamples);
  $$WhoopStepSamplesTableTableManager get whoopStepSamples =>
      $$WhoopStepSamplesTableTableManager(_db, _db.whoopStepSamples);
  $$WhoopSleepStateSamplesTableTableManager get whoopSleepStateSamples =>
      $$WhoopSleepStateSamplesTableTableManager(
        _db,
        _db.whoopSleepStateSamples,
      );
  $$WhoopRespSamplesTableTableManager get whoopRespSamples =>
      $$WhoopRespSamplesTableTableManager(_db, _db.whoopRespSamples);
  $$WhoopGravitySamplesTableTableManager get whoopGravitySamples =>
      $$WhoopGravitySamplesTableTableManager(_db, _db.whoopGravitySamples);
  $$WhoopRawFieldSamplesTableTableManager get whoopRawFieldSamples =>
      $$WhoopRawFieldSamplesTableTableManager(_db, _db.whoopRawFieldSamples);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
}
