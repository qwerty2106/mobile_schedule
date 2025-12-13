import 'package:supabase_flutter/supabase_flutter.dart';

class Api {
  //Выборка всех записей
  Future<dynamic> getData() {
    return Supabase.instance.client.from('lessons').select();
  }

  //Регистрация
  Future<dynamic> signUp(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      print('Пользователь успешно зарегистрирован!');
    } catch (e) {
      print('Ошибка регистрации! $e');
    }
  }

  //Аутентификация
  Future<dynamic> signIn(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Успешный вход!');
    } catch (e) {
      print('Ошибка входа! $e');
    }
  }

  //Создание записи
  Future<dynamic> createData(subject, type, task, startTime, finishTime) {
    return Supabase.instance.client.from('lessons').insert({
      'subject': subject,
      'type': type,
      'task': task,
      'start_time': startTime.toIso8601String(),
      'finish_time': finishTime.toIso8601String(),
    });
  }

  //Удаление записи
  Future<dynamic> deleteData(id) {
    return Supabase.instance.client.from('lessons').delete().eq('id', id);
  }

  //Обновление зависи
  Future<dynamic> updateData(int id, String subject, String type, String task, DateTime startTime, DateTime finishTime) {
    return Supabase.instance.client.from('lessons').update({
      'subject': subject,
      'type': type,
      'task': task,
      'start_time': startTime.toIso8601String(),
      'finish_time': finishTime.toIso8601String(),
    }).eq('id', id);
  }
}
