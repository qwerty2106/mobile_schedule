import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';
import 'package:intl/intl.dart';

class TasksList extends StatefulWidget {
  final Api api;
  const TasksList({required this.api, Key? key}) : super(key: key);

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  late Future<List<dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _futureData = widget.api.getData().then((v) => List<dynamic>.from(v ?? []));
  }

  Future<void> refresh() async {
    setState(() {
      _load();
    });
    await _futureData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        final raw = snapshot.data ?? [];

        if (raw.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Center(child: Text('Задач нет', style: TextStyle(color: Colors.grey))),
              ],
            ),
          );
        }

        // Parse and group by date
        final today = DateTime.now();
        DateTime stripDate(DateTime d) => DateTime(d.year, d.month, d.day);

        final List<Map<String, dynamic>> items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final parsed = items.map((item) {
          DateTime? start;
          DateTime? finish;
          try {
            start = DateTime.parse(item['start_time'].toString());
            finish = DateTime.parse(item['finish_time'].toString());
          } catch (_) {}
          item['__start_dt'] = start;
          item['__finish_dt'] = finish;
          item['__date_key'] = start != null ? stripDate(start) : null;
          return item;
        }).toList();

        final todayKey = stripDate(today);
        final tomorrowKey = stripDate(today.add(const Duration(days: 1)));

        final todayTasks = parsed.where((i) => i['__date_key'] != null && (i['__date_key'] as DateTime).isAtSameMomentAs(todayKey)).toList();
        final tomorrowTasks = parsed.where((i) => i['__date_key'] != null && (i['__date_key'] as DateTime).isAtSameMomentAs(tomorrowKey)).toList();
        final other = parsed.where((i) => i['__date_key'] == null || (!((i['__date_key'] as DateTime).isAtSameMomentAs(todayKey) || (i['__date_key'] as DateTime).isAtSameMomentAs(tomorrowKey)))).toList();

        // Group other by date
        final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
        for (final it in other) {
          final key = it['__date_key'] as DateTime? ?? DateTime(1970);
          grouped.putIfAbsent(key, () => []).add(it);
        }

        // Sort groups by date
        final sortedDates = grouped.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Today section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: Row(
                  children: const [
                    Icon(Icons.today, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Сегодня', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (todayTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                  child: Text('Нет задач на сегодня', style: TextStyle(color: Colors.grey)),
                )
              else ...todayTasks.map((item) => _buildTaskCard(context, item)).toList(),

              const SizedBox(height: 8),

              // Tomorrow section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: Row(
                  children: const [
                    Icon(Icons.wb_sunny, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Завтра', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (tomorrowTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                  child: Text('Нет задач на завтра', style: TextStyle(color: Colors.grey)),
                )
              else ...tomorrowTasks.map((item) => _buildTaskCard(context, item)).toList(),

              const SizedBox(height: 12),

              // Other days
              if (sortedDates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Text('Другие дни', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              ...sortedDates.expand((dateKey) {
                final list = grouped[dateKey]!;
                final header = Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6, left: 6),
                  child: Text(DateFormat('dd.MM.yyyy, EEEE', 'ru').format(dateKey), style: const TextStyle(color: Colors.grey)),
                );
                final cards = list.map((item) => _buildTaskCard(context, item)).toList();
                return [header, ...cards];
              }).toList(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> item) {
    final start = item['__start_dt'] as DateTime?;
    final finish = item['__finish_dt'] as DateTime?;
    final timeRange = (start != null && finish != null)
        ? '${DateFormat.Hm().format(start)} • ${DateFormat.Hm().format(finish)}'
        : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(timeRange, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['subject'].toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item['type'].toString(), style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(item['task'].toString(), style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/form', arguments: {'id': item['id']});
                    refresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await widget.api.deleteData(item['id']);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись удалена')));
                      refresh();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
