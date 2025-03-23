import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ikchatbot/ikchatbot.dart';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {

  bool isLoaded = false;
  List<String> keywords = [];
  List<String> responses = [];

  Future<void> loadChatBase() async {
    DocumentSnapshot contactSnap = await FirebaseFirestore.instance.collection('contact').doc('knowledgeBase').get();
    Map<String, dynamic> chatBase = contactSnap.data() as Map<String, dynamic>;
    keywords = chatBase['keywords'].cast<String>();
    responses = chatBase['responses'].cast<String>();

    setState(() {
      isLoaded = true;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadChatBase();
  }


  
  @override
  Widget build(BuildContext context) {

    final chatBotConfig = IkChatBotConfig(
      //SMTP Rating to your mail Settings
      ratingIconYes: const Icon(Icons.star),
      ratingIconNo: const Icon(Icons.star_border),
      ratingIconColor: Colors.black,
      ratingBackgroundColor: Colors.white,
      ratingButtonText: 'Submit Rating',
      thankyouText: 'Thanks for your rating!',
      ratingText: 'Rate your experience:',
      ratingTitle: 'Thank you for using the chatbot!',
      body: 'This is a test email sent from Flutter and Dart.',
      subject: 'Test Rating',
      recipient: 'recipient@example.com',
      isSecure: false,
      senderName: 'Your Name',
      smtpUsername: 'Your Email',
      smtpPassword: 'your password',
      smtpServer: 'stmp.gmail.com',
      smtpPort: 587,
      //Settings to your system Configurations
      sendIcon: const Icon(Icons.send, color: Colors.black),
      userIcon: const Icon(Icons.person_2_outlined, color: Colors.white),
      botIcon: const Icon(Icons.person, color: Colors.white),
      botChatColor: Colors.green[800]!,
      delayBot: 100,
      closingTime: 1,
      delayResponse: 1,
      userChatColor: Colors.green[800]!,
      waitingTime: 1,
      keywords: keywords,
      responses: responses,
      backgroundColor: Colors.white,
      backgroundImage:
      'https://i.pinimg.com/736x/d2/bf/d3/d2bfd3ea45910c01255ae022181148c4.jpg',
      backgroundAssetimage: "lib/assets/bg.jpeg",
      initialGreeting:
      "Hello! \nWelcome to tiffn Support.\nHow can I assist you today?",
      defaultResponse: "Sorry, I didn't understand your response.",
      inactivityMessage: "Is there anything else you need help with?",
      closingMessage: "This conversation will now close.",
      inputHint: 'Send a message',
      waitingText: 'Please wait...',
      useAsset: false,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('tiffn Support'),
      ),
      body: (isLoaded)? ikchatbot(config: chatBotConfig) : Center(child: CircularProgressIndicator(),),
    );
  }
}
