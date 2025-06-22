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

  // ドーパミンレベル（0.0〜1.2）を計算
  double get dopamineLevel {
    if (ejaculationDates.isEmpty) return 0.0;
    final days = DateTime.now().difference(ejaculationDates.last).inDays;

    if (days <= 1) {
      return 0.2; // 低（Low）：Day 0-1
    } else if (days <= 4) {
      return 0.4; // 中（Medium）：Day 2-4
    } else if (days <= 6) {
      return 0.8; // 高（High）：Day 5-6
    } else if (days == 7) {
      return 1.0; // ピーク注意日（Peak）：Day 7
    } else {
      return 1.2; // 不安定（Unstable）：Day 8以降
    }
  }

  // 指定日のドーパミンレベルを計算
  double getDopamineLevelForDate(DateTime date) {
    if (ejaculationDates.isEmpty) return 0.0;

    // その日以前の最も近い発射日を探す
    var previousDates = ejaculationDates
        .where((ejaculationDate) =>
            ejaculationDate.isBefore(date) || isSameDay(ejaculationDate, date))
        .toList();

    if (previousDates.isEmpty) return 0.0;

    DateTime lastEjaculationBeforeDate =
        previousDates.reduce((a, b) => a.isAfter(b) ? a : b);

    // 発射日からの経過日数を計算
    int daysSinceEjaculation =
        date.difference(lastEjaculationBeforeDate).inDays;

    // 経過日数に基づいてドーパミンレベルを計算
    if (daysSinceEjaculation <= 1) {
      return 0.2; // 低（Low）：Day 0-1
    } else if (daysSinceEjaculation <= 4) {
      return 0.4; // 中（Medium）：Day 2-3
    } else if (daysSinceEjaculation <= 6) {
      return 0.8; // 高（High）：Day 4-6
    } else if (daysSinceEjaculation == 7) {
      return 1.0; // ピーク注意日（Peak）：Day 7
    } else {
      return 1.2; // 不安定（Unstable）：Day 8以降
    }
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
                      TestosteroneGauge(level: dopamineLevel),
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => false,
                          calendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const {
                            CalendarFormat.month: '月',
                          },
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final isEjaculationDay = ejaculationDates
                                  .any((date) => isSameDay(day, date));
                              final level = getDopamineLevelForDate(day);
                              Color color = Colors.grey; // デフォルト値
                              Color textColor = Colors.black;
                              if (level == 0.0) {
                                color = Colors.grey; // 発射日より前の日
                              } else if (level <= 0.2) {
                                color = Colors.redAccent; // 低
                              } else if (level <= 0.4) {
                                color = Colors.yellow; // 中
                              } else if (level <= 0.8) {
                                color = Colors.lightGreen; // 高
                              } else if (level == 1.0) {
                                color = Colors.green.shade900; // ピーク
                              } else if (level == 1.2) {
                                color = Colors.orange; // 不安定
                              }
                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: isEjaculationDay
                                      ? Colors.deepPurple
                                      : color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: isEjaculationDay
                                          ? Colors.white
                                          : textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                            todayBuilder: (context, day, focusedDay) {
                              final isEjaculationDay = ejaculationDates
                                  .any((date) => isSameDay(day, date));
                              final level = getDopamineLevelForDate(day);
                              Color color = Colors.grey; // デフォルト値
                              Color textColor = Colors.black;
                              if (level == 0.0) {
                                color = Colors.grey; // 発射日より前の日
                              } else if (level <= 0.2) {
                                color = Colors.redAccent; // 低
                              } else if (level <= 0.4) {
                                color = Colors.yellow; // 中
                              } else if (level <= 0.8) {
                                color = Colors.lightGreen; // 高
                              } else if (level == 1.0) {
                                color = Colors.green.shade900; // ピーク
                              } else if (level == 1.2) {
                                color = Colors.orange; // 不安定
                              }
                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: isEjaculationDay
                                      ? Colors.deepPurple
                                      : color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.deepPurple,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: isEjaculationDay
                                          ? Colors.white
                                          : textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });

                            // 選択された日が発射日かどうかを確認
                            final isSelectedDayEjaculation = ejaculationDates
                                .any((date) => isSameDay(date, selectedDay));

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(isSelectedDayEjaculation
                                    ? '発射記録の削除'
                                    : '発射記録'),
                                content: Text(isSelectedDayEjaculation
                                    ? '${selectedDay.year}/${selectedDay.month}/${selectedDay.day}の記録を削除しますか？'
                                    : '${selectedDay.year}/${selectedDay.month}/${selectedDay.day}に記録しますか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        if (isSelectedDayEjaculation) {
                                          // 発射日を削除
                                          ejaculationDates.removeWhere((date) =>
                                              isSameDay(date, selectedDay));
                                        } else {
                                          // 発射日を追加
                                          ejaculationDates.add(selectedDay);
                                        }
                                      });
                                      await _saveEjaculationDates();
                                      if (mounted) {
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(isSelectedDayEjaculation
                                                ? '削除完了'
                                                : '記録完了'),
                                            content: Text(
                                                isSelectedDayEjaculation
                                                    ? '記録を削除しました。'
                                                    : '記録が保存されました。'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(isSelectedDayEjaculation
                                        ? '削除する'
                                        : '記録する'),
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
                        Column(
                          children: [
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
                                    color:
                                        Colors.green.shade900.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('ピーク'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen.withOpacity(0.2),
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
                                    color: Colors.yellow.withOpacity(0.2),
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
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('不安定'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'ドーパミンレベルについて',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '発射から7日かけて、ドーパミンレベルは最大値に近づきます。\n'
                                '発射間隔をコントロールすることで、より良い体調と精神状態を保つことができます。',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '今月の発射回数: ${ejaculationDates.where((date) => date.year == DateTime.now().year && date.month == DateTime.now().month).length}回',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '前回の発射から: ${lastEjaculationDate != null ? DateTime.now().difference(lastEjaculationDate!).inDays : 0}日',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
  final double level; // 0.0〜1.2
  const TestosteroneGauge({super.key, required this.level});

  String getLevelText() {
    if (level <= 0.2) return '低';
    if (level <= 0.4) return '中';
    if (level <= 0.8) return '高';
    if (level == 1.0) return 'ピーク';
    if (level == 1.2) return '不安定';
    return '中';
  }

  Color getLevelColor() {
    if (level <= 0.2) return Colors.redAccent;
    if (level <= 0.4) return Colors.yellow;
    if (level <= 0.8) return Colors.lightGreen;
    if (level == 1.0) return Colors.green.shade900;
    if (level == 1.2) return Colors.orange;
    return Colors.yellow;
  }

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
                getLevelText(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: getLevelColor(),
                ),
              ),
              const SizedBox(height: 8),
              const Text('ドーパミンレベル'),
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

  Color getLevelColor() {
    if (level <= 0.2) return Colors.redAccent;
    if (level <= 0.4) return Colors.yellow;
    if (level <= 0.8) return Colors.lightGreen;
    if (level == 1.0) return Colors.green.shade900;
    if (level == 1.2) return Colors.orange;
    return Colors.yellow;
  }

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
      ..color = getLevelColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(10), 0, 2 * pi, false, backgroundPaint);
    canvas.drawArc(rect.deflate(10), startAngle, sweepAngle, false, levelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
