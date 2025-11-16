import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  // Dummy live video ID
  final String _liveVideoId =
      'VZEOIIxfuZc'; // Replace with real live video ID later

  late YoutubePlayerController _controller;

  // Dummy upcoming live events
  final List<Map<String, String>> _upcomingLives = [
    {'title': 'Sunday Service', 'date': 'Nov 17, 2025', 'time': '9:00 AM'},
    {
      'title': 'Youth Prayer Meeting',
      'date': 'Nov 18, 2025',
      'time': '6:00 PM',
    },
    {'title': 'Bible Study', 'date': 'Nov 20, 2025', 'time': '5:00 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: _liveVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        isLive: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Live Coverage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            // Live YouTube Video
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upcoming Live Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingLives.length,
              itemBuilder: (context, index) {
                final event = _upcomingLives[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue[50],
                  child: ListTile(
                    leading: const Icon(Icons.live_tv, color: Colors.blue),
                    title: Text(
                      event['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${event['date']} - ${event['time']}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You tapped "${event['title']}"'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
