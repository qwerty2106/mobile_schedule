import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class Api {
  //Выборка всех записей
  Future<dynamic> getData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return <dynamic>[];
    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final result = await Supabase.instance.client
        .from('lessons')
        .select()
        .eq('user_id', user.id)
        .gte('start_time', startOfDay.toIso8601String()) // начиная с сегодняшнего дня
        .order('start_time');
    return result;
  }

  //Прошедшие занятия
  Future<dynamic> getPastData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return <dynamic>[];
    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final result = await Supabase.instance.client
        .from('lessons')
        .select()
        .eq('user_id', user.id)
        .lt('start_time', startOfDay.toIso8601String())
        .order('start_time', ascending: false);
    return result;
  }

  // Отправить повторно подтверждение (magic link)
  /// Попытка отправить magic link для входа на почту. Это эффективная альтернатива повторной отправке подтверждения.
  /// Возвращает `null` при успехе или строку с ошибкой.
  Future<String?> resendConfirmation(String email) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      return null;
    } catch (e) {
      debugPrint('Ошибка отправки подтверждения: $e');
      return e.toString();
    }
  }

  //Регистрация
  /// Returns `null` on success, or an error message string on failure.
  /// Returns a map: { 'error': String? , 'needsConfirmation': bool }
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      // If the user is not logged in immediately, it usually means email confirmation is required
      final user = Supabase.instance.client.auth.currentUser;
      return {'error': null, 'needsConfirmation': user == null};
    } catch (e) {
      debugPrint('Ошибка регистрации! $e');
      return {'error': e.toString(), 'needsConfirmation': false};
    }
  }

  //Аутентификация
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> signIn(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      debugPrint('Ошибка входа! $e');
      return e.toString();
    }
  }

  //Создание записи
  Future<dynamic> createData(subject, type, task, startTime, finishTime) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return Supabase.instance.client.from('lessons').insert({
      'subject': subject,
      'type': type,
      'task': task,
      'start_time': startTime.toIso8601String(),
      'finish_time': finishTime.toIso8601String(),
      'user_id': user.id,
    });
  }

  //Удаление записи
  Future<dynamic> deleteData(id) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return Supabase.instance.client
        .from('lessons')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  //Обновление зависи
  Future<dynamic> updateData(
    int id,
    String subject,
    String type,
    String task,
    DateTime startTime,
    DateTime finishTime,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return Supabase.instance.client
        .from('lessons')
        .update({
          'subject': subject,
          'type': type,
          'task': task,
          'start_time': startTime.toIso8601String(),
          'finish_time': finishTime.toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
