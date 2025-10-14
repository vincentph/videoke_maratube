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
  final List<String> videos = [
    'dQw4w9WgXcQ',
    '9bZkp7q19f0',
    '3JZ_D3ELwOQ',
    'L_jWHffIx5E',
    'oHg5SJYRHA0',
  ];

  @override
  void initState() {
    super.initState();

    _controller.loadVideoById(videoId: videos[0]);

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
                
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: size.width,
                    height: videoHeight,
                    child: YoutubePlayer(controller: _controller),
                  ),
                ), // end of Align (video player)

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
