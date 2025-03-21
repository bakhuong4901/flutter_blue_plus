package com.lib.flutter_blue_plus.model;

import android.os.Parcel;
import android.os.Parcelable;

import java.util.GregorianCalendar;
import java.util.Locale;

public class GlucoseMeasurementRecord implements Parcelable {
    private int sequenceNumber;
    private GregorianCalendar calendar;
    private int timeOffset;
    private GlucoseConcentrationMeasurementUnit glucoseConcentrationMeasurementUnit;
    private float glucoseConcentrationValue;
    private int type;
    private int sampleLocationInteger;
    private String testBloodType;
    private String sampleLocation;
    private SensorStatusAnnunciation sensorStatusAnnunciation;

    public GlucoseMeasurementRecord() {
        this.sequenceNumber = 0;  // Số thứ tự của lần đo.
        this.calendar = new GregorianCalendar(Locale.UK); // Ngày giờ của lần đo, mặc định là múi giờ UK.
        this.timeOffset = 0; // Độ lệch thời gian so với thời điểm đo.
        this.glucoseConcentrationMeasurementUnit = GlucoseConcentrationMeasurementUnit.MOLES_PER_LITRE; // Đơn vị đo đường huyết (mol/L hoặc kg/L).
        this.glucoseConcentrationValue = 0f; // Giá trị đo nồng độ glucose.
        this.type = 0;  // Loại mẫu máu (Ví dụ: máu mao mạch, máu động mạch, huyết tương...).
        this.sampleLocationInteger = 0;  // Vị trí lấy mẫu (Ví dụ: ngón tay, dái tai...).
        this.testBloodType = "Capillary Whole blood";  // Chuỗi chứa loại máu đo (cập nhật dựa vào type).
        this.sampleLocation = "Earlobe"; // Chuỗi chứa vị trí lấy mẫu (cập nhật dựa vào sampleLocationInteger).
        this.sensorStatusAnnunciation = null; // Trạng thái của cảm biến đo (có thể null nếu không có dữ liệu).
        initializeBloodTypeAndLocation();
    }

    private void initializeBloodTypeAndLocation() {
        switch (type) {
            case 0:
                testBloodType = "Reserved for future use"; // Dùng cho mục đích sau này
                break;
            case 1:
                testBloodType = "Capillary Whole blood"; // Máu toàn phần mao mạch
                break;
            case 2:
                testBloodType = "Capillary Plasma"; // Huyết tương mao mạch
                break;
            case 3:
                testBloodType = "Venous Whole blood"; // Máu toàn phần tĩnh mạch
                break;
            case 4:
                testBloodType = "Venous Plasma"; // Huyết tương tĩnh mạch
                break;
            case 5:
                testBloodType = "Arterial Whole blood"; // Máu toàn phần động mạch
                break;
            case 6:
                testBloodType = "Arterial Plasma"; // Huyết tương động mạch
                break;
            case 7:
                testBloodType = "Undetermined Whole blood"; // Máu toàn phần chưa xác định
                break;
            case 8:
                testBloodType = "Undetermined Plasma"; // Huyết tương chưa xác định
                break;
            case 9:
                testBloodType = "Interstitial Fluid (ISF)"; // Dịch kẽ (ISF)
                break;
            case 10:
                testBloodType = "Control Solution"; // Dung dịch đối trứng
                break;
            default:
                testBloodType = "Reserved for future use"; // Dùng cho mục đích sau này
                break;
        }

        switch (sampleLocationInteger) {
            case 0:
                sampleLocation = "Reserved for future use"; // Dùng cho mục đích sau này
                break;
            case 1:
                sampleLocation = "Finger"; // Ngón tay
                break;
            case 2:
                sampleLocation = "Alternate Site Test (AST)"; // Xét nghiệm vị trí thay thế
                break;
            case 3:
                sampleLocation = "Earlobe"; // Dái tai
                break;
            case 4:
                sampleLocation = "Control solution"; // Dung dịch kiểm soát
                break;
            case 15:
                sampleLocation = "Sample Location value not available"; // Giá trị vị trí mẫu không khả dụng
                break;
            default:
                sampleLocation = "Reserved for future use"; // Dùng cho mục đích sau này
                break;
        }
    }

    public String convertGlucoseConcentrationValueToMilligramsPerDeciliter() {
        return (glucoseConcentrationValue * 100_000) + "mg/dL";
    }

    // CHUYỂN ĐỔI GIÁ TRỊ
    public enum GlucoseConcentrationMeasurementUnit {
        MOLES_PER_LITRE("mol/L"), KILOGRAM_PER_LITRE("kg/L");

        private final String unit;

        GlucoseConcentrationMeasurementUnit(String unit) {
            this.unit = unit;
        }
    }

    protected GlucoseMeasurementRecord(Parcel in) {
        sequenceNumber = in.readInt();
        timeOffset = in.readInt();
        glucoseConcentrationValue = in.readFloat();
        type = in.readInt();
        sampleLocationInteger = in.readInt();
        testBloodType = in.readString();
        sampleLocation = in.readString();
        glucoseConcentrationMeasurementUnit = (GlucoseConcentrationMeasurementUnit) in.readSerializable();
    }

    public static final Creator<GlucoseMeasurementRecord> CREATOR = new Creator<GlucoseMeasurementRecord>() {
        @Override
        public GlucoseMeasurementRecord createFromParcel(Parcel in) {
            return new GlucoseMeasurementRecord(in);
        }

        @Override
        public GlucoseMeasurementRecord[] newArray(int size) {
            return new GlucoseMeasurementRecord[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(sequenceNumber);
        dest.writeInt(timeOffset);
        dest.writeFloat(glucoseConcentrationValue);
        dest.writeInt(type);
        dest.writeInt(sampleLocationInteger);
        dest.writeString(testBloodType);
        dest.writeString(sampleLocation);
        dest.writeSerializable(glucoseConcentrationMeasurementUnit);
    }
}
