import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web_rtc/models/config.dart';

class ConfigService {
  Config? _config;

  // Singleton для глобального доступа
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // Метод для загрузки конфигурации из файла
  Future<void> loadConfig() async {

    final contents = await rootBundle.loadString('assets/config.json');
    final jsonMap = jsonDecode(contents) as Map<String, dynamic>;
    _config = Config.fromJson(jsonMap);

  }

  // Метод для доступа к конфигурации
  Config get config {
    if (_config == null) {
      throw Exception('Config not loaded. Call loadConfig() first.');
    }
    return _config!;
  }
}
