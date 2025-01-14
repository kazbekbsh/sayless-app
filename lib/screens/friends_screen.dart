import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FriendsScreen extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String myId;
  FriendsScreen(this.baseUrl, this.myId, this.token);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List friends = [];
  String newFriend = '';
  String error = '';

  Future<void> fetchFriends() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          friends = jsonDecode(response.body)['users'];
        });
      }
    } catch (err) {
      setState(() {
        error = 'Ошибка загрузки списка друзей';
      });
    }
  }

  Future<void> addFriend() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/friends'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
        body: jsonEncode({'nickname': newFriend}),
      );
      if (response.statusCode == 200) {
        fetchFriends(); // Обновляем список
      }
    } catch (err) {
      setState(() {
        error = 'Ошибка добавления друга';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои друзья')),
      body: Column(
        children: [
          if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(friends[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.video_call),
                  onPressed: () {
                    Navigator.pushNamed(context, '/call', arguments: {
                      'myId': widget.myId,
                      'friendId': friends[i],
                    });
                  },
                ),
              ),
            ),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Я: ${widget.myId} Добавить друга'),
            onChanged: (value) => setState(() => newFriend = value),
          ),
          ElevatedButton(onPressed: addFriend, child: Text('Добавить')),
        ],
      ),
    );
  }
}
