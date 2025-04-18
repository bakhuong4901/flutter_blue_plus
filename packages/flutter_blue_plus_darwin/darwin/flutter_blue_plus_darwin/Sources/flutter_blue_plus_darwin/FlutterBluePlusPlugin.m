// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import "./include/flutter_blue_plus_darwin/FlutterBluePlusPlugin.h"
#import "./include/flutter_blue_plus_darwin/GlucoseProfileConfiguration.h"
#import "./include/flutter_blue_plus_darwin/GlucoseMeasurementRecord.h"
#import "./include/flutter_blue_plus_darwin/SensorStatusAnnunciation.h"
#import "./include/flutter_blue_plus_darwin/BluetoothGattStateInformationReceiver.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define Log(LEVEL, FORMAT, ...) [self log:LEVEL format:@"[FBP-iOS] " FORMAT, ##__VA_ARGS__]
// 2902 là UUID của Client Characteristic Configuration Descriptor (CCCD), dùng để bật/tắt notify/indicate trên BLE.
NSString *const CCCD = @"2902";

@interface CBUUID (CBUUIDAdditionsFlutterBluePlus)
- (NSString *)uuidStr;
@end

// LOG
@implementation CBUUID (CBUUIDAdditionsFlutterBluePlus)
- (NSString *)uuidStr {
    return [self.UUIDString lowercaseString];
}
@end

typedef NS_ENUM(NSUInteger, LogLevel
) {
LNONE = 0,
        LERROR = 1,
        LWARNING = 2,
        LINFO = 3,
        LDEBUG = 4,
        LVERBOSE = 5,
};

@interface FlutterBluePlusPlugin ()
@property(nonatomic, retain) NSObject <FlutterPluginRegistrar> *registrar;
@property(nonatomic, retain) FlutterMethodChannel *methodChannel;
@property(nonatomic, retain) CBCentralManager *centralManager; // Quản lý Bluetooth IOS
@property(nonatomic) NSMutableDictionary *knownPeripherals; // Danh sách thiết bị BLE đã biết.
@property(nonatomic) NSMutableDictionary *connectedPeripherals; // Thiết bị BLE đang kết nối.
@property(nonatomic) NSMutableDictionary *currentlyConnectingPeripherals; // Thiết bị đang kết nối.
@property(nonatomic) NSMutableArray *servicesToDiscover;
@property(nonatomic) NSMutableArray *characteristicsToDiscover;
@property(nonatomic) NSMutableDictionary *didWriteWithoutResponse;
@property(nonatomic) NSMutableDictionary *peripheralMtu;
@property(nonatomic) NSMutableDictionary *writeChrs;
@property(nonatomic) NSMutableDictionary *writeDescs;
@property(nonatomic) NSMutableDictionary *scanCounts;
@property(nonatomic) NSDictionary *scanFilters; // Bộ lọc khi quét thiết bị.
@property(nonatomic) NSTimer *checkForMtuChangesTimer;
@property(nonatomic) LogLevel logLevel; // Mức độ ghi log.
@property(nonatomic) NSNumber *showPowerAlert;
@property(nonatomic) NSNumber *restoreState;
@property(strong, nonatomic) CBService *glucoseService;
@property(strong, nonatomic) NSMutableArray *glucoseMeasurementRecords; // KHUONG Array to store glucose measurement records

@end

// Khởi tạo method channel để Flutter có thể gọi qua native
@implementation FlutterBluePlusPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:NAMESPACE @"/methods"
                                                                      binaryMessenger:[registrar messenger]];
    FlutterBluePlusPlugin *instance = [[FlutterBluePlusPlugin alloc] init];
    instance.methodChannel = methodChannel;
    instance.knownPeripherals = [NSMutableDictionary new];
    instance.connectedPeripherals = [NSMutableDictionary new];
    instance.currentlyConnectingPeripherals = [NSMutableDictionary new];
    instance.servicesToDiscover = [NSMutableArray new];
    instance.characteristicsToDiscover = [NSMutableArray new];
    instance.didWriteWithoutResponse = [NSMutableDictionary new];
    instance.peripheralMtu = [NSMutableDictionary new];
    instance.writeChrs = [NSMutableDictionary new];
    instance.writeDescs = [NSMutableDictionary new];
    instance.scanCounts = [NSMutableDictionary new];
    instance.logLevel = LDEBUG;
    instance.showPowerAlert = @(YES);
    instance.restoreState = @(NO);
    instance.glucoseMeasurementRecords = [NSMutableArray new]; // KHUONG

    [registrar addMethodCallDelegate:instance channel:methodChannel];
}

//////////////////////////////////////////////////////////// Flutter dùng để gọi qua native code
// ██   ██   █████   ███    ██  ██████   ██       ███████    
// ██   ██  ██   ██  ████   ██  ██   ██  ██       ██         
// ███████  ███████  ██ ██  ██  ██   ██  ██       █████      
// ██   ██  ██   ██  ██  ██ ██  ██   ██  ██       ██         
// ██   ██  ██   ██  ██   ████  ██████   ███████  ███████                                                       
//                                                      
// ███    ███  ███████  ████████  ██   ██   ██████   ██████  
// ████  ████  ██          ██     ██   ██  ██    ██  ██   ██ 
// ██ ████ ██  █████       ██     ███████  ██    ██  ██   ██ 
// ██  ██  ██  ██          ██     ██   ██  ██    ██  ██   ██ 
// ██      ██  ███████     ██     ██   ██   ██████   ██████                                              
//                                                      
//  ██████   █████   ██       ██                           
// ██       ██   ██  ██       ██                           
// ██       ███████  ██       ██                           
// ██       ██   ██  ██       ██                           
//  ██████  ██   ██  ███████  ███████                     

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    @try {
        Log(LDEBUG, @"handleMethodCall: %@", call.method);

        if ([@"setLogLevel" isEqualToString:call.method]) {
            NSNumber *idx = [call arguments];
            self.logLevel = (LogLevel) [idx integerValue];
            result(@YES);
            return;
        }

        if ([@"setOptions" isEqualToString:call.method]) {
            NSDictionary *args = (NSDictionary *) call.arguments;
            self.showPowerAlert = args[@"show_power_alert"];
            self.restoreState = args[@"restore_state"];
            result(@YES);
            return;
        }

        // initialize adapter
        if (self.centralManager == nil) {
            Log(LDEBUG, @"initializing CBCentralManager");

            NSMutableDictionary *options = [NSMutableDictionary dictionary];

            if ([self.showPowerAlert boolValue]) {
                options[CBCentralManagerOptionShowPowerAlertKey] = self.showPowerAlert;
            }

            if ([self.restoreState boolValue]) {
                options[CBCentralManagerOptionRestoreIdentifierKey] = @"flutterBluePlusRestoreIdentifier";
            }

            Log(LDEBUG, @"showPowerAlert: %@", [self.showPowerAlert boolValue] ? @"yes" : @"no");
            Log(LDEBUG, @"restoreState: %@", [self.restoreState boolValue] ? @"yes" : @"no");

            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
        }
        // initialize timer
        if (self.checkForMtuChangesTimer == nil) {
            Log(LDEBUG, @"initializing checkForMtuChangesTimer");

            self.checkForMtuChangesTimer = [NSTimer scheduledTimerWithTimeInterval:0.025
                                                                            target:self
                                                                          selector:@selector(checkForMtuChangesCallback)
                                                                          userInfo:@{}
                                                                           repeats:YES];
        }
        // check that we have an adapter, except for the 
        // functions that don't need it
        if (self.centralManager == nil &&
            [@"flutterRestart" isEqualToString:call.method] == false &&
            [@"connectedCount" isEqualToString:call.method] == false &&
            [@"setLogLevel" isEqualToString:call.method] == false &&
            [@"isSupported" isEqualToString:call.method] == false &&
            [@"getAdapterName" isEqualToString:call.method] == false &&
            [@"getAdapterState" isEqualToString:call.method] == false) {
            NSString *s = @"the device does not support bluetooth";
            result([FlutterError errorWithCode:@"bluetoothUnavailable" message:s details:NULL]);
            return;
        }

        if ([@"flutterRestart" isEqualToString:call.method]) {
            // no adapter?
            if (self.centralManager == nil) {
                result(@(0)); // no work to do
                return;
            }

            if ([self isAdapterOn]) {
                [self.centralManager stopScan];
            }

            // all dart state is reset after flutter restart
            // (i.e. Hot Restart) so also reset native state
            [self disconnectAllDevices:@"flutterRestart"];

            Log(LDEBUG, @"connectedPeripherals: %lu", self.connectedPeripherals.count);

            if (self.connectedPeripherals.count == 0) {
                [self.knownPeripherals removeAllObjects];
            }

            result(@(self.connectedPeripherals.count));
            return;
        } else if ([@"connectedCount" isEqualToString:call.method]) {
            Log(LDEBUG, @"connectedPeripherals: %lu", self.connectedPeripherals.count);
            if (self.connectedPeripherals.count == 0) {
                Log(LDEBUG, @"Hot Restart: complete");
                [self.knownPeripherals removeAllObjects];
            }
            result(@(self.connectedPeripherals.count));
            return;
        } else if ([@"isSupported" isEqualToString:call.method]) {
            result(self.centralManager != nil ? @(YES) : @(NO));
        } else if ([@"getAdapterName" isEqualToString:call.method]) {
#if TARGET_OS_IOS
            result([[UIDevice currentDevice] name]);
#else // MacOS
            // TODO: support this via hostname?
            result(@"Mac Bluetooth Adapter");
#endif
        }
        if ([@"getAdapterState" isEqualToString:call.method]) {
            // get state
            int adapterState = 0; // BmAdapterStateEnum.unknown
            if (self.centralManager) {
                adapterState = [self bmAdapterStateEnum:self.centralManager.state];
            }

            // See BmBluetoothAdapterState
            NSDictionary *response = @{
                    @"adapter_state": @(adapterState),
            };

            result(response);
        } else if ([@"turnOn" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"turnOn"
                                       message:@"iOS does not support turning on bluetooth"
                                       details:NULL]);
        } else if ([@"turnOff" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"turnOff"
                                       message:@"iOS does not support turning off bluetooth"
                                       details:NULL]);
        }
            // Bắt đầu quét tìm kiếm thiết bị
        else if ([@"startScan" isEqualToString:call.method]) {
            // See BmScanSettings
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSArray *withServices = args[@"with_services"];
            NSNumber *continuousUpdates = args[@"continuous_updates"];

            // check adapter state
            if ([self isAdapterOn] == false) {
                NSString *as = [self cbManagerStateString:self.centralManager.state];
                NSString *s = [NSString stringWithFormat:@"bluetooth must be turned on. (%@)", as];
                result([FlutterError errorWithCode:@"startScan" message:s details:NULL]);
                return;
            }

            // remember this for later
            self.scanFilters = args;

            // allowDuplicates?
            NSMutableDictionary < NSString * , id > *scanOpts = [NSMutableDictionary new];
            if ([continuousUpdates boolValue]) {
                [scanOpts setObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
            }

            // filters implemented by FBP, not the OS
            BOOL hasCustomFilters =
                    [self hasFilter:@"with_remote_ids"] ||
                    [self hasFilter:@"with_names"] ||
                    [self hasFilter:@"with_keywords"] ||
                    [self hasFilter:@"with_msd"] ||
                    [self hasFilter:@"with_service_data"];

            // filter services
            NSArray *services = [NSArray array];
            for (int i = 0; i < [withServices count]; i++) {
                NSString *uuid = withServices[i];
                services = [services arrayByAddingObject:[CBUUID UUIDWithString:uuid]];
            }

            // If any custom filter is set then we cannot filter by services.
            // Why? An advertisement can match either the service filter *or*
            // the custom filter. It does not have to match both. So we cannot have
            // iOS & macOS filtering out any advertisements.
            if (hasCustomFilters) {
                services = [NSArray array];
            }

            // clear counts
            [self.scanCounts removeAllObjects];

            // start scanning
            [self.centralManager scanForPeripheralsWithServices:services options:scanOpts];

            result(@YES);
        }
            // Dừng tìm kiếm thiết bị
        else if ([@"stopScan" isEqualToString:call.method]) {
            [self.centralManager stopScan];
            result(@YES);
        } else if ([@"getSystemDevices" isEqualToString:call.method]) {
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSMutableArray *withServices = [NSMutableArray new];
            for (NSString *uuid in args[@"with_services"]) {
                [withServices addObject:[CBUUID UUIDWithString:uuid]];
            }

            // this returns devices connected by *any* app
            NSArray *periphs = [self.centralManager retrieveConnectedPeripheralsWithServices:withServices];

            // Devices
            NSMutableArray *deviceProtos = [NSMutableArray new];
            for (CBPeripheral *p in periphs) {
                [deviceProtos addObject:[self bmBluetoothDevice:p]];
            }

            // See BmDevicesList
            NSDictionary *response = @{
                    @"devices": deviceProtos,
            };

            result(response);
        } else if ([@"connect" isEqualToString:call.method]) {
            // See BmConnectRequest
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSString *remoteId = args[@"remote_id"];
            NSNumber *autoConnect = args[@"auto_connect"];

            // check adapter state - Kiểm tra trạng thái kết của Bluetooth
            if ([self isAdapterOn] == false) {
                NSString *as = [self cbManagerStateString:self.centralManager.state];
                NSString *s = [NSString stringWithFormat:@"bluetooth must be turned on. (%@)", as];
                result([FlutterError errorWithCode:@"connect" message:s details:NULL]);
                return;
            }

            // already connecting?
            if ([self.currentlyConnectingPeripherals objectForKey:remoteId] != nil) {
                Log(LDEBUG, @"already connecting");
                result(@YES); // still work to do // Đang kết nối
                return;
            }

            // already connected? - Kiểm tra thiết bị có đang kết nối không?
            if ([self getConnectedPeripheral:remoteId] != nil) {
                Log(LDEBUG, @"already connected");
                result(@NO); // no work to do - Đã kết nối
                return;
            }

            // parse
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:remoteId];
            if (uuid == nil) {
                result([FlutterError errorWithCode:@"connect" message:@"invalid remoteId" details:remoteId]);
                return;
            }

            // check the devices iOS knowns about
            CBPeripheral *peripheral = nil;
            for (CBPeripheral *p in [self.centralManager retrievePeripheralsWithIdentifiers:@[
                    uuid]]) {
                if ([[p.identifier UUIDString] isEqualToString:remoteId]) {
                    peripheral = p;
                    break;
                }
            }
            if (peripheral == nil) {
                result([FlutterError errorWithCode:@"connect" message:@"Peripheral not found" details:remoteId]);
                return;
            }

            // we must keep a strong reference to any CBPeripheral before we connect to it.
            // Why? CoreBluetooth does not keep strong references and will warn about API MISUSE and weak ptrs.
            [self.knownPeripherals setObject:peripheral forKey:remoteId];

            // set ourself as delegate
            peripheral.delegate = self;

            // options
            NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
            if (@available
            (iOS
            17, *)) {
                // note: use CBConnectPeripheralOptionEnableAutoReconnect constant
                // when all developers can be excpected to be on iOS 17+
                [options setObject:autoConnect forKey:@"kCBConnectOptionEnableAutoReconnect"];
            }

            // Kết nối thiết bị
            [self.centralManager connectPeripheral:peripheral options:options];

            // add to currently connecting peripherals
            [self.currentlyConnectingPeripherals setObject:peripheral forKey:remoteId];

            result(@YES);
        }
            // Ngắt kết nối
        else if ([@"disconnect" isEqualToString:call.method]) {
            // remoteId is passed raw, not in a NSDictionary
            NSString *remoteId = [call arguments];

            // already disconnected?
            CBPeripheral *peripheral = nil;
            if (peripheral == nil) {
                peripheral = [self.currentlyConnectingPeripherals objectForKey:remoteId];
                if (peripheral != nil) {
                    Log(LDEBUG, @"disconnect: cancelling connection in progress");
                    // Xóa thiết bị khỏi danh sách currentlyConnectingPeripherals
                    [self.currentlyConnectingPeripherals removeObjectForKey:remoteId];
                }
            }
            if (peripheral == nil) {
                peripheral = [self getConnectedPeripheral:remoteId];
            }
            if (peripheral == nil) {
                Log(LDEBUG, @"already disconnected");
                result(@NO); // no work to do
                return;
            }

            // disconnect
            [self.centralManager cancelPeripheralConnection:peripheral];

            result(@YES);
        } else if ([@"discoverServices" isEqualToString:call.method]) {
            // remoteId is passed raw, not in a NSDictionary
            NSString *remoteId = [call arguments];

            // Find peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"discoverServices" message:s details:remoteId]);
                return;
            }

            // Clear helper arrays
            [self.servicesToDiscover removeAllObjects];
            [self.characteristicsToDiscover removeAllObjects];

            // start discovery
            [peripheral discoverServices:nil];

            result(@YES);
        } else if ([@"readCharacteristic" isEqualToString:call.method]) {
            // See BmReadCharacteristicRequest
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSString *remoteId = args[@"remote_id"];
            NSString *serviceUuid = args[@"service_uuid"];
            NSString *characteristicUuid = args[@"characteristic_uuid"];
            NSString *primaryServiceUuid = args[@"primary_service_uuid"];

            // Find peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"readCharacteristic" message:s details:remoteId]);
                return;
            }

            // Find characteristic
            NSError *error = nil;
            CBCharacteristic *characteristic = [self locateCharacteristic:characteristicUuid
                                                               peripheral:peripheral
                                                              serviceUuid:serviceUuid
                                                       primaryServiceUuid:primaryServiceUuid
                                                                    error:&error];
            if (characteristic == nil) {
                result([FlutterError errorWithCode:@"readCharacteristic" message:error.localizedDescription details:NULL]);
                return;
            }

            // check readable
            if ((characteristic.properties & CBCharacteristicPropertyRead) == 0) {
                NSString *s = @"The READ property is not supported by this BLE characteristic";
                result([FlutterError errorWithCode:@"writeCharacteristic" message:s details:NULL]);
                return;
            }

            // Trigger a read
            [peripheral readValueForCharacteristic:characteristic];

            result(@YES);
        } else if ([@"writeCharacteristic" isEqualToString:call.method]) {
            // See BmWriteCharacteristicRequest
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSString *remoteId = args[@"remote_id"];
            NSString *serviceUuid = args[@"service_uuid"];
            NSString *characteristicUuid = args[@"characteristic_uuid"];
            NSString *primaryServiceUuid = args[@"primary_service_uuid"];
            NSNumber *writeTypeNumber = args[@"write_type"];
            NSNumber *allowLongWrite = args[@"allow_long_write"];
            NSData *value = args[@"value"];

            // Find peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"writeCharacteristic" message:s details:remoteId]);
                return;
            }

            // Get correct write type
            CBCharacteristicWriteType writeType =
                    ([writeTypeNumber intValue] == 0
                     ? CBCharacteristicWriteWithResponse
                     : CBCharacteristicWriteWithoutResponse);

            // check maximum payload
            int maxLen = [self getMaxPayload:peripheral forType:writeType allowLongWrite:[allowLongWrite boolValue]];
            int dataLen = (int) value.length;
            if (dataLen > maxLen) {
                NSString *t =
                        [writeTypeNumber intValue] == 0 ? @"withResponse" : @"withoutResponse";
                NSString *a = [allowLongWrite boolValue] ? @", allowLongWrite" : @", noLongWrite";
                NSString *b = [writeTypeNumber intValue] == 0 ? a : @"";
                NSString *f = @"data longer than allowed. dataLen: %d > max: %d (%@%@)";
                NSString *s = [NSString stringWithFormat:f, dataLen, maxLen, t, b];
                result([FlutterError errorWithCode:@"writeCharacteristic" message:s details:NULL]);
                return;
            }

            // device not ready?
            if (writeType == CBCharacteristicWriteWithoutResponse &&
                !peripheral.canSendWriteWithoutResponse) {
                // canSendWriteWithoutResponse is the current readiness of the peripheral to accept more write requests.
                NSString *s = @"canSendWriteWithoutResponse is false. you must slow down";
                result([FlutterError errorWithCode:@"writeCharacteristic" message:s details:NULL]);
                return;
            }

            // Find characteristic
            NSError *error = nil;
            CBCharacteristic *characteristic = [self locateCharacteristic:characteristicUuid
                                                               peripheral:peripheral
                                                              serviceUuid:serviceUuid
                                                       primaryServiceUuid:primaryServiceUuid
                                                                    error:&error];
            if (characteristic == nil) {
                result([FlutterError errorWithCode:@"writeCharacteristic" message:error.localizedDescription details:NULL]);
                return;
            }

            // check writeable
            if (writeType == CBCharacteristicWriteWithoutResponse) {
                if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) ==
                    0) {
                    NSString *s = @"The WRITE_NO_RESPONSE property is not supported by this BLE characteristic";
                    result([FlutterError errorWithCode:@"writeCharacteristic" message:s details:NULL]);
                    return;
                }
            } else {
                if ((characteristic.properties & CBCharacteristicPropertyWrite) == 0) {
                    NSString *s = @"The WRITE property is not supported by this BLE characteristic";
                    result([FlutterError errorWithCode:@"writeCharacteristic" message:s details:NULL]);
                    return;
                }
            }

            // remember the data we are writing
            NSString *key = [NSString stringWithFormat:@"%@:%@:%@:%@", remoteId, serviceUuid, characteristicUuid,
                                                       primaryServiceUuid != nil
                                                       ? primaryServiceUuid : @""];
            [self.writeChrs setObject:value forKey:key];

            // Write to characteristic
            [peripheral writeValue:value forCharacteristic:characteristic type:writeType];

            // remember the most recent write withoutResponse
            if (writeType == CBCharacteristicWriteWithoutResponse) {
                [self.didWriteWithoutResponse setObject:args forKey:remoteId];
            }

            result(@YES);
        } else if ([@"readDescriptor" isEqualToString:call.method]) {
            // See BmReadDescriptorRequest
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSString *remoteId = args[@"remote_id"];
            NSString *serviceUuid = args[@"service_uuid"];
            NSString *characteristicUuid = args[@"characteristic_uuid"];
            NSString *descriptorUuid = args[@"descriptor_uuid"];
            NSString *primaryServiceUuid = args[@"primary_service_uuid"];

            // Find peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"readDescriptor" message:s details:remoteId]);
                return;
            }

            // Find characteristic
            NSError *error = nil;
            CBCharacteristic *characteristic = [self locateCharacteristic:characteristicUuid
                                                               peripheral:peripheral
                                                              serviceUuid:serviceUuid
                                                       primaryServiceUuid:primaryServiceUuid
                                                                    error:&error];
            if (characteristic == nil) {
                result([FlutterError errorWithCode:@"readDescriptor" message:error.localizedDescription details:NULL]);
                return;
            }

            // Find descriptor
            CBDescriptor *descriptor = [self locateDescriptor:descriptorUuid characteristic:characteristic error:&error];
            if (descriptor == nil) {
                result([FlutterError errorWithCode:@"readDescriptor" message:error.localizedDescription details:NULL]);
                return;
            }

            [peripheral readValueForDescriptor:descriptor];

            result(@YES);
        } else if ([@"writeDescriptor" isEqualToString:call.method]) {
            // See BmWriteDescriptorRequest
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSString *remoteId = args[@"remote_id"];
            NSString *serviceUuid = args[@"service_uuid"];
            NSString *characteristicUuid = args[@"characteristic_uuid"];
            NSString *descriptorUuid = args[@"descriptor_uuid"];
            NSString *primaryServiceUuid = args[@"primary_service_uuid"];
            NSData *value = args[@"value"];

            // Find peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"writeDescriptor" message:s details:remoteId]);
                return;
            }

            // check mtu
            int mtu = (int) [self getMtu:peripheral];
            int dataLen = (int) value.length;
            if ((mtu - 3) < dataLen) {
                NSString *f = @"data is longer than MTU allows. dataLen: %d > maxDataLen: %d";
                NSString *s = [NSString stringWithFormat:f, dataLen, (mtu - 3)];
                result([FlutterError errorWithCode:@"writeDescriptor" message:s details:NULL]);
                return;
            }

            // Find characteristic
            NSError *error = nil;
            CBCharacteristic *characteristic = [self locateCharacteristic:characteristicUuid
                                                               peripheral:peripheral
                                                              serviceUuid:serviceUuid
                                                       primaryServiceUuid:primaryServiceUuid
                                                                    error:&error];
            if (characteristic == nil) {
                result([FlutterError errorWithCode:@"writeDescriptor" message:error.localizedDescription details:NULL]);
                return;
            }

            // Find descriptor
            CBDescriptor *descriptor = [self locateDescriptor:descriptorUuid characteristic:characteristic error:&error];
            if (descriptor == nil) {
                result([FlutterError errorWithCode:@"writeDescriptor" message:error.localizedDescription details:NULL]);
                return;
            }
            // remember the data we are writing
            NSString *key = [NSString stringWithFormat:@"%@:%@:%@:%@:%@", remoteId, serviceUuid, characteristicUuid,
                                                       descriptorUuid, primaryServiceUuid != nil
                                                                       ? primaryServiceUuid : @""];
            [self.writeDescs setObject:value forKey:key];

            // Write descriptor
            [peripheral writeValue:value forDescriptor:descriptor];

            result(@YES);
        } else if ([@"setNotifyValue" isEqualToString:call.method]) {
            // See BmSetNotifyValueRequest
            NSDictionary *args = (NSDictionary *) call.arguments;
            NSString *remoteId = args[@"remote_id"];
            NSString *serviceUuid = args[@"service_uuid"];
            NSString *characteristicUuid = args[@"characteristic_uuid"];
            NSString *primaryServiceUuid = args[@"primary_service_uuid"];
            NSNumber *enable = args[@"enable"];

            // Find peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"setNotifyValue" message:s details:remoteId]);
                return;
            }

            // Find characteristic
            NSError *error = nil;
            CBCharacteristic *characteristic = [self locateCharacteristic:characteristicUuid
                                                               peripheral:peripheral
                                                              serviceUuid:serviceUuid
                                                       primaryServiceUuid:primaryServiceUuid
                                                                    error:&error];
            if (characteristic == nil) {
                result([FlutterError errorWithCode:@"setNotifyValue" message:error.localizedDescription details:NULL]);
                return;
            }

            // check notify-able
            bool canNotify = (characteristic.properties & CBCharacteristicPropertyNotify) != 0;
            bool canIndicate = (characteristic.properties & CBCharacteristicPropertyIndicate) != 0;
            if (!canIndicate && !canNotify) {
                NSString *s = @"neither NOTIFY nor INDICATE properties are supported by this BLE characteristic";
                result([FlutterError errorWithCode:@"setNotifyValue" message:s details:NULL]);
                return;
            }

            // Check that CCCD is found, this is necessary for subscribing
            // Kiểm tra xem CCCD đã tìm thấy chưa, điều này cần thiết để đăng ký
            CBDescriptor *descriptor = [self locateDescriptor:CCCD characteristic:characteristic error:nil];
            if (descriptor == nil) {
                Log(LWARNING, @"Warning: CCCD descriptor for characteristic not found: %@",
                    characteristicUuid);
            }

            // Set notification value - Đặt giá trị thông báo
            [peripheral setNotifyValue:[enable boolValue] forCharacteristic:characteristic];

            result(@YES);
        } else if ([@"requestMtu" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"requestMtu"
                                       message:@"iOS does not allow mtu requests to the peripheral"
                                       details:NULL]);
        } else if ([@"readRssi" isEqualToString:call.method]) {
            // remoteId is passed raw, not in a NSDictionary
            NSString *remoteId = [call arguments];

            // get peripheral
            CBPeripheral *peripheral = [self getConnectedPeripheral:remoteId];
            if (peripheral == nil) {
                NSString *s = @"device is disconnected";
                result([FlutterError errorWithCode:@"readRssi" message:s details:remoteId]);
                return;
            }

            [peripheral readRSSI];

            result(@YES);
        } else if ([@"requestConnectionPriority" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"requestConnectionPriority"
                                       message:@"android only"
                                       details:NULL]);
        } else if ([@"getPhySupport" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"getPhySupport"
                                       message:@"android only"
                                       details:NULL]);
        } else if ([@"setPreferredPhy" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"setPreferredPhy"
                                       message:@"android only"
                                       details:NULL]);
        } else if ([@"getBondedDevices" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"getBondedDevices"
                                       message:@"android only"
                                       details:NULL]);
        } else if ([@"createBond" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"setPreferredPhy"
                                       message:@"android only"
                                       details:NULL]);
        } else if ([@"removeBond" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"removeBond"
                                       message:@"android only"
                                       details:NULL]);
        } else if ([@"clearGattCache" isEqualToString:call.method]) {
            result([FlutterError errorWithCode:@"clearGattCache"
                                       message:@"android only"
                                       details:NULL]);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
    @catch (NSException *e) {
        NSString *stackTrace = [[e callStackSymbols] componentsJoinedByString:@"\n"];
        NSDictionary *details = @{@"stackTrace": stackTrace};
        result([FlutterError errorWithCode:@"iosException" message:[e reason] details:details]);
    }
}

