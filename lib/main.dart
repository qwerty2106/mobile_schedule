import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';
import 'package:mobile_schedule/form.dart';
import 'package:mobile_schedule/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'widgets/tasks_list.dart';
import 'widgets/past_list.dart';

//Запуск приложения
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize intl locale data (used for Russian weekdays/dates)
  await initializeDateFormatting('ru');

  await Supabase.initialize(
    url: 'https://dllhkfwyiexblndowpxh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsbGhrZnd5aWV4YmxuZG93cHhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxMDc4OTEsImV4cCI6MjA3NTY4Mzg5MX0.gd0UW_yiHnH2TotoAv8s6-Jvfg-jPq4ybMKVz18bsaM',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final initial = Supabase.instance.client.auth.currentUser == null
        ? '/login'
        : '/';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      initialRoute: initial,
      routes: {
        '/': (content) => const MyHomePage(),
        '/login': (content) => const LoginPage(),
        '/form': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          if (args != null && args.containsKey('id')) {
            return FormPage(lessonId: args['id']); //Обновление записи
          } else {
            return FormPage(); //Создание новой записи
          }
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final api = Api();
  final GlobalKey _tasksKey = GlobalKey();
  final GlobalKey _pastKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      //Если пользователь не авторизован, то открываем login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _delete(id) async {
    await api.deleteData(id);
  }

  @override
  Widget build(BuildContext context) {
    // build UI by selected tab
    String title = 'Расписание занятий';
    final rawHeaderDate = DateFormat('EEEE, dd.MM.yy', 'ru').format(DateTime.now());
    final headerDate = rawHeaderDate.isNotEmpty ? (rawHeaderDate[0].toUpperCase() + rawHeaderDate.substring(1)) : rawHeaderDate;

    Widget body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text('Сегодня', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Text(headerDate, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: TasksList(
            key: _tasksKey,
            api: api,
          ),
        ),
      ],
    );

    if (_currentIndex == 1) {
      title = 'Прошедшие занятия';
      body = PastList(key: _pastKey, api: api);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // login should open route instead of acting as a tab
          if (index == 2) {
            Navigator.pushNamed(context, '/login');
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            label: 'Домой',
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: 'Прошедшие',
            icon: Icon(Icons.history),
          ),
          BottomNavigationBarItem(
            label: 'Вход',
            icon: Icon(Icons.login),
          ),
        ],
      ),
      body: body,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/form',
                ).then((result) {
                  // refresh lists after returning from form
                  ( _tasksKey.currentState as dynamic)?.refresh();
                  ( _pastKey.currentState as dynamic)?.refresh();
                });
              },
            )
          : null,
    );
  }
}
