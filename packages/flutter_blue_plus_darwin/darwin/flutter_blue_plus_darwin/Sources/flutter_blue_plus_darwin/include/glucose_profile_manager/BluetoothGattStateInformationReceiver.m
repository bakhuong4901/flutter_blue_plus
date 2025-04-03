#import "BluetoothGattStateInformationReceiver.h"
#import <CoreBluetooth/CoreBluetooth.h>


NSString *const BLUETOOTH_LE_GATT_ACTION_CONNECTED_TO_DEVICE = @"BLUETOOTH_LE_GATT_ACTION_CONNECTED_TO_DEVICE";
NSString *const BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE = @"BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE";
NSString *const BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE = @"BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE";
NSString *const BLUETOOTH_LE_GATT_GLUCOSE_MEASUREMENT_RECORD_EXTRA = @"BLUETOOTH_LE_GATT_GLUCOSE_MEASUREMENT_RECORD_EXTRA";
NSString *const DEVICE_CONNECTED_TO_EXTRA = @"DEVICE_CONNECTED_TO_EXTRA";
NSString *const RECORDS_SENT_COMPLETE = @"RECORDS_SENT_COMPLETE";

@interface BluetoothGattStateInformationReceiver ()
@property(nonatomic, weak) id <BluetoothGattStateInformationCallback> callback;
@end

@implementation BluetoothGattStateInformationReceiver

- (instancetype)initWithCallback:(id <BluetoothGattStateInformationCallback>)callback {
    self = [super init];
    if (self) {
        _callback = callback;
    }
    return self;
}

- (void)handleEvent:(NSString *)action withUserInfo:(NSDictionary *)userInfo {
    if ([action isEqualToString:BLUETOOTH_LE_GATT_ACTION_CONNECTED_TO_DEVICE]) {
        CBPeripheral *connectedDevice = userInfo[DEVICE_CONNECTED_TO_EXTRA];
        if (connectedDevice) {
            [self.callback connectedToAGattServer:connectedDevice];
        }
    } else if ([action isEqualToString:BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE]) {
        [self.callback disconnectedFromAGattServer];
    } else if ([action isEqualToString:BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE]) {
        @synchronized (self) {
            GlucoseMeasurementRecord *record = userInfo[BLUETOOTH_LE_GATT_GLUCOSE_MEASUREMENT_RECORD_EXTRA];
            if (record) {
                [self.callback glucoseMeasurementRecordAvailable:record];
            }
        }
    } else if ([action isEqualToString:RECORDS_SENT_COMPLETE]) {
        [self.callback recordsSentComplete];
    }
}

@end