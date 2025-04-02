// GlucoseProfileConfiguration.m
#import "GlucoseProfileConfiguration.h"

@implementation GlucoseProfileConfiguration

// UUIDs cho các dịch vụ và đặc điểm
NSString *const DEVICE_BATTERY_CHARACTERISTIC_UUID = @"0000180F-0000-1000-8000-00805f9b34fb"; // đo mức pin của thiết bị
NSString *const GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID = @"00002A18-0000-1000-8000-00805f9b34fb";// đặc điểm đo glucose
NSString *const GLUCOSE_FEATURE_CHARACTERISTIC_UUID = @"00002A51-0000-1000-8000-00805f9b34fb";// cho biết các tính năng hỗ trợ của máy đo đường huyết
NSString *const GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID = @"00002A34-0000-1000-8000-00805f9b34fb";// đặc điểm chứa thông tin bối cảnh đo của glucose, như thời gian đo
NSString *const RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID = @"00002A52-0000-1000-8000-00805f9b34fb";// Đặc điểm điều khiển truy cập dữ liệu đo lường
NSString *const GLUCOSE_SERVICE_UUID = @"00001808-0000-1000-8000-00805f9b34fb";// Dịch vụ BLE cho đo glucose
NSString *const CLIENT_CHARACTERISTICS_CONFIGURATION_DESCRIPTOR = @"00002902-0000-1000-8000-00805f9b34fb";// Descriptor dùng để bật thông báo cho client

// Glucose profile opcodes - Mã lệnh kiểm soát truy cập dữ liệu
const NSInteger OP_CODE_REPORT_STORED_RECORDS = 1;// Yêu cầu gửi tất cả dữ liệu đo đã lưu.
const NSInteger OP_CODE_DELETE_STORED_RECORDS = 2;// Xóa dữ liệu đo đã lưu.
const NSInteger OP_CODE_ABORT_OPERATION = 3;// Hủy thao tác hiện tại.
const NSInteger OP_CODE_REPORT_NUMBER_OF_RECORDS = 4;// Yêu cầu số lượng bản ghi đã lưu.
const NSInteger OP_CODE_NUMBER_OF_STORED_RECORDS_RESPONSE = 5;// Phản hồi số lượng bản ghi lưu trữ.
const NSInteger OP_CODE_RESPONSE_CODE = 6;// Mã phản hồi chung từ thiết bị BLE.

// Glucose profile operators -  Mã định danh
const NSInteger OPERATOR_NULL = 0;//Không có toán tử nào.
const NSInteger OPERATOR_ALL_RECORDS = 1;// Chọn tất cả bản ghi.
const NSInteger OPERATOR_LESS_THEN_OR_EQUAL = 2;// Chọn bản ghi có giá trị nhỏ hơn hoặc bằng một giá trị nhất định.
const NSInteger OPERATOR_GREATER_THEN_OR_EQUAL = 3;// Chọn bản ghi có giá trị lớn hơn hoặc bằng một giá trị nhất định.
const NSInteger OPERATOR_WITHING_RANGE = 4;// Chọn bản ghi nằm trong khoảng giá trị.
const NSInteger OPERATOR_FIRST_RECORD = 5;// Chọn bản ghi đầu tiên.
const NSInteger OPERATOR_LAST_RECORD = 6;// Chọn bản ghi cuối cùng.

// Glucose measurement filter types - Mã bộ lọc
const NSInteger FILTER_TYPE_NULL = 0;// Không lọc.
const NSInteger FILTER_TYPE_SEQUENCE_NUMBER = 1;// Lọc theo số thứ tự của bản ghi.
const NSInteger FILTER_TYPE_USER_FACING_TIME = 2;// Lọc theo thời gian đo của người dùng.

// Glucose profile response types - Mã phản hồi từ thiết bị BLE
const NSInteger RESPONSE_SUCCESS = 1; // Thành công
const NSInteger RESPONSE_OP_CODE_NOT_SUPPORTED = 2; // Mã lệnh không được hỗ trợ.
const NSInteger RESPONSE_INVALID_OPERATOR = 3;// Toán tử không hợp lệ.
const NSInteger RESPONSE_OPERATOR_NOT_SUPPORTED = 4;// Toán tử không được hỗ trợ.
const NSInteger RESPONSE_INVALID_OPERAND = 5;// Toán hạng không hợp lệ.
const NSInteger RESPONSE_NO_RECORDS_FOUND = 6;// Không tìm thấy bản ghi.
const NSInteger RESPONSE_ABORT_UNSUCCESSFUL = 7;// Hủy thao tác thất bại.
const NSInteger RESPONSE_PROCEDURE_NOT_COMPLETED = 8;// Quá trình không hoàn thành.
const NSInteger RESPONSE_OPERAND_NOT_SUPPORTED = 9;// Toán hạng không được hỗ trợ.

@end
