// BluetoothGattStateInformationReceiver.m
#import "BluetoothGattStateInformationReceiver.h"
#import <CoreBluetooth/CoreBluetooth.h>

@implementation BluetoothGattStateInformationReceiver

- (instancetype)initWithDelegate:(id<BluetoothGattStateInformationDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)registerForBluetoothNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBluetoothNotification:)
                                                 name:CBPeripheralDidConnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBluetoothNotification:)
                                                 name:CBPeripheralDidDisconnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBluetoothNotification:)
                                                 name:@"GlucoseMeasurementRecordAvailable"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBluetoothNotification:)
                                                 name:@"RecordsSentComplete"
                                               object:nil];
}

- (void)unregisterFromBluetoothNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleBluetoothNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:CBPeripheralDidConnectNotification]) {
        CBPeripheral *connectedDevice = notification.object;
        if ([self.delegate respondsToSelector:@selector(connectedToAGattServer:)]) {
            [self.delegate connectedToAGattServer:connectedDevice];
        }
    }
    else if ([notification.name isEqualToString:CBPeripheralDidDisconnectNotification]) {
        if ([self.delegate respondsToSelector:@selector(disconnectedFromAGattServer)]) {
            [self.delegate disconnectedFromAGattServer];
        }
    }
    else if ([notification.name isEqualToString:@"GlucoseMeasurementRecordAvailable"]) {
        NSDictionary *glucoseMeasurementRecord = notification.userInfo;
        if ([self.delegate respondsToSelector:@selector(glucoseMeasurementRecordAvailable:)]) {
            [self.delegate glucoseMeasurementRecordAvailable:glucoseMeasurementRecord];
        }
    }
    else if ([notification.name isEqualToString:@"RecordsSentComplete"]) {
        if ([self.delegate respondsToSelector:@selector(recordsSentComplete)]) {
            [self.delegate recordsSentComplete];
        }
    }
}

@end
