import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BetterMeApp());
}

class BetterMeApp extends StatelessWidget {
  const BetterMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Me',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.grey,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final HabitsController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = HabitsController();
    _controller.load().then((_) {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      TodayPage(controller: _controller),
      HabitsPage(controller: _controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Better Me'),
        centerTitle: false,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Habits'),
        ],
      ),
    );
  }
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.controller});
  final HabitsController controller;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    final today = widget.controller.todayKey;
    final habits = widget.controller.habits;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: habits.isEmpty
          ? const Center(child: Text('Add your first habit on the Habits tab.'))
          : ListView.separated(
              itemCount: habits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final completed = habit.completedDays.contains(today);
                return ListTile(
                  title: Text(habit.name),
                  subtitle: Text('Streak: ${habit.streak}'),
                  trailing: Switch(
                    value: completed,
                    onChanged: (_) async {
                      await widget.controller.toggleToday(habit);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.controller});
  final HabitsController controller;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addHabitDialog() async {
    _nameController.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New habit'),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'e.g. Drink water',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_nameController.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      await widget.controller.addHabit(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = widget.controller.habits;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: habits.isEmpty
            ? const Center(child: Text('No habits yet.'))
            : ReorderableListView.builder(
                itemCount: habits.length,
                onReorder: (oldIndex, newIndex) async {
                  await widget.controller.reorder(oldIndex, newIndex);
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return Dismissible(
                    key: ValueKey(habit.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await widget.controller.deleteHabit(habit);
                      setState(() {});
                    },
                    child: ListTile(
                      title: Text(habit.name),
                      subtitle: Text('Created ${_formatDate(habit.createdAt)}  •  Streak: ${habit.streak}'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    Set<String>? completedDays,
  }) : completedDays = completedDays ?? <String>{};

  final String id;
  final String name;
  final DateTime createdAt;
  final Set<String> completedDays;

  int get streak {
    int streakCount = 0;
    DateTime day = DateTime.now();
    String key = _dayKey(day);
    while (completedDays.contains(key)) {
      streakCount += 1;
      day = day.subtract(const Duration(days: 1));
      key = _dayKey(day);
    }
    return streakCount;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDays': completedDays.toList(),
    };
  }

  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      completedDays: (json['completedDays'] as List<dynamic>).map((e) => e as String).toSet(),
    );
  }
}

class HabitsController {
  static const String _prefsKey = 'habits_data_v1';
  final List<Habit> _habits = <Habit>[];

  List<Habit> get habits => List.unmodifiable(_habits);
  String get todayKey => _dayKey(DateTime.now());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as List<dynamic>;
    _habits
      ..clear()
      ..addAll(data.map((e) => Habit.fromJson(e as Map<String, dynamic>)));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  Future<void> addHabit(String name) async {
    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _habits.add(habit);
    await _save();
  }

  Future<void> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, item);
    await _save();
  }

  Future<void> toggleToday(Habit habit) async {
    final today = todayKey;
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx == -1) return;
    final target = _habits[idx];
    if (target.completedDays.contains(today)) {
      target.completedDays.remove(today);
    } else {
      target.completedDays.add(today);
    }
    await _save();
  }
}

String _dayKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
