/// Chuyển đổi mol/L hoặc kg/dL sang mg/dL
///
/// [value]: giá trị cần chuyển đổi
/// [unit]: đơn vị đầu vào: "mol/L" hoặc "kg/dL"
/// [molarMass]: khối lượng phân tử của chất (g/mol)
///
/// Trả về giá trị mg/dL (double)
int convertToMgPerDl(double value, String unit, double molarMass) {
  switch (unit) {
    case 'MOLES_PER_LITRE':
      // mol/L * molar mass (g/mol) * 100 (vì 1g/L = 100mg/dL)
      return (value * molarMass * 100).round();
    case 'KILOGRAM_PER_LITRE':
      // kg/dL * 1,000,000 (mg/dL)
      return (value * 100000).round();
    default:
      throw ArgumentError(
          'Unsupported unit: $unit. Only "mol/L" and "kg/dL" are supported.');
  }
}
