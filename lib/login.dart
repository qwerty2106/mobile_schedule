import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => __LoginPageState();
}

class __LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final api = Api();
  String login = "";
  String password = "";
  int _currentIndex = 1;

  void _signIn() async {
    if (login.trim() == "" || password.trim() == "") return;
    await api.signIn(login, password);
    setState(() {});
  }

  void _signUp() async {
    if (login.trim() == "" || password.trim() == "") return;
    await api.signUp(login, password);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Login'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          }
        },
        items: [
          BottomNavigationBarItem(label: 'Домой', icon: Icon(Icons.home)),
          BottomNavigationBarItem(label: 'Вход', icon: Icon(Icons.login)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Введите логин...'),
                    onChanged: (value) {
                      login = value;
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Введите пароль...'),
                    onChanged: (value) {
                      password = value;
                    },
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: _signIn, child: Text('Войти')),
                      TextButton(
                        onPressed: _signUp,
                        child: Text('Зарегистироваться'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
