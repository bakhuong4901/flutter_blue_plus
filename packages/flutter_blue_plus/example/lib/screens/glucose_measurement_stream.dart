import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus_example/model/glucose_measurement_record_model.dart';
// import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';

class GlucoseMeasurementStream {
  static const MethodChannel _channel =
      MethodChannel('flutter_blue_plus/methods');
  static final GlucoseMeasurementStream _instance =
      GlucoseMeasurementStream._internal();

  factory GlucoseMeasurementStream() => _instance;

  GlucoseMeasurementStream._internal();

  final _glucoseController =
      StreamController<BmGlucoseRecordResponse>.broadcast();

  Stream<BmGlucoseRecordResponse> get glucoseStream =>
      _glucoseController.stream;

  void initialize() {
    print("GlucoseMeasurementStream initialized"); // Debug print
    _channel.setMethodCallHandler((call) async {
      if (call.method == "OnGlucoseRecordsReceived") {
        print("Raw data received: ${call.arguments}");

        final Map<String, dynamic> mappedData =
            Map<String, dynamic>.from(call.arguments as Map);
        final response = BmGlucoseRecordResponse.fromMap(mappedData);
        print("Parsed response: $response");

        _glucoseController.add(response);
      }
    });
  }

  void dispose() {
    _glucoseController.close();
  }
}
