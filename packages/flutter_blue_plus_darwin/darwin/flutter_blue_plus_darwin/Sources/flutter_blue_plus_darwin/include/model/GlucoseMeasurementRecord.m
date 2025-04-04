// GlucoseMeasurementRecord.m
#import "GlucoseMeasurementRecord.h"

@implementation GlucoseMeasurementRecord

// Phương thức khởi tạo
- (instancetype)initWithSequenceNumber:(NSInteger)sequenceNumber
                              calendar:(NSDate *)calendar
                            timeOffset:(NSInteger)timeOffset
   glucoseConcentrationMeasurementUnit:(GlucoseConcentrationMeasurementUnit)unit
             glucoseConcentrationValue:(float)value
                                  type:(NSInteger)type
                 sampleLocationInteger:(NSInteger)sampleLocationInteger
              sensorStatusAnnunciation:(nullable NSNumber *)status {
    self = [super init];
    if (self) {
        _sequenceNumber = sequenceNumber;
        _calendar = calendar;
        _timeOffset = timeOffset;
        _glucoseConcentrationMeasurementUnit = unit;
        _glucoseConcentrationValue = value;
        _type = type;
        _sampleLocationInteger = sampleLocationInteger;
        _sensorStatusAnnunciation = status;

        // Xử lý kiểu máu và vị trí mẫu
        [self updateTestBloodTypeAndSampleLocation];
    }
    return self;
}

// Phương thức chuyển đổi nồng độ glucose sang mg/dL
- (NSString *)convertGlucoseConcentrationValueToMilligramsPerDeciliter {
    return [NSString stringWithFormat:@"%.0f mg/dL", self.glucoseConcentrationValue * 100000];

}

// Cập nhật loại máu và vị trí mẫu
- (void)updateTestBloodTypeAndSampleLocation {
    switch (self.type) {
        case 0:
            _testBloodType = @"Reserved for future use";
            break;
        case 1:
            _testBloodType = @"Capillary Whole blood";
            break;
        case 2:
            _testBloodType = @"Capillary Plasma";
            break;
        case 3:
            _testBloodType = @"Venous Whole blood";
            break;
        case 4:
            _testBloodType = @"Venous Plasma";
            break;
        case 5:
            _testBloodType = @"Arterial Whole blood";
            break;
        case 6:
            _testBloodType = @"Arterial Plasma";
            break;
        case 7:
            _testBloodType = @"Undetermined Whole blood";
            break;
        case 8:
            _testBloodType = @"Undetermined Plasma";
            break;
        case 9:
            _testBloodType = @"Interstitial Fluid (ISF)";
            break;
        case 10:
            _testBloodType = @"Control Solution";
            break;
        default:
            _testBloodType = @"Reserved for future use";
            break;
    }

    switch (self.sampleLocationInteger) {
        case 0:
            _sampleLocation = @"Reserved for future use";
            break;
        case 1:
            _sampleLocation = @"Finger";
            break;
        case 2:
            _sampleLocation = @"Alternate Site Test (AST)";
            break;
        case 3:
            _sampleLocation = @"Earlobe";
            break;
        case 4:
            _sampleLocation = @"Control solution";
            break;
        case 15:
            _sampleLocation = @"Sample Location value not available";
            break;
        default:
            _sampleLocation = @"Reserved for future use";
            break;
    }
}

// Phương thức mã hóa đối tượng để truyền qua các activity khác
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.sequenceNumber forKey:@"sequenceNumber"];
    [coder encodeObject:self.calendar forKey:@"calendar"];
    [coder encodeInteger:self.timeOffset forKey:@"timeOffset"];
    [coder encodeInteger:self.glucoseConcentrationMeasurementUnit forKey:@"glucoseConcentrationMeasurementUnit"];
    [coder encodeFloat:self.glucoseConcentrationValue forKey:@"glucoseConcentrationValue"];
    [coder encodeInteger:self.type forKey:@"type"];
    [coder encodeInteger:self.sampleLocationInteger forKey:@"sampleLocationInteger"];
    [coder encodeObject:self.testBloodType forKey:@"testBloodType"];
    [coder encodeObject:self.sampleLocation forKey:@"sampleLocation"];
    [coder encodeObject:self.sensorStatusAnnunciation forKey:@"sensorStatusAnnunciation"];
}

// Phương thức giải mã đối tượng
- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    NSInteger sequenceNumber = [coder decodeIntegerForKey:@"sequenceNumber"];
    NSDate *calendar = [coder decodeObjectForKey:@"calendar"];
    NSInteger timeOffset = [coder decodeIntegerForKey:@"timeOffset"];
    GlucoseConcentrationMeasurementUnit unit = [coder decodeIntegerForKey:@"glucoseConcentrationMeasurementUnit"];
    float glucoseConcentrationValue = [coder decodeFloatForKey:@"glucoseConcentrationValue"];
    NSInteger type = [coder decodeIntegerForKey:@"type"];
    NSInteger sampleLocationInteger = [coder decodeIntegerForKey:@"sampleLocationInteger"];
    NSString *testBloodType = [coder decodeObjectForKey:@"testBloodType"];
    NSString *sampleLocation = [coder decodeObjectForKey:@"sampleLocation"];
    NSNumber *sensorStatusAnnunciation = [coder decodeObjectForKey:@"sensorStatusAnnunciation"];

    self = [self initWithSequenceNumber:sequenceNumber
                               calendar:calendar
                             timeOffset:timeOffset
    glucoseConcentrationMeasurementUnit:unit
              glucoseConcentrationValue:glucoseConcentrationValue
                                   type:type
                  sampleLocationInteger:sampleLocationInteger
               sensorStatusAnnunciation:sensorStatusAnnunciation];

    return self;
}

@end
