import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as flutter_painting;
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(BikiniBottomNewsApp());
}

class BikiniBottomNewsApp extends StatelessWidget {
  const BikiniBottomNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bikini Bottom News',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan.shade400,
          secondary: Colors.purple.shade400,
          surface: Colors.indigo.shade900,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.righteous(
            fontSize: 28, // Decreased from 32
            fontWeight: FontWeight.bold,
            color: Colors.cyan.shade200,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 14, // Decreased from 16
            color: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: BikiniBottomNewsHomePage(),
    );
  }
}

class BikiniBottomNewsHomePage extends StatefulWidget {
  const BikiniBottomNewsHomePage({super.key});

  @override
  _BikiniBottomNewsHomePageState createState() =>
      _BikiniBottomNewsHomePageState();
}

class _BikiniBottomNewsHomePageState extends State<BikiniBottomNewsHomePage>
    with SingleTickerProviderStateMixin {
  PlatformFile? _selectedFile;
  String? _videoUrl;
  bool _isUploading = false;
  bool _isGenerating = false;
  final Dio _dio = Dio();
  VideoPlayerController? _videoPlayerController;
  double _generationProgress = 0.0;
  bool _isAIGenerated = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addListener(() {
        setState(() {
          _generationProgress = _progressController.value;
        });
      });
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'png',
        'jpg',
        'jpeg',
        'doc',
        'docx',
        'pdf',
        'mp4',
        'avi'
      ],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        _selectedFile = file;
        _videoUrl = null;
        _disposeVideoPlayer();
        _isAIGenerated = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      _showBikinibottomDialog(
        'Barnacles!',
        'You need to select a file first, buddy!',
        Icons.error_outline,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isGenerating = true;
      _progressController.forward(from: 0);
    });

    try {
      final mimeType = lookupMimeType(_selectedFile!.path!);
      if (mimeType == null || !_isAllowedMimeType(mimeType)) {
        _showBikinibottomDialog(
          'Sweet Neptune!',
          'That file type isn\'t allowed in Bikini Bottom!',
          Icons.warning_amber_rounded,
        );
        return;
      }

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
          contentType: DioMediaType.parse(mimeType),
        ),
        'aiStyle': 'Bikini Bottom News',
      });

      final response = await _dio.post(
        'https://vibevision.ai/api/generate-video/bikini-bottom-news',
        data: formData,
      );

      // Wait for generation animation to complete
      await _progressController.forward();
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _videoUrl = response.data['videoUrl'];
        _isUploading = false;
        _isGenerating = false;
        _isAIGenerated = true;
        _initializeVideoPlayer();
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isGenerating = false;
      });
      _showBikinibottomDialog(
        'Tartar Sauce!',
        'Something went wrong with the news generation!',
        Icons.cloud_off,
      );
    }
  }

  void _showBikinibottomDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.indigo.shade900.withOpacity(0.95),
        title: Row(
          children: [
            Icon(icon,
                color: Colors.cyan.shade300, size: 24), // Decreased from 28
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.righteous(
                color: Colors.cyan.shade200,
                fontSize: 18, // Decreased from 20
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12, // Decreased from 14
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Got it!',
              style: TextStyle(
                color: Colors.cyan.shade300,
                fontSize: 12, // Decreased from 14
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.cyan.shade400, width: 2),
        ),
      ),
    );
  }

  void _initializeVideoPlayer() {
    if (_videoUrl != null) {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(_videoUrl!))
            ..initialize().then((_) {
              setState(() {});
              _videoPlayerController!.addListener(() {
                if (_videoPlayerController!.value.position >=
                    _videoPlayerController!.value.duration) {
                  _progressController.value = 1.0;
                }
              });
            })
            ..setLooping(false)
            ..play();
    }
  }

  Future<void> _downloadVideo() async {
    if (_videoUrl == null) return;

    try {
      final response = await _dio.get(
        _videoUrl!,
        options: Options(responseType: ResponseType.bytes),
      );

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Your Bikini Bottom News Video',
        fileName: 'bikini_bottom_news.mp4',
      );

      if (result != null) {
        await Dio().download(_videoUrl!, result);
        _showBikinibottomDialog(
          'Success!',
          'Your news video has been saved!',
          Icons.check_circle,
        );
      }
    } catch (e) {
      _showBikinibottomDialog(
        'Barnacles!',
        'Failed to download the video!',
        Icons.error,
      );
    }
  }

  void _disposeVideoPlayer() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  bool _isAllowedMimeType(String mimeType) {
    final allowedTypes = [
      'image/png',
      'image/jpeg',
      'image/jpg',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'video/mp4',
      'video/avi',
    ];
    return allowedTypes.contains(mimeType);
  }

  flutter_painting.LinearGradient _buildGradient() {
    return flutter_painting.LinearGradient(
      colors: [
        Colors.indigo.shade900.withOpacity(0.95),
        Colors.purple.shade900.withOpacity(0.95)
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv_rounded,
              color: Colors.cyan.shade300,
              size: 32, // Decreased from 36
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                duration: const Duration(seconds: 2), curve: Curves.easeInOut),
            const SizedBox(width: 10),
            Text(
              'Bikini Bottom News Generator',
              style: GoogleFonts.righteous(
                color: Colors.cyan.shade200,
                fontSize: 20, // Decreased from 24
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.purple.shade400,
                    blurRadius: 8,
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage('https://example.com/underwater-bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.indigo.shade900.withOpacity(0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: _isGenerating ? _buildGenerationScreen() : _buildMainContent(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileUploadCard(),
            const SizedBox(height: 20),
            _buildUploadButton(),
            const SizedBox(height: 20),
            if (_videoUrl != null) _buildGeneratedVideoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200, // Decreased from 240
                height: 200, // Decreased from 240
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.shade400,
                      Colors.purple.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.shade400.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    value: _generationProgress,
                    strokeWidth: 14, // Decreased from 16
                    backgroundColor: Colors.indigo.shade800.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.cyan.shade200,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 32, // Decreased from 36
                    color: Colors.white,
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(),
                  const SizedBox(height: 6),
                  Text(
                    '${(_generationProgress * 100).toInt()}%',
                    style: GoogleFonts.righteous(
                      fontSize: 32, // Decreased from 36
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.cyan.shade400,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ).animate().scale(),
          const SizedBox(height: 32),
          Text(
            'Creating News in\nBikini Bottom Style...',
            textAlign: TextAlign.center,
            style: GoogleFonts.righteous(
              color: Colors.cyan.shade200,
              fontSize: 20, // Decreased from 24
              height: 1.3,
              shadows: [
                Shadow(
                  color: Colors.purple.shade400,
                  blurRadius: 10,
                ),
              ],
            ),
          ).animate().fadeIn().shimmer(),
        ],
      ),
    );
  }

  Widget _buildFileUploadCard() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 180, // Decreased from 220
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.shade900.withOpacity(0.8),
              Colors.purple.shade900.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.cyan.shade400,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.shade400.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: 64, // Decreased from 80
              color: Colors.cyan.shade300,
            )
                .animate()
                .scale(duration: const Duration(seconds: 1))
                .then()
                .shake(delay: const Duration(seconds: 1)),
            const SizedBox(height: 20),
            Text(
              _selectedFile != null
                  ? 'Selected: ${_selectedFile!.name}'
                  : '✨ Drop Your Content Here! ✨',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16, // Decreased from 18
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 10),
              Text(
                'Tap to change file',
                style: GoogleFonts.poppins(
                  color: Colors.cyan.shade200,
                  fontSize: 10, // Decreased from 12
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _uploadFile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan.shade400,
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 24), // Decreased padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 10,
        shadowColor: Colors.cyan.shade700,
      ),
      child: _isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 24), // Decreased from 28
                const SizedBox(width: 10),
                Text(
                  'Create Some News!',
                  style: GoogleFonts.righteous(
                    color: Colors.white,
                    fontSize: 18, // Decreased from 22
                  ),
                ),
              ],
            ),
    ).animate().shimmer(delay: const Duration(seconds: 1));
  }

  Widget _buildGeneratedVideoSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.shade900.withOpacity(0.8),
            Colors.purple.shade900.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.cyan.shade400,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.shade400.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_creation,
                  color: Colors.cyan.shade300,
                  size: 24, // Decreased from 28
                ),
                const SizedBox(width: 10),
                Text(
                  '🎬 Your News Report 📺',
                  style: GoogleFonts.righteous(
                    color: Colors.cyan.shade200,
                    fontSize: 20, // Decreased from 24
                    shadows: [
                      Shadow(
                        color: Colors.purple.shade400,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!)
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 800))
                          .scale(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  VideoProgressIndicator(
                    _videoPlayerController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.cyan.shade300,
                      backgroundColor: Colors.indigo.shade700,
                      bufferedColor: Colors.purple.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_videoPlayerController!.value.isPlaying) {
                              _videoPlayerController!.pause();
                            } else {
                              _videoPlayerController!.play();
                            }
                          });
                        },
                        icon: Icon(
                          _videoPlayerController!.value.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: Colors.cyan.shade300,
                          size: 40, // Decreased from 48
                        ),
                      ).animate().scale(),
                      IconButton(
                        onPressed: () {
                          _videoPlayerController!.seekTo(Duration.zero);
                          _videoPlayerController!.play();
                        },
                        icon: Icon(
                          Icons.replay_circle_filled_rounded,
                          color: Colors.cyan.shade300,
                          size: 40, // Decreased from 48
                        ),
                      ).animate().scale(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _videoPlayerController!.setVolume(
                                _videoPlayerController!.value.volume == 0
                                    ? 1.0
                                    : 0.0);
                          });
                        },
                        icon: Icon(
                          _videoPlayerController!.value.volume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 40, // Decreased from 48
                        ),
                      ).animate().scale(),
                      IconButton(
                        onPressed: _downloadVideo,
                        icon: Icon(
                          Icons.download_rounded,
                          color: Colors.cyan.shade300,
                          size: 40, // Decreased from 48
                        ),
                      ).animate().scale(),
                    ],
                  )
                ],
              )
            else
              Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.cyan.shade300),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade900.withOpacity(0.95),
              Colors.purple.shade900.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.shade700.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© Bikini Bottom News',
              style: GoogleFonts.righteous(
                color: Colors.cyan.shade200,
                fontSize: 14, // Decreased from 16
              ),
            ).animate().fadeIn(),
            if (_isAIGenerated)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4), // Decreased padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.shade700.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14, // Decreased from 16
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Generated',
                      style: GoogleFonts.poppins(
                        fontSize: 10, // Decreased from 12
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shimmer(),
          ],
        ),
      ),
    );
  }
}
