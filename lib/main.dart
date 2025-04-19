import 'package:chat_project/chat_view.dart';
import 'package:chat_project/chat_viewmodel.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ChatView(viewmodel: ChatViewmodel()));
  }
}
