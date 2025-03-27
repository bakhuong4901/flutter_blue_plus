package com.lib.flutter_blue_plus.glucose_profile_manager;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.lib.flutter_blue_plus.model.GlucoseMeasurementRecord;

/*
BluetoothGattStateInformationReceiver collects and distributes important information about the state
of the current GATT connection.
More specifically, this class receives updates from the SugaIOTBluetoothLeService and broadcasts
information to any other Android component that registers for the broadcast.
*/

public class BluetoothGattStateInformationReceiver extends BroadcastReceiver {

    private final BluetoothGattStateInformationCallback bluetoothGattStateInformationCallback;

    public interface BluetoothGattStateInformationCallback {
        // Gửi dữ liệu đo đường huyết nhận được từ thiết bị Bluetooth
        void glucoseMeasurementRecordAvailable(GlucoseMeasurementRecord glucoseMeasurementRecord);

        // Gọi khi thiết bị kết nối thành công với GATT SERVER
        void connectedToAGattServer(BluetoothDevice connectedDevice);

        // Gọi khi thiết bị bị ngắt kết nối khỏi GATT server
        void disconnectedFromAGattServer();

        // Xử lý trạng thái ghép đôi Bluetooth
        void bondStateExtra(int boundState);

        // Gọi khi toàn bộ dữ liệu đo đường huyết đã được gửi xong
        void recordsSentComplete();
    }

    public BluetoothGattStateInformationReceiver(BluetoothGattStateInformationCallback callback) {
        this.bluetoothGattStateInformationCallback = callback;
    }

    // Sự kiện khi thiết bị Bluetooth kết nối thành công với GATT Server.
    public static final String BLUETOOTH_LE_GATT_ACTION_CONNECTED_TO_DEVICE = BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED;

    //  Sự kiện khi thiết bị Bluetooth ngắt kết nối với GATT Server.
    public static final String BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE = BluetoothAdapter.ACTION_DISCOVERY_FINISHED;

    // Sự kiện khi nhận được dữ liệu đo đường huyết từ thiết bị Bluetooth.
    public static final String BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE = BluetoothAdapter.ACTION_SCAN_MODE_CHANGED;

    // Dữ liệu đo đường huyết được đính kèm trong Intent.
    public static final String BLUETOOTH_LE_GATT_GLUCOSE_MEASUREMENT_RECORD_EXTRA = BluetoothDevice.EXTRA_DEVICE;

    // Thông tin thiết bị Bluetooth vừa kết nối (dữ liệu kiểu BluetoothDevice)
    public static final String DEVICE_CONNECTED_TO_EXTRA = BluetoothAdapter.EXTRA_PREVIOUS_CONNECTION_STATE;

    // Sự kiện khi toàn bộ dữ liệu đo đường huyết đã được gửi xong.
    public static final String RECORDS_SENT_COMPLETE = BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE;

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent != null) {
            String action = intent.getAction();
            // Khi thiết bị kết nối với GATT Server
            if (BLUETOOTH_LE_GATT_ACTION_CONNECTED_TO_DEVICE.equals(action)) {
                BluetoothDevice connectedDevice = intent.getParcelableExtra(DEVICE_CONNECTED_TO_EXTRA);
                if (connectedDevice != null) {
                    bluetoothGattStateInformationCallback.connectedToAGattServer(connectedDevice);
                }
            }
            // Khi thiết bị ngắt kết nối với GATT Server

            else if (BLUETOOTH_LE_GATT_ACTION_DISCONNECTED_FROM_DEVICE.equals(action)) {
                bluetoothGattStateInformationCallback.disconnectedFromAGattServer();
            }
            // Khi nhận được dữ liệu đo đường huyết

            else if (BLUETOOTH_LE_GATT_ACTION_GLUCOSE_MEASUREMENT_RECORD_AVAILABLE.equals(action)) {
                synchronized (this) {
                    GlucoseMeasurementRecord glucoseMeasurementRecord = intent.getParcelableExtra(BLUETOOTH_LE_GATT_GLUCOSE_MEASUREMENT_RECORD_EXTRA);
                    if (glucoseMeasurementRecord != null) {
                        bluetoothGattStateInformationCallback.glucoseMeasurementRecordAvailable(glucoseMeasurementRecord);
                    }
                }
            } else if (RECORDS_SENT_COMPLETE.equals(action)) {
                bluetoothGattStateInformationCallback.recordsSentComplete();
            }
        }
    }
}