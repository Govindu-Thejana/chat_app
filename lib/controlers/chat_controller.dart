import 'package:chat_app/models/massage_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/providers/chat_provider.dart';
import 'package:chat_app/providers/user_provider.dart';
import 'package:chat_app/screens/ChatPages/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatController {
  final BuildContext context;
  ChatProvider chatProvider = ChatProvider();
  User? currentuser = FirebaseAuth.instance.currentUser;
  ChatController(this.context);

  // Generate a unique chat ID based on user IDs
  String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort(); // Sort IDs to ensure consistency
    return '${ids[0]}_${ids[1]}';
  }

  // Start a chat by either fetching or creating a new chat
  Future<void> startChat(UserModel chatter) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final currentUserId = userProvider.user?.uid;
    if (currentUserId == null) {
      throw Exception('Current user ID is not available.');
    }

    final chatId = generateChatId(currentUserId, chatter.uid);

    // Fetch or create a new chat
    try {
      await chatProvider.fetchChat(chatId);
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatteruid: chatter.uid,
            chatId: chatId,
            chatterName:
                chatter.username, // Update this with the actual recipient name
            chatterImageUrl: chatter
                .profilePictureURL, // Update this with the actual recipient image URL
            isOnline:
                chatter.isOnline, // Update this with the actual online status
            lastSeen: chatter.lastLogin
                .toString(), // Update this with the actual last seen info
          ),
        ),
      );
    } catch (e) {
      Logger().i('Error starting chat: $e');
    }
  }

  Future<MessageModel?> sendMessage(String chatId, String senderId, String text,
      bool isimage, String imageurl) async {
    if (text.isEmpty) return null; // Early return if the message text is empty

    final messageId = const Uuid().v4(); // Generate a unique ID for the message
    //Get the current time in UTC and convert it to Sri Lanka time (UTC+5:30)
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    Logger().f(currentTimeZone);
    DateTime now = DateTime.now();

// Use Firestore's Timestamp for consistency
    final Timestamp firestoreTimestamp = Timestamp.fromDate(now);
    MessageModel message;
    if (isimage) {
      message = MessageModel(
        messageId: messageId,
        senderId: currentuser!.uid,
        text: imageurl,
        mediaURL: imageurl,
        timestamp:
            firestoreTimestamp, // Use Firestore's Timestamp for consistency
        status: 'sent',
        deleteForEveryone: false,
        edited: false,
      );
    } else {
      message = MessageModel(
        messageId: messageId,
        senderId: currentuser!.uid,
        text: text,
        timestamp:
            firestoreTimestamp, // Use Firestore's Timestamp for consistency
        status: 'sent',
        deleteForEveryone: false,
        edited: false,
      );
    }
    try {
      // Add the message to the Firestore collection
      chatProvider.addMessage(chatId, message, senderId, isimage);

      Logger().i('Message sent');

      return message; // Return the message object
    } catch (e) {
      Logger().e('Error sending message: $e');
      return null; // Return null in case of an error
    }
  }
}
