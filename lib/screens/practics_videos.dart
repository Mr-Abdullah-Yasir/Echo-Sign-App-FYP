import 'dart:math';

import 'package:flutter/material.dart';

import 'sign_animation.dart';

class PracticeScreen extends StatefulWidget {
  static const String routeName = '/practics_videos';

  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  final TextEditingController _searchController = TextEditingController();
  final Random _random = Random();

  bool isLearningMode = true;
  String _selectedCategory = 'All';

  int _quizIndex = 0;
  List<_PracticeItem> _quizChoices = const [];
  _PracticeItem? _quizAnswer;
  _PracticeItem? _selectedAnswer;
  bool _answerSubmitted = false;

  final List<_PracticeItem> practiceItems = const [
    _PracticeItem('Hello', 'HELLO', 'Greetings'),
    _PracticeItem('Hi', 'HI', 'Greetings'),
    _PracticeItem('How are you?', 'HOW YOU', 'Greetings'),
    _PracticeItem('Yes', 'YES', 'Common'),
    _PracticeItem('No', 'NO', 'Common'),
    _PracticeItem('Please', 'PLEASE', 'Common'),
    _PracticeItem('Thank you', 'THANK-YOU', 'Common'),
    _PracticeItem('Help', 'HELP', 'Common'),

    _PracticeItem('I', 'I', 'Pronouns'),
    _PracticeItem('You', 'YOU', 'Pronouns'),
    _PracticeItem('He', 'HE', 'Pronouns'),
    _PracticeItem('She', 'SHE', 'Pronouns'),
    _PracticeItem('We', 'WE', 'Pronouns'),
    _PracticeItem('They', 'THEY', 'Pronouns'),

    _PracticeItem('What', 'WHAT', 'Questions'),
    _PracticeItem('Where', 'WHERE', 'Questions'),
    _PracticeItem('When', 'WHEN', 'Questions'),
    _PracticeItem('Who', 'WHO', 'Questions'),
    _PracticeItem('Why', 'WHY', 'Questions'),
    _PracticeItem('How', 'HOW', 'Questions'),

    _PracticeItem('Go', 'GO', 'Actions'),
    _PracticeItem('Come', 'COME', 'Actions'),
    _PracticeItem('Want', 'WANT', 'Actions'),
    _PracticeItem('Need', 'NEED', 'Actions'),
    _PracticeItem('Like', 'LIKE', 'Actions'),
    _PracticeItem('Have', 'HAVE', 'Actions'),

    _PracticeItem('School', 'SCHOOL', 'Daily Life'),
    _PracticeItem('Home', 'HOME', 'Daily Life'),
    _PracticeItem('Work', 'WORK', 'Daily Life'),
    _PracticeItem('Food', 'FOOD', 'Daily Life'),
    _PracticeItem('Water', 'WATER', 'Daily Life'),
    _PracticeItem('Today', 'TODAY', 'Daily Life'),
    _PracticeItem('Tomorrow', 'TOMORROW', 'Daily Life'),
    _PracticeItem('Yesterday', 'YESTERDAY', 'Daily Life'),

    _PracticeItem('Good', 'GOOD', 'Feelings'),
    _PracticeItem('Bad', 'BAD', 'Feelings'),
    _PracticeItem('Happy', 'HAPPY', 'Feelings'),
    _PracticeItem('Sad', 'SAD', 'Feelings'),
  ];

