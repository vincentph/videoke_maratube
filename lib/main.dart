import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';


void main() {
  runApp(const VideokeMaratube());
}

class VideokeMaratube extends StatelessWidget {
  const VideokeMaratube({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Videoke Maratube',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late YoutubePlayerController _controller;
  GoogleSignInAccount? _currentUser;
  int _currentIndex = 0;
  bool _isMiniPlayer = false;

  final List<Widget> _pages = [
    const Center(child: Text("Home Page")),
    const Center(child: Text("Search Page")),
    const Center(child: Text("Settings Page")),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize YouTube player
    _controller = YoutubePlayerController(
      initialVideoId: 'dQw4w9WgXcQ',
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    final GoogleSignIn signIn = GoogleSignIn.instance;

    // Attempt lightweight authentication

  }

  void _handleAuthEvent(GoogleSignInAccount account) {
    setState(() {
      _currentUser = account;
    });
  }

  void _handleAuthError(Object error) {
    debugPrint('Google Sign-In error: $error');
  }

  Future<void> manualSignIn() async {
    final GoogleSignIn signIn = GoogleSignIn.instance;

    if (await signIn.supportsAuthenticate()) {
      try {
        final account = await signIn.authenticate();
        setState(() {
          _currentUser = account;
        });
      } catch (e) {
        debugPrint('Manual Sign-In failed: $e');
      }
    } else if (kIsWeb) {
      // Web-specific fallback if needed
      debugPrint('Web fallback: render button via Google Sign-In SDK');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleMiniPlayer() {
    setState(() {
      _isMiniPlayer = !_isMiniPlayer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isMiniPlayer)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                  ),
                ),
              Expanded(child: _pages[_currentIndex]),
            ],
          ),

          if (_isMiniPlayer)
            Positioned(
              top: 20,
              left: 20,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final miniWidth = screenWidth * 0.7;
                  final miniHeight = miniWidth * 9 / 16;

                  return Row(
                    children: [
                      SizedBox(
                        width: miniWidth,
                        height: miniHeight,
                        child: GestureDetector(
                          onTap: toggleMiniPlayer,
                          child: YoutubePlayer(
                            controller: _controller,
                            showVideoProgressIndicator: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Video Title",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentUser?.displayName ?? "Author Name",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _isMiniPlayer = true;
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      floatingActionButton: !_isMiniPlayer
          ? FloatingActionButton(
              onPressed: toggleMiniPlayer,
              child: const Icon(Icons.minimize),
            )
          : null,
    );
  }
}
