import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'params.dart';
import 'dart:async';


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
      origin: 'https://www.youtube-nocookie.com',
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

    //  Listen for video end event
    _controller.listen((event) {

      if (event.hasError) {
        // The raw error code
        final errorCode = event.error;

        // Print it directly
        print("YouTube Player Error: $errorCode");

        // Optional: print the player state for debugging
        print("Player state: ${event.playerState}");
        // Remove current video if you want
        removeCurrentVideo();
      }        
      else {
        print("NO ERROR");
      }

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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final query = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54, // dim background slightly
      builder: (context) {
        final dialog = AlertDialog(
          backgroundColor: Colors.grey[900],
          //title: const Text(
          //  "Search Videos",
          //  style: TextStyle(color: Colors.white),
          //),
          content: SizedBox(
            width: 250, // smaller width
            height: 30, // smaller height          
            child: TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search video...",
                hintStyle: TextStyle(color: Colors.white54),
              ),
              enableInteractiveSelection: false,
              contextMenuBuilder: (context, editableTextState) {
                return const SizedBox.shrink(); // removes emoji/clipboard toolbar
              },
              onSubmitted: (value) {
                Navigator.pop(context, value.trim());
              },
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 10, bottom: 4),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            
            // 🔹 Compact text buttons
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(40, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(40, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () =>
                  Navigator.pop(context, searchController.text.trim()),
              child: const Text(
                "Search",
                style: TextStyle(color: Colors.lightBlue, fontSize: 13),
              ),
            ),
            
          ],
        );

        // If landscape → place it at upper right corner
        if (isLandscape) {
          return Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 50, right: 16),
              child: SizedBox(
                width: 300, // smaller width
                child: dialog,
              ),
            ),
          );
        } else {
          // Portrait → normal centered dialog
          return dialog;
        }
      },
    );

    if (query != null && query.isNotEmpty) {
      await fetchSearchResults(query);
      setState(() {
        showSearchResults = true;
      });

      // Auto-hide after 3 seconds (for landscape mode)
      //if (isLandscape) {
      //  Future.delayed(const Duration(seconds: 3), () {
      //    if (mounted) {
      //      setState(() {
      //        showSearchResults = false;
      //      });
      //    }
      //  });
      //}
    }
  }



  Future<void> fetchSearchResults(String query) async {
    final apiKey = youtubeApiKey;
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=20&q=$query&key=$apiKey';

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
                  child: SafeArea(
                    child: YoutubePlayer(controller: _controller),
                  ),                  
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

                            //ScaffoldMessenger.of(context).showSnackBar(
                            //  SnackBar(
                            //    content: Text("curr v: $currentVideoId, vid len: $videos.length"),
                            //    duration: const Duration(seconds: 5),
                            //  ),
                            //);                            


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
                          //IconButton(
                          //  icon: const Icon(Icons.home, color: Colors.white),
                          //  onPressed: () {},
                          //),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: _showSearchDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.video_library, color: Colors.white), // 📖 Playlist icon
                            onPressed: () {
                              setState(() {
                                // Toggle the video list
                                showList = !showList;
                                // If you also want to hide search results when toggling
                                if (showList) showSearchResults = false;
                              });
                            },
                          ),                          
                          //IconButton(
                          //  icon: const Icon(Icons.settings, color: Colors.white),
                          //  onPressed: () {},
                          //),
                        ],
                      ),
                    ),
                  ),
                ), // end of Align (bottom icons)
           
              ],
            );
          } else {
            // Landscape layout: Fullscreen video
            return Stack(
              children: [
                // Fullscreen video
                Positioned.fill(
                  child: SafeArea(
                    child: YoutubePlayer(controller: _controller),
                  ),                  
                ),

                // Video list / search results at bottom
                if (showList || showSearchResults)
                  Positioned(
                    left: 0,
                    right: 25, // leave space for side buttons
                    bottom: 0,
                    height: 150, // adjust as needed
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: showSearchResults
                            ? searchResults.length
                            : videos.length,
                        itemBuilder: (context, index) {
                          final video = showSearchResults
                              ? searchResults[index]
                              : videos[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (showSearchResults) {
                                  if (currentVideoId != null) {
                                    videos.add(video);
                                  } else {
                                    playVideo(video['id']!);
                                  }
                                  showSearchResults = false;
                                  showList = true;

                                  // Hide the main video list after 3 seconds
                                  Future.delayed(const Duration(seconds: 3), () {
                                    setState(() {
                                      showList = false;
                                    });
                                  });

                                } else {
                                  videos.removeAt(index);
                                  playVideo(video['id']!);
                                  Future.delayed(const Duration(seconds: 3), () {
                                    setState(() {
                                      showList = false;
                                    });
                                  });                                  
                                }
                              });
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Image.network(video['thumbnail']!, fit: BoxFit.cover),
                                  Text(video['title']!,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Right side icon buttons
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //IconButton(
                        //  icon: const Icon(Icons.home, color: Colors.white),
                        //  onPressed: () {},
                        //),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _showSearchDialog,
                        ),
                        IconButton(
                          icon: const Icon(Icons.video_library, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              // Toggle the video list
                              showList = !showList;
                              // If you also want to hide search results when toggling
                              if (showList) showSearchResults = false;
                            });
                          },
                        ),
                        //IconButton(
                        //  icon: const Icon(Icons.settings, color: Colors.white),
                        //  onPressed: () {},
                        //),
                      ],
                    ),
                  ),
                ),
              ],
            );


            //_controller.enterFullScreen();
            //return YoutubePlayer(controller: _controller);
          }
        },
      ),
    );
  }
}
