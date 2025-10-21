import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'params.dart';

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
  List<Map<String, String>> videos = [];
  List<Map<String, String>> searchResults = [];
  bool isLoading = true;
  bool showList = true;
  bool showSearchResults = false;

  String? currentVideoId; // track the current playing video

  @override
  void initState() {
    super.initState();
    // fetchVideos();

    //  Listen for video end event
    _controller.listen((event) {
     if (event.playerState == PlayerState.ended) {
        // remove video when it ends
        removeCurrentVideo();
      }
    });    

  }

  Future<void> fetchVideos() async {
    final apiKey = youtubeApiKey;
    const searchQuery = 'videoke karaoke songs';
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=20&q=$searchQuery&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    setState(() {
      videos = (data['items'] as List)
          .map((item) => {
                'id': item['id']['videoId'].toString(),
                'title': item['snippet']['title'].toString(),
                'thumbnail': item['snippet']['thumbnails']['medium']['url']
                    .toString(),
              })
          .toList()
          .cast<Map<String, String>>();
      isLoading = false;
    });

    if (videos.isNotEmpty) {
      playVideo(videos[0]['id']!);
    }
  }

  void playVideo(String videoId) {
    setState(() {
      currentVideoId = videoId;
    });
    _controller.loadVideoById(videoId: videoId);
  }

  void removeCurrentVideo() {
    if (currentVideoId != null) {
      setState(() {
        videos.removeWhere((v) => v['id'] == currentVideoId);
        currentVideoId = null;

        // auto play next if available
        if (videos.isNotEmpty) {
          playVideo(videos[0]['id']!);
        }
      });
    }
  }

  Future<void> _showSearchDialog() async {
    TextEditingController searchController = TextEditingController();

    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Search Videos", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter video title...",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, searchController.text.trim()),
            child: const Text("Search", style: TextStyle(color: Colors.lightBlue)),
          ),
        ],
      ),
    );

    if (query != null && query.isNotEmpty) {
      await fetchSearchResults(query);
      setState(() {
        showSearchResults = true;
      });
    }
  }

  Future<void> fetchSearchResults(String query) async {
    final apiKey = youtubeApiKey;
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=10&q=$query&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    setState(() {
      searchResults = (data['items'] as List)
          .map((item) => {
                'id': item['id']['videoId'].toString(),
                'title': item['snippet']['title'].toString(),
                'thumbnail': item['snippet']['thumbnails']['medium']['url']
                    .toString(),
              })
          .toList()
          .cast<Map<String, String>>();
    });
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

                // Show main list or search results
                if (showList || showSearchResults)
                  Positioned(
                    top: videoHeight,
                    left: 0,
                    right: 0,
                    bottom: 60, // leave space for icons
                    child: ListView.builder(
                      itemCount: showSearchResults
                          ? searchResults.length
                          : videos.length,
                      itemBuilder: (context, index) {
                        final video = showSearchResults
                            ? searchResults[index]
                            : videos[index];
                        return ListTile(
                          leading: Image.network(
                            video['thumbnail']!,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            video['title']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            //print("Vidoes lenght: $videos.length");

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("curr v: $currentVideoId, vid len: $videos.length"),
                                duration: const Duration(seconds: 5),
                              ),
                            );                            


                            //if (currentVideoId != null) {
                            //  print("Removing current video: $currentVideoId"); // print first
                            //  //videos.removeWhere((v) => v['id'] == currentVideoId);
                            //} else {
                            //  playVideo(video["id"]!);
                            //}                         
                            setState(() {
                              
                              // Add search result to the end of main list
                              if (showSearchResults) {
                                if(currentVideoId  != null) {
                                  videos.add(video); // append at the end
                                } else {
                                  playVideo(video["id"]!);                                   
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Video Added"),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );                                  
                                showSearchResults = false; // hide search results
                                showList = true; // show main list
                                //if(_isVidoesEmpty) {
                                //  playVideo(video["id"]!);
                                //  _isVidoesEmpty = false;
                                //}
                              } else {
                                videos.removeAt(index);
                                playVideo(video['id']!);
                              }
                            });

                            // Then play the tapped video
                            //playVideo(currentVideoId!);
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
                            onPressed: _showSearchDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.book, color: Colors.white), // 📖 Playlist icon
                            onPressed: () {
                              setState(() {
                                showSearchResults = false; // hide search results
                                showList = true; // show playlist videos
                              });
                            },
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
