import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SermonsPage extends StatefulWidget {
  // Remove const because we have mutable fields
  SermonsPage({super.key});

  @override
  State<SermonsPage> createState() => _SermonsPageState();
}

class _SermonsPageState extends State<SermonsPage> {
  // Dummy YouTube video IDs
  final List<String> _videoIds = [
    'VZEOIIxfuZc',
    'dQw4w9WgXcQ',
    '9bZkp7q19f0',
    '3JZ_D3ELwOQ',
    'L_jWHffIx5E',
    'e-ORhEE9VVg',
    'kJQP7kiw5Fk',
    'RgKAFK5djSk',
    'fJ9rUzIMcZQ',
    'hT_nvWreIhg',
  ];

  // Map to store initialized controllers for visible items
  final Map<int, YoutubePlayerController> _controllers = {};

  @override
  void dispose() {
    // Dispose all controllers when widget is disposed
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Initialize controller only when needed (lazy loading)
  YoutubePlayerController _getController(int index) {
    if (_controllers.containsKey(index)) {
      return _controllers[index]!;
    } else {
      final controller = YoutubePlayerController(
        initialVideoId: _videoIds[index],
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
      _controllers[index] = controller;
      return controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sermons',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _videoIds.length,
        itemBuilder: (context, index) {
          final controller = _getController(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  YoutubePlayer(
                    controller: controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sermon ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
