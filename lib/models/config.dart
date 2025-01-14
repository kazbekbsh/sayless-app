import 'ice_server.dart';

class Config {
  final String apiBaseUrl;
  final String websocketUrl;
  final List<Map<String, dynamic>> iceServers;

  const Config({
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.iceServers,
  });

  // Метод для десериализации из JSON
  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      apiBaseUrl: json['apiBaseUrl'] as String,
      websocketUrl: json['websocketUrl'] as String,
      // iceServers: json['iceServers']
      iceServers: (json['iceServers'] as List<dynamic>)
          .map((itemJson) => itemJson as Map<String, dynamic>)
          .toList()
      // iceServers: (json['iceServers'] as List<dynamic>)
      //     .map((itemJson) => ICEServer.fromJson(itemJson as Map<String, dynamic>))
      //     .toList(),
    );
  }
}