////////////////////////////////////////////////////////////////////// Tiện ích riêng tư
// ██████   ██████   ██  ██    ██   █████   ████████  ███████ 
// ██   ██  ██   ██  ██  ██    ██  ██   ██     ██     ██      
// ██████   ██████   ██  ██    ██  ███████     ██     █████   
// ██       ██   ██  ██   ██  ██   ██   ██     ██     ██      
// ██       ██   ██  ██    ████    ██   ██     ██     ███████
//
// ██    ██  ████████  ██  ██       ███████ 
// ██    ██     ██     ██  ██       ██      
// ██    ██     ██     ██  ██       ███████ 
// ██    ██     ██     ██  ██            ██ 
//  ██████      ██     ██  ███████  ███████ 

- (CBPeripheral *)getConnectedPeripheral:(NSString *)remoteId {
    return [self.connectedPeripherals objectForKey:remoteId];
}

- (CBCharacteristic *)locateCharacteristic:(NSString *)characteristicId
                                peripheral:(CBPeripheral *)peripheral
                               serviceUuid:(NSString *)serviceUuid
                        primaryServiceUuid:(NSString *)primaryServiceUuid
                                     error:(NSError **)error {
    // remember
    bool isSecondaryService = primaryServiceUuid != nil;

    // primary service
    if (primaryServiceUuid == nil) {
        primaryServiceUuid = serviceUuid;
    }

    // primary service
    CBService *primaryService = [self getServiceFromArray:primaryServiceUuid array:[peripheral services]];
    if (primaryService == nil || !primaryService.isPrimary) {
        NSString *s = [NSString stringWithFormat:@"primary service not found '%@'", primaryServiceUuid];
        NSDictionary *d = @{NSLocalizedDescriptionKey: s};
        *error = [NSError errorWithDomain:@"flutterBluePlus" code:1000 userInfo:d];
        return nil;
    }

    // associated primary service
    CBService *secondaryService = nil;
    if (isSecondaryService) {
        secondaryService = [self getServiceFromArray:serviceUuid array:[primaryService includedServices]];
        if (error && !secondaryService) {
            NSString *s = [NSString stringWithFormat:@"secondary service not found '%@' (primary service %@)", serviceUuid, primaryServiceUuid];
            NSDictionary *d = @{NSLocalizedDescriptionKey: s};
            *error = [NSError errorWithDomain:@"flutterBluePlus" code:1001 userInfo:d];
            return nil;
        }
    }

    // which service?
    CBService *service = (secondaryService != nil) ? secondaryService : primaryService;

    // characteristic
    CBCharacteristic *characteristic = [self getCharacteristicFromArray:characteristicId array:[service characteristics]];
    if (characteristic == nil) {
        NSString *format = @"characteristic not found in service (chr: '%@', svc: '%@')";
        NSString *s = [NSString stringWithFormat:format, characteristicId, serviceUuid];
        NSDictionary *d = @{NSLocalizedDescriptionKey: s};
        *error = [NSError errorWithDomain:@"flutterBluePlus" code:1002 userInfo:d];
        return nil;
    }
    return characteristic;
}


- (CBDescriptor *)locateDescriptor:(NSString *)descriptorId characteristic:(CBCharacteristic *)characteristic error:(NSError **)error {
    CBDescriptor *descriptor = [self getDescriptorFromArray:descriptorId array:[characteristic descriptors]];
    if (descriptor == nil && error != nil) {
        NSString *format = @"descriptor not found in characteristic (desc: '%@', chr: '%@')";
        NSString *s = [NSString stringWithFormat:format, descriptorId, [characteristic.UUID uuidStr]];
        NSDictionary *d = @{NSLocalizedDescriptionKey: s};
        *error = [NSError errorWithDomain:@"flutterBluePlus" code:1002 userInfo:d];
        return nil;
    }
    return descriptor;
}

- (CBService *)getServiceFromArray:(NSString *)uuid array:(NSArray

<CBService *> *)array
{
    for (CBService *s in array) {
        if ([s.UUID isEqual:[CBUUID UUIDWithString:uuid]]) {
            return s;
        }
    }
    return nil;
}

//Hàm lấy Characteristic từ Service
- (CBCharacteristic *)getCharacteristicFromArray:(NSString *)uuid array:(NSArray

<CBCharacteristic *> *)array
{
    for (CBCharacteristic *c in array) {
        if ([c.UUID isEqual:[CBUUID UUIDWithString:uuid]]) {
            return c;
        }
    }
    return nil;
}

// KHUONG - Helper method to find characteristic by UUID
- (CBCharacteristic *)findCharacteristic:(NSString *)uuidString inService:(CBService *)service {
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuidString]]) {
            return characteristic;
        }
    }
    return nil;
}

- (CBDescriptor *)getDescriptorFromArray:(NSString *)uuid array:(NSArray

<CBDescriptor *> *)array
{
    for (CBDescriptor *d in array) {
        if ([d.UUID isEqual:[CBUUID UUIDWithString:uuid]]) {
            return d;
        }
    }
    return nil;
}

- (void)disconnectAllDevices:(NSString *)func {
    Log(LDEBUG, @"disconnectAllDevices(%@)", func);

    // request disconnections
    for (NSString *key in self.connectedPeripherals) {
        CBPeripheral *peripheral = [self.connectedPeripherals objectForKey:key];

        Log(LDEBUG, @"calling disconnect: %@", key);

        if ([func isEqualToString:@"adapterTurnOff"]) {
            // inexplicably, iOS does not call 'didDisconnectPeripheral' when
            // the adapter is turned off, so we must send these responses manually

            // Note: when the adapter is turned off, it is an 'api misuse'
            // to call cancelPeripheralConnection. It is implied.

            // See BmConnectionStateResponse
            NSDictionary *result = @{
                    @"remote_id": [[peripheral identifier] UUIDString],
                    @"connection_state": @([self bmConnectionStateEnum:CBPeripheralStateDisconnected]),
                    @"disconnect_reason_code": @(1573878), // just a random value, could be anything.
                    @"disconnect_reason_string": @"Bluetooth turned off",
            };

            // Send connection state
            [self.methodChannel invokeMethod:@"OnConnectionStateChanged" arguments:result];
        }

        if ([func isEqualToString:@"flutterRestart"] && [self isAdapterOn]) {
            // request disconnection
            [self.centralManager cancelPeripheralConnection:peripheral];
        }
    }

    // normally connectedPeripherals will be updated by 'didDisconnectPeripheral',
    // but iOS does not call 'didDisconnectPeripheral' when the
    // adapter is turned off, so we must clear it ourself
    if ([func isEqualToString:@"adapterTurnOff"]) {
        [self.connectedPeripherals removeAllObjects];
        [self.currentlyConnectingPeripherals removeAllObjects];
    }

    // note: we do *not* clear self.knownPeripherals
    // Otherwise the peripheral would not have any strong references 
    // and would be garbage collected, making the didDisconnectPeripheral
    // callback not called

    [self.servicesToDiscover removeAllObjects];
    [self.characteristicsToDiscover removeAllObjects];
    [self.didWriteWithoutResponse removeAllObjects];
    [self.peripheralMtu removeAllObjects];
    [self.writeChrs removeAllObjects];
    [self.writeDescs removeAllObjects];
}

////////////////////////////////////
// ███    ███ ████████ ██    ██ 
// ████  ████    ██    ██    ██ 
// ██ ████ ██    ██    ██    ██ 
// ██  ██  ██    ██    ██    ██ 
// ██      ██    ██     ██████  

// in iOS, mtu is negotatiated once automatically sometime after the
// the connection process, but there is no platform callback for it.
- (void)checkForMtuChangesCallback {
    for (NSString *key in self.connectedPeripherals) {

        CBPeripheral *peripheral = [self.connectedPeripherals objectForKey:key];

        int curMtu = (int) [self getMtu:peripheral];

        NSNumber *prevMtu = (NSNumber * )
        [self.peripheralMtu objectForKey:peripheral];

        // mtu changed?
        if (prevMtu == nil || [prevMtu intValue] != curMtu) {

            // remember new mtu value
            [self.peripheralMtu setObject:@(curMtu) forKey:peripheral];

            NSString *remoteId = [[peripheral identifier] UUIDString];

            // See BmMtuChangedResponse
            NSDictionary *mtuChanged = @{
                    @"remote_id": remoteId,
                    @"mtu": @(curMtu),
                    @"success": @(1),
                    @"error_string": @"success",
                    @"error_code": @(0),
            };

            // send mtu value
            [self.methodChannel invokeMethod:@"OnMtuChanged" arguments:mtuChanged];
        }
    }
}

/////////////////////////////////////////////////////////////////////////////////////
//  ██████  ██████    ██████  ███████  ███    ██  ████████  ██████    █████  ██      
// ██       ██   ██  ██       ██       ████   ██     ██     ██   ██  ██   ██ ██      
// ██       ██████   ██       █████    ██ ██  ██     ██     ██████   ███████ ██      
// ██       ██   ██  ██       ██       ██  ██ ██     ██     ██   ██  ██   ██ ██      
//  ██████  ██████    ██████  ███████  ██   ████     ██     ██   ██  ██   ██ ███████ 
//                                                                                                                                          
// ███    ███   █████   ███    ██   █████    ██████   ███████  ██████               
// ████  ████  ██   ██  ████   ██  ██   ██  ██        ██       ██   ██              
// ██ ████ ██  ███████  ██ ██  ██  ███████  ██   ███  █████    ██████               
// ██  ██  ██  ██   ██  ██  ██ ██  ██   ██  ██    ██  ██       ██   ██              
// ██      ██  ██   ██  ██   ████  ██   ██   ██████   ███████  ██   ██              
//                                                                                                                                                   
// ██████   ███████  ██       ███████   ██████    █████   ████████  ███████          
// ██   ██  ██       ██       ██       ██        ██   ██     ██     ██               
// ██   ██  █████    ██       █████    ██   ███  ███████     ██     █████            
// ██   ██  ██       ██       ██       ██    ██  ██   ██     ██     ██               
// ██████   ███████  ███████  ███████   ██████   ██   ██     ██     ███████ 

- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)state {

    Log(LDEBUG, @"centralManagerWillRestoreState");

    // restore adapter state
    [self centralManagerDidUpdateState:central];

    NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];

    for (CBPeripheral *peripheral in peripherals) {

        // Set the delegate to self to receive the peripheral callbacks
        peripheral.delegate = self;

        if (peripheral.state != CBPeripheralStateConnected) {
            // connect
            Log(LDEBUG, @"Restore: reconnecting to %@", peripheral.identifier.UUIDString);
            [self.centralManager connectPeripheral:peripheral options:nil];
        } else {
            // update connection state
            Log(LDEBUG, @"Restore: already connected to %@", peripheral.identifier.UUIDString);
            [self centralManager:central didConnectPeripheral:peripheral];

            for (CBService *service in peripheral.services) {

                // restore services
                [self peripheral:peripheral didDiscoverServices:nil];

                for (CBCharacteristic *characteristic in service.characteristics) {

                    // restore characteristics
                    [self peripheral:peripheral didDiscoverCharacteristicsForService:service error:nil];

                    // restore notifications
                    if (characteristic.isNotifying) {
                        [self peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:nil];
                    }
                }
            }
        }
    }
}

// Khi trạng thái Bluetooth thay đổi.
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager

*)central
{
    Log(LDEBUG, @"centralManagerDidUpdateState %@",
        [self cbManagerStateString:self.centralManager.state]);

    int adapterState = [self bmAdapterStateEnum:self.centralManager.state];

    // stop scanning when adapter is turned off. 
    // Otherwise, scanning automatically resumes when the adapter is
    // turned back on. I don't think most users expect that.
    if (self.centralManager.state != CBManagerStatePoweredOn) {
        [self.centralManager stopScan];
    }

    // See BmBluetoothAdapterState
    NSDictionary *response = @{
            @"adapter_state": @(adapterState),
    };

    [self.methodChannel invokeMethod:@"OnAdapterStateChanged" arguments:response];

    // disconnect all devices
    if (self.centralManager.state != CBManagerStatePoweredOn) {
        [self disconnectAllDevices:@"adapterTurnOff"];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary

<NSString *, id> *)
advertisementData
        RSSI
:(NSNumber *)RSSI
{
    Log(LVERBOSE, @"centralManager didDiscoverPeripheral");

    NSString *remoteId = [[peripheral identifier] UUIDString];

    // add to known peripherals
    [self.knownPeripherals setObject:peripheral forKey:remoteId];

    // advertising data
    NSArray * advServices = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    NSString *advName = advertisementData[CBAdvertisementDataLocalNameKey];
    NSData *advMsd = advertisementData[CBAdvertisementDataManufacturerDataKey];
    NSDictionary * advSd = advertisementData[CBAdvertisementDataServiceDataKey];

    BOOL allow = NO;

    // are any filters set?
    BOOL isAnyFilterSet = [self hasFilter:@"with_services"] ||
                          [self hasFilter:@"with_remote_ids"] ||
                          [self hasFilter:@"with_names"] ||
                          [self hasFilter:@"with_keywords"] ||
                          [self hasFilter:@"with_msd"] ||
                          [self hasFilter:@"with_service_data"];

    // no filters set? allow all
    if (!isAnyFilterSet) {
        allow = YES;
    }

    // apply filters only if at least one filter is set
    // Note: filters are additive. An advertisment can match *any* filter
    if (isAnyFilterSet) {
        // filter services
        if (!allow && [self foundService:self.scanFilters[@"with_services"] target:advServices]) {
            allow = YES;
        }

        // filter remoteIds
        if (!allow && [self foundRemoteId:self.scanFilters[@"with_remote_ids"] target:remoteId]) {
            allow = YES;
        }

        // filter names
        if (!allow && [self foundName:self.scanFilters[@"with_names"] target:advName]) {
            allow = YES;
        }

        // filter keywords
        if (!allow && [self foundKeyword:self.scanFilters[@"with_keywords"] target:advName]) {
            allow = YES;
        }

        // filter msd
        if (!allow && [self foundMsd:self.scanFilters[@"with_msd"] msd:advMsd]) {
            allow = YES;
        }

        // filter service data
        if (!allow && [self foundServiceData:self.scanFilters[@"with_service_data"] sd:advSd]) {
            allow = YES;
        }
    }

    // If no filters are satisfied, return
    if (!allow) {
        return;
    }

    // filter divisor
    if ([self.scanFilters[@"continuous_updates"] integerValue] != 0) {
        NSInteger count = [self scanCountIncrement:remoteId];
        NSInteger divisor = [self.scanFilters[@"continuous_divisor"] integerValue];
        if ((count % divisor) != 0) {
            return;
        }
    }

    // See BmScanResponse
    NSDictionary * response = @{
            @"advertisements": @[
                    [self bmScanAdvertisement:remoteId advertisementData:advertisementData RSSI:RSSI]],
    };

    [self.methodChannel invokeMethod:@"OnScanResponse" arguments:response];
}

// 😎 1️⃣
- (void)centralManager:(CBCentralManager *)central
//KHƯƠNG Khi thiết bị BLE kết nối thành công.
  didConnectPeripheral:(CBPeripheral *)peripheral { // = onConnectionStateChange JAVA Kết nối thành công
    Log(LDEBUG, @"didConnectPeripheral");
    NSLog(@"🔗 Đã kết nối với thiết bị BLE: %@", peripheral.name);
    NSString *remoteId = [[peripheral identifier] UUIDString];

    // remember the connected peripherals of *this app* - Nhớ và thêm các thiết bị vào danh sách đã kết nối
    [self.connectedPeripherals setObject:peripheral forKey:remoteId];

    // remove from currently connecting peripherals - Gỡ thiết bị khỏi danh sách đang kết nối
    [self.currentlyConnectingPeripherals removeObjectForKey:remoteId];
    NSLog(@"🔗 Đã kết nối với thiết bị BLE: %@", peripheral.name);
    // Register self as delegate for peripheral - Đăng ký delegate để nhận sự kiện từ thiết bị
    peripheral.delegate = self;
    // Bắt đầu quét dịch vụ (giống gatt.discoverServices() trên Android)
    [peripheral discoverServices:nil]; // = gatt.discoverServices() (SUGAIOT)

    // See BmConnectionStateResponse
    // Gửi sự kiện kết nối thành công về Flutter
    NSDictionary *result = @{
            @"remote_id": remoteId,
            @"connection_state": @([self bmConnectionStateEnum:peripheral.state]),
            @"disconnect_reason_code": [NSNull null],
            @"disconnect_reason_string": [NSNull null],
    };

    // Send connection state
    [self.methodChannel invokeMethod:@"OnConnectionStateChanged" arguments:result];
}

// 😎 1️⃣.1️⃣
- (void) centralManager:(CBCentralManager *)central
// Khi thiết bị BLE bị ngắt kết nối.
didDisconnectPeripheral:(CBPeripheral *)peripheral // = onConnectionStateChange JAVA Ngắt kết nối với thiết bị
                  error:(NSError *)error {
    if (error) {
        NSLog(@"⚠️ Lỗi khi mất kết nối: %@", [error localizedDescription]);
        Log(LERROR, @"didDisconnectPeripheral:");
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        NSLog(@"🔌 Thiết bị BLE bị ngắt kết nối.");
        Log(LDEBUG, @"didDisconnectPeripheral:");
    }

    NSString *remoteId = [[peripheral identifier] UUIDString];

    // remember the connected peripherals of *this app* - Xóa thiết bị khỏi danh sách đã kết nối
    [self.connectedPeripherals removeObjectForKey:remoteId];

    // remove from currently connecting peripherals
    [self.currentlyConnectingPeripherals removeObjectForKey:remoteId];

    // clear negotiated mtu
    [self.peripheralMtu removeObjectForKey:peripheral];

    // Unregister self as delegate for peripheral, not working #42
    peripheral.delegate = nil;

    // random number defined by flutter blue plus
    int bmUserCanceledErrorCode = 23789258;

    // See BmConnectionStateResponse
    // Gửi sự kiện mất kết nối về Flutter
    //KHƯƠNG Gửi broadcast thông báo ngắt kết nối
    [[NSNotificationCenter defaultCenter] postNotificationName:BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE
                                                        object:nil
                                                      userInfo:@{@"peripheral": peripheral}];
    // KHƯƠNG
    NSDictionary *result = @{
            @"remote_id": remoteId,
            @"connection_state": @([self bmConnectionStateEnum:peripheral.state]),
            @"disconnect_reason_code": error ? @(error.code)
                                             : @(bmUserCanceledErrorCode), // Mã lỗi tùy chỉnh
            @"disconnect_reason_string": error ? [error localizedDescription]
                                               : @("Ngắt kết nối thành công"),
//                                         @("connection canceled"),
    };

    // Send connection state
    [self.methodChannel invokeMethod:@"OnConnectionStateChanged" arguments:result];
}

- (void)    centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                     error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didFailToConnectPeripheral:");
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didFailToConnectPeripheral:");
    }

    NSString *remoteId = [[peripheral identifier] UUIDString];

    // remove from currently connecting peripherals
    [self.currentlyConnectingPeripherals removeObjectForKey:remoteId];

    // See BmConnectionStateResponse
    NSDictionary *result = @{
            @"remote_id": [[peripheral identifier] UUIDString],
            @"connection_state": @([self bmConnectionStateEnum:peripheral.state]),
            @"disconnect_reason_code": error ? @(error.code) : [NSNull null],
            @"disconnect_reason_string": error ? [error localizedDescription] : [NSNull null],
    };

    // Send connection state
    [self.methodChannel invokeMethod:@"OnConnectionStateChanged" arguments:result];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ██████  ██████   ██████   ███████  ██████   ██  ██████   ██   ██  ███████  ██████    █████   ██      
// ██       ██   ██  ██   ██  ██       ██   ██  ██  ██   ██  ██   ██  ██       ██   ██  ██   ██  ██      
// ██       ██████   ██████   █████    ██████   ██  ██████   ███████  █████    ██████   ███████  ██      
// ██       ██   ██  ██       ██       ██   ██  ██  ██       ██   ██  ██       ██   ██  ██   ██  ██      
//  ██████  ██████   ██       ███████  ██   ██  ██  ██       ██   ██  ███████  ██   ██  ██   ██  ███████
//
// ██████   ███████  ██       ███████   ██████    █████   ████████  ███████          
// ██   ██  ██       ██       ██       ██        ██   ██     ██     ██               
// ██   ██  █████    ██       █████    ██   ███  ███████     ██     █████            
// ██   ██  ██       ██       ██       ██    ██  ██   ██     ██     ██               
// ██████   ███████  ███████  ███████   ██████   ██   ██     ██     ███████ 

/// KHƯƠNG - Xử lý khi tìm thấy dịch vụ UUID đã cấu hình
// 😎 2️⃣
- (void) peripheral:(CBPeripheral *)peripheral
// tìm kiếm dịch vụ UUID của BLE (MÁY) - Tìm dịch vụ glucose sau khi peripheral đã khám phá các dịch vụ.
// didDiscoverServices  ➡️ didDiscoverCharacteristicsForService
didDiscoverServices:(NSError *)error { // = onServicesDiscovered JAVA
    if (error) {
        Log(LERROR, @"didDiscoverServices:");
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didDiscoverServices:");
    }
    // discover characteristics and included services - khám phá các đặc điểm và dịch vụ đi kèm
    [self.servicesToDiscover addObjectsFromArray:peripheral.services];
    for (CBService *s in [peripheral services]) {
        Log(LDEBUG, @"svc: %@", [s.UUID uuidStr]);
        [peripheral discoverCharacteristics:nil forService:s];
        [peripheral discoverIncludedServices:nil forService:s];
    }
    // KHƯƠNG
    // Tìm glucose service
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:GLUCOSE_SERVICE_UUID]]) {
            self.glucoseService = service;
            NSLog(@"✅ Found Glucose Service: %@", service.UUID.UUIDString);
            // Tìm glucose measurement characteristic
            CBCharacteristic *glucoseMeasurementCharacteristic = [self findCharacteristic:GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID
                                                                                inService:service];
            if (glucoseMeasurementCharacteristic) {
                // Thiết lập thông báo cho đặc tính đo glucose
                NSData *enableNotificationValue = [NSData dataWithBytes:&(uint16_t) {
                        0x01}                                    length:sizeof(uint16_t)];
                [self setCharacteristicClientConfigDescriptor:peripheral
                                               characteristic:glucoseMeasurementCharacteristic
                                                        value:enableNotificationValue];
            }
            break;
        }
    }
}
/// KHƯƠNG


