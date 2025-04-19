import 'package:chat_project/chat_view.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatViewmodel extends IChatViewModel {
  final List<types.Message> _messages = [];
  final types.User _user = types.User(id: 'user1');
  final types.User _userAI = types.User(
    id: 'userAI',
    imageUrl:
        'https://www.akhilleus-technology.com/wp-content/uploads/2024/04/bouclier-4.png',
  );
  List<String> _responses = ["Personnaliser", "Garder l'assistant par défaut"];
  bool _isResponseButtonVisible = true;
  bool _isResponseCarousselVisible = false;

  @override
  void initConversation() {
    final textMessage = types.TextMessage(
      author: _userAI,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: "Bonjour Benny, Bravo ! Votre compte à bien été créé.",
    );

    _messages.insert(0, textMessage);

    final textMessage2 = types.TextMessage(
      author: _userAI,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          "Je serai votre assistant personnel. Mon rôle est de vous aider à collecter et organiser vos souvenirs comme jamais auparavant.",
    );

    _messages.insert(0, textMessage2);

    final textMessage3 = types.TextMessage(
      author: _userAI,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          "Vous pouvez choisir ma personnalité ce qui me permettra de vous aider au mieux tout en rendant votre expérience authentique et agréable.",
    );

    _messages.insert(0, textMessage3);

    final textMessage4 = types.TextMessage(
      author: _userAI,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: "Que voulez-vous faire ?",
    );

    _messages.insert(0, textMessage4);

    notifyListeners();
  }

  @override
  List<types.Message> get messages => _messages;

  @override
  types.User get user => _user;

  @override
  bool get isResponseButtonVisible => _isResponseButtonVisible;

  @override
  bool get isResponseCarousselVisible => _isResponseCarousselVisible;

  @override
  List<String> get responses => _responses;

  @override
  void onSendButtonTouched(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _messages.insert(0, textMessage);
    notifyListeners();
    continueChat();
  }

  void continueChat() async {
    final lastMessage = _messages.first;

    if (lastMessage is types.TextMessage &&
        lastMessage.text == "Personnaliser") {
      await Future.delayed(const Duration(seconds: 1));
      final textMessage = types.TextMessage(
        author: _userAI,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: "D'abord, choississez votre genre : ",
      );

      _messages.insert(0, textMessage);
      _responses = ["Féminin", "Masculin", "Neutre"];
    } else if (lastMessage is types.TextMessage &&
        (lastMessage.text == "Féminin" ||
            lastMessage.text == "Masculin" ||
            lastMessage.text == "Neutre")) {
      await Future.delayed(const Duration(seconds: 1));
      final textMessage = types.TextMessage(
        author: _userAI,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: "Maintenant, quelle tonalité souhaitez-vous pour nos échanges ?",
      );

      _messages.insert(0, textMessage);
      _responses = ["Formelle", "Chaleureux", "Amusant"];
      _isResponseButtonVisible = false;
      _isResponseCarousselVisible = true;
    } else {
      _isResponseButtonVisible = false;
      _isResponseCarousselVisible = false;
    }
    notifyListeners();
  }

  @override
  Future<void> pickVideo() {
    throw UnimplementedError();
  }
}
