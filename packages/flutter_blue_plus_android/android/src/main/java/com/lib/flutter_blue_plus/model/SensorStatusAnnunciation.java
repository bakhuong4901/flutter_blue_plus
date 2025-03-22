package com.lib.flutter_blue_plus.model;
import android.os.Parcel;
import android.os.Parcelable;

/**
 * SensorStatusAnnunciation provides additional information about the state of the
 * glucose sensor at the time of the glucose concentration value measurement.
 */
public class SensorStatusAnnunciation implements Parcelable {
    private boolean deviceBatteryLowAtTimeOfMeasurement;
    private boolean sensorMalfunctionAtTimeOfMeasurement;
    private boolean bloodSampleInsufficientAtTimeOfMeasurement;
    private boolean stripInsertionError;
    private boolean stripTypeIncorrectForDevice;
    private boolean sensorResultHigherThanDeviceCanProcess;
    private boolean sensorResultLowerThanTheDeviceCanProcess;
    private boolean sensorTemperatureTooHighForValidTestResult;
    private boolean sensorTemperatureTooLowForValidTestResult;
    private boolean sensorReadInterruptedBecauseStripWasPulledTooSoon;
    private boolean generalDeviceFaultHasOccurredInSensor;
    private boolean timeFaultHasOccurredInTheSensor;

    public SensorStatusAnnunciation() {
        this.deviceBatteryLowAtTimeOfMeasurement = false;
        this.sensorMalfunctionAtTimeOfMeasurement = false;
        this.bloodSampleInsufficientAtTimeOfMeasurement = false;
        this.stripInsertionError = false;
        this.stripTypeIncorrectForDevice = false;
        this.sensorResultHigherThanDeviceCanProcess = false;
        this.sensorResultLowerThanTheDeviceCanProcess = false;
        this.sensorTemperatureTooHighForValidTestResult = false;
        this.sensorTemperatureTooLowForValidTestResult = false;
        this.sensorReadInterruptedBecauseStripWasPulledTooSoon = false;
        this.generalDeviceFaultHasOccurredInSensor = false;
        this.timeFaultHasOccurredInTheSensor = false;
    }

    protected SensorStatusAnnunciation(Parcel in) {
        deviceBatteryLowAtTimeOfMeasurement = in.readByte() != 0;
        sensorMalfunctionAtTimeOfMeasurement = in.readByte() != 0;
        bloodSampleInsufficientAtTimeOfMeasurement = in.readByte() != 0;
        stripInsertionError = in.readByte() != 0;
        stripTypeIncorrectForDevice = in.readByte() != 0;
        sensorResultHigherThanDeviceCanProcess = in.readByte() != 0;
        sensorResultLowerThanTheDeviceCanProcess = in.readByte() != 0;
        sensorTemperatureTooHighForValidTestResult = in.readByte() != 0;
        sensorTemperatureTooLowForValidTestResult = in.readByte() != 0;
        sensorReadInterruptedBecauseStripWasPulledTooSoon = in.readByte() != 0;
        generalDeviceFaultHasOccurredInSensor = in.readByte() != 0;
        timeFaultHasOccurredInTheSensor = in.readByte() != 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeByte((byte) (deviceBatteryLowAtTimeOfMeasurement ? 1 : 0));
        dest.writeByte((byte) (sensorMalfunctionAtTimeOfMeasurement ? 1 : 0));
        dest.writeByte((byte) (bloodSampleInsufficientAtTimeOfMeasurement ? 1 : 0));
        dest.writeByte((byte) (stripInsertionError ? 1 : 0));
        dest.writeByte((byte) (stripTypeIncorrectForDevice ? 1 : 0));
        dest.writeByte((byte) (sensorResultHigherThanDeviceCanProcess ? 1 : 0));
        dest.writeByte((byte) (sensorResultLowerThanTheDeviceCanProcess ? 1 : 0));
        dest.writeByte((byte) (sensorTemperatureTooHighForValidTestResult ? 1 : 0));
        dest.writeByte((byte) (sensorTemperatureTooLowForValidTestResult ? 1 : 0));
        dest.writeByte((byte) (sensorReadInterruptedBecauseStripWasPulledTooSoon ? 1 : 0));
        dest.writeByte((byte) (generalDeviceFaultHasOccurredInSensor ? 1 : 0));
        dest.writeByte((byte) (timeFaultHasOccurredInTheSensor ? 1 : 0));
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<SensorStatusAnnunciation> CREATOR = new Creator<SensorStatusAnnunciation>() {
        @Override
        public SensorStatusAnnunciation createFromParcel(Parcel in) {
            return new SensorStatusAnnunciation(in);
        }

        @Override
        public SensorStatusAnnunciation[] newArray(int size) {
            return new SensorStatusAnnunciation[size];
        }
    };
}
