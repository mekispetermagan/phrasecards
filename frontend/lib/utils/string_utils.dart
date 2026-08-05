import 'package:characters/characters.dart';

final List<String> alphabetENLower = "abcdefghijklmnopqrstuvwxyz".characters
    .toList();
final List<String> alphabetENUpper = [
  for (String x in alphabetENLower) x.toUpperCase(),
];
final List<String> alphabetEN = [...alphabetENLower, ...alphabetENUpper];
final List<String> accentedHULower = "áéíóöőúüű".characters.toList();
final List<String> accentedHUUpper = [
  for (String x in accentedHULower) x.toUpperCase(),
];
final List<String> accentedHU = [...accentedHULower, ...accentedHUUpper];
final List<String> alphabetHULower = [...alphabetENLower, ...accentedHULower];
final List<String> alphabetHUUpper = [...alphabetENUpper, ...accentedHUUpper];
final List<String> alphabetHU = [...alphabetHULower, ...alphabetHUUpper];

List<String> toWords(String text) {
  List<String> result = [];
  String currentWord = "";
  for (String x in text.characters) {
    if (alphabetHU.contains(x)) {
      currentWord += x;
    } else if (currentWord != "") {
      result.add(currentWord);
      currentWord = "";
    }
  }
  if (currentWord != "") {
    result.add(currentWord);
    currentWord = "";
  }
  return result;
}

List<String> toWordsWithPunctuation(String text) {
  List<String> result = [];
  String currentWord = "";
  for (String x in text.characters) {
    if (x != " ") {
      currentWord += x;
    } else if (currentWord != "") {
      result.add(currentWord);
      currentWord = "";
    }
  }
  if (currentWord != "") {
    result.add(currentWord);
    currentWord = "";
  }
  return result;
}

bool hasAccents(String text) {
  for (String character in text.characters) {
    if (accentedHU.contains(character)) return true;
  }

  return false;
}

String deAccentChar(String char) {
  return switch (char) {
    "Á" => "A",
    "É" => "E",
    "Í" => "I",
    "Ó" || "Ö" || "Ő" => "O",
    "Ú" || "Ü" || "Ű" => "U",
    _ => char,
  };
}

String deAccentString(String text) {
  return [for (String x in text.characters) deAccentChar(x)].join();
}
