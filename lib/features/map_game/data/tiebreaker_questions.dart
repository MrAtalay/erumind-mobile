class TiebreakerQuestion {
  final String text;
  final String textEn;
  final int answer;
  final List<int> options; // always contains answer

  const TiebreakerQuestion({
    required this.text,
    required this.textEn,
    required this.answer,
    required this.options,
  });
}

const List<TiebreakerQuestion> kTiebreakerQuestions = [
  TiebreakerQuestion(
    text: 'Berlin Duvarı kaç yılında yıkıldı?',
    textEn: 'In what year did the Berlin Wall fall?',
    answer: 1989,
    options: [1985, 1987, 1989, 1993],
  ),
  TiebreakerQuestion(
    text: 'Türkiye Cumhuriyeti kaç yılında kuruldu?',
    textEn: 'In what year was the Republic of Turkey founded?',
    answer: 1923,
    options: [1919, 1921, 1923, 1926],
  ),
  TiebreakerQuestion(
    text: "İnsanlar ilk kez kaç yılında Ay'a ayak bastı?",
    textEn: 'In what year did humans first set foot on the Moon?',
    answer: 1969,
    options: [1965, 1967, 1969, 1972],
  ),
  TiebreakerQuestion(
    text: 'Fransız Devrimi kaç yılında başladı?',
    textEn: 'In what year did the French Revolution begin?',
    answer: 1789,
    options: [1783, 1787, 1789, 1793],
  ),
  TiebreakerQuestion(
    text: 'Amerikan Bağımsızlık Bildirgesi kaç yılında ilan edildi?',
    textEn: 'In what year was the American Declaration of Independence proclaimed?',
    answer: 1776,
    options: [1770, 1774, 1776, 1780],
  ),
  TiebreakerQuestion(
    text: 'Modern Olimpiyat Oyunları ilk kez kaç yılında düzenlendi?',
    textEn: 'In what year were the first modern Olympic Games held?',
    answer: 1896,
    options: [1890, 1896, 1900, 1904],
  ),
  TiebreakerQuestion(
    text: 'Sovyetler Birliği kaç yılında dağıldı?',
    textEn: 'In what year did the Soviet Union dissolve?',
    answer: 1991,
    options: [1989, 1990, 1991, 1993],
  ),
  TiebreakerQuestion(
    text: 'Birinci Dünya Savaşı kaç yılında sona erdi?',
    textEn: 'In what year did World War I end?',
    answer: 1918,
    options: [1916, 1917, 1918, 1919],
  ),
];
