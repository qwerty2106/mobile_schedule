import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';
import 'package:mobile_schedule/form.dart';
import 'package:mobile_schedule/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Запуск приложения
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      initialRoute: '/',
      routes: {
        '/': (content) => const MyHomePage(),
        '/login': (content) => const LoginPage(),
        '/form': (content) => const FormPage(),
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

  void _delete(id) async {
    await api.deleteData(id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      //Запрос
      future: api.getData(),
      builder: (context, snapshot) {
        //Запрос выполнен
        if (snapshot.connectionState == ConnectionState.done) {
          //Ошибка
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error} occured'));
          }
          //Данные есть
          else if (snapshot.hasData) {
            final data = snapshot.data;
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text('Расписание занятий'),
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (index == 1) {
                    Navigator.pushNamed(context, '/login');
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    label: 'Домой',
                    icon: Icon(Icons.home),
                  ),
                  BottomNavigationBarItem(
                    label: 'Вход',
                    icon: Icon(Icons.login),
                  ),
                ],
              ),
              body: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) => ListTile(
                  title: Row(
                    children: [
                      Divider(color: Colors.grey, thickness: 2),
                      Column(
                        children: [
                          Text(
                            data[index]['start_time'].toString().substring(
                              11,
                              16,
                            ),
                          ),
                          Text(
                            data[index]['finish_time'].toString().substring(
                              11,
                              16,
                            ),
                          ),
                        ],
                      ),
                      // Divider(color: Colors.grey, thickness: 2),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data[index]['subject'].toString()),
                          Text(
                            style: TextStyle(color: Colors.grey),
                            data[index]['type'].toString(),
                          ),
                          Text(
                            style: TextStyle(fontStyle: FontStyle.italic),
                            data[index]['task'].toString(),
                          ),
                          TextButton(
                            onPressed: () => _delete(data[index]['id']),
                            child: Text('Удалить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              //Добавление записи
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.pushNamed(context, '/form');
                },
              ),
            );
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
