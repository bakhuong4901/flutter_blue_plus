// Thông báo trạng thái cảm  biến
class SensorStatusAnnunciation {
  bool deviceBatteryLowAtTimeOfMeasurement;
  bool sensorMalfunctionAtTimeOfMeasurement;
  bool bloodSampleInsufficientAtTimeOfMeasurement;
  bool stripInsertionError;
  bool stripTypeIncorrectForDevice;
  bool sensorResultHigherThanDeviceCanProcess;
  bool sensorResultLowerThanTheDeviceCanProcess;
  bool sensorTemperatureTooHighForValidTestResult;
  bool sensorTemperatureTooLowForValidTestResult;
  bool sensorReadInterruptedBecauseStripWasPulledTooSoon;
  bool generalDeviceFaultHasOccurredInSensor;
  bool timeFaultHasOccurredInTheSensor;

  SensorStatusAnnunciation({
    this.deviceBatteryLowAtTimeOfMeasurement = false,
    this.sensorMalfunctionAtTimeOfMeasurement = false,
    this.bloodSampleInsufficientAtTimeOfMeasurement = false,
    this.stripInsertionError = false,
    this.stripTypeIncorrectForDevice = false,
    this.sensorResultHigherThanDeviceCanProcess = false,
    this.sensorResultLowerThanTheDeviceCanProcess = false,
    this.sensorTemperatureTooHighForValidTestResult = false,
    this.sensorTemperatureTooLowForValidTestResult = false,
    this.sensorReadInterruptedBecauseStripWasPulledTooSoon = false,
    this.generalDeviceFaultHasOccurredInSensor = false,
    this.timeFaultHasOccurredInTheSensor = false,
  });

  factory SensorStatusAnnunciation.fromMap(Map<String, dynamic> json) {
    return SensorStatusAnnunciation(
      deviceBatteryLowAtTimeOfMeasurement:
          json['deviceBatteryLowAtTimeOfMeasurement'] ?? false,
      sensorMalfunctionAtTimeOfMeasurement:
          json['sensorMalfunctionAtTimeOfMeasurement'] ?? false,
      bloodSampleInsufficientAtTimeOfMeasurement:
          json['bloodSampleInsufficientAtTimeOfMeasurement'] ?? false,
      stripInsertionError: json['stripInsertionError'] ?? false,
      stripTypeIncorrectForDevice: json['stripTypeIncorrectForDevice'] ?? false,
      sensorResultHigherThanDeviceCanProcess:
          json['sensorResultHigherThanDeviceCanProcess'] ?? false,
      sensorResultLowerThanTheDeviceCanProcess:
          json['sensorResultLowerThanTheDeviceCanProcess'] ?? false,
      sensorTemperatureTooHighForValidTestResult:
          json['sensorTemperatureTooHighForValidTestResult'] ?? false,
      sensorTemperatureTooLowForValidTestResult:
          json['sensorTemperatureTooLowForValidTestResult'] ?? false,
      sensorReadInterruptedBecauseStripWasPulledTooSoon:
          json['sensorReadInterruptedBecauseStripWasPulledTooSoon'] ?? false,
      generalDeviceFaultHasOccurredInSensor:
          json['generalDeviceFaultHasOccurredInSensor'] ?? false,
      timeFaultHasOccurredInTheSensor:
          json['timeFaultHasOccurredInTheSensor'] ?? false,
    );
  }
}

//Model data sau khi nhận từ Native gửi qua method channel
class GlucoseMeasurementRecord {
  int? sequenceNumber; // thứ tự lần đo
  int? year;
  int? month;
  int? day;
  int? hours;
  int? minutes;
  int? seconds;
  int? timeOffset; // độ lệch thời gian
  String? glucoseConcentrationMeasurementUnit; // đơn vị đo
  double? glucoseConcentrationValue; // giá trị đo
  int? type;
  String? testBloodType; // loại mẫu
  int? sampleLocationInteger; // Vị trí lấy mẫu (số)
  String? sampleLocation; // Tên vị trí lấy mẫu
  SensorStatusAnnunciation? sensorStatusAnnunciation;
  String? mealInfo;

  factory GlucoseMeasurementRecord.fromMap(Map<String, dynamic> json) {
    return GlucoseMeasurementRecord(
      sequenceNumber:
          json['sequenceNumber'] != null ? json['sequenceNumber'] : null,
      year: json['baseTimeYear'] != null ? json['baseTimeYear'] : null,
      month: json['baseTimeMonth'] != null ? json['baseTimeMonth'] : null,
      day: json['baseTimeDay'] != null ? json['baseTimeDay'] : null,
      hours: json['baseTimeHours'] != null ? json['baseTimeHours'] : null,
      minutes: json['baseTimeMinutes'] != null ? json['baseTimeMinutes'] : null,
      seconds: json['baseTimeSeconds'] != null ? json['baseTimeSeconds'] : null,
      timeOffset: json['timeOffset'] != null ? json['timeOffset'] : null,
      glucoseConcentrationMeasurementUnit:
          json['measurementUnit'] != null ? json['measurementUnit'] : null,
      glucoseConcentrationValue: json['glucoseConcentrationValue'] != null
          ? json['glucoseConcentrationValue']
          : null,
      type: json['type'] != null ? json['type'] : null,
      testBloodType:
          json['testBloodType'] != null ? json['testBloodType'] : null,
      sampleLocationInteger: json['sampleLocationInteger'] != null
          ? json['sampleLocationInteger']
          : null,
      sampleLocation:
          json['sampleLocation'] != null ? json['sampleLocation'] : null,
      sensorStatusAnnunciation: json['sensorStatusAnnunciation'] != null
          ? SensorStatusAnnunciation.fromMap(
              Map<String, dynamic>.from(json['sensorStatusAnnunciation']))
          : null,
      mealInfo: json['mealInfo'],
    );
  }

  GlucoseMeasurementRecord({
    this.sequenceNumber,
    this.year,
    this.month,
    this.day,
    this.hours,
    this.minutes,
    this.seconds,
    this.timeOffset,
    this.glucoseConcentrationMeasurementUnit,
    this.glucoseConcentrationValue,
    this.type,
    this.testBloodType,
    this.sampleLocationInteger,
    this.sampleLocation,
    this.sensorStatusAnnunciation,
    this.mealInfo,
  });
}

class BmGlucoseRecordResponse {
  final List<GlucoseMeasurementRecord> listGlucoseMeasurementRecord;

  factory BmGlucoseRecordResponse.fromMap(Map<dynamic, dynamic> json) {
    List<GlucoseMeasurementRecord> listGlucoseMeasurementRecord = [];
    if (json['glucoseDataRecords'] != null) {
      // Cast List<dynamic> to List<Map<String, dynamic>>
      final List<dynamic> records = json['glucoseDataRecords'] as List<dynamic>;
      listGlucoseMeasurementRecord = records
          .map((item) => GlucoseMeasurementRecord.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return BmGlucoseRecordResponse(
        listGlucoseMeasurementRecord: listGlucoseMeasurementRecord);
  }

  BmGlucoseRecordResponse({
    required this.listGlucoseMeasurementRecord,
  });
}
