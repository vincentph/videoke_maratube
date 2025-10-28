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
  bool showList = false;
  bool showSearchResults = false;

  String? currentVideoId; // track the current playing video

  @override
  void initState() {
    super.initState();

    //  Listen for video end event
    _controller.listen((event) {
     if (event.playerState == PlayerState.ended) {
        // remove video when it ends
        removeCurrentVideo();
        // auto play next if available
        if (videos.isNotEmpty) {
          playVideo(videos[0]['id']!);
          videos.removeAt(0);
        }

      }
    });    

    showList = false;
    showSearchResults = false;
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
        //if (videos.isNotEmpty) {

        //  playVideo(videos[0]['id']!);
        //}
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
            final topPadding = MediaQuery.of(context).padding.top;
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final screenHeight = MediaQuery.of(context).size.height;
            final listTitleHeight = 40.0;
            final iconsHeight = 46.0;
            final videoHeight = size.width * 9 / 16;

            return Stack(
              children: [
                // Video player
                // Video player fixed at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topPadding, // include padding
                  child:
                    SizedBox(
                      height: topPadding,
                      width: double.infinity,
                    ),
                  ),

                Positioned(
                  top: topPadding,
                  left: 0,
                  right: 0,
                  height: videoHeight, // include padding
                  child:
                    SizedBox(
                      height: topPadding,
                      width: double.infinity,
                      child: YoutubePlayer(controller: _controller),
                    ),
                  ),



                // Show main list or search results
                //if (showList || showSearchResults)
                  //For Title of list
                  if(videos.isNotEmpty || searchResults.isNotEmpty)
                    Positioned(
                      top: topPadding + videoHeight,
                      left: 4,
                      right: 0,
                      height: listTitleHeight, // include padding
                      child:
                        SizedBox(
                          height: listTitleHeight,
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: 
                              Text(showSearchResults?"<< Search Result >>":(videos.isNotEmpty?"<< Line Up >>":""),
                                style: const TextStyle(
                                  fontSize: 18,      // increase font size
                                  fontWeight: FontWeight.bold, 
                                ),                            
                            ),
                          ),
                        ),
                    ),
                  
                  //For the content of the list
                  Positioned(
                    top: topPadding + videoHeight + listTitleHeight,
                    left: 0,
                    right: 0,
                    bottom: bottomPadding + iconsHeight , // leave space for icons, with additional space
                    child:
                      ListView.builder(
                        padding: EdgeInsets.zero, // ← remove extra space
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

                              setState(() {
                                
                                // Add search result to the end of main list
                                if (showSearchResults) {
                                  if(currentVideoId  != null) {
                                    videos.add(video); // append at the end
                                  } else {
                                    playVideo(video["id"]!);                                   
                                  }
                                  /*
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Video Added"),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  */                                  
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
                    child: SafeArea(
                      bottom: true, // only protect bottom area
                      top: false,
                      left: false,
                      right: false,   
                      child: Container(
                        color: Colors.grey[900],
                        height: iconsHeight,
                        padding: const EdgeInsets.symmetric(vertical: 4),                                         
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
                    child: YoutubePlayer(controller: _controller),
                ),
              ]
            );  

            //_controller.enterFullScreen();
            //return YoutubePlayer(controller: _controller);
          }
        },
      ),
    );
  }
}
