import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_rtc/services/config_service.dart';

class WebRTCVideoChat extends StatefulWidget {
  final String friendId;
  final String myId;

  WebRTCVideoChat(this.myId, this.friendId);

  @override
  _WebRTCVideoChatState createState() => _WebRTCVideoChatState();
}

class _WebRTCVideoChatState extends State<WebRTCVideoChat> {

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  final config = ConfigService().config;

  WebSocketChannel? _signalingSocket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    _startCall();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signalingSocket?.sink.close();
    super.dispose();
  }

  void _connectToSignalingServer() {

    final clientId = widget.myId;

    final url = '${config.websocketUrl}?id=$clientId';
    _signalingSocket = WebSocketChannel.connect(Uri.parse(url));

    _signalingSocket?.stream.listen((data) async {
      final message = json.decode(data);
      if (message['type'] == 'offer') {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(message['sdp'], 'offer'),
        );
        final answer = await _peerConnection?.createAnswer();
        await _peerConnection?.setLocalDescription(answer!);
        _sendMessage({
          'type': 'answer',
          'target': message['sender'],
          'sdp': answer!.sdp,
        });
      } else if (message['type'] == 'answer') {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(message['sdp'], 'answer'),
        );
      } else if (message['type'] == 'candidate') {
        final candidate = RTCIceCandidate(
          message['candidate'],
          message['sdpMid'],
          message['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    });
  }

  Future<void> _startLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      _showError("Error accessing camera/microphone: $e");
      print("Error accessing camera/microphone: $e");
    }
  }


  void _setupPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': config.iceServers,
    });

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (event) {
      if (_remoteRenderer.srcObject == null) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _peerConnection?.onIceCandidate = (candidate) {
      final targetId = widget.friendId;
      if (targetId.isNotEmpty && candidate != null) {
        _sendMessage({
          'type': 'candidate',
          'target': targetId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };
  }

  void _startCall() async {
    // Проверяем подключение к сигнальному серверу
    if (_signalingSocket == null || _signalingSocket?.closeCode != null) {
      _connectToSignalingServer();
    }

    await _startLocalStream();
    _setupPeerConnection();

    final offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);

    final targetId = widget.friendId;
    if (targetId.isNotEmpty) {
      _sendMessage({
        'type': 'offer',
        'target': targetId,
        'sdp': offer?.sdp,
      });
    }
  }

  void _endCall() {
    _peerConnection?.close();
    _peerConnection = null;

    setState(() {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    });
    Navigator.pop(context);
  }

  void _sendMessage(Map<String, dynamic> message) {
    _signalingSocket?.sink.add(json.encode(message));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _swapVideos() {
    setState(() {
      _isLocalVideoMain = !_isLocalVideoMain; // Меняем состояние
    });
  }

  // Позиция удалённого видео
  double _remoteVideoTop = 20.0;
  double _remoteVideoLeft = 20.0;

  // Управление отображением потоков
  bool _isLocalVideoMain = true; // Если `true`, локальный поток главный

  double _calculateAspectRatio(RTCVideoRenderer renderer) {
    final videoWidth = renderer.videoWidth;
    final videoHeight = renderer.videoHeight;

    if (videoWidth > 0 && videoHeight > 0) {
      return videoWidth / videoHeight;
    }
    return 4 / 3; // Соотношение сторон по умолчанию
  }

  @override
  Widget build(BuildContext context) {
    // Рассчитываем размеры экрана
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Выбираем текущий поток для плавающего видео
    final floatingRenderer = _isLocalVideoMain ? _remoteRenderer : _localRenderer;
    final aspectRatio = _calculateAspectRatio(floatingRenderer);

    // Рассчитываем размеры контейнера для плавающего видео
    final floatingVideoWidth = screenWidth * 0.4; // 40% от ширины экрана
    final floatingVideoHeight = floatingVideoWidth / aspectRatio;

    return Scaffold(
      appBar: AppBar(title: Text(widget.friendId)),
      body: Stack(
        children: [
          // Локальное видео на заднем плане
          RTCVideoView(
            _isLocalVideoMain ? _localRenderer : _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),

          // Плавающее удалённое видео
          Positioned(
            top: _remoteVideoTop,
            left: _remoteVideoLeft,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _remoteVideoTop = (_remoteVideoTop + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 200);
                  _remoteVideoLeft = (_remoteVideoLeft + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 150);
                });
              },
              onTap: _swapVideos, // Меняем видео по нажатию
              child: Container(
                width: floatingVideoWidth,
                height: floatingVideoHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: RTCVideoView(
                  _isLocalVideoMain ? _remoteRenderer : _localRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ),
          ),
          // Кнопка завершения звонка
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Отступ снизу
              child: FloatingActionButton(
                onPressed: _endCall,
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}