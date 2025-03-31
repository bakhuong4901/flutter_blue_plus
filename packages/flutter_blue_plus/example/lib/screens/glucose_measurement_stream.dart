import 'dart:async';
import 'package:flutter_blue_plus_example/model/glucose_measurement_record_model.dart';
// import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';

class GlucoseMeasurementStream {
  static final GlucoseMeasurementStream _instance = GlucoseMeasurementStream._internal();
  factory GlucoseMeasurementStream() => _instance;
  GlucoseMeasurementStream._internal();

  final _glucoseController = StreamController<BmGlucoseRecordResponse>.broadcast();
  Stream<BmGlucoseRecordResponse> get glucoseStream => _glucoseController.stream;

  // void initialize() {
  //   FlutterBluePlusPlatform.instance..listen((event) {
  //     if (event.method == "OnGlucoseRecordsReceived") {
  //       try {
  //         final response = BmGlucoseRecordResponse.fromMap(event.arguments);
  //         _glucoseController.add(response);
  //       } catch (e) {
  //         print("Error parsing glucose data: $e");
  //       }
  //     }
  //   });
  // }

  void dispose() {
    _glucoseController.close();
  }
}