import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF040C20),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const DiceHome(),
    );
  }
}

class DiceHome extends StatefulWidget {
  const DiceHome({super.key});

  @override
  State<DiceHome> createState() => _DiceHomeState();
}

class _DiceHomeState extends State<DiceHome> {
  final Random _random = Random();
  final List<_RollEntry> _history = <_RollEntry>[];

  int _diceValue = 1;
  int _lastGuess = 0;
  double _diceTurns = 0;

  int get _total => _history.length;
  double get _average => _history.isEmpty
      ? 0
      : _history.map((e) => e.rolled).reduce((a, b) => a + b) / _history.length;
  int get _sixes => _history.where((value) => value.rolled == 6).length;
  int get _ones => _history.where((value) => value.rolled == 1).length;
  int get _bonusHits => _history.where((value) => value.bonus > 0).length;
  int get _bonusPoints => _history.fold(0, (sum, e) => sum + e.bonus);

  Future<void> _pickAndRoll() async {
    final int? selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A37),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Select a number',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 260,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(6, (index) {
              final int number = index + 1;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, number),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF132247),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2B3C66)),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFE7EDFF),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );

    if (selected == null) {
      return;
    }

    final int rolled = _random.nextInt(6) + 1;
    final int bonus = selected == rolled ? 10 : 0;

    setState(() {
      _lastGuess = selected;
      _diceValue = rolled;
      _diceTurns += 1.5 + _random.nextDouble();
      _history.insert(
        0,
        _RollEntry(
          guessed: selected,
          rolled: rolled,
          bonus: bonus,
          timestamp: DateTime.now(),
        ),
      );
    });

    final bool wonBonus = bonus > 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: wonBonus ? const Color(0xFF1D8E53) : const Color(0xFF1A2B52),
        content: Text(
          wonBonus
              ? 'Bonus +$bonus! You selected $selected and rolled $rolled.'
              : 'You selected $selected and rolled $rolled. No bonus this time.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_RollEntry> bonusHistory =
        _history.where((entry) => entry.bonus > 0).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Lucky Roll',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select 1-6, then roll to win bonus',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6F7DA6),
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickAndRoll,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x66FFD51A), Color(0x00040C20)],
                            radius: 0.7,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 156,
                        height: 156,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACD1A),
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88FECF1A),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 14,
                              top: 14,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            Center(
                              child: AnimatedRotation(
                                turns: _diceTurns,
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                child: Image.asset(
                                  'assets/images/dice_$_diceValue.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _lastGuess == 0
                      ? 'Rolled a $_diceValue'
                      : 'Selected $_lastGuess and rolled $_diceValue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF8EA0CC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 240,
                  child: ElevatedButton.icon(
                    onPressed: _pickAndRoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACD1A),
                      foregroundColor: const Color(0xFF0A1127),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.casino, size: 20),
                    label: Text(
                      'Roll Dice',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatCard(
                      icon: Icons.radio_button_checked,
                      iconColor: const Color(0xFF5B8BFF),
                      title: '$_total',
                      subtitle: 'Total',
                    ),
                    _StatCard(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFFF9C613),
                      title: _average.toStringAsFixed(0),
                      subtitle: 'Average',
                    ),
                    _StatCard(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFF22C082),
                      title: '$_sixes',
                      subtitle: 'Sixes',
                    ),
                    _StatCard(
                      icon: Icons.favorite,
                      iconColor: const Color(0xFFFF5A64),
                      title: '$_ones',
                      subtitle: 'Ones',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F2D54), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFFFACD1A), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Bonus: $_bonusPoints points ($_bonusHits wins)',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFE7EDFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ROLL HISTORY',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFF9AA7CC),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _history.isEmpty
                    ? _emptyBox('No rolls yet')
                    : _historyList(_history.take(6).toList()),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'BONUS HISTORY',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFFF3CF54),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                bonusHistory.isEmpty
                    ? _emptyBox('No bonus wins yet')
                    : _bonusList(bonusHistory.take(6).toList()),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyList(List<_RollEntry> rolls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0E1A37).withValues(alpha: 0.7),
            border: Border.all(
              color: const Color(0xFF243057),
              width: 1,
            ),
          ),
          child: Column(
            children: rolls.map((entry) {
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.casino, color: Color(0xFF7E90BC), size: 18),
                title: Text(
                  'Guess ${entry.guessed} | Rolled ${entry.rolled}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFCFD7F5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _bonusList(List<_RollEntry> bonuses) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2C52).withValues(alpha: 0.7),
          border: Border.all(color: const Color(0xFF3D4F73), width: 1),
        ),
        child: Column(
          children: bonuses.map((entry) {
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.emoji_events, color: Color(0xFFFACD1A), size: 18),
              title: Text(
                'Matched ${entry.guessed}! +${entry.bonus} bonus',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFF3BF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _formatTime(entry.timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFD7C577),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101C3D).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF243057),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF5C6D97),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7AA4),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    final String second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _RollEntry {
  const _RollEntry({
    required this.guessed,
    required this.rolled,
    required this.bonus,
    required this.timestamp,
  });

  final int guessed;
  final int rolled;
  final int bonus;
  final DateTime timestamp;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1A38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2D54), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: const Color(0xFFE7EDFF),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF7181AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
