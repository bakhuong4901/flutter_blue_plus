package com.lib.flutter_blue_plus.glucose_profile_manager;

import java.util.UUID;

public class GlucoseProfileConfiguration {

    // UUIDs for Glucose Profile Services and Characteristics
    public static final UUID DEVICE_BATTERY_CHARACTERISTIC_UUID = UUID.fromString("0000180F-0000-1000-8000-00805f9b34fb");
    public static final UUID GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID = UUID.fromString("00002A18-0000-1000-8000-00805f9b34fb");
    public static final UUID GLUCOSE_FEATURE_CHARACTERISTIC_UUID = UUID.fromString("00002A51-0000-1000-8000-00805f9b34fb");
    public static final UUID GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID = UUID.fromString("00002A34-0000-1000-8000-00805f9b34fb");
    public static final UUID RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID = UUID.fromString("00002A52-0000-1000-8000-00805f9b34fb");
    public static final UUID GLUCOSE_SERVICE_UUID = UUID.fromString("00001808-0000-1000-8000-00805f9b34fb");
    public static final UUID CLIENT_CHARACTERISTICS_CONFIGURATION_DESCRIPTOR = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    // Glucose Profile Opcodes
    public static final int OP_CODE_REPORT_STORED_RECORDS = 1;
    public static final int OP_CODE_DELETE_STORED_RECORDS = 2;
    public static final int OP_CODE_ABORT_OPERATION = 3;
    public static final int OP_CODE_REPORT_NUMBER_OF_RECORDS = 4;
    public static final int OP_CODE_NUMBER_OF_STORED_RECORDS_RESPONSE = 5;
    public static final int OP_CODE_RESPONSE_CODE = 6;

    // Glucose Profile Operators
    public static final int OPERATOR_NULL = 0;
    public static final int OPERATOR_ALL_RECORDS = 1;
    public static final int OPERATOR_LESS_THEN_OR_EQUAL = 2;
    public static final int OPERATOR_GREATER_THEN_OR_EQUAL = 3;
    public static final int OPERATOR_WITHIN_RANGE = 4;
    public static final int OPERATOR_FIRST_RECORD = 5;
    public static final int OPERATOR_LAST_RECORD = 6;

    // Glucose Measurement Filter Type
    public static final int FILTER_TYPE_NULL = 0;
    public static final int FILTER_TYPE_SEQUENCE_NUMBER = 1;
    public static final int FILTER_TYPE_USER_FACING_TIME = 2;

    // Glucose Profile Response Type
    public static final int RESPONSE_SUCCESS = 1;
    public static final int RESPONSE_OP_CODE_NOT_SUPPORTED = 2;
    public static final int RESPONSE_INVALID_OPERATOR = 3;
    public static final int RESPONSE_OPERATOR_NOT_SUPPORTED = 4;
    public static final int RESPONSE_INVALID_OPERAND = 5;
    public static final int RESPONSE_NO_RECORDS_FOUND = 6;
    public static final int RESPONSE_ABORT_UNSUCCESSFUL = 7;
    public static final int RESPONSE_PROCEDURE_NOT_COMPLETED = 8;
    public static final int RESPONSE_OPERAND_NOT_SUPPORTED = 9;
}
