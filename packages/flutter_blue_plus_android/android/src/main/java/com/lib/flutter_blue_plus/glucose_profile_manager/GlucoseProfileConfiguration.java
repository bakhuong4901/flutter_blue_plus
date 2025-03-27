package com.lib.flutter_blue_plus.glucose_profile_manager;

import java.util.UUID;

public class GlucoseProfileConfiguration {

    // UUIDs for Glucose Profile Services and Characteristics
    //đo mức pin của thiết bị
    public static final UUID DEVICE_BATTERY_CHARACTERISTIC_UUID = UUID.fromString("0000180F-0000-1000-8000-00805f9b34fb");
    // đặc điểm đo glucose
    public static final UUID GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID = UUID.fromString("00002A18-0000-1000-8000-00805f9b34fb");
    // cho biết các tính năng hỗ trợ của máy đo đường huyết
    public static final UUID GLUCOSE_FEATURE_CHARACTERISTIC_UUID = UUID.fromString("00002A51-0000-1000-8000-00805f9b34fb");
    // đặc điểm chứa thông tin bối cảnh đo của glucose, như thời gian đo
    public static final UUID GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID = UUID.fromString("00002A34-0000-1000-8000-00805f9b34fb");
    // Đặc điểm điều khiển truy cập dữ liệu đo lường
    public static final UUID RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID = UUID.fromString("00002A52-0000-1000-8000-00805f9b34fb");
    // Dịch vụ BLE cho đo glucose
    public static final UUID GLUCOSE_SERVICE_UUID = UUID.fromString("00001808-0000-1000-8000-00805f9b34fb");
    // Descriptor dùng để bật thông báo cho client
    public static final UUID CLIENT_CHARACTERISTICS_CONFIGURATION_DESCRIPTOR = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    // Glucose Profile Opcodes - Mã lệnh kiểm soát truy cập dữ liệu
    public static final int OP_CODE_REPORT_STORED_RECORDS = 1; // Yêu cầu gửi tất cả dữ liệu đo đã lưu.
    public static final int OP_CODE_DELETE_STORED_RECORDS = 2; // Xóa dữ liệu đo đã lưu.
    public static final int OP_CODE_ABORT_OPERATION = 3; // Hủy thao tác hiện tại.
    public static final int OP_CODE_REPORT_NUMBER_OF_RECORDS = 4; // Yêu cầu số lượng bản ghi đã lưu.
    public static final int OP_CODE_NUMBER_OF_STORED_RECORDS_RESPONSE = 5; // Phản hồi số lượng bản ghi lưu trữ.
    public static final int OP_CODE_RESPONSE_CODE = 6; // Mã phản hồi chung từ thiết bị BLE.

    // Glucose Profile Operators - Mã định danh
    public static final int OPERATOR_NULL = 0; // Không có toán tử nào.
    public static final int OPERATOR_ALL_RECORDS = 1; // Chọn tất cả bản ghi.
    public static final int OPERATOR_LESS_THEN_OR_EQUAL = 2; // Chọn bản ghi có giá trị nhỏ hơn hoặc bằng một giá trị nhất định.
    public static final int OPERATOR_GREATER_THEN_OR_EQUAL = 3; // Chọn bản ghi có giá trị lớn hơn hoặc bằng một giá trị nhất định.
    public static final int OPERATOR_WITHIN_RANGE = 4; // Chọn bản ghi nằm trong khoảng giá trị.
    public static final int OPERATOR_FIRST_RECORD = 5; // Chọn bản ghi đầu tiên.
    public static final int OPERATOR_LAST_RECORD = 6; // Chọn bản ghi cuối cùng.

    // Glucose Measurement Filter Type - Mã bộ lọc
    public static final int FILTER_TYPE_NULL = 0;// Không lọc.
    public static final int FILTER_TYPE_SEQUENCE_NUMBER = 1; // Lọc theo số thứ tự của bản ghi.
    public static final int FILTER_TYPE_USER_FACING_TIME = 2; // Lọc theo thời gian đo của người dùng.

    // Glucose Profile Response Type - Mã phản hồi từ thiết bị BLE
    public static final int RESPONSE_SUCCESS = 1; // Thành công
    public static final int RESPONSE_OP_CODE_NOT_SUPPORTED = 2; // Mã lệnh không được hỗ trợ.
    public static final int RESPONSE_INVALID_OPERATOR = 3; // Toán tử không hợp lệ.
    public static final int RESPONSE_OPERATOR_NOT_SUPPORTED = 4; // Toán tử không được hỗ trợ.
    public static final int RESPONSE_INVALID_OPERAND = 5; // Toán hạng không hợp lệ.
    public static final int RESPONSE_NO_RECORDS_FOUND = 6; // Không tìm thấy bản ghi.
    public static final int RESPONSE_ABORT_UNSUCCESSFUL = 7; // Hủy thao tác thất bại.
    public static final int RESPONSE_PROCEDURE_NOT_COMPLETED = 8; // Quá trình không hoàn thành.
    public static final int RESPONSE_OPERAND_NOT_SUPPORTED = 9; // Toán hạng không được hỗ trợ.
}
