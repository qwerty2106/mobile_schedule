import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FormPage extends StatefulWidget {
  final int? lessonId;

  const FormPage({super.key, this.lessonId});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final Api api = Api();

  late TextEditingController _subjectController;
  late TextEditingController _typeController;
  late TextEditingController _taskController;

  DateTime? _startTime;
  DateTime? _finishTime;

  Map<String, dynamic>? _currentLesson;

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллеры
    _subjectController = TextEditingController();
    _typeController = TextEditingController();
    _taskController = TextEditingController();

    if (widget.lessonId != null) {
      _loadLessonData(widget.lessonId!);
    } else {
      _startTime = DateTime.now();
      _finishTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    //Очистка контроллеров
    _subjectController.dispose();
    _typeController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonData(int id) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('User not authenticated');

      final response = await Supabase.instance.client
          .from('lessons')
          .select()
          .eq('id', id)
          .eq('user_id', uid)
          .maybeSingle();

      if (response != null) {
        if (!mounted) return;
        _currentLesson = Map<String, dynamic>.from(response as Map);
        //Обновляем контроллеры
        _subjectController.text = _currentLesson?['subject'] ?? '';
        _typeController.text = _currentLesson?['type'] ?? '';
        _taskController.text = _currentLesson?['task'] ?? '';
        _startTime = DateTime.tryParse(_currentLesson?['start_time']?.toString() ?? '') ?? DateTime.now();
        _finishTime = DateTime.tryParse(_currentLesson?['finish_time']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 1));
        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Запись не найдена')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startTime == null || _finishTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите время начала и окончания')),
      );
      return;
    }

    try {
      if (widget.lessonId != null) {
        await api.updateData(widget.lessonId!, _subjectController.text.trim(), _typeController.text.trim(), _taskController.text.trim(), _startTime!, _finishTime!);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись обновлена')));
      } else {
        await api.createData(_subjectController.text.trim(), _typeController.text.trim(), _taskController.text.trim(), _startTime!, _finishTime!);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись создана')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

  //Методы выбора даты/времени
  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      );
      if (time != null) {
        if (!mounted) return;
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectFinishTime() async {
    if (_startTime == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сначала выберите время начала')),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _finishTime ?? _startTime!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_finishTime ?? _startTime!),
      );
      if (time != null) {
        if (!mounted) return;
        setState(() {
          _finishTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String _formatDateTime(DateTime? dt) => dt == null ? 'Не выбрано' : DateFormat('dd.MM.yyyy HH:mm').format(dt);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.lessonId != null ? 'Редактировать запись' : 'Создать запись'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Заголовок (Предмет)
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Предмет',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Введите предмет' : null,
                ),
                const SizedBox(height: 16),

                //Тип
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: 'Тип занятия (Лекция, Практика и т.д.)',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                //Задача
                TextFormField(
                  controller: _taskController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Задание / Описание',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                //Время
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text('Начало: ${_formatDateTime(_startTime)}'),
                        onPressed: _selectStartTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text('Окончание: ${_formatDateTime(_finishTime)}'),
                        onPressed: _selectFinishTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                //Сохранение
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(widget.lessonId != null ? 'Обновить' : 'Создать'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}