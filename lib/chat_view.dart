import 'dart:io';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
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
    if (message is! types.TextMessage) {
      return CustomMessageWidget(message: message, messageWidth: 200);
    }
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
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final file = File(widget.filePath);
      final fileExists = await file.exists();

      if (!fileExists) {
        setState(() => _hasError = true);
        return;
      }

      _controller = VideoPlayerController.file(file);

      await _controller.initialize();
      _controller.addListener(() {
        if (mounted) setState(() {});
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text("Impossible de charger la vidéo"),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: 250,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey.shade300,
              ),
              padding: const EdgeInsets.all(0),
            ),
          ),
        ],
      ),
    );
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

class CarousselWidget extends StatefulWidget {
  final List<String> responses;
  final IChatViewModel viewmodel;
  const CarousselWidget({
    super.key,
    required this.responses,
    required this.viewmodel,
  });

  @override
  State<CarousselWidget> createState() => _CarousselWidgetState();
}

class _CarousselWidgetState extends State<CarousselWidget> {
  final _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.responses.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.viewmodel.onSendButtonTouched(
                      types.PartialText(text: widget.responses[index]),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TonalityWidget(
                      response: widget.responses[index],
                      viewmodel: widget.viewmodel,
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.responses.length,
              (i) => Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentPage ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
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
          left: 8.0,
          right: 8.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12.0),
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
          left: 16.0,
          right: 16.0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
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
          left: 16.0,
          right: 16.0,
          child: Text(
            response,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: 20.0,
          left: 16.0,
          right: 16.0,
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
              onPressed: () {
                widget.viewmodel.pickVideo();
              },
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