  List<String> get _categories {
    final values = practiceItems.map((item) => item.category).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  List<_PracticeItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();

    return practiceItems.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;

      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.gloss.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createQuizQuestion();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSign(_PracticeItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignAnimationScreen(
          originalText: item.title,
          aslGloss: item.gloss,
        ),
      ),
    );
  }

  void _createQuizQuestion() {
    if (practiceItems.length < 4) return;

    final answer = practiceItems[_random.nextInt(practiceItems.length)];

    final wrongAnswers = practiceItems
        .where((item) => item.gloss != answer.gloss)
        .toList()
      ..shuffle(_random);

    final choices = <_PracticeItem>[
      answer,
      ...wrongAnswers.take(3),
    ]..shuffle(_random);

    if (!mounted) return;

    setState(() {
      _quizIndex++;
      _quizAnswer = answer;
      _quizChoices = choices;
      _selectedAnswer = null;
      _answerSubmitted = false;
    });
  }

  void _submitAnswer(_PracticeItem item) {
    if (_answerSubmitted) return;

    setState(() {
      _selectedAnswer = item;
      _answerSubmitted = true;
    });
  }

  bool _isCorrectChoice(_PracticeItem item) {
    return _answerSubmitted && item.gloss == _quizAnswer?.gloss;
  }

  bool _isWrongSelectedChoice(_PracticeItem item) {
    return _answerSubmitted &&
        _selectedAnswer?.gloss == item.gloss &&
        item.gloss != _quizAnswer?.gloss;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Practice Mode',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildModeToggle(),
          if (isLearningMode) ...[
            _buildSearchBar(),
            _buildCategoryChips(),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: isLearningMode
                ? _buildLearningList()
                : _buildTestingMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment:
                  isLearningMode ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accentPurple, Color(0xFF8231FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildToggleTab(
                    label: 'Learning',
                    icon: Icons.menu_book_rounded,
                    isActive: isLearningMode,
                    onTap: () => setState(() => isLearningMode = true),
                  ),
                ),
                Expanded(
                  child: _buildToggleTab(
                    label: 'Testing',
                    icon: Icons.quiz_rounded,
                    isActive: !isLearningMode,
                    onTap: () {
                      setState(() => isLearningMode = false);
                      if (_quizAnswer == null) {
                        _createQuizQuestion();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search signs or categories...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Colors.white38,
                  ),
                ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCategory = category);
            },
            selectedColor: accentPurple,
            backgroundColor: darkButtonColor,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.w600,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildLearningList() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No matching practice signs.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return GestureDetector(
          onTap: () => _openSign(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: darkButtonColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sign_language_rounded,
                    color: accentPurple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: accentPurple,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gloss: ${item.gloss}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestingMode() {
    final answer = _quizAnswer;

    if (answer == null || _quizChoices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: accentPurple),
      );
    }

    final correct = _selectedAnswer?.gloss == answer.gloss;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Text(
                  'Question $_quizIndex',
                  style: const TextStyle(
                    color: accentPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Watch the sign, then choose its meaning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _openSign(answer),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Watch Sign',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ..._quizChoices.map((choice) {
            Color borderColor = Colors.white10;
            Color fillColor = darkButtonColor;
            IconData? trailingIcon;

            if (_isCorrectChoice(choice)) {
              borderColor = Colors.greenAccent;
              fillColor = Colors.green.withValues(alpha: 0.14);
              trailingIcon = Icons.check_circle_rounded;
            } else if (_isWrongSelectedChoice(choice)) {
              borderColor = Colors.redAccent;
              fillColor = Colors.red.withValues(alpha: 0.14);
              trailingIcon = Icons.cancel_rounded;
            }

            return GestureDetector(
              onTap: () => _submitAnswer(choice),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        choice.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailingIcon != null)
                      Icon(
                        trailingIcon,
                        color: _isCorrectChoice(choice)
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                  ],
                ),
              ),
            );
          }),
          if (_answerSubmitted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: correct
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                correct
                    ? 'Correct! ${answer.title} = ${answer.gloss}'
                    : 'The correct answer is ${answer.title} (${answer.gloss}).',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _createQuizQuestion,
                style: FilledButton.styleFrom(
                  backgroundColor: accentPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.navigate_next_rounded),
                label: const Text(
                  'Next Question',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeItem {
  final String title;
  final String gloss;
  final String category;

  const _PracticeItem(
    this.title,
    this.gloss,
    this.category,
  );
}
