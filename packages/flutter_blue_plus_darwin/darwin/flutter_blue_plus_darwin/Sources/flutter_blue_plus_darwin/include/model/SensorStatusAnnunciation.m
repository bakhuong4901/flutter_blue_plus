// SensorStatusAnnunciation.m
#import "SensorStatusAnnunciation.h"

@implementation SensorStatusAnnunciation

// Phương thức khởi tạo
- (instancetype)         initWithDeviceBatteryLow:(BOOL)deviceBatteryLow
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
                  timeFaultHasOccurredInTheSensor:(BOOL)timeFault {
    self = [super init];
    if (self) {
        _deviceBatteryLowAtTimeOfMeasurement = deviceBatteryLow;
        _sensorMalfunctionAtTimeOfMeasurement = sensorMalfunction;
        _bloodSampleInsufficientAtTimeOfMeasurement = bloodSampleInsufficient;
        _stripInsertionError = stripInsertionError;
        _stripTypeIncorrectForDevice = stripTypeIncorrectForDevice;
        _sensorResultHigherThanDeviceCanProcess = sensorResultHigherThanDevice;
        _sensorResultLowerThanTheDeviceCanProcess = sensorResultLowerThanDevice;
        _sensorTemperatureTooHighForValidTestResult = sensorTemperatureTooHigh;
        _sensorTemperatureTooLowForValidTestResult = sensorTemperatureTooLow;
        _sensorReadInterruptedBecauseStripWasPulledTooSoon = sensorReadInterrupted;
        _generalDeviceFaultHasOccurredInSensor = generalDeviceFault;
        _timeFaultHasOccurredInTheSensor = timeFault;
    }
    return self;
}

// Phương thức mã hóa đối tượng
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.deviceBatteryLowAtTimeOfMeasurement forKey:@"deviceBatteryLowAtTimeOfMeasurement"];
    [coder encodeBool:self.sensorMalfunctionAtTimeOfMeasurement forKey:@"sensorMalfunctionAtTimeOfMeasurement"];
    [coder encodeBool:self.bloodSampleInsufficientAtTimeOfMeasurement forKey:@"bloodSampleInsufficientAtTimeOfMeasurement"];
    [coder encodeBool:self.stripInsertionError forKey:@"stripInsertionError"];
    [coder encodeBool:self.stripTypeIncorrectForDevice forKey:@"stripTypeIncorrectForDevice"];
    [coder encodeBool:self.sensorResultHigherThanDeviceCanProcess forKey:@"sensorResultHigherThanDeviceCanProcess"];
    [coder encodeBool:self.sensorResultLowerThanTheDeviceCanProcess forKey:@"sensorResultLowerThanTheDeviceCanProcess"];
    [coder encodeBool:self.sensorTemperatureTooHighForValidTestResult forKey:@"sensorTemperatureTooHighForValidTestResult"];
    [coder encodeBool:self.sensorTemperatureTooLowForValidTestResult forKey:@"sensorTemperatureTooLowForValidTestResult"];
    [coder encodeBool:self.sensorReadInterruptedBecauseStripWasPulledTooSoon forKey:@"sensorReadInterruptedBecauseStripWasPulledTooSoon"];
    [coder encodeBool:self.generalDeviceFaultHasOccurredInSensor forKey:@"generalDeviceFaultHasOccurredInSensor"];
    [coder encodeBool:self.timeFaultHasOccurredInTheSensor forKey:@"timeFaultHasOccurredInTheSensor"];
}

// Phương thức giải mã đối tượng
- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    BOOL deviceBatteryLow = [coder decodeBoolForKey:@"deviceBatteryLowAtTimeOfMeasurement"];
    BOOL sensorMalfunction = [coder decodeBoolForKey:@"sensorMalfunctionAtTimeOfMeasurement"];
    BOOL bloodSampleInsufficient = [coder decodeBoolForKey:@"bloodSampleInsufficientAtTimeOfMeasurement"];
    BOOL stripInsertionError = [coder decodeBoolForKey:@"stripInsertionError"];
    BOOL stripTypeIncorrect = [coder decodeBoolForKey:@"stripTypeIncorrectForDevice"];
    BOOL sensorResultHigher = [coder decodeBoolForKey:@"sensorResultHigherThanDeviceCanProcess"];
    BOOL sensorResultLower = [coder decodeBoolForKey:@"sensorResultLowerThanTheDeviceCanProcess"];
    BOOL sensorTempTooHigh = [coder decodeBoolForKey:@"sensorTemperatureTooHighForValidTestResult"];
    BOOL sensorTempTooLow = [coder decodeBoolForKey:@"sensorTemperatureTooLowForValidTestResult"];
    BOOL sensorReadInterrupted = [coder decodeBoolForKey:@"sensorReadInterruptedBecauseStripWasPulledTooSoon"];
    BOOL generalDeviceFault = [coder decodeBoolForKey:@"generalDeviceFaultHasOccurredInSensor"];
    BOOL timeFault = [coder decodeBoolForKey:@"timeFaultHasOccurredInTheSensor"];

    return [self         initWithDeviceBatteryLow:deviceBatteryLow
                                sensorMalfunction:sensorMalfunction
                          bloodSampleInsufficient:bloodSampleInsufficient
                              stripInsertionError:stripInsertionError
                      stripTypeIncorrectForDevice:stripTypeIncorrect
                     sensorResultHigherThanDevice:sensorResultHigher
                      sensorResultLowerThanDevice:sensorResultLower
       sensorTemperatureTooHighForValidTestResult:sensorTempTooHigh
        sensorTemperatureTooLowForValidTestResult:sensorTempTooLow
sensorReadInterruptedBecauseStripWasPulledTooSoon:sensorReadInterrupted
            generalDeviceFaultHasOccurredInSensor:generalDeviceFault
                  timeFaultHasOccurredInTheSensor:timeFault];
}

@end
