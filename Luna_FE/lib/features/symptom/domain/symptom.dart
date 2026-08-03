enum Symptom {
  cramps('cramps', 'Đau bụng'),
  backPain('back_pain', 'Đau lưng'),
  headache('headache', 'Đau đầu'),
  nausea('nausea', 'Buồn nôn'),
  dizziness('dizziness', 'Chóng mặt'),
  fatigue('fatigue', 'Uể oải'),
  insomnia('insomnia', 'Mất ngủ'),
  sweetCravings('sweet_cravings', 'Thèm ngọt'),
  breastTenderness('breast_tenderness', 'Căng ngực'),
  acne('acne', 'Nổi mụn');

  const Symptom(this.wireValue, this.label);
  final String wireValue;
  final String label;

  static Symptom fromWire(String value) =>
      values.firstWhere((item) => item.wireValue == value);
}
