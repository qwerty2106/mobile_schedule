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
  static Future<dynamic> getData() {
    return Supabase.instance.client.from('tasks').select();
  }

  static Future<dynamic> createData(subject, type, task) {
    return Supabase.instance.client.from('tasks').insert({
      'subject': subject,
      'type': type,
      'task': task,
    });
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

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Api.getData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error} occured'));
          } else if (snapshot.hasData) {
            final data = snapshot.data;
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text('Schedule'),
              ),
              body: ListTileTheme(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) =>
                      ListTile(title: Text(data[index]['subject'])),
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
  String timeStart = "";
  String timeFinish = "";

  void _submit() {
    Api.createData(subject, type, task);
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
                onFieldSubmitted: (value) {
                  setState(() {
                    subject = value;
                  });
                },
              ),
              //Type
              TextFormField(
                decoration: InputDecoration(labelText: 'Type'),
                keyboardType: TextInputType.text,
                onFieldSubmitted: (value) {
                  setState(() {
                    type = value;
                  });
                },
              ),
              //Task
              TextFormField(
                decoration: InputDecoration(labelText: 'Task'),
                keyboardType: TextInputType.text,
                onFieldSubmitted: (value) {
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
