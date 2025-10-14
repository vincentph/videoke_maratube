import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  runApp(VideokeMaraTube());
}

class VideokeMaraTube extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Videoke MaraTube',
      theme: ThemeData.dark(),
      home: VideoScreen(),
    );
  }
}

class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with AutomaticKeepAliveClientMixin {

  final _controller = YoutubePlayerController(
    params: YoutubePlayerParams(
      mute: false,
      showControls: true,
      showFullscreenButton: true,
    ),
  );

  // Sample video list (replace with your own video IDs)
  final List<Map<String, String>> videos = [
    {'id': 'dQw4w9WgXcQ', 'title': 'Never Gonna Give You Up'},
    {'id': '9bZkp7q19f0', 'title': 'Gangnam Style'},
    {'id': '3JZ_D3ELwOQ', 'title': 'See You Again'},
    {'id': 'L_jWHffIx5E', 'title': 'Smells Like Teen Spirit'},
    {'id': 'oHg5SJYRHA0', 'title': 'Surprise Video'},
  ];

  @override
  void initState() {
    super.initState();

    _controller.loadVideoById(videoId: videos[0]['id']!);

  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // <-- keeps the player alive across rotations

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for keep-alive
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (isPortrait) {
            final videoHeight = size.width * 9 / 16;

            return Stack(
              children: [
                // Video player
                // Video player fixed at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: videoHeight,
                  child: YoutubePlayer(controller: _controller),
                ), // end of Positioned (video)

                // Scrollable list below video
                Positioned(
                  top: videoHeight,
                  left: 0,
                  right: 0,
                  bottom: 60, // leave space for icons
                  child: ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return ListTile(
                        leading: const Icon(Icons.play_circle_outline,
                            color: Colors.white),
                        title: Text(video['title']!,
                            style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          _controller.loadVideoById(videoId: video['id']!);
                        },
                      );
                    },
                  ),
                ), // end of Positioned (list)

                // Bottom icon bar aligned at bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.grey[900],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.home, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ), // end of Align (bottom icons)
           
              ],
            );
          } else {
            // Landscape: Fullscreen
            //_controller.enterFullScreen();
            return YoutubePlayer(controller: _controller);
          }
        },
      ),
    );
  }
}
