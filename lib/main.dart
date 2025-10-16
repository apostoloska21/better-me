import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'system_form.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const BetterMeApp());
}

class BetterMeApp extends StatelessWidget {
  const BetterMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6), // blue-500
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFEAEAEA)),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Color(0x143B82F6),
          backgroundColor: Colors.white,
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
  late final SystemsController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = SystemsController();
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
      SystemsPage(controller: _controller),
    ];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Better Me', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Soft gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF7EB3), // pink
                  Color(0xFF8B5CF6), // purple
                  Color(0xFF0F0F10), // near-black
                ],
              ),
            ),
          ),
          SafeArea(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    offset: Offset(0, 6),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
                  NavigationDestination(icon: Icon(Icons.view_list_outlined), selectedIcon: Icon(Icons.view_list), label: 'Systems'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.controller});
  final SystemsController controller;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    final today = widget.controller.todayKey;
    final systems = widget.controller.systems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: systems.isEmpty
          ? const Center(child: Text('Add a system on the Systems tab.'))
          : ListView.separated(
              itemCount: systems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final system = systems[index];
                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                system.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x143B82F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${system.habits.length} habit${system.habits.length == 1 ? '' : 's'}',
                                style: const TextStyle(color: Color(0xFF1F59D1), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (system.habits.isEmpty)
                          const Text('No habits yet.', style: TextStyle(color: Colors.grey))
                        else
                          ...system.habits.map((habit) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
                                            Text('🔥 Streak ${habit.streak}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  WeekSquares(
                                    habit: habit,
                                    todayKey: today,
                                    onToggleToday: () async {
                                      await widget.controller.toggleToday(habit);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SystemsPage extends StatefulWidget {
  const SystemsPage({super.key, required this.controller});
  final SystemsController controller;

  @override
  State<SystemsPage> createState() => _SystemsPageState();
}

class _SystemsPageState extends State<SystemsPage> {
  Future<void> _openCreateForm() async {
    final TextEditingController nameCtrl = TextEditingController();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New system', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Morning Routine',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) => Navigator.of(context).pop(v.trim().isEmpty ? null : true),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create system'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (changed == true) setState(() {});
    if (changed == true && nameCtrl.text.trim().isNotEmpty) {
      await widget.controller.addSystem(nameCtrl.text.trim());
      if (mounted) setState(() {});
    }
  }

  Future<void> _openEditForm(SystemModel system) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, controller) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SystemFormPage(controller: widget.controller, system: system),
          );
        },
      ),
    );
    if (changed == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final systems = widget.controller.systems;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF7EB3), Color(0xFF8B5CF6), Color(0xFF0F0F10)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: systems.isEmpty
                ? const Center(child: Text('No systems yet.'))
                : ReorderableListView.builder(
                    itemCount: systems.length,
                    onReorder: (oldIndex, newIndex) async {
                      await widget.controller.reorderSystems(oldIndex, newIndex);
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final system = systems[index];
                      return Dismissible(
                        key: ValueKey(system.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: const Color(0xFFE53935),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await widget.controller.deleteSystem(system);
                          setState(() {});
                        },
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFEAEAEA)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        system.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Manage',
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF1F59D1)),
                                      onPressed: () => _openEditForm(system),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (system.habits.isEmpty)
                                  const Text('No habits yet.', style: TextStyle(color: Colors.grey))
                                else
                                  Column(
                                    children: system.habits.map((habit) {
                                      return Dismissible(
                                        key: ValueKey(habit.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: const Color(0xFFE53935),
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 16),
                                          child: const Icon(Icons.delete_outline, color: Colors.white),
                                        ),
                                        onDismissed: (_) async {
                                          await widget.controller.deleteHabit(system, habit);
                                          setState(() {});
                                        },
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                          dense: true,
                                          title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text('Created ${_formatDate(habit.createdAt)}  •  Streak: ${habit.streak}'),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
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

class WeekSquares extends StatelessWidget {
  const WeekSquares({super.key, required this.habit, required this.todayKey, required this.onToggleToday});

  final Habit habit;
  final String todayKey;
  final VoidCallback onToggleToday;

  List<DateTime> _currentWeekDays(DateTime today) {
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7)); // Sunday as start
    return List<DateTime>.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _currentWeekDays(today);
    return Row(
      children: days.map((d) {
        final key = _dayKey(d);
        final isToday = key == todayKey;
        final isCompleted = habit.completedDays.contains(key);
        final isPast = d.isBefore(DateTime(today.year, today.month, today.day));
        final isFuture = d.isAfter(DateTime(today.year, today.month, today.day));
        final canTap = isToday; // only today can be toggled

        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final todayDoneColor = Colors.green.shade600;
        final missedColor = Colors.red.shade400;
        Color bg;
        Color border;
        Color textColor;

        if (isToday && isCompleted) {
          bg = todayDoneColor;
          border = todayDoneColor;
          textColor = Colors.white;
        } else if (isPast && !isCompleted) {
          bg = missedColor.withOpacity(0.15);
          border = missedColor;
          textColor = missedColor;
        } else if (isToday && !isCompleted) {
          bg = Colors.green.withOpacity(0.08);
          border = Colors.green.shade600;
          textColor = Colors.green.shade700;
        } else {
          bg = Colors.grey.shade200;
          border = Colors.grey.shade300;
          textColor = isCompleted ? Colors.white : Colors.black87;
          if (isCompleted) {
            bg = Colors.grey.shade600;
            border = Colors.grey.shade600;
          }
        }

        Widget square = Container(
          width: 40,
          height: 48,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                d.day.toString(),
                style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
        );

        if (canTap) {
          square = InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggleToday,
            child: square,
          );
        } else {
          square = Tooltip(
            message: isPast ? 'Past' : 'Future',
            child: Opacity(opacity: isPast || isFuture ? 0.7 : 1.0, child: square),
          );
        }

        return square;
      }).toList(),
    );
  }
}

