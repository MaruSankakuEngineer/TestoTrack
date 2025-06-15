import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(const TestoTrackApp());
}

class TestoTrackApp extends StatelessWidget {
  const TestoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TestoTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageController _pageController = PageController();
  List<DateTime> ejaculationDates = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEjaculationDates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ページを切り替える
  void _changePage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ページが変更されたときの処理
  void _onPageChanged(int page) {
    if (page == 0) {
      _pageController.jumpToPage(2);
    } else if (page == 3) {
      _pageController.jumpToPage(1);
    }
  }

  // 保存された発射日を読み込む
  Future<void> _loadEjaculationDates() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDates = prefs.getStringList('ejaculationDates');
    if (savedDates != null) {
      setState(() {
        ejaculationDates =
            savedDates.map((date) => DateTime.parse(date)).toList();
      });
    }
  }

  // 発射日を保存する
  Future<void> _saveEjaculationDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'ejaculationDates',
      ejaculationDates.map((date) => date.toIso8601String()).toList(),
    );
  }

  // 最新の発射日を取得
  DateTime? get lastEjaculationDate =>
      ejaculationDates.isNotEmpty ? ejaculationDates.last : null;

  // テストステロンレベル（0.0〜1.0）を計算
  double get testosteroneLevel {
    if (ejaculationDates.isEmpty) return 1.0;
    final days = DateTime.now().difference(ejaculationDates.last).inDays;
    if (days >= 7) return 1.0;
    return (days / 7).clamp(0.0, 1.0);
  }

  // 指定日のテストステロンレベルを計算
  double getTestosteroneLevelForDate(DateTime date) {
    if (ejaculationDates.isEmpty) return 1.0;

    // その日付以前の最新の発射日を探す
    DateTime? lastDate;
    for (var d in ejaculationDates.reversed) {
      if (d.isBefore(date) || isSameDay(d, date)) {
        lastDate = d;
        break;
      }
    }

    if (lastDate == null) return 1.0;
    final days = date.difference(lastDate).inDays;
    if (days >= 7) return 1.0;
    return (days / 7).clamp(0.0, 1.0);
  }

  // 発射記録
  void _recordEjaculation() async {
    setState(() {
      ejaculationDates.add(DateTime.now());
    });
    await _saveEjaculationDates();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記録完了'),
        content: const Text('記録が保存されました。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TestosteroneGauge(level: testosteroneLevel),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(32),
                          backgroundColor: Colors.deepPurple,
                        ),
                        onPressed: _recordEjaculation,
                        child: const Icon(
                          Icons.power_settings_new,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('記録する'),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => false,
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final isEjaculationDay = ejaculationDates.any((date) => isSameDay(day, date));
                            final level = getTestosteroneLevelForDate(day);
                            Color color;
                            if (level < 0.33) {
                              color = Colors.redAccent;
                            } else if (level < 0.66) {
                              color = Colors.orangeAccent;
                            } else {
                              color = Colors.green;
                            }
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isEjaculationDay 
                                    ? Colors.deepPurple 
                                    : color.withOpacity(0.2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isEjaculationDay ? Colors.white : Colors.black,
                                  fontWeight: isEjaculationDay ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('発射記録'),
                              content: Text('${selectedDay.year}/${selectedDay.month}/${selectedDay.day}に記録しますか？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    setState(() {
                                      ejaculationDates.add(selectedDay);
                                    });
                                    await _saveEjaculationDates();
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('記録完了'),
                                          content: const Text('記録が保存されました。'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('記録する'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '発射日: ${lastEjaculationDate != null ? "${lastEjaculationDate!.year}/${lastEjaculationDate!.month}/${lastEjaculationDate!.day}" : "未記録"}',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('発射日'),
                          const SizedBox(width: 24),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('高'),
                          const SizedBox(width: 24),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('中'),
                          const SizedBox(width: 24),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('低'),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class TestosteroneGauge extends StatelessWidget {
  final double level; // 0.0〜1.0
  const TestosteroneGauge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _GaugePainter(level),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(level * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('テストステロンレベル'),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double level;
  _GaugePainter(this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * level;
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    final levelPaint = Paint()
      ..color = level < 0.33
          ? Colors.redAccent
          : (level < 0.66 ? Colors.orangeAccent : Colors.green)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(10), 0, 2 * pi, false, backgroundPaint);
    canvas.drawArc(rect.deflate(10), startAngle, sweepAngle, false, levelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