// Callback khi tìm thấy characteristics
- (void)                  peripheral:(CBPeripheral *)peripheral
// Lấy danh sách các đặc tính (characteristics) của dịch vụ BLE.
// Khi đặc tính được phát hiện, nó tìm đặc tính đo glucose và bật thông báo (setNotifyValue:YES).
// 😎 2️⃣.1️⃣
didDiscoverCharacteristicsForService:(CBService *)service
                               error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didDiscoverCharacteristicsForService:");
        Log(LERROR, @"  svc: %@", [service.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didDiscoverCharacteristicsForService:");
        Log(LDEBUG, @"  svc: %@", [service.UUID uuidStr]);
    }

    // Loop through and discover descriptors for characteristics
    [self.servicesToDiscover removeObject:service];
    [self.characteristicsToDiscover addObjectsFromArray:service.characteristics];
    for (CBCharacteristic *c in [service characteristics]) {
        Log(LDEBUG, @"    chr: %@", [c.UUID uuidStr]);
        [peripheral discoverDescriptorsForCharacteristic:c];
    }
    // KHUONG
    if ([service.UUID isEqual:[CBUUID UUIDWithString:GLUCOSE_SERVICE_UUID]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID]]) {
                // Thiết lập thông báo cho đặc tính đo glucose
                NSData *enableNotificationValue = [NSData dataWithBytes:&(uint16_t) {
                        0x01}                                    length:sizeof(uint16_t)];
                if (![self setCharacteristicClientConfigDescriptor:peripheral characteristic:characteristic value:enableNotificationValue]) {
                    NSLog(@"❌ Không thể thiết lập thông báo cho characteristic: %@",
                          characteristic.UUID.UUIDString);
                }
                break;
            }
        }
        // KHUONG


    }
}

/// KHƯƠNG (Giống với setCharacteristicClientConfigDescriptor of SUGAIOT and JAVA)
- (BOOL)setCharacteristicClientConfigDescriptor:(CBPeripheral *)peripheral
                                 characteristic:(CBCharacteristic *)characteristic
                                          value:(NSData *)value {
    // 🔹 1. Kích hoạt thông báo cho đặc tính (Bật Notify/Indicate)
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    // 🔹 2. Lấy UUID của Client Characteristic Configuration Descriptor (CCCD)
    CBUUID *configDescriptorUUID = [CBUUID UUIDWithString:CLIENT_CHARACTERISTICS_CONFIGURATION_DESCRIPTOR];

    // 🔹 3. Tìm descriptor phù hợp trong danh sách descriptors của characteristic
    CBDescriptor *clientCharacteristicConfigDesc = nil;
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        if ([descriptor.UUID isEqual:configDescriptorUUID]) {
            clientCharacteristicConfigDesc = descriptor;
            break;
        }
    }

    // 🔹 4. Nếu tìm thấy descriptor, ghi giá trị vào nó
    if (clientCharacteristicConfigDesc) {
        NSLog(@"✅ CCCD đã được tìm thấy, tiến hành ghi giá trị.");
        // chỉ ghi được vào Characteristic mới đau
//        [peripheral writeValue:value forDescriptor:clientCharacteristicConfigDesc];

        // 🔹 5. Gọi trực tiếp `didWriteValueForDescriptor`
        [self peripheral:peripheral didWriteValueForDescriptor:clientCharacteristicConfigDesc error:nil];

        return YES;
    }

    NSLog(@"❌ Không tìm thấy Client Characteristic Configuration Descriptor.");
    return NO;

}
/// KHƯƠNG

- (void)                     peripheral:(CBPeripheral *)peripheral
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
                                  error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didDiscoverDescriptorsForCharacteristic:");
        Log(LERROR, @"  chr: %@", [characteristic.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        // KHƯƠNG cái này in ra UUIDs của thiết bị tiểu đường
        Log(LDEBUG, @"didDiscoverDescriptorsForCharacteristic:");
        Log(LDEBUG, @"KHUONG UUID chr: %@", [characteristic.UUID uuidStr]);
    }

    // print descriptors - mô tả đặc tính
    for (CBDescriptor *d in [characteristic descriptors]) {
        Log(LDEBUG, @"    desc: %@", [d.UUID uuidStr]);
    }

    // have we finished discovering? - Đã khám phá xong chưa?
    [self.characteristicsToDiscover removeObject:characteristic];
    if (self.servicesToDiscover.count > 0 || self.characteristicsToDiscover.count > 0) {
        return; // Still discovering
    }

    // Add BmBluetoothServices to array - Thêm vào mảng
    NSMutableArray *services = [NSMutableArray new];
    for (CBService *s in [peripheral services]) {
        [services addObject:[self bmBluetoothService:peripheral service:s]];
    }

    // See BmDiscoverServicesResult
    NSDictionary *response = @{
            @"remote_id": [peripheral.identifier UUIDString],
            @"services": services,
            @"success": error == nil ? @(1) : @(0),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    };
    // Send updated tree
    [self.methodChannel invokeMethod:@"OnDiscoveredServices" arguments:response];
}

- (void)                   peripheral:(CBPeripheral *)peripheral
didDiscoverIncludedServicesForService:(CBService *)service
                                error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didDiscoverIncludedServicesForService:");
        Log(LERROR, @"  svc: %@", [service.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didDiscoverIncludedServicesForService:");
        Log(LDEBUG, @"  svc: %@", [service.UUID uuidStr]);
    }

    // discover characteristics 
    [peripheral discoverCharacteristics:nil forService:service];
}

//KHƯƠNG - Xử lý dữ liệu đo đường huyết khi có dữ liệu đo mới
// 😎 4️⃣
- (void)             peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic // = onCharacteristicChanged JAVA
                          error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didUpdateValueForCharacteristic:");
        Log(LERROR, @"  chr: %@", [characteristic.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didUpdateValueForCharacteristic:");
        Log(LDEBUG, @"  chr: %@", [characteristic.UUID uuidStr]);
    }

    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID]]) {
        GlucoseMeasurementRecord *glucoseMeasurementRecord = [[GlucoseMeasurementRecord alloc] init];
        int offset = 0;

        // Get flag byte
        uint8_t flag;
        [characteristic.value getBytes:&flag range:NSMakeRange(offset, 1)];
        offset += 1; // offset is 1

        // Get sequence number
        uint16_t sequenceNumber;
        [characteristic.value getBytes:&sequenceNumber range:NSMakeRange(offset, 2)];
        glucoseMeasurementRecord.sequenceNumber = sequenceNumber;
        offset += 2;  // offset is 3

        // Get base time
        uint16_t baseTimeYear;
        [characteristic.value getBytes:&baseTimeYear range:NSMakeRange(offset, 2)];
        offset += 2; // offset is 5

        uint8_t baseTimeMonth, baseTimeDay, baseTimeHours, baseTimeMinutes, baseTimeSeconds;
        [characteristic.value getBytes:&baseTimeMonth range:NSMakeRange(offset++, 1)];
        [characteristic.value getBytes:&baseTimeDay range:NSMakeRange(offset++, 1)];
        [characteristic.value getBytes:&baseTimeHours range:NSMakeRange(offset++, 1)];
        [characteristic.value getBytes:&baseTimeMinutes range:NSMakeRange(offset++, 1)];
        [characteristic.value getBytes:&baseTimeSeconds range:NSMakeRange(offset++, 1)];

        // Create calendar
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.year = baseTimeYear;
        components.month = baseTimeMonth;
        components.day = baseTimeDay;
        components.hour = baseTimeHours;
        components.minute = baseTimeMinutes;
        components.second = baseTimeSeconds;
        glucoseMeasurementRecord.calendar = [calendar dateFromComponents:components];

        // Time Offset
        if (flag & (1 << 0)) {
            uint16_t timeOffset;
            [characteristic.value getBytes:&timeOffset range:NSMakeRange(offset, 2)];
            glucoseMeasurementRecord.timeOffset = timeOffset;
            offset += 2; // offset is 12
        } else {
            glucoseMeasurementRecord.timeOffset = 0;
        }

        // Handle glucose concentration
        if (flag & (1 << 1)) {
            uint16_t glucoseValue;
            [characteristic.value getBytes:&glucoseValue range:NSMakeRange(offset, 1)];

            // Glucose concentration unit of measurement
            if (flag & (1 << 2)) {
                glucoseMeasurementRecord.glucoseConcentrationMeasurementUnit = MOLES_PER_LITRE;
            } else {
                glucoseMeasurementRecord.glucoseConcentrationMeasurementUnit = KILOGRAM_PER_LITRE;
            }

            glucoseMeasurementRecord.glucoseConcentrationValue = glucoseValue;

            offset += 2; // offset is 14

            // Get type and sample location
            uint8_t typeAndSampleLocation;
            [characteristic.value getBytes:&typeAndSampleLocation range:NSMakeRange(offset, 1)];
            glucoseMeasurementRecord.type = typeAndSampleLocation >> 4;
            glucoseMeasurementRecord.sampleLocationInteger = typeAndSampleLocation & 0x0F;
            offset += 1; // offset is 15
            [glucoseMeasurementRecord updateTestBloodTypeAndSampleLocation];

        }

        // Handle sensor status
        if (flag & (1 << 2)) {
            uint16_t sensorStatusValue;
            [characteristic.value getBytes:&sensorStatusValue range:NSMakeRange(offset, 2)];
            offset += 2; // offset is 16 or 12 or 9

            SensorStatusAnnunciation *sensorStatus = [[SensorStatusAnnunciation alloc] init];
            sensorStatus.deviceBatteryLowAtTimeOfMeasurement = sensorStatusValue & (1 << 0);
            sensorStatus.sensorMalfunctionAtTimeOfMeasurement = sensorStatusValue & (1 << 1);
            sensorStatus.bloodSampleInsufficientAtTimeOfMeasurement = sensorStatusValue & (1 << 2);
            sensorStatus.stripInsertionError = sensorStatusValue & (1 << 3);
            sensorStatus.stripTypeIncorrectForDevice = sensorStatusValue & (1 << 4);
            sensorStatus.sensorResultHigherThanDeviceCanProcess = sensorStatusValue & (1 << 5);
            sensorStatus.sensorResultLowerThanTheDeviceCanProcess = sensorStatusValue & (1 << 6);
            sensorStatus.sensorTemperatureTooHighForValidTestResult = sensorStatusValue & (1 << 7);
            sensorStatus.sensorTemperatureTooLowForValidTestResult = sensorStatusValue & (1 << 8);
            sensorStatus.sensorReadInterruptedBecauseStripWasPulledTooSoon =
                    sensorStatusValue & (1 << 9);
            sensorStatus.generalDeviceFaultHasOccurredInSensor = sensorStatusValue & (1 << 10);
            sensorStatus.timeFaultHasOccurredInTheSensor = sensorStatusValue & (1 << 11);

            glucoseMeasurementRecord.sensorStatusAnnunciation = sensorStatus;
        }

        // Send broadcast
        [[NSNotificationCenter defaultCenter] postNotificationName:BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE
                                                            object:nil
                                                          userInfo:@{
                                                                  @"glucoseMeasurementRecord": glucoseMeasurementRecord}];
        [self.glucoseMeasurementRecords addObject:glucoseMeasurementRecord];
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID]]) {
        // xử lý thông tin để biết là trước khi ăn, sau khi ăn, nhịn đói và không xác định.
        // TODO: Handle glucose measurement context characteristic
        NSData *data = characteristic.value;
        if (data != nil && data.length >= 5) {
            const uint8_t *bytes = (const uint8_t *) data.bytes;

            // Byte 1–2 là Sequence Number (Little Endian)
            int contextSequenceNumber = bytes[1] | (bytes[2] << 8);

            // Byte thứ 5 (index 4) là thông tin bữa ăn
            uint8_t mealByte = bytes[4];
            NSString *mealInfo;

            switch (mealByte) {
                case 0x01:
                    mealInfo = @"Trước khi ăn";
                    break;
                case 0x02:
                    mealInfo = @"Sau khi ăn";
                    break;
                case 0x03:
                    mealInfo = @"Khi đói";
                    break;
                default:
                    mealInfo = @"Không xác định";
                    break;
            }

            // Tìm đúng GlucoseMeasurementRecord theo sequenceNumber
            for (GlucoseMeasurementRecord *record in self.glucoseMeasurementRecords) {
                if (record.sequenceNumber == contextSequenceNumber) {
                    record.mealInfo = mealInfo;
                    NSLog(@"[DEBUG] Gán mealInfo cho record #%d: %@", contextSequenceNumber,
                          mealInfo);
                    break;
                }
            }
        }
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RECORDS_SENT_COMPLETE
                                                            object:nil];
    }
    [self printGlucoseMeasurementRecords];
    [self sendGlucoseRecordsToFlutter:self.glucoseMeasurementRecords];

}

// Gửi dữ liệu GlucoseMeasurementRecord qua Method Channel
- (void)sendGlucoseRecordsToFlutter:(NSArray

<GlucoseMeasurementRecord *> *)records {
    NSMutableArray *glucoseMeasurementList = [NSMutableArray array];

    for (GlucoseMeasurementRecord *record in records) {
        NSMutableDictionary *glucoseData = [NSMutableDictionary dictionary];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear |
                                                             NSCalendarUnitMonth |
                                                             NSCalendarUnitDay |
                                                             NSCalendarUnitHour |
                                                             NSCalendarUnitMinute |
                                                             NSCalendarUnitSecond)
                                                   fromDate:record.calendar];

        glucoseData[@"sequenceNumber"] = @(record.sequenceNumber);
        glucoseData[@"baseTimeYear"] = @(components.year);
        glucoseData[@"baseTimeMonth"] = @(components.month);
        glucoseData[@"baseTimeDay"] = @(components.day);
        glucoseData[@"baseTimeHours"] = @(components.hour);
        glucoseData[@"baseTimeMinutes"] = @(components.minute);
        glucoseData[@"baseTimeSeconds"] = @(components.second);
        glucoseData[@"timeOffset"] = @(record.timeOffset);

        glucoseData[@"measurementUnit"] =
                record.glucoseConcentrationMeasurementUnit == MOLES_PER_LITRE ? @"MOLES_PER_LITRE"
                                                                              : @"KILOGRAM_PER_LITRE";
//        glucoseData[@"glucoseConcentrationValue"] = @(record.glucoseConcentrationValue);
        glucoseData[@"glucoseConcentrationValue"] = @((float) record.glucoseConcentrationValue /
                                                      100000.0f);

        glucoseData[@"type"] = @(record.type);
        glucoseData[@"testBloodType"] = record.testBloodType;
        glucoseData[@"sampleLocation"] = record.sampleLocation ?: @"";
        glucoseData[@"sampleLocationInteger"] = @(record.sampleLocationInteger);
        glucoseData[@"mealInfo"] = record.mealInfo;

        if (record.sensorStatusAnnunciation) {
            NSMutableDictionary *sensorStatus = [NSMutableDictionary dictionary];
            sensorStatus[@"batteryLow"] = @(record.sensorStatusAnnunciation.deviceBatteryLowAtTimeOfMeasurement);
            sensorStatus[@"sensorMalfunction"] = @(record.sensorStatusAnnunciation.sensorMalfunctionAtTimeOfMeasurement);
            sensorStatus[@"insufficientBloodSample"] = @(record.sensorStatusAnnunciation.bloodSampleInsufficientAtTimeOfMeasurement);
            sensorStatus[@"stripInsertionError"] = @(record.sensorStatusAnnunciation.stripInsertionError);
            sensorStatus[@"stripTypeIncorrect"] = @(record.sensorStatusAnnunciation.stripTypeIncorrectForDevice);
            sensorStatus[@"resultHigherThanProcessable"] = @(record.sensorStatusAnnunciation.sensorResultHigherThanDeviceCanProcess);
            sensorStatus[@"resultLowerThanProcessable"] = @(record.sensorStatusAnnunciation.sensorResultLowerThanTheDeviceCanProcess);
            sensorStatus[@"temperatureTooHigh"] = @(record.sensorStatusAnnunciation.sensorTemperatureTooHighForValidTestResult);
            sensorStatus[@"temperatureTooLow"] = @(record.sensorStatusAnnunciation.sensorTemperatureTooLowForValidTestResult);
            sensorStatus[@"readInterrupted"] = @(record.sensorStatusAnnunciation.sensorReadInterruptedBecauseStripWasPulledTooSoon);
            sensorStatus[@"generalDeviceFault"] = @(record.sensorStatusAnnunciation.generalDeviceFaultHasOccurredInSensor);
            sensorStatus[@"timeFault"] = @(record.sensorStatusAnnunciation.timeFaultHasOccurredInTheSensor);

            glucoseData[@"sensorStatus"] = sensorStatus;
        }

        [glucoseMeasurementList addObject:glucoseData];
    }

    NSDictionary * glucoseDataRecords = @{@"glucoseDataRecords": glucoseMeasurementList};

    // Gửi về Flutter
    [self.methodChannel invokeMethod:@"OnGlucoseRecordsReceived" arguments:glucoseDataRecords];

}


// Phương thức in danh sách các bản ghi GlucoseMeasurementRecord
- (void)printGlucoseMeasurementRecords {
    if (self.glucoseMeasurementRecords.count == 0) {
        NSLog(@"Danh sách không có bản ghi đo đường huyết nào.");
        return;
    }

    NSLog(@"Danh sách các bản ghi đo đường huyết:");

    for (GlucoseMeasurementRecord *record in self.glucoseMeasurementRecords) {
        NSLog(@"-----------------------------------------------------");
        NSLog(@"Số thứ tự lần đo: %d", record.sequenceNumber);
        NSLog(@"Thời gian đo: %@",
              record.calendar); // cái này đang trả ra hiển thị trên UI flutter đúng với bên Android
        // còn hiển thị log ở đây là sẽ lệch 7h so với bên JAVA nhưng cái này là đúng với flutter vì chỉ là hiển thị ra log thôi nhoá 😂

        NSLog(@"Độ lệch thời gian (timeOffset): %d", record.timeOffset);

        // In nồng độ glucose và đơn vị đo
        if (record.glucoseConcentrationMeasurementUnit ==
            MOLES_PER_LITRE) {
            NSLog(@"Nồng độ glucose : %@",
                  [record convertGlucoseConcentrationValueToMilligramsPerDeciliter]);

        } else {

            NSLog(@"Nồng độ glucose : %@",
                  [record convertGlucoseConcentrationValueToMilligramsPerDeciliter]);

        }
        NSLog(@"Value: %0.f", record.glucoseConcentrationValue);
        NSLog(@"Đơn vị đo: %@",
              record.glucoseConcentrationMeasurementUnit == MOLES_PER_LITRE ? @"MOLES_PER_LITRE"
                                                                            : @"KILOGRAM_PER_LITRE");    // In loại mẫu và vị trí lấy mẫu
        NSLog(@"Loại mẫu: %d", record.type);
        NSLog(@"Tên mẫu: %@", record.testBloodType);
        NSLog(@"Where: %@", record.sampleLocation);
        NSLog(@"MEAL: %@", record.mealInfo);
        NSLog(@"Vị trí lấy mẫu: %d", record.sampleLocationInteger);

        if (record.sensorStatusAnnunciation != nil) {
            SensorStatusAnnunciation *sensor = record.sensorStatusAnnunciation;
            NSLog(@"Trạng thái cảm biến:");
            NSLog(@"Pin yếu: %@", sensor.deviceBatteryLowAtTimeOfMeasurement ? @"YES" : @"NO");
            NSLog(@"Lỗi cảm biến: %@",
                  sensor.sensorMalfunctionAtTimeOfMeasurement ? @"YES" : @"NO");
            NSLog(@"Mẫu máu không đủ: %@",
                  sensor.bloodSampleInsufficientAtTimeOfMeasurement ? @"YES" : @"NO");
            NSLog(@"Lỗi chèn que thử: %@", sensor.stripInsertionError ? @"YES" : @"NO");
            NSLog(@"Loại dải không đúng cho thiết bị: %@",
                  sensor.stripTypeIncorrectForDevice ? @"YES" : @"NO");
            NSLog(@"Cảm biến kết quả cao hơn thiết bị có thể xử lý: %@",
                  sensor.sensorResultHigherThanDeviceCanProcess ? @"YES" : @"NO");
            NSLog(@"Cảm biến kết quả thấp hơn thiết bị có thể xử lý: %@",
                  sensor.sensorResultLowerThanTheDeviceCanProcess ? @"YES" : @"NO");
            NSLog(@"Nhiệt độ quá cao: %@",
                  sensor.sensorTemperatureTooHighForValidTestResult ? @"YES" : @"NO");
            NSLog(@"Nhiệt độ quá thấp: %@",
                  sensor.sensorTemperatureTooLowForValidTestResult ? @"YES" : @"NO");
            NSLog(@"Cảm biến đọc bị gián đoạn Vì Dải Đã Được Kéo Quá Sớm: %@",
                  sensor.sensorReadInterruptedBecauseStripWasPulledTooSoon ? @"YES" : @"NO");
            NSLog(@"Lỗi thiết bị chung đã xảy ra trong cảm biến: %@",
                  sensor.generalDeviceFaultHasOccurredInSensor ? @"YES" : @"NO");
            NSLog(@"Thời gian Lỗi đã xảy ra trong cảm biến: %@",
                  sensor.timeFaultHasOccurredInTheSensor ? @"YES" : @"NO");
        }
    }
}


