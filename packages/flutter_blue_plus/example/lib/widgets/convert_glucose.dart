/// Chuyển đổi mol/L hoặc kg/dL sang mg/dL
///
/// [value]: giá trị cần chuyển đổi
/// [unit]: đơn vị đầu vào: "mol/L" hoặc "kg/dL"
/// [molarMass]: khối lượng phân tử của chất (g/mol)
///
/// Trả về giá trị mg/dL (double)
/// 1. Glucose
/// Molar mass = 180.16 g/mol
/// 1 mmol/L = 18.016 mg/dL
/// 2. Cholesterol
/// Molar mass = 386.6 g/mol
/// 1 mmol/L = 38.66 mg/dL
/// 3. Creatinine
/// Molar mass = 113.12 g/mol
/// 1 mmol/L = 11.312 mg/dL
int convertToMgPerDl(double value, String unit) {
  switch (unit) {
    case 'MOLES_PER_LITRE':
      // mol/L * molar mass (g/mol) * 100 (vì 1g/L = 100mg/dL)
      return (value * 180.16 * 10).round();
    case 'KILOGRAM_PER_LITRE':
      // kg/dL * 100,000 (mg/dL)
      return (value * 100000).round();
    default:
      throw ArgumentError(
          'Unsupported unit: $unit. Only "mol/L" and "kg/dL" are supported.');
  }
}

// Chuyển mmol/L sang mg/dL (1 mmol/L = 18.0182 mg/dL)
double toMilligramsPerDeciliter(double glucoseValue) {
  return glucoseValue * 18.0182;
}

// mg/DL sang mmol/L
double mgDlToMmolL(double mgPerDl) {
  return mgPerDl / 18.016;
}

double molToMmol(double molPerL) {
  return molPerL * 1000;
}

double glucoseKgDlToMmolL(double kgPerDl) {
  const double glucoseMolarMass = 180.16; // g/mol
  return (kgPerDl * 100000) / glucoseMolarMass;
}

// format thời gian đo
String formattedTime(int hourB, int minuteB) {
  int hour = hourB;
  int minute = minuteB;
  String amPm = hour >= 12 ? "PM" : "AM";
  int displayHour = hour % 12 == 0 ? 12 : hour % 12;
  String formattedMinute = minute.toString().padLeft(2, '0');
  return "$displayHour:$formattedMinute$amPm";
}
