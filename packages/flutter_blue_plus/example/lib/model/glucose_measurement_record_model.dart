// Thông báo trạng thái cảm  biến
class SensorStatusAnnunciation {
  SensorStatusAnnunciation();
}

//Model data sau khi nhận từ Native gửi qua method channel
class GlucoseMeasurementRecord {
  int? sequenceNumber;
  int? year;
  int? month;
  int? day;
  int? hours;
  int? minutes;
  int? seconds;
  int? timeOffset;
  String? glucoseConcentrationMeasurementUnit;
  double? glucoseConcentrationValue;
  int? type;
  int? sampleLocationInteger;
  String? sampleLocation;
  SensorStatusAnnunciation? sensorStatusAnnunciation;

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
      sampleLocationInteger: json['sampleLocationInteger'] != null
          ? json['sampleLocationInteger']
          : null,
      sampleLocation:
          json['sampleLocation'] != null ? json['sampleLocation'] : null,
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
    this.sampleLocationInteger,
    this.sampleLocation,
    this.sensorStatusAnnunciation,
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
