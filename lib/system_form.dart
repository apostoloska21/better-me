import 'package:flutter/material.dart';
import 'main.dart';

class SystemFormPage extends StatefulWidget {
  const SystemFormPage({super.key, required this.controller, this.system});

  final SystemsController controller;
  final SystemModel? system;

  @override
  State<SystemFormPage> createState() => _SystemFormPageState();
}

class _SystemFormPageState extends State<SystemFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _habitController = TextEditingController();
  SystemModel? _current;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _current = widget.system;
    _nameController.text = _current?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _createSystem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    await widget.controller.addSystem(name);
    // Resolve the newly created system (last added with matching name and latest time)
    final created = widget.controller.systems.last;
    setState(() {
      _current = created;
      _creating = false;
    });
  }

  Future<void> _addHabit() async {
    if (_current == null) return;
    _habitController.clear();
    final result = await showModalBottomSheet<String>(
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
              const Text('New habit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _habitController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Drink water',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_habitController.text.trim()),
                  child: const Text('Add habit'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return;
    await widget.controller.addHabit(_current!, result);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _current != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit system' : 'New system', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Done',
              icon: const Icon(Icons.check, color: Color(0xFF1F59D1)),
              onPressed: () => Navigator.of(context).pop(true),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              enabled: !isEdit, // name is set on creation only for now
              decoration: const InputDecoration(
                labelText: 'System name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (!isEdit)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _creating ? null : _createSystem,
                  child: _creating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create system'),
                ),
              ),
            if (isEdit) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Habits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    tooltip: 'Add habit',
                    icon: const Icon(Icons.add, color: Color(0xFF1F59D1)),
                    onPressed: _addHabit,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _current!.habits.isEmpty
                    ? const Center(child: Text('No habits yet. Tap + to add one.'))
                    : ListView.separated(
                        itemCount: _current!.habits.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final habit = _current!.habits[index];
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
                              await widget.controller.deleteHabit(_current!, habit);
                              setState(() {});
                            },
                            child: ListTile(
                              title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Created ${_formatDate(habit.createdAt)}  •  Streak: ${habit.streak}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}


