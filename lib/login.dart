import 'package:flutter/material.dart';
import 'package:mobile_schedule/api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => __LoginPageState();
}

class __LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final api = Api();
  String email = "";
  String password = "";
  int _currentIndex = 1;

  void _signIn() async {
    if (email.trim() == "" || password.trim() == "") return;
    final error = await api.signIn(email, password);
    if (error == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка входа: $error')));
    }
  }

  void _signUp() async {
    if (email.trim() == "" || password.trim() == "") return;
    final error = await api.signUp(email, password);
    if (error == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка регистрации: $error')));
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Вход'),
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
                      email = value;
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
