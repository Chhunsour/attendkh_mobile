import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            SizedBox(width: 8),
            Text('HR AI Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _ChatBubble(
                  isUser: false,
                  message: 'Hello! 👋 I\'m your HR assistant. How can I help you today? You can ask me about:\n\n• Leave balances\n• Company policies\n• Attendance records\n• Payslip details\n• And more!',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      filled: true,
                      fillColor: AppColors.grey100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isUser;
  final String message;

  const _ChatBubble({required this.isUser, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.grey100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.grey800,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}