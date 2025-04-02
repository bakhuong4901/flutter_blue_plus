// GlucoseProfileConfiguration.h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GlucoseProfileConfiguration : NSObject

// UUIDs cho các dịch vụ và đặc điểm
extern NSString *const DEVICE_BATTERY_CHARACTERISTIC_UUID;
extern NSString *const GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID;
extern NSString *const GLUCOSE_FEATURE_CHARACTERISTIC_UUID;
extern NSString *const GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID;
extern NSString *const RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID;
extern NSString *const GLUCOSE_SERVICE_UUID;
extern NSString *const CLIENT_CHARACTERISTICS_CONFIGURATION_DESCRIPTOR;

// Glucose profile opcodes
extern const NSInteger OP_CODE_REPORT_STORED_RECORDS;
extern const NSInteger OP_CODE_DELETE_STORED_RECORDS;
extern const NSInteger OP_CODE_ABORT_OPERATION;
extern const NSInteger OP_CODE_REPORT_NUMBER_OF_RECORDS;
extern const NSInteger OP_CODE_NUMBER_OF_STORED_RECORDS_RESPONSE;
extern const NSInteger OP_CODE_RESPONSE_CODE;

// Glucose profile operators
extern const NSInteger OPERATOR_NULL;
extern const NSInteger OPERATOR_ALL_RECORDS;
extern const NSInteger OPERATOR_LESS_THEN_OR_EQUAL;
extern const NSInteger OPERATOR_GREATER_THEN_OR_EQUAL;
extern const NSInteger OPERATOR_WITHING_RANGE;
extern const NSInteger OPERATOR_FIRST_RECORD;
extern const NSInteger OPERATOR_LAST_RECORD;

// Glucose measurement filter types
extern const NSInteger FILTER_TYPE_NULL;
extern const NSInteger FILTER_TYPE_SEQUENCE_NUMBER;
extern const NSInteger FILTER_TYPE_USER_FACING_TIME;

// Glucose profile response types
extern const NSInteger RESPONSE_SUCCESS;
extern const NSInteger RESPONSE_OP_CODE_NOT_SUPPORTED;
extern const NSInteger RESPONSE_INVALID_OPERATOR;
extern const NSInteger RESPONSE_OPERATOR_NOT_SUPPORTED;
extern const NSInteger RESPONSE_INVALID_OPERAND;
extern const NSInteger RESPONSE_NO_RECORDS_FOUND;
extern const NSInteger RESPONSE_ABORT_UNSUCCESSFUL;
extern const NSInteger RESPONSE_PROCEDURE_NOT_COMPLETED;
extern const NSInteger RESPONSE_OPERAND_NOT_SUPPORTED;

@end

        NS_ASSUME_NONNULL_END
