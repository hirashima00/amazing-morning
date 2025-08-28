import 'package:flutter/material.dart';
import 'dart:math';

class SlotMachinePage extends StatefulWidget {
  const SlotMachinePage({super.key});

  @override
  State<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends State<SlotMachinePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<String> _emojis = [
    '🍒',
    '🍋',
    '🍊',
    '🍉',
    '🍇',
    '🍓',
    '🍎',
    '🍑',
    '🔔',
    '⭐',
  ];
  int _resultIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animation.addListener(() {
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _determineResult();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _spin() {
    _animationController.reset();
    _animationController.forward();
  }

  void _determineResult() {
    final random = Random();
    setState(() {
      _resultIndex = random.nextInt(_emojis.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Slot Machine'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSlotReel(),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _spin,
              child: const Text('SPIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotReel() {
    double translateY = _animation.value * (_emojis.length * 100);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(0, -translateY),
            child: Column(
              children: _emojis.map((emoji) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}