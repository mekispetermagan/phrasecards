enum PhraseGroup { learning, practiced, established }

extension PhraseGroupDetails on PhraseGroup {
  String get label => switch (this) {
    PhraseGroup.learning => 'Learning',
    PhraseGroup.practiced => 'Practiced',
    PhraseGroup.established => 'Established',
  };

  bool includes(int views) => switch (this) {
    PhraseGroup.learning => views <= 12,
    PhraseGroup.practiced => views >= 13 && views <= 24,
    PhraseGroup.established => views >= 25,
  };
}

bool isLocallyNew(int views) => views <= 3;