- (void)            peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                         error:(NSError *)error {
    // Note: this callback is only called for writeWithResponse
    if (error) {
        Log(LERROR, @"didWriteValueForCharacteristic:");
        Log(LERROR, @"  chr: %@", [characteristic.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didWriteValueForCharacteristic:");
        Log(LDEBUG, @"  chr: %@", [characteristic.UUID uuidStr]);
    }

    CBService *primaryService = [self getPrimaryService:peripheral characteristic:characteristic];

    // for convenience
    NSString *remoteId = [peripheral.identifier UUIDString];
    NSString *serviceUuid = [characteristic.service.UUID uuidStr];
    NSString *characteristicUuid = [characteristic.UUID uuidStr];

    // what data did we write?
    NSString *key = [NSString stringWithFormat:@"%@:%@:%@:%@", remoteId, serviceUuid, characteristicUuid,
                                               primaryService != nil ? [primaryService.UUID uuidStr]
                                                                     : @""];
    NSData *value = self.writeChrs[key] ? self.writeChrs[key] : [NSMutableData data];
    [self.writeChrs removeObjectForKey:key];

    // See BmCharacteristicData
    NSMutableDictionary *result = [@{
            @"remote_id": remoteId,
            @"service_uuid": [characteristic.service.UUID uuidStr],
            @"characteristic_uuid": characteristicUuid,
            @"primary_service_uuid": primaryService ? [primaryService.UUID uuidStr] : [NSNull null],
            @"value": value,
            @"success": @(error == nil),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    } mutableCopy];

    // remove if null
    if (!primaryService) { [result removeObjectForKey:@"primary_service_uuid"]; }

    [self.methodChannel invokeMethod:@"OnCharacteristicWritten" arguments:result];
}

- (void)                         peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
                                      error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didUpdateNotificationStateForCharacteristic:");
        Log(LERROR, @"  chr: %@", [characteristic.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didUpdateNotificationStateForCharacteristic:");
        Log(LDEBUG, @"  chr: %@", [characteristic.UUID uuidStr]);
    }

    CBService *primaryService = [self getPrimaryService:peripheral characteristic:characteristic];

    // Oddly iOS does not update the CCCD descriptors when didUpdateNotificationState is called.
    // So instead of using characteristic.descriptors we have to manually recreate the
    // CCCD descriptor using isNotifying & characteristic.properties
    int value = 0;
    if (characteristic.isNotifying) {
        // in iOS, if a characteristic supports both indications and notifications,
        // then CoreBluetooth will default to indications
        bool supportsNotify = (characteristic.properties & CBCharacteristicPropertyNotify) != 0;
        bool supportsIndicate = (characteristic.properties & CBCharacteristicPropertyIndicate) != 0;
        if (characteristic.isNotifying &&
            supportsIndicate) { value = 2; } // '2' comes from the CCCD BLE spec
        if (characteristic.isNotifying &&
            supportsNotify) { value = 1; } // '1' comes from the CCCD BLE spec
    }

    // See BmDescriptorData
    NSMutableDictionary *result = [@{
            @"remote_id": [peripheral.identifier UUIDString],
            @"service_uuid": [characteristic.service.UUID uuidStr],
            @"characteristic_uuid": [characteristic.UUID uuidStr],
            @"descriptor_uuid": CCCD,
            @"primary_service_uuid": primaryService ? [primaryService.UUID uuidStr] : [NSNull null],
            @"value": [NSData dataWithBytes:&value length:sizeof(value)],
            @"success": @(error == nil),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    } mutableCopy];

    // remove if null
    if (!primaryService) { [result removeObjectForKey:@"primary_service_uuid"]; }

    [self.methodChannel invokeMethod:@"OnDescriptorWritten" arguments:result];
}

- (void)         peripheral:(CBPeripheral *)peripheral
didUpdateValueForDescriptor:(CBDescriptor *)descriptor
                      error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didUpdateValueForDescriptor:");
        Log(LERROR, @"  chr: %@", [descriptor.characteristic.UUID uuidStr]);
        Log(LERROR, @"  desc: %@", [descriptor.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didUpdateValueForDescriptor:");
        Log(LDEBUG, @"  chr: %@", [descriptor.characteristic.UUID uuidStr]);
        Log(LDEBUG, @"  desc: %@", [descriptor.UUID uuidStr]);
    }

    CBService *primaryService = [self getPrimaryService:peripheral characteristic:descriptor.characteristic];

    NSData *data = [self descriptorToData:descriptor];

    // See BmDescriptorData
    NSMutableDictionary *result = [@{
            @"remote_id": [peripheral.identifier UUIDString],
            @"service_uuid": [descriptor.characteristic.service.UUID uuidStr],
            @"characteristic_uuid": [descriptor.characteristic.UUID uuidStr],
            @"descriptor_uuid": [descriptor.UUID uuidStr],
            @"primary_service_uuid": primaryService ? [primaryService.UUID uuidStr] : [NSNull null],
            @"value": data,
            @"success": @(error == nil),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    } mutableCopy];

    // remove if null
    if (!primaryService) { [result removeObjectForKey:@"primary_service_uuid"]; }

    [self.methodChannel invokeMethod:@"OnDescriptorRead" arguments:result];
}

// Hàm ghi Descriptor để nhận dữ liệu
// 😎 3️⃣
- (void)        peripheral:(CBPeripheral *)peripheral
didWriteValueForDescriptor:(CBDescriptor *)descriptor // = onDescriptorWrite trong JAVA
                     error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didWriteValueForDescriptor:");
        Log(LERROR, @"  chr: %@", [descriptor.characteristic.UUID uuidStr]);
        Log(LERROR, @"  desc: %@", [descriptor.UUID uuidStr]);
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didWriteValueForDescriptor:");
        Log(LDEBUG, @"  chr: %@", [descriptor.characteristic.UUID uuidStr]);
        Log(LDEBUG, @"  desc: %@", [descriptor.UUID uuidStr]);
    }

    CBService *primaryService = [self getPrimaryService:peripheral characteristic:descriptor.characteristic];

    // for convenience
    NSString *remoteId = [peripheral.identifier UUIDString];
    NSString *serviceUuid = [descriptor.characteristic.service.UUID uuidStr];
    NSString *characteristicUuid = [descriptor.characteristic.UUID uuidStr];
    NSString *descriptorUuid = [descriptor.UUID uuidStr];

    // what data did we write?
    NSString *key = [NSString stringWithFormat:@"%@:%@:%@:%@:%@", remoteId, serviceUuid, characteristicUuid,
                                               descriptorUuid,
                                               primaryService != nil ? [primaryService.UUID uuidStr]
                                                                     : @""];
    NSData *value = self.writeChrs[key] ? self.writeChrs[key] : [NSMutableData data];
    [self.writeDescs removeObjectForKey:key];

    // See BmDescriptorData
    NSMutableDictionary *result = [@{
            @"remote_id": remoteId,
            @"service_uuid": serviceUuid,
            @"characteristic_uuid": characteristicUuid,
            @"descriptor_uuid": descriptorUuid,
            @"primary_service_uuid": primaryService ? [primaryService.UUID uuidStr] : [NSNull null],
            @"value": value,
            @"success": @(error == nil),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    } mutableCopy];

    // remove if null
    if (!primaryService) { [result removeObjectForKey:@"primary_service_uuid"]; }

    [self.methodChannel invokeMethod:@"OnDescriptorWritten" arguments:result];
    if (!descriptor || !peripheral) {
        NSLog(@"❌ Descriptor hoặc Peripheral không hợp lệ.");
        return;
    }
    CBUUID *uuid = descriptor.characteristic.UUID;
    NSLog(@"🔫 UUID: %@", uuid.UUIDString);

    if ([uuid isEqual:[CBUUID UUIDWithString:GLUCOSE_MEASUREMENT_CHARACTERISTIC_UUID]]) {
        CBCharacteristic *glucoseMeasurementContextCharacteristic = [self findCharacteristic:GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID inService:self.glucoseService];

        // 1️⃣ Nếu là đặc tính đo glucose, tiếp tục bật Notify cho Glucose Measurement Context (nếu có)
        if (glucoseMeasurementContextCharacteristic) {
            NSLog(@"🔹 Bật Notify cho Glucose Measurement Context");

            NSData *enableNotificationValue = [NSData dataWithBytes:&(uint16_t) {
                    0x01}                                    length:sizeof(uint16_t)];
            [self setCharacteristicClientConfigDescriptor:peripheral
                                           characteristic:glucoseMeasurementContextCharacteristic
                                                    value:enableNotificationValue];
        } else {
            NSLog(@"⚠️ Không tìm thấy Glucose Measurement Context, bật Indicate cho Record Access Control Point");
            CBCharacteristic *recordControlAccessPointCharacteristic = [self findCharacteristic:RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID inService:self.glucoseService];
            NSData *enableIndicationValue = [NSData dataWithBytes:&(uint16_t) {
                    0x02}                                  length:sizeof(uint16_t)];
            [self setCharacteristicClientConfigDescriptor:peripheral
                                           characteristic:recordControlAccessPointCharacteristic
                                                    value:enableIndicationValue];
        }
    }
        // 2️⃣ Nếu là Glucose Measurement Context, tiếp tục bật Indicate cho Record Access Control Point
    else if ([uuid isEqual:[CBUUID UUIDWithString:GLUCOSE_MEASUREMENT_CONTEXT_CHARACTERISTIC_UUID]]) {
        NSLog(@"🔹 Bật Indicate cho Record Access Control Point");

        CBCharacteristic *recordAccessControlPointCharacteristic = [self findCharacteristic:RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID inService:self.glucoseService];

        NSData *enableIndicationValue = [NSData dataWithBytes:&(uint16_t) {
                0x02}                                  length:sizeof(uint16_t)];
        [self setCharacteristicClientConfigDescriptor:peripheral
                                       characteristic:recordAccessControlPointCharacteristic
                                                value:enableIndicationValue];
    }
        // 3️⃣ Nếu đã bật Indicate cho Record Access Control Point, gửi lệnh lấy dữ liệu đo đường huyết
    else if ([uuid isEqual:[CBUUID UUIDWithString:RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID]]) {
        NSLog(@"✅ Indication đã được thiết lập cho Record Access Control Point.");
        CBCharacteristic *racp = [self findCharacteristic:RECORD_ACCESS_CONTROL_POINT_CHARACTERISTIC_UUID inService:self.glucoseService];
        if (racp) {
            uint8_t opCode = OP_CODE_REPORT_STORED_RECORDS;
            uint8_t operator = OPERATOR_ALL_RECORDS;
            NSMutableData *command = [NSMutableData data];
            [command appendBytes:&opCode length:sizeof(opCode)];
            [command appendBytes:&operator length:sizeof(operator)];

            [peripheral writeValue:command forCharacteristic:racp type:CBCharacteristicWriteWithResponse];
        }
    }
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    Log(LDEBUG, @"didUpdateName: %@", [peripheral name]);

    // See BmNameChanged
    NSDictionary *result = @{
            @"remote_id": [[peripheral identifier] UUIDString],
            @"name": [peripheral name] ? [peripheral name] : [NSNull null],
    };

    [self.methodChannel invokeMethod:@"OnNameChanged" arguments:result];
}

- (void)peripheral:(CBPeripheral *)peripheral
 didModifyServices:(NSArray

<CBService *> *)invalidatedServices
{
    Log(LDEBUG, @"didModifyServices");

    NSDictionary * result = [self bmBluetoothDevice:peripheral];

    [self.methodChannel invokeMethod:@"OnServicesReset" arguments:result];
}

- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)rssi error:(NSError *)error {
    if (error) {
        Log(LERROR, @"didReadRSSI:");
        Log(LERROR, @"  error: %@", [error localizedDescription]);
    } else {
        Log(LDEBUG, @"didReadRSSI: %@", rssi);
    }

    // See BmReadRssiResult
    NSDictionary *result = @{
            @"remote_id": [peripheral.identifier UUIDString],
            @"rssi": rssi,
            @"success": @(error == nil),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    };

    [self.methodChannel invokeMethod:@"OnReadRssi" arguments:result];
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    Log(LVERBOSE, @"peripheralIsReadyToSendWriteWithoutResponse");

    // peripheralIsReadyToSendWriteWithoutResponse is used to signal
    // when a 'writeWithoutResponse' request has completed.
    // The dart code will wait for this signal, so that we don't
    // queue writes too fast, which iOS would then drop the packets.

    NSDictionary *request = [self.didWriteWithoutResponse objectForKey:[[peripheral identifier] UUIDString]];
    if (request == nil) {
        Log(LERROR, @"didWriteWithoutResponse is null");
        return;
    }

    // See BmWriteCharacteristicRequest
    NSString *serviceUuid = request[@"service_uuid"];
    NSString *characteristicUuid = request[@"characteristic_uuid"];
    NSString *primaryServiceUuid = request[@"primary_service_uuid"];
    NSString *value = request[@"value"];

    // Find characteristic
    NSError *error = nil;
    CBCharacteristic *characteristic = [self locateCharacteristic:characteristicUuid
                                                       peripheral:peripheral
                                                      serviceUuid:serviceUuid
                                               primaryServiceUuid:primaryServiceUuid
                                                            error:&error];
    if (characteristic == nil) {
        Log(LERROR, @"Error: peripheralIsReadyToSendWriteWithoutResponse: %@",
            [error localizedDescription]);
        return;
    }

    // See BmCharacteristicData
    NSMutableDictionary *result = [@{
            @"remote_id": [peripheral.identifier UUIDString],
            @"service_uuid": [characteristic.service.UUID uuidStr],
            @"characteristic_uuid": [characteristic.UUID uuidStr],
            @"primary_service_uuid": primaryServiceUuid != nil ? primaryServiceUuid : [NSNull null],
            @"value": value,
            @"success": @(error == nil),
            @"error_string": error ? [error localizedDescription] : @"success",
            @"error_code": error ? @(error.code) : @(0),
    } mutableCopy];

    // remove if null
    if (!primaryServiceUuid) { [result removeObjectForKey:@"primary_service_uuid"]; }

    [self.methodChannel invokeMethod:@"OnCharacteristicWritten" arguments:result];
}

//////////////////////////////////////////////////////////////////////
// ███    ███  ███████   ██████
// ████  ████  ██       ██
// ██ ████ ██  ███████  ██   ███
// ██  ██  ██       ██  ██    ██
// ██      ██  ███████   ██████
//
// ██   ██  ███████  ██       ██████   ███████  ██████   ███████
// ██   ██  ██       ██       ██   ██  ██       ██   ██  ██
// ███████  █████    ██       ██████   █████    ██████   ███████
// ██   ██  ██       ██       ██       ██       ██   ██       ██
// ██   ██  ███████  ███████  ██       ███████  ██   ██  ███████

- (int)bmAdapterStateEnum:(CBManagerState)adapterState {
    switch (adapterState) {
        case CBManagerStateUnknown:
            return 0; // BmAdapterStateEnum.unknown
        case CBManagerStateUnsupported:
            return 1; // BmAdapterStateEnum.unavailable
        case CBManagerStateUnauthorized:
            return 2; // BmAdapterStateEnum.unauthorized
        case CBManagerStateResetting:
            return 3; // BmAdapterStateEnum.turningOn
        case CBManagerStatePoweredOn:
            return 4; // BmAdapterStateEnum.on
        case CBManagerStatePoweredOff:
            return 6; // BmAdapterStateEnum.off
        default:
            return 0; // BmAdapterStateEnum.unknown
    }
    return 0;
}

- (NSDictionary *)bmScanAdvertisement:(NSString *)remoteId
                    advertisementData:(NSDictionary

<NSString *, id> *)
advertisementData
        RSSI
:(NSNumber *)RSSI
{
    NSString *advName = advertisementData[CBAdvertisementDataLocalNameKey];
    NSNumber *connectable = advertisementData[CBAdvertisementDataIsConnectable];
    NSNumber *txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey];
    NSData *manufData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    NSArray * serviceUuids = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    NSDictionary * serviceData = advertisementData[CBAdvertisementDataServiceDataKey];

    // Manufacturer Data
    NSDictionary * manufDataB = nil;
    if (manufData != nil && manufData.length >= 2) {

        // first 2 bytes are manufacturerId (little endian)
        uint8_t bytes[2];
        [manufData getBytes:bytes length:2];
        unsigned short manufId = (unsigned short) (bytes[0] | bytes[1] << 8);

        // trim off first 2 bytes
        NSData *trimmed = [manufData subdataWithRange:NSMakeRange(2, manufData.length - 2)];

        manufDataB = @{
                @(manufId): trimmed,
        };
    }

    // Service Uuids - convert from CBUUID's to UUID strings
    NSArray * serviceUuidsB = nil;
    if (serviceUuids != nil) {
        NSMutableArray *mutable = [[NSMutableArray alloc] init];
        for (CBUUID *uuid in serviceUuids) {
            [mutable addObject:[uuid uuidStr]];
        }
        serviceUuidsB = [mutable copy];
    }

    // Service Data - convert from CBUUID's to UUID strings
    NSDictionary * serviceDataB = nil;
    if (serviceData != nil) {
        NSMutableDictionary *mutable = [[NSMutableDictionary alloc] init];
        for (CBUUID *uuid in serviceData) {
            NSData *data = serviceData[uuid];
            [mutable setObject:data forKey:[uuid uuidStr]];
        }
        serviceDataB = [mutable copy];
    }

    // platform name
    NSString *platformName = nil;
    if ([self.knownPeripherals objectForKey:remoteId] != nil) {
        CBPeripheral *peripheral = [self.knownPeripherals objectForKey:remoteId];
        platformName = peripheral.name;
    }

    // See BmScanAdvertisement
    // perf: only add keys if they exist
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    if (remoteId) { map[@"remote_id"] = remoteId; }
    if (platformName) { map[@"platform_name"] = platformName; }
    if (advName) { map[@"adv_name"] = advName; }
    if (connectable.boolValue) { map[@"connectable"] = connectable; }
    if (txPower) { map[@"tx_power_level"] = txPower; }
    if (manufDataB) { map[@"manufacturer_data"] = manufDataB; }
    if (serviceUuidsB) { map[@"service_uuids"] = serviceUuidsB; }
    if (serviceDataB) { map[@"service_data"] = serviceDataB; }
    if (RSSI) { map[@"rssi"] = RSSI; }
    return map;
}

