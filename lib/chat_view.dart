import 'dart:io';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

abstract class IChatViewModel extends ChangeNotifier {
  List<types.Message> get messages;
  types.User get user;
  List<String> get responses;
  bool get isResponseButtonVisible;
  bool get isResponseCarousselVisible;
  void initConversation();
  void onSendButtonTouched(types.PartialText message);
  Future<void> pickVideo();
}

class ChatView extends StatefulWidget {
  final IChatViewModel viewmodel;
  const ChatView({super.key, required this.viewmodel});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    widget.viewmodel.initConversation();
  }

  @override
  Widget build(BuildContext context) {
    final viewmodel = widget.viewmodel;
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant Personnel')),
      body: AnimatedBuilder(
        animation: widget.viewmodel,
        builder: (context, child) {
          return SafeArea(
            child: Chat(
              messages: viewmodel.messages,
              onSendPressed: viewmodel.onSendButtonTouched,
              user: viewmodel.user,
              bubbleBuilder: (
                child, {
                required message,
                required nextMessageInGroup,
              }) {
                final isCurrentUser = message.author.id == viewmodel.user.id;
                return CustomBubbleWidget(
                  message: message,
                  nextMessageInGroup: nextMessageInGroup,
                  isCurrentUser: isCurrentUser,
                );
              },
              customMessageBuilder: (message, {required messageWidth}) {
                return CustomMessageWidget(
                  message: message,
                  messageWidth: messageWidth,
                );
              },
              customBottomWidget:
                  viewmodel.isResponseButtonVisible
                      ? ResponseButtonWidget(
                        responses: viewmodel.responses,
                        viewmodel: viewmodel,
                      )
                      : viewmodel.isResponseCarousselVisible
                      ? CarousselWidget(
                        responses: viewmodel.responses,
                        viewmodel: viewmodel,
                      )
                      : CustomBottomWidget(viewmodel: viewmodel),
              showUserAvatars: true,
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);

    if (video != null) {
      final videoMessage = types.FileMessage(
        author: widget.viewmodel.user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        name: 'Video',
        size: await video.length(),
        uri: video.path,
        mimeType: 'video/mp4',
      );

      setState(() {
        widget.viewmodel.messages.insert(0, videoMessage);
      });
    }
  }
}

class CustomBubbleWidget extends StatelessWidget {
  final types.Message message;
  final bool nextMessageInGroup;
  final bool isCurrentUser;

  const CustomBubbleWidget({
    super.key,
    required this.message,
    required this.nextMessageInGroup,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser ? Colors.purple[100] : Colors.blue[200];

    final nip = isCurrentUser ? BubbleNip.rightBottom : BubbleNip.leftBottom;

    return Bubble(
      elevation: 1,
      padding: BubbleEdges.all(10),
      color: bubbleColor,
      nip: nextMessageInGroup ? BubbleNip.no : nip,
      margin:
          nextMessageInGroup
              ? const BubbleEdges.symmetric(horizontal: 6)
              : null,
      child: Builder(
        builder: (context) {
          return Text(
            (message as types.TextMessage).text,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          );
        },
      ),
    );
  }
}

class CustomMessageWidget extends StatelessWidget {
  final types.Message message;
  final int messageWidth;

  const CustomMessageWidget({
    super.key,
    required this.message,
    required this.messageWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (message is types.FileMessage &&
        (message as types.FileMessage).mimeType == 'video/mp4') {
      return VideoMessageWidget(filePath: (message as types.FileMessage).uri);
    }
    return const SizedBox.shrink();
  }
}

class VideoMessageWidget extends StatefulWidget {
  final String filePath;

  const VideoMessageWidget({super.key, required this.filePath});

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 48,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ],
          ),
        )
        : const CircularProgressIndicator();
  }
}

class ResponseButtonWidget extends StatelessWidget {
  final List<String> responses;
  final IChatViewModel viewmodel;
  const ResponseButtonWidget({
    super.key,
    required this.responses,
    required this.viewmodel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            responses.map((response) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    viewmodel.onSendButtonTouched(
                      types.PartialText(text: response),
                    );
                  },
                  child: Text(response),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class CarousselWidget extends StatelessWidget {
  final List<String> responses;
  final IChatViewModel viewmodel;
  const CarousselWidget({
    super.key,
    required this.responses,
    required this.viewmodel,
  });

  @override
  Widget build(BuildContext context) {
    CarouselController? controller;
    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.8),
        itemCount: responses.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              print("Tapped on: ${responses[index]}");
              viewmodel.onSendButtonTouched(
                types.PartialText(text: responses[index]),
              );
            },
            child: Card(
              elevation: 4,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: TonalityWidget(
                response: responses[index],
                viewmodel: viewmodel,
              ),
            ),
          );
        },
      ),
      // CarouselView(
      //   itemExtent: MediaQuery.sizeOf(context).width - 100,
      //   shrinkExtent: 200,
      //   padding: const EdgeInsets.all(8),
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      //   itemSnapping: true,
      //   elevation: 4,
      //   backgroundColor: Colors.white,
      //   controller: controller,
      //   children: List.generate(responses.length, (int index) {
      //     return TonalityWidget(
      //       response: responses[index],
      //       viewmodel: viewmodel,
      //     );
      //   }),
      // ),
    );
  }
}

class TonalityWidget extends StatelessWidget {
  final IChatViewModel viewmodel;
  final String response;
  const TonalityWidget({
    super.key,
    required this.response,
    required this.viewmodel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 8.0,
          bottom: 100,
          // Positionné en bas du parent
          left: 8.0, // Aligné à gauche
          right: 8.0, // Aligné à droite pour prendre toute la largeur
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12.0), // Coins arrondis
            ),
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Icon(Icons.chat_bubble, color: Colors.white, size: 80),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 108.0,
          // Positionné en bas du parent
          left: 16.0, // Aligné à gauche
          right: 16.0, // Aligné à droite pour prendre toute la largeur
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0), // Coins arrondis
            ),
            height: 70,
            width: MediaQuery.of(context).size.width,
            child: Text(
              "Je suis à votre disposition pour vous fournir des informations.",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ),
        Positioned(
          bottom: 60.0,
          // Positionné en bas du parent
          left: 16.0, // Aligné à gauche
          right: 16.0, // Aligné à droite pour prendre toute la largeur
          child: Text(
            response,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: 20.0,
          // Positionné en bas du parent
          left: 16.0, // Aligné à gauche
          right: 16.0, // Aligné à droite pour prendre toute la largeur
          child: SizedBox(
            height: 40,
            child: Text(
              "Une assistante personnelle formelle et professionnelle.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomBottomWidget extends StatefulWidget {
  final IChatViewModel viewmodel;

  const CustomBottomWidget({super.key, required this.viewmodel});

  @override
  State<CustomBottomWidget> createState() => _CustomBottomWidgetState();
}

class _CustomBottomWidgetState extends State<CustomBottomWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _showCameraIcon = true;

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      setState(() {
        _showCameraIcon = _textController.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          if (_showCameraIcon)
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.blue),
              onPressed: () {},
            ),

          if (!_showCameraIcon)
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  widget.viewmodel.onSendButtonTouched(
                    types.PartialText(text: text),
                  );
                  _textController.clear();
                }
              },
            ),
        ],
      ),
    );
  }
}
