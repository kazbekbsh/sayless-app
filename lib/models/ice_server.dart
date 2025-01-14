class ICEServer {
  final String urls;
  final String? username;
  final String? credential;

  const ICEServer({
    required this.urls,
    required this.username,
    required this.credential,
  });

  // Метод для десериализации из JSON
  factory ICEServer.fromJson(Map<String, dynamic> json) {
    return ICEServer(
      urls: json['urls'] as String,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }
}