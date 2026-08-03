enum Mood {
  neutral('neutral', 'Bình thường', '😐'),
  happy('happy', 'Vui vẻ', '😊'),
  sad('sad', 'Buồn', '😢'),
  angry('angry', 'Bực bội', '😠'),
  sleepy('sleepy', 'Buồn ngủ', '😴'),
  tired('tired', 'Mệt mỏi', '🥱'),
  anxious('anxious', 'Lo âu', '😟');

  const Mood(this.wireValue, this.label, this.emoji);
  final String wireValue;
  final String label;
  final String emoji;

  static Mood fromWire(String value) =>
      values.firstWhere((item) => item.wireValue == value);
}
