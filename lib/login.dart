import 'dart:async';

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

  // Resend cooldown timer (seconds left)
  int _resendCooldownSeconds = 0;
  Timer? _resendTimer;
  bool _resendSending = false;


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
          : (lower.contains('confirm') || lower.contains('verify') || lower.contains('email'))
              ? 'Email не подтвержден. Проверьте почту и подтвердите аккаунт.'
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
    final result = await api.signUp(email.trim(), password);
    setState(() {
      _loading = false;
    });
    final error = result['error'] as String?;
    final needsConfirmation = result['needsConfirmation'] as bool? ?? false;

    if (error == null && !needsConfirmation) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } else if (error == null && needsConfirmation) {
      final msg = 'Проверьте почту — мы отправили письмо для подтверждения. После подтверждения нажмите "Проверить".';
      if (mounted) {
        setState(() => _authError = msg);
        showDialog(
            context: context,
            builder: (_) => StatefulBuilder(builder: (context, setLocalState) {
                  var sending = false;
                  return AlertDialog(
                    title: const Text('Подтвердите email'),
                    content: Text(msg),
                    actions: [
                      TextButton(
                        child: const Text('Отправить повторно'),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _handleResendAction();
                        },
                      ),
                      TextButton(
                        child: const Text('Проверить'),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _checkConfirmation();
                        },
                      ),
                      TextButton(child: const Text('ОК'), onPressed: () => Navigator.pop(context)),
                    ],
                  );
                }));
      }
    } else {
      final lower = (error ?? '').toLowerCase();
      if (lower.contains('duplicate') || lower.contains('exists')) {
        final friendly = 'Пользователь с таким email уже существует';
        if (mounted) {
          setState(() => _authError = friendly);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
        }
      } else if (lower.contains('rate') || lower.contains('429') || lower.contains('over_email_send_rate_limit')) {
        // parse seconds from message, if available
        final secs = _parseCooldownSeconds(error ?? '') ?? 90;
        _startResendCooldown(secs);
        final friendly = 'Слишком часто. Повторная отправка через $secs секунд.';
        if (mounted) {
          setState(() => _authError = friendly);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
        }
      } else {
        // Generic message to avoid exposing raw server errors
        final friendly = 'Ошибка регистрации. Попробуйте позже.';
        debugPrint('Registration error (raw): $error');
        if (mounted) {
          setState(() => _authError = friendly);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
        }
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

  Future<void> _checkConfirmation() async {
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
          : (lower.contains('confirm') || lower.contains('verify') || lower.contains('email'))
              ? 'Email всё ещё не подтверждён. Проверьте почту.'
              : 'Ошибка при проверке. Попробуйте снова.';
      debugPrint('Sign-in error on checkConfirmation: $error');
      if (mounted) {
        setState(() => _authError = friendly);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      }
    }
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = seconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldownSeconds <= 1) {
        t.cancel();
        setState(() => _resendCooldownSeconds = 0);
      } else {
        setState(() => _resendCooldownSeconds -= 1);
      }
    });
  }

  String _formatCooldown(int s) {
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  int? _parseCooldownSeconds(String err) {
    try {
      final re = RegExp(r'after\s*(\d+)\s*seconds', caseSensitive: false);
      final m = re.firstMatch(err);
      if (m != null && m.groupCount >= 1) return int.tryParse(m.group(1)!);
      // fallback to any number in the string
      final re2 = RegExp(r'(\d+)');
      final m2 = re2.firstMatch(err);
      if (m2 != null) return int.tryParse(m2.group(1)!);
    } catch (e) {
      debugPrint('parseCooldown error: $e');
    }
    return null;
  }

  Future<void> _handleResendAction() async {
    if (_resendCooldownSeconds > 0 || _resendSending) return;
    setState(() => _resendSending = true);
    final err = await api.resendConfirmation(email.trim());
    setState(() => _resendSending = false);
    if (err == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Письмо повторно отправлено. Проверьте почту.')));
    } else {
      final lower = err.toLowerCase();
      if (lower.contains('rate') || lower.contains('429') || lower.contains('over_email_send_rate_limit')) {
        // parse seconds if provided by server
        final secs = _parseCooldownSeconds(err) ?? 90;
        _startResendCooldown(secs);
        final friendly = 'Слишком часто. Повторная отправка через $secs секунд.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      } else {
        // Generic message
        debugPrint('Resend confirmation error: $err');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось отправить письмо. Попробуйте позже.')));
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
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
                          if (_authError!.toLowerCase().contains('подтверд')) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: (_loading || _resendCooldownSeconds > 0 || _resendSending) ? null : _handleResendAction,
                                child: _resendSending
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : (_resendCooldownSeconds > 0
                                        ? Text('Отправить повторно (${_formatCooldown(_resendCooldownSeconds)})')
                                        : const Text('Отправить письмо повторно')),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
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
