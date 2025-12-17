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
  bool _loading = false;
  String? _authError;


  void _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _authError = null;
    });
    final error = await api.signIn(email.trim(), password);
    setState(() {
      _loading = false;
    });
    if (error == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } else {
      final lower = error.toLowerCase();
      final friendly = (lower.contains('invalid') || lower.contains('credentials') || lower.contains('wrong'))
          ? 'Неправильный логин или пароль'
          : 'Ошибка входа: $error';
      if (mounted) {
        setState(() => _authError = friendly);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      }
    }
  }

  void _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _authError = null;
    });
    final error = await api.signUp(email.trim(), password);
    setState(() {
      _loading = false;
    });
    if (error == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } else {
      final lower = error.toLowerCase();
      final friendly = (lower.contains('duplicate') || lower.contains('exists'))
          ? 'Пользователь с таким email уже существует'
          : 'Ошибка регистрации: $error';
      if (mounted) {
        setState(() => _authError = friendly);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      }
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
        title: const Text('Вход'),
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
        items: const [
          BottomNavigationBarItem(label: 'Домой', icon: Icon(Icons.home)),
          BottomNavigationBarItem(label: 'Вход', icon: Icon(Icons.login)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight - 48,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) => email = v,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Введите логин';
                            if (!v.contains('@')) return 'Введите корректный email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            hintText: '•••••••',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          obscureText: true,
                          onChanged: (v) => password = v,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Введите пароль';
                            if (v.length < 6) return 'Пароль должен быть не меньше 6 символов';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_authError != null) ...[
                          Text(_authError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Войти'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading ? null : _signUp,
                          child: const Text('Зарегистрироваться'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