class SystemModel {
  SystemModel({
    required this.id,
    required this.name,
    required this.createdAt,
    List<Habit>? habits,
  }) : habits = habits ?? <Habit>[];

  final String id;
  final String name;
  final DateTime createdAt;
  final List<Habit> habits;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'habits': habits.map((h) => h.toJson()).toList(),
    };
  }

  static SystemModel fromJson(Map<String, dynamic> json) {
    return SystemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      habits: (json['habits'] as List<dynamic>).map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SystemsController {
  static const String _systemsPrefsKey = 'systems_data_v1';
  static const String _legacyHabitsKey = 'habits_data_v1';

  final List<SystemModel> _systems = <SystemModel>[];

  List<SystemModel> get systems => List.unmodifiable(_systems);
  String get todayKey => _dayKey(DateTime.now());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Try new structure first
    final rawSystems = prefs.getString(_systemsPrefsKey);
    if (rawSystems != null) {
      final data = jsonDecode(rawSystems) as List<dynamic>;
      _systems
        ..clear()
        ..addAll(data.map((e) => SystemModel.fromJson(e as Map<String, dynamic>)));
      return;
    }

    // Migrate legacy habits into a default system if present
    final rawLegacy = prefs.getString(_legacyHabitsKey);
    if (rawLegacy != null) {
      final data = jsonDecode(rawLegacy) as List<dynamic>;
      final legacyHabits = data.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
      final defaultSystem = SystemModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'My Habits',
        createdAt: DateTime.now(),
        habits: legacyHabits,
      );
      _systems
        ..clear()
        ..add(defaultSystem);
      await _save();
      return;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_systems.map((s) => s.toJson()).toList());
    await prefs.setString(_systemsPrefsKey, raw);
  }

  Future<void> addSystem(String name) async {
    final system = SystemModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _systems.add(system);
    await _save();
  }

  Future<void> deleteSystem(SystemModel system) async {
    _systems.removeWhere((s) => s.id == system.id);
    await _save();
  }

  Future<void> reorderSystems(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _systems.removeAt(oldIndex);
    _systems.insert(newIndex, item);
    await _save();
  }

  Future<void> addHabit(SystemModel system, String name) async {
    final idx = _systems.indexWhere((s) => s.id == system.id);
    if (idx == -1) return;
    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _systems[idx].habits.add(habit);
    await _save();
  }

  Future<void> deleteHabit(SystemModel system, Habit habit) async {
    final idx = _systems.indexWhere((s) => s.id == system.id);
    if (idx == -1) return;
    _systems[idx].habits.removeWhere((h) => h.id == habit.id);
    await _save();
  }

  Future<void> toggleToday(Habit habit) async {
    final today = todayKey;
    // Find habit across systems
    for (final system in _systems) {
      final idx = system.habits.indexWhere((h) => h.id == habit.id);
      if (idx != -1) {
        final target = system.habits[idx];
        if (target.completedDays.contains(today)) {
          target.completedDays.remove(today);
        } else {
          target.completedDays.add(today);
        }
        await _save();
        return;
      }
    }
  }
}

String _dayKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
