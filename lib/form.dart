import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final api = Api();

  String subject = "";
  String type = "";
  String task = "";
  DateTime startTime = DateTime.now();
  DateTime finishTime = DateTime.now();

  void _submit() async {
    await api.createData(subject, type, task, startTime, finishTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Создание новой записи'),
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
