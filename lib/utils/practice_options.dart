const practiceTypes = [
  'チーム練習',
  '個人練習',
  'ミーティング',
  '練習試合',
  '大会',
];

const repeatTypes = [
  '1回のみ',
  '毎日',
  '毎週',
  '毎月',
];

List<String> generateCountOptions() {
  return List.generate(52, (index) => '${index + 1}');
}