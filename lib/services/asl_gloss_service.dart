class AslGlossService {
  static const Map<String, String> _specialPhrases = {
    // Greetings / common expressions
    'how are you': 'HOW YOU',
    'how are you doing': 'HOW YOU',
    'what is your name': 'YOUR NAME WHAT',
    'what s your name': 'YOUR NAME WHAT',
    'where do you live': 'YOU LIVE WHERE',
    'where are you going': 'YOU GO WHERE',
    'where are you': 'YOU WHERE',
    'what do you want': 'YOU WANT WHAT',
    'what do you need': 'YOU NEED WHAT',
    'who are you': 'YOU WHO',
    'who is he': 'HE WHO',
    'who is she': 'SHE WHO',
    'when will you come': 'YOU COME WHEN',
    'when are you coming': 'YOU COME WHEN',
    'why are you sad': 'YOU SAD WHY',
    'why are you happy': 'YOU HAPPY WHY',
    'do you like coffee': 'COFFEE YOU LIKE',
    'do you want water': 'WATER YOU WANT',
    'do you need help': 'YOU NEED HELP',
    'i love you': 'I LOVE YOU',
    'thank you': 'THANK-YOU',
    'please help me': 'PLEASE HELP ME',
    'nice to meet you': 'NICE MEET YOU',
    'see you tomorrow': 'TOMORROW SEE YOU',

    // Useful statements
    'i will go to school tomorrow': 'TOMORROW I SCHOOL GO',
    'i am going to school tomorrow': 'TOMORROW I SCHOOL GO',
    'i am going home': 'I HOME GO',
    'i will go home': 'I HOME GO',
    'i am happy': 'I HAPPY',
    'i am sad': 'I SAD',
    'you are good': 'YOU GOOD',
    'you are happy': 'YOU HAPPY',
  };

  static const Set<String> _greetings = {
    'hello',
    'hi',
    'hey',
  };

  static const Set<String> _removeWords = {
    // English linking / auxiliary words that often do not need
    // a separate manual sign in this simplified gloss system.
    'am',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'do',
    'does',
    'did',
    'will',
    'shall',
    'would',
    'should',
    'a',
    'an',
    'the',
    'to',
  };

  static const Set<String> _timeWords = {
    'today',
    'tomorrow',
    'yesterday',
    'now',
    'later',
    'tonight',
    'morning',
    'afternoon',
    'evening',
  };

  static const Set<String> _whWords = {
    'what',
    'where',
    'who',
    'why',
    'when',
  };

  static const Map<String, String> _wordMap = {
    // Pronouns / possessives
    'i': 'I',
    'me': 'ME',
    'my': 'MY',
    'mine': 'MINE',
    'you': 'YOU',
    'your': 'YOUR',
    'yours': 'YOURS',
    'he': 'HE',
    'him': 'HE',
    'his': 'HIS',
    'she': 'SHE',
    'her': 'HER',
    'hers': 'HERS',
    'we': 'WE',
    'us': 'WE',
    'our': 'OUR',
    'ours': 'OURS',
    'they': 'THEY',
    'them': 'THEY',
    'their': 'THEIR',
    'theirs': 'THEIRS',

    // Common verb normalization
    'going': 'GO',
    'goes': 'GO',
    'went': 'GO',
    'gone': 'GO',
    'coming': 'COME',
    'comes': 'COME',
    'came': 'COME',
    'likes': 'LIKE',
    'liked': 'LIKE',
    'liking': 'LIKE',
    'wants': 'WANT',
    'wanted': 'WANT',
    'wanting': 'WANT',
    'needs': 'NEED',
    'needed': 'NEED',
    'needing': 'NEED',
    'has': 'HAVE',
    'had': 'HAVE',
    'having': 'HAVE',
    'works': 'WORK',
    'worked': 'WORK',
    'working': 'WORK',
    'lives': 'LIVE',
    'lived': 'LIVE',
    'living': 'LIVE',
    'does': 'DO',
    'doing': 'DO',
    'did': 'DO',
    'says': 'SAY',
    'said': 'SAY',
    'seeing': 'SEE',
    'saw': 'SEE',
    'eating': 'EAT',
    'ate': 'EAT',
    'drinking': 'DRINK',
    'drank': 'DRINK',

    // Common nouns
    'schools': 'SCHOOL',
    'homes': 'HOME',
    'friends': 'FRIEND',
    'teachers': 'TEACHER',
    'books': 'BOOK',

    // Common expressions
    'thanks': 'THANK-YOU',
  };

  String convert(String englishText) {
    final normalized = _normalize(englishText);
    if (normalized.isEmpty) return '';

    // 1) Exact known sentence/phrase.
    final exactSpecial = _specialPhrases[normalized];
    if (exactSpecial != null) {
      return exactSpecial;
    }

    final words = normalized.split(' ').where((word) => word.isNotEmpty).toList();

    // 2) Preserve greetings at the beginning.
    //
    // This is what fixes:
    // "Hello, how are you?"
    // -> HELLO HOW YOU
    //
    // The previous converter treated HOW separately and could create
    // duplicated / badly ordered output.
    final greetingGloss = <String>[];

    while (words.isNotEmpty && _greetings.contains(words.first)) {
      greetingGloss.add(_toGlossWord(words.removeAt(0)));
    }

    if (words.isEmpty) {
      return _cleanGloss(greetingGloss);
    }

    // After removing HELLO / HI / HEY, check whether the rest of the
    // sentence is one of our reliable common patterns.
    final remainder = words.join(' ');
    final remainderSpecial = _specialPhrases[remainder];

    if (remainderSpecial != null) {
      return _cleanGloss([
        ...greetingGloss,
        ...remainderSpecial.split(' '),
      ]);
    }

    // 3) General rule-based fallback.
    final genericGloss = _convertGeneric(words);

    return _cleanGloss([
      ...greetingGloss,
      ...genericGloss,
    ]);
  }

  List<String> _convertGeneric(List<String> originalWords) {
    final time = <String>[];
    final body = <String>[];
    final wh = <String>[];

    bool hasHow = false;

    for (final raw in originalWords) {
      if (raw.isEmpty) continue;

      // HOW is handled exactly once.
      if (raw == 'how') {
        hasHow = true;
        continue;
      }

      if (_removeWords.contains(raw)) {
        continue;
      }

      if (_timeWords.contains(raw)) {
        time.add(_toGlossWord(raw));
        continue;
      }

      if (_whWords.contains(raw)) {
        wh.add(_toGlossWord(raw));
        continue;
      }

      body.add(_toGlossWord(raw));
    }

    // ASL commonly places time information before the main clause.
    final reorderedBody = _moveDirectionalVerbAfterDestination(body);

    final result = <String>[
      ...time,

      // For the simplified questions supported by EchoSign, HOW stays
      // before the subject/body. Unlike the old code, it is inserted once.
      if (hasHow) 'HOW',

      ...reorderedBody,

      // WH words such as WHAT / WHERE / WHY / WHO / WHEN are placed at
      // the end in this simplified fallback.
      ...wh,
    ];

    return _removeAdjacentDuplicates(result);
  }

  List<String> _moveDirectionalVerbAfterDestination(List<String> words) {
    if (words.length < 2) return words;

    final result = List<String>.from(words);

    // Convert common English order:
    // I GO SCHOOL -> I SCHOOL GO
    // I GO HOME   -> I HOME GO
    //
    // Only do this for a small set of destination/location words so we
    // don't blindly rearrange every sentence.
    const destinations = {
      'SCHOOL',
      'HOME',
      'WORK',
      'STORE',
      'CHURCH',
      'HOSPITAL',
      'OFFICE',
    };

    for (final verb in const ['GO', 'COME']) {
      final verbIndex = result.indexOf(verb);

      if (verbIndex >= 0 &&
          verbIndex + 1 < result.length &&
          destinations.contains(result[verbIndex + 1])) {
        final destination = result.removeAt(verbIndex + 1);
        result.insert(verbIndex, destination);
      }
    }

    return result;
  }

  List<String> _removeAdjacentDuplicates(List<String> words) {
    if (words.isEmpty) return words;

    final result = <String>[];

    for (final word in words) {
      if (result.isEmpty || result.last != word) {
        result.add(word);
      }
    }

    return result;
  }

  String _normalize(String value) {
    var text = value.toLowerCase().trim();

    // Normalize common contractions before punctuation is removed.
    const contractions = {
      "what's": 'what is',
      "where's": 'where is',
      "who's": 'who is',
      "how's": 'how is',
      "i'm": 'i am',
      "you're": 'you are',
      "he's": 'he is',
      "she's": 'she is',
      "we're": 'we are',
      "they're": 'they are',
      "don't": 'do not',
      "doesn't": 'does not',
      "didn't": 'did not',
      "can't": 'cannot',
      "won't": 'will not',
    };

    contractions.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    return text
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _toGlossWord(String word) {
    return _wordMap[word] ?? word.toUpperCase();
  }

  String _cleanGloss(List<String> words) {
    return _removeAdjacentDuplicates(words)
        .where((word) => word.trim().isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
