#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "GlucoseMeasurementRecord.h"

@protocol BluetoothGattStateInformationCallback <NSObject>
// Gửi dữ liệu đo đường huyết nhận được từ thiết bị bluetooth
- (void)glucoseMeasurementRecordAvailable:(GlucoseMeasurementRecord *)glucoseMeasurementRecord;

// Gọi khi thiết bị kết nối thành công với GATT SERVER
- (void)connectedToAGattServer:(CBPeripheral *)connectedDevice;

// Gọi khi thiết bị bị ngắt kết nối khỏi GATT server
- (void)disconnectedFromAGattServer;

// Xử lý trạng thái ghép đôi Bluetooth
- (void)bondStateExtra:(NSInteger)boundState;

// Gọi khi toàn bộ dữ liệu đo đường huyết đã được gửi xong
- (void)recordsSentComplete;
@end

@interface BluetoothGattStateInformationReceiver : NSObject

// Constants
extern NSString *const BLUETOOTH_LE_GATT_ACTION_CONNECTED_TO_DEVICE;
extern NSString *const BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE;
extern NSString *const BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE;
extern NSString *const BLUETOOTH_LE_GATT_GLUCOSE_MEASUREMENT_RECORD_EXTRA;
extern NSString *const DEVICE_CONNECTED_TO_EXTRA;
extern NSString *const RECORDS_SENT_COMPLETE;

- (instancetype)initWithCallback:(id<BluetoothGattStateInformationCallback>)callback;
- (void)handleEvent:(NSString *)action withUserInfo:(NSDictionary *)userInfo;

@end