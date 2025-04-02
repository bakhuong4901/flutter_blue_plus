// GlucoseMeasurementRecord.h
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GlucoseConcentrationMeasurementUnit
) {
MOLES_PER_LITRE,
KILOGRAM_PER_LITRE
};

typedef NS_ENUM(NSInteger, SensorStatusAnnunciation
) {
SENSOR_STATUS_OK,
SENSOR_STATUS_ERROR
// Thêm các trạng thái cảm biến khác nếu cần
};

NS_ASSUME_NONNULL_BEGIN

@interface GlucoseMeasurementRecord : NSObject <NSCoding>

@property(nonatomic, assign) NSInteger sequenceNumber; // Số thứ tự của lần đo
@property(nonatomic, strong) NSDate *calendar; // Ngày giờ của lần đo
@property(nonatomic, assign) NSInteger timeOffset; // Độ lệch thời gian so với thời điểm đo
@property(nonatomic, assign) GlucoseConcentrationMeasurementUnit glucoseConcentrationMeasurementUnit; // Đơn vị đo đường huyết
@property(nonatomic, assign) float glucoseConcentrationValue; // Giá trị đo nồng độ glucose
@property(nonatomic, assign) NSInteger type; // Loại mẫu máu
@property(nonatomic, assign) NSInteger sampleLocationInteger; // Vị trí lấy mẫu
@property(nonatomic, strong) NSString *testBloodType; // Loại máu đo
@property(nonatomic, strong) NSString *sampleLocation; // Vị trí lấy mẫu
@property(nonatomic, nullable, strong) NSNumber *sensorStatusAnnunciation; // Trạng thái của cảm biến đo

// Phương thức khởi tạo
- (instancetype)initWithSequenceNumber:(NSInteger)sequenceNumber
                              calendar:(NSDate *)calendar
                            timeOffset:(NSInteger)timeOffset
   glucoseConcentrationMeasurementUnit:(GlucoseConcentrationMeasurementUnit)unit
             glucoseConcentrationValue:(float)value
                                  type:(NSInteger)type
                 sampleLocationInteger:(NSInteger)sampleLocationInteger
              sensorStatusAnnunciation:(nullable NSNumber

*)
status;

// Chuyển đổi giá trị nồng độ glucose sang mg/dL
- (NSString *)convertGlucoseConcentrationValueToMilligramsPerDeciliter;

@end

NS_ASSUME_NONNULL_END
