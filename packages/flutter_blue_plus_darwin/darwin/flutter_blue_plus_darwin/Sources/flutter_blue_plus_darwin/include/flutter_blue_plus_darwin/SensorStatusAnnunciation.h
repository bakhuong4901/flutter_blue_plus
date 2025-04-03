// SensorStatusAnnunciation.h
//#ifndef SENSOR_STATUS_ANNUNCIATION_H
//#define SENSOR_STATUS_ANNUNCIATION_H
//#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorStatusAnnunciation : NSObject <NSCoding>

// Các trạng thái của cảm biến
@property (nonatomic, assign) BOOL deviceBatteryLowAtTimeOfMeasurement; // Pin của thiết bị yếu khi đo
@property (nonatomic, assign) BOOL sensorMalfunctionAtTimeOfMeasurement; // Cảm biến bị lỗi trong quá trình đo
@property (nonatomic, assign) BOOL bloodSampleInsufficientAtTimeOfMeasurement; // Lượng mẫu máu không đủ để đo
@property (nonatomic, assign) BOOL stripInsertionError; // Lỗi khi lắp que thử vào máy
@property (nonatomic, assign) BOOL stripTypeIncorrectForDevice; // Loại que thử không phù hợp với thiết bị
@property (nonatomic, assign) BOOL sensorResultHigherThanDeviceCanProcess; // Kết quả đo cao hơn giới hạn thiết bị có thể xử lý
@property (nonatomic, assign) BOOL sensorResultLowerThanTheDeviceCanProcess; // Kết quả đo thấp hơn giới hạn thiết bị có thể xử lý
@property (nonatomic, assign) BOOL sensorTemperatureTooHighForValidTestResult; // Nhiệt độ của cảm biến quá cao để có kết quả hợp lệ
@property (nonatomic, assign) BOOL sensorTemperatureTooLowForValidTestResult; // Nhiệt độ của cảm biến quá thấp để có kết quả hợp lệ
@property (nonatomic, assign) BOOL sensorReadInterruptedBecauseStripWasPulledTooSoon; // Việc đo bị gián đoạn do que thử bị rút ra quá sớm
@property (nonatomic, assign) BOOL generalDeviceFaultHasOccurredInSensor; // Lỗi chung của thiết bị xảy ra trong cảm biến
@property (nonatomic, assign) BOOL timeFaultHasOccurredInTheSensor; // Lỗi thời gian trong cảm biến (có thể do đồng hồ sai)

// Phương thức khởi tạo
- (instancetype)initWithDeviceBatteryLow:(BOOL)deviceBatteryLow
        sensorMalfunction:(BOOL)sensorMalfunction
        bloodSampleInsufficient:(BOOL)bloodSampleInsufficient
        stripInsertionError:(BOOL)stripInsertionError
        stripTypeIncorrectForDevice:(BOOL)stripTypeIncorrectForDevice
        sensorResultHigherThanDevice:(BOOL)sensorResultHigherThanDevice
        sensorResultLowerThanDevice:(BOOL)sensorResultLowerThanDevice
        sensorTemperatureTooHighForValidTestResult:(BOOL)sensorTemperatureTooHigh
        sensorTemperatureTooLowForValidTestResult:(BOOL)sensorTemperatureTooLow
        sensorReadInterruptedBecauseStripWasPulledTooSoon:(BOOL)sensorReadInterrupted
        generalDeviceFaultHasOccurredInSensor:(BOOL)generalDeviceFault
        timeFaultHasOccurredInTheSensor:(BOOL)timeFault;

// Phương thức mã hóa đối tượng để truyền qua các activity khác
- (void)encodeWithCoder:(NSCoder *)coder;
- (nullable instancetype)initWithCoder:(NSCoder *)coder;

@end

        NS_ASSUME_NONNULL_END
