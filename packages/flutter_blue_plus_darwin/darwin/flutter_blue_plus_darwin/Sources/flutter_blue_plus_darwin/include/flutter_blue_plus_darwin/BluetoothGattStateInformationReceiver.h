// BluetoothGattStateInformationReceiver.h
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BluetoothGattStateInformationDelegate <NSObject>

// Gửi dữ liệu đo đường huyết nhận được từ thiết bị Bluetooth
- (void)glucoseMeasurementRecordAvailable:(NSDictionary *)glucoseMeasurementRecord;

// Gọi khi thiết bị kết nối thành công với GATT Server
- (void)connectedToAGattServer:(CBPeripheral *)connectedDevice;

// Gọi khi thiết bị bị ngắt kết nối khỏi GATT Server
- (void)disconnectedFromAGattServer;

// Xử lý trạng thái ghép đôi Bluetooth
- (void)bondStateExtra:(NSInteger)bondState;

// Gọi khi toàn bộ dữ liệu đo đường huyết đã được gửi xong
- (void)recordsSentComplete;

@end

@interface BluetoothGattStateInformationReceiver : NSObject

@property (nonatomic, weak) id<BluetoothGattStateInformationDelegate> delegate;

// Khởi tạo với delegate
- (instancetype)initWithDelegate:(id<BluetoothGattStateInformationDelegate>)delegate;

// Đăng ký để lắng nghe thông báo Bluetooth
- (void)registerForBluetoothNotifications;

// Hủy đăng ký lắng nghe thông báo Bluetooth
- (void)unregisterFromBluetoothNotifications;

@end

        NS_ASSUME_NONNULL_END
