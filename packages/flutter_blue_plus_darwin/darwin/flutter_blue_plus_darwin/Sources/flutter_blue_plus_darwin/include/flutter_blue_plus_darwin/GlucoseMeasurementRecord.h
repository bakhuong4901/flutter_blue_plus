#import <Foundation/Foundation.h>
#import "SensorStatusAnnunciation.h"

typedef NS_ENUM(NSInteger, GlucoseConcentrationMeasurementUnit
) {
GlucoseConcentrationMeasurementUnitMolesPerLitre,
GlucoseConcentrationMeasurementUnitKilogramPerLitre
};

@interface GlucoseMeasurementRecord : NSObject <NSCoding, NSSecureCoding>

@property(nonatomic, assign) NSInteger sequenceNumber;
@property(nonatomic, strong) NSDate *calendar; // Lưu trữ ngày giờ
@property(nonatomic, assign) NSInteger timeOffset;
@property(nonatomic, assign) GlucoseConcentrationMeasurementUnit glucoseConcentrationMeasurementUnit;
@property(nonatomic, assign) float glucoseConcentrationValue;
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) NSInteger sampleLocationInteger;
@property(nonatomic, strong) NSString *testBloodType;
@property(nonatomic, strong) NSString *sampleLocation;
@property(nonatomic, strong) SensorStatusAnnunciation *sensorStatusAnnunciation;
//// Chuyển đổi giá trị nồng độ glucose sang mg/dL

- (NSString *)convertGlucoseConcentrationValueToMilligramsPerDeciliter;

@end