- (NSDictionary *)bmBluetoothDevice:(CBPeripheral *)peripheral {
    return @{
            @"remote_id": [[peripheral identifier] UUIDString],
            @"platform_name": [peripheral name] ? [peripheral name] : [NSNull null],
    };
}

- (int)bmConnectionStateEnum:(CBPeripheralState)connectionState {
    switch (connectionState) {
        case CBPeripheralStateDisconnected:
            return 0; // BmConnectionStateEnum.disconnected
        case CBPeripheralStateConnected:
            return 1; // BmConnectionStateEnum.connected
        default:
            return 0;
    }
}

- (NSDictionary *)bmBluetoothService:(CBPeripheral *)peripheral service:(CBService *)service {
    // Characteristics
    NSMutableArray *characteristicProtos = [NSMutableArray new];
    for (CBCharacteristic *c in [service characteristics]) {
        [characteristicProtos addObject:[self bmBluetoothCharacteristic:peripheral characteristic:c]];
    }

    // Included Services
    NSMutableArray *includedServicesProtos = [NSMutableArray new];
    for (CBService *included in [service includedServices]) {
        // service includes itself?
        if ([included.UUID isEqual:service.UUID]) {
            continue; // skip, infinite recursion
        }
        [includedServicesProtos addObject:[self bmBluetoothService:peripheral service:included]];
    }

    // See BmBluetoothService
    return @{
            @"remote_id": [peripheral.identifier UUIDString],
            @"service_uuid": [service.UUID uuidStr],
            @"characteristics": characteristicProtos,
    };
}

- (NSDictionary *)bmBluetoothCharacteristic:(CBPeripheral *)peripheral
                             characteristic:(CBCharacteristic *)characteristic {
    CBService *primaryService = [self getPrimaryService:peripheral characteristic:characteristic];

    // descriptors
    NSMutableArray *descriptors = [NSMutableArray new];
    for (CBDescriptor *d in [characteristic descriptors]) {
        // See: BmBluetoothDescriptor
        NSMutableDictionary *desc = [@{
                @"remote_id": [peripheral.identifier UUIDString],
                @"service_uuid": [d.characteristic.service.UUID uuidStr],
                @"characteristic_uuid": [d.characteristic.UUID uuidStr],
                @"descriptor_uuid": [d.UUID uuidStr],
                @"primary_service_uuid": primaryService ? [primaryService.UUID uuidStr]
                                                        : [NSNull null],
        } mutableCopy];

        // remove if null
        if (!primaryService) { [desc removeObjectForKey:@"primary_service_uuid"]; }

        [descriptors addObject:desc];
    }

    CBCharacteristicProperties props = characteristic.properties;

    // See: BmCharacteristicProperties
    NSDictionary *propsMap = @{
            @"broadcast": @((props & CBCharacteristicPropertyBroadcast) != 0),
            @"read": @((props & CBCharacteristicPropertyRead) != 0),
            @"write_without_response": @((props & CBCharacteristicPropertyWriteWithoutResponse) !=
                                         0),
            @"write": @((props & CBCharacteristicPropertyWrite) != 0),
            @"notify": @((props & CBCharacteristicPropertyNotify) != 0),
            @"indicate": @((props & CBCharacteristicPropertyIndicate) != 0),
            @"authenticated_signed_writes": @(
                    (props & CBCharacteristicPropertyAuthenticatedSignedWrites) != 0),
            @"extended_properties": @((props & CBCharacteristicPropertyExtendedProperties) != 0),
            @"notify_encryption_required": @(
                    (props & CBCharacteristicPropertyNotifyEncryptionRequired) != 0),
            @"indicate_encryption_required": @(
                    (props & CBCharacteristicPropertyIndicateEncryptionRequired) != 0),
    };

    // See BmBluetoothCharacteristic
    NSMutableDictionary *result = [@{
            @"remote_id": [peripheral.identifier UUIDString],
            @"service_uuid": [characteristic.service.UUID uuidStr],
            @"characteristic_uuid": [characteristic.UUID uuidStr],
            @"primary_service_uuid": primaryService ? [primaryService.UUID uuidStr] : [NSNull null],
            @"descriptors": descriptors,
            @"properties": propsMap,
    } mutableCopy];

    // remove if null
    if (!primaryService) { [result removeObjectForKey:@"primary_service_uuid"]; }

    return result;
}

//////////////////////////////////////////
// ██    ██ ████████  ██  ██       ███████
// ██    ██    ██     ██  ██       ██
// ██    ██    ██     ██  ██       ███████
// ██    ██    ██     ██  ██            ██
//  ██████     ██     ██  ███████  ███████

- (bool)isAdapterOn {
    return self.centralManager.state == CBManagerStatePoweredOn;
}

- (NSInteger)scanCountIncrement:(NSString *)remoteId {
    if (!self.scanCounts[remoteId]) { self.scanCounts[remoteId] = @(0); }
    NSInteger count = [self.scanCounts[remoteId] integerValue];
    self.scanCounts[remoteId] = @(count + 1);
    return count;
}

- (BOOL)hasFilter:(NSString *)key {
    NSArray *filterArray = self.scanFilters[key];
    return (filterArray != nil && [filterArray count] > 0);
}

- (BOOL)foundService:(NSArray

<NSString *> *)
services
        target
:(NSArray<CBUUID *> *)target
{
    if (target == nil || target.count == 0) {
        return NO;
    }
    for (CBUUID *s in target) {
        if ([services containsObject:[s uuidStr]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)foundKeyword:(NSArray

<NSString *> *)
keywords
        target
:(NSString *)target
{
    if (target == nil) {
        return NO;
    }
    for (NSString *k in keywords) {
        if ([target rangeOfString:k].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)foundName:(NSArray

<NSString *> *)
names
        target
:(NSString *)target
{
    if (target == nil) {
        return NO;
    }
    for (NSString *n in names) {
        if ([target isEqualToString:n]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)foundRemoteId:(NSArray

<NSString *> *)
remoteIds
        target
:(NSString *)target
{
    if (target == nil) {
        return NO;
    }
    for (NSString *r in remoteIds) {
        if ([[target lowercaseString] isEqualToString:[r lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)foundServiceData:(NSArray

<NSDictionary*>*)
filters
        sd
:(NSDictionary *)sd
{
    if (sd == nil || sd.count == 0) {
        return NO;
    }
    for (NSDictionary *f in filters) {
        NSString *service = f[@"service"];
        NSData *data = f[@"data"];
        NSData *mask = f[@"mask"];

        // mask
        if (mask.length == 0 && data.length > 0) {
            uint8_t *bytes = malloc(data.length);
            memset(bytes, 1, data.length);
            mask = [NSData dataWithBytesNoCopy:bytes length:data.length freeWhenDone:YES];
        }

        // found a match?
        for (CBUUID *uuid in sd) {
            NSString *a = [uuid uuidStr];
            NSString *b = [service lowercaseString];
            if ([a isEqualToString:b] && [self findData:data inData:sd[uuid] usingMask:mask]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)foundMsd:(NSArray

<NSDictionary*>*)
filters
        msd
:(NSData *)msd
{
    if (msd == nil || msd.length < 2) {
        return NO;
    }
    for (NSDictionary *f in filters) {
        NSNumber *manufacturerId = f[@"manufacturer_id"];
        NSData *data = f[@"data"];
        NSData *mask = f[@"mask"];

        // first 2 bytes are manufacturer id
        unsigned short mId = 0;
        [msd getBytes:&mId length:2];

        // mask
        if (mask.length == 0 && data.length > 0) {
            uint8_t *bytes = malloc(data.length);
            memset(bytes, 1, data.length);
            mask = [NSData dataWithBytesNoCopy:bytes length:data.length freeWhenDone:YES];
        }

        // trim off first 2 bytes
        NSData *trim = [msd subdataWithRange:NSMakeRange(2, msd.length - 2)];

        // manufacturer id & data
        if (mId == [manufacturerId integerValue] &&
            [self findData:data inData:trim usingMask:mask]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)findData:(NSData *)find inData:(NSData *)data usingMask:(NSData *)mask {
    // Ensure find & mask are same length
    if ([find length] != [mask length]) {
        return NO;
    }

    const uint8_t *bFind = [find bytes];
    const uint8_t *bData = [data bytes];
    const uint8_t *bMask = [mask bytes];

    for (NSUInteger i = 0; i < [find length]; i++) {
        // Perform bitwise AND with mask and then compare
        if ((bFind[i] & bMask[i]) != (bData[i] & bMask[i])) {
            return NO;
        }
    }

    return YES;
}

- (NSString *)cbManagerStateString:(CBManagerState)adapterState {
    switch (adapterState) {
        case CBManagerStateUnknown:
            return @"CBManagerStateUnknown";
        case CBManagerStateUnsupported:
            return @"CBManagerStateUnsupported";
        case CBManagerStateUnauthorized:
            return @"CBManagerStateUnauthorized";
        case CBManagerStateResetting:
            return @"CBManagerStateResetting";
        case CBManagerStatePoweredOn:
            return @"CBManagerStatePoweredOn";
        case CBManagerStatePoweredOff:
            return @"CBManagerStatePoweredOff";
        default:
            return @"unhandled";
    }
    return @"";
}

- (void)log:(LogLevel)level
     format:(NSString *)format, ... {
    if (level <= self.logLevel) {
        va_list args;
        va_start(args, format);
        NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
        NSLog(@"%@", msg);
        va_end(args);
    }
}

- (int)getMaxPayload:(CBPeripheral *)peripheral forType:(CBCharacteristicWriteType)writeType allowLongWrite:(bool)allowLongWrite {
    // if allowLongWrite is disabled, we can only write up to MTU-3
    if (allowLongWrite == false) {
        writeType = CBCharacteristicWriteWithoutResponse;
    }

    // For withoutResponse, or allowLongWrite == false
    //   iOS returns MTU-3. In theory, MTU can be as high as 65535 (16-bit).
    //   I've seen iOS return 524 for this value. But typically it is lower.
    //   The MTU negotiated by the OS depends on iOS version.
    //
    // For withResponse,
    //   iOS typically returns a constant value of 512, regardless of MTU.
    //   This is because iOS will autosplit large writes
    int maxForType = (int) [peripheral maximumWriteValueLengthForType:writeType];

    // In order to operate the same on both iOS & Android, we enforce a
    // maximum of 512, which is the same as android. This is also the
    // maxAttrLen of a characteristic in the BLE specification.
    return MIN(maxForType, 512);
}

- (int)getMtu:(CBPeripheral *)peripheral {
    int maxPayload = [self getMaxPayload:peripheral forType:CBCharacteristicWriteWithoutResponse allowLongWrite:false];
    return maxPayload + 3; // ATT overhead
}

- (CBService *)getPrimaryService:(CBPeripheral *)peripheral
                  characteristic:(CBCharacteristic *)characteristic {
    CBService *service = characteristic.service;

    // is this *already* a primary service?
    if ([service isPrimary]) {
        return nil;
    }

    // Otherwise, iterate all services until we find the primary service
    for (CBService *primary in [peripheral services]) {
        for (CBService *secondary in [primary includedServices]) {
            if ([secondary.UUID isEqual:service.UUID]) {
                return primary;
            }
        }
    }

    return NULL;
}

- (NSData *)descriptorToData:(CBDescriptor *)descriptor {
    NSData *data = nil;
    if (descriptor.value) {
        if ([descriptor.value isKindOfClass:[NSString class]]) {
            // NSString
            data = [descriptor.value dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([descriptor.value isKindOfClass:[NSNumber class]]) {
            // NSNumber
            int value = [descriptor.value intValue];
            data = [NSData dataWithBytes:&value length:sizeof(value)];
        } else if ([descriptor.value isKindOfClass:[NSData class]]) {
            // NSData
            data = descriptor.value;
        }
    }
    return data;
}
@end
