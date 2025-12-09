import 'package:flutter/material.dart';
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

//Статический класс для запросов
class Api {
  //Выборка всех записей
  static Future<dynamic> getData() {
    return Supabase.instance.client.from('lessons').select();
  }

  //Создание записи
  static Future<dynamic> createData(
    subject,
    type,
    task,
    startTime,
    finishTime,
  ) {
    return Supabase.instance.client.from('lessons').insert({
      'subject': subject,
      'type': type,
      'task': task,
      'start_time': startTime.toIso8601String(),
      'finish_time': finishTime.toIso8601String(),
    });
  }

  //Удаление записи
  static Future<dynamic> deleteData(id) {
    return Supabase.instance.client.from('lessons').delete().eq('id', id);
  }
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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

void _delete(id) async{
  await Api.deleteData(id);
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      //Запрос
      future: Api.getData(),
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
                title: Text('Schedule'),
              ),
              body: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) => ListTile(
                  title: Row(
                    children: [
                      // Column(
                      //   children: [Text(data[index]['priority'].toString())],
                      // ),
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
                          TextButton(onPressed: () => _delete(data[index]['id']), child: Text('Удалить'))
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FormRoute()),
                  );
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

class FormRoute extends StatefulWidget {
  const FormRoute({super.key});

  @override
  State<FormRoute> createState() => _FormRouteState();
}

class _FormRouteState extends State<FormRoute> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  String subject = "";
  String type = "";
  String task = "";
  DateTime startTime = DateTime.now();
  DateTime finishTime = DateTime.now();

  void _submit() async {
    await Api.createData(subject, type, task, startTime, finishTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Create new lesson'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //Subject
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject'),
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    subject = value;
                  });
                },
              ),
              //Type
              TextFormField(
                decoration: InputDecoration(labelText: 'Type'),
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    type = value;
                  });
                },
              ),
              //Task
              TextFormField(
                decoration: InputDecoration(labelText: 'Task'),
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    task = value;
                  });
                },
              ),

              TextButton(onPressed: _submit, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
