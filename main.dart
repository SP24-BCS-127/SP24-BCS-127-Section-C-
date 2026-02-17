// main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const CandyCounterApp());
}

class CandyCounterApp extends StatelessWidget {
  const CandyCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Georgia', // Gives it a slightly more "storybook" feel
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background for a soft, premium feel
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1EB), Color(0xFFACE0F9)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating White Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "POINTS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5A7AB1),
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // Bubbled Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _candyButton(
                  icon: Icons.remove,
                  color: const Color(0xFFFF8B94), // Pastel Pink
                  onTap: () => setState(() => _score--),
                ),
                const SizedBox(width: 30),
                _candyButton(
                  icon: Icons.add,
                  color: const Color(0xFF97E5D1), // Mint Green
                  onTap: () => setState(() => _score++),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Text Link for Reset
            TextButton(
              onPressed: () => setState(() => _score = 0),
              child: const Text(
                'Start Over',
                style: TextStyle(
                  color: Color(0xFF5A7AB1),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom "Candy" style button
  Widget _candyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 35),
      ),
    );
  }
}
