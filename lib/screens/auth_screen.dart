import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_rtc/services/config_service.dart';

class AuthScreen extends StatefulWidget {

  AuthScreen();

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  String username = '';
  String password = '';
  String confirmPassword = '';
  String error = '';
  final config = ConfigService().config;

  Future<void> handleSubmit() async {
    final endpoint = isRegister ? '${config.apiBaseUrl}/register' : '${config.apiBaseUrl}/login';
    final body = jsonEncode({'username': username, 'password': password});
    try {
      final response = await http.post(Uri.parse(endpoint), body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        // Сохраняем токен и переходим на страницу друзей
        Navigator.pushReplacementNamed(context, '/friends', arguments: {
          'myId': username,
          'token': token,
        });
      } else {
        setState(() {
          error = jsonDecode(response.body)['message'] ?? 'Ошибка';
        });
      }
    } catch (err) {
      setState(() {
        error = 'Не удалось подключиться к серверу';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegister ? 'Регистрация' : 'Авторизация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Имя пользователя'),
              onChanged: (value) => setState(() => username = value),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
              onChanged: (value) => setState(() => password = value),
            ),
            if (isRegister)
              TextField(
                decoration: const InputDecoration(labelText: 'Подтвердите пароль'),
                obscureText: true,
                onChanged: (value) => setState(() => confirmPassword = value),
              ),
            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: handleSubmit,
              child: Text(isRegister ? 'Зарегистрироваться' : 'Войти'),
            ),
            TextButton(
              onPressed: () => setState(() => isRegister = !isRegister),
              child: Text(isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
