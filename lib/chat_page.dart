import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'api_config.dart';

class ChatPage extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const ChatPage({
    Key? key,
    required this.pharmacyId,
    required this.pharmacyName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  List<ChatMessage> messages = [];
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = await _apiService.getUser();
      if (user == null) {
        _showError('User not found');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.webBaseUrl.replaceFirst('/api', '')}/public/chat/${widget.pharmacyId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Load messages response status: ${response.statusCode}');
      print('🔍 Load messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = (data['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();
        });
      } else {
        _showError('Failed to load messages: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showError('Error loading messages: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final user = await _apiService.getUser();
      if (user == null) {
        _showError('User not found');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.webBaseUrl.replaceFirst('/api', '')}/public/chat/${widget.pharmacyId}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': messageText,
          'senderId': user['id'],
          'senderName': user['name'] ?? 'Patient',
          'senderType': 'patient',
        }),
      );

      print('🔍 Chat response status: ${response.statusCode}');
      print('🔍 Chat response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add(ChatMessage.fromJson(data['message']));
        });
        _scrollToBottom();
      } else {
        _showError('Failed to send message: ${response.statusCode} - ${response.body}');
        _messageController.text = messageText; // Restore message
      }
    } catch (e) {
      _showError('Error sending message: $e');
      _messageController.text = messageText; // Restore message
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pharmacyName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const Text(
              'Online',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3748),
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7FAFC),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Color(0xFF718096),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF718096),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              'Start a conversation with the pharmacy',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFA0AEC0),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF667eea)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF667eea),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isSending ? null : _sendMessage,
                    icon: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isPatient = message.senderType == 'patient';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isPatient) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.local_hospital, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isPatient ? const Color(0xFF667eea) : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isPatient ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isPatient ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isPatient ? Colors.white : const Color(0xFF2D3748),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isPatient 
                          ? Colors.white.withOpacity(0.7) 
                          : const Color(0xFF718096),
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isPatient) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF48BB78),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class ChatMessage {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final String senderType;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'],
      message: json['message'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderType: json['senderType'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
