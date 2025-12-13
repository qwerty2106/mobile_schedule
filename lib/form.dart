import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final response = await Supabase.instance.client
          .from('lessons')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _currentLesson = response as Map<String, dynamic>;
          //Обновляем контроллеры
          _subjectController.text = _currentLesson?['subject'] ?? '';
          _typeController.text = _currentLesson?['type'] ?? '';
          _taskController.text = _currentLesson?['task'] ?? '';
          _startTime = DateTime.tryParse(_currentLesson?['start_time']) ?? DateTime.now();
          _finishTime = DateTime.tryParse(_currentLesson?['finish_time']) ?? DateTime.now().add(const Duration(hours: 1));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Запись не найдена')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  void _submit() async {
    if (_startTime == null || _finishTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, выберите время начала и окончания')),
      );
      return;
    }

    if (widget.lessonId != null) {
      await api.updateData(widget.lessonId!, _subjectController.text, _typeController.text, _taskController.text, _startTime!, _finishTime!);
    } else {
      await api.createData(_subjectController.text, _typeController.text, _taskController.text, _startTime!, _finishTime!);
    }

    Navigator.pop(context);
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
      ScaffoldMessenger.of(context).showSnackBar(
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.lessonId != null ? 'Редактировать запись' : 'Создать запись'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Заголовок (Предмет)
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Предмет'),
                onChanged: (value) {},
              ),
              SizedBox(height: 16),

              //Тип
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: 'Тип занятия (Лекция, Практика и т.д.)'),
              ),
              SizedBox(height: 16),

              //Задача
              TextFormField(
                controller: _taskController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Задание / Описание'),
              ),
              SizedBox(height: 16),

              //Начало тайминга
              ElevatedButton(
                onPressed: _selectStartTime,
                child: Text(_startTime == null
                    ? 'Выберите время начала'
                    : 'Начало: ${_startTime!.toIso8601String().substring(0, 16)}'),
              ),
              SizedBox(height: 16),

              //Конец тайминга
              ElevatedButton(
                onPressed: _selectFinishTime,
                child: Text(_finishTime == null
                    ? 'Выберите время окончания'
                    : 'Окончание: ${_finishTime!.toIso8601String().substring(0, 16)}'),
              ),
              SizedBox(height: 32),

              //Сохранение
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.lessonId != null ? 'Обновить' : 'Создать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}