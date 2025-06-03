import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;
import '../../../data/services/quran_audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int surahNumber;
  final int ayahNumber;

  const AudioPlayerWidget({super.key, 
    required this.audioUrl,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _errorMessage = '';
  final QuranAudioService _audioService = QuranAudioService();
  int _retryAttempts = 0;
  final int _maxRetryAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();

    // Listen to player state changes for completion
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          // Reset position when completed
          _audioPlayer.seek(Duration.zero);
        }
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((newDuration) {
      if (mounted && newDuration != null) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    // Initial audio setup
    await _loadAudio();
  }

  Future<void> _loadAudio() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get the actual audio URL from the service if not provided
      String audioUrl = widget.audioUrl;
      if (audioUrl.isEmpty) {
        try {
          audioUrl = await _audioService.getVerseAudioUrl(
            widget.surahNumber, 
            widget.ayahNumber
          );
          debugPrint('Fetched audio URL: $audioUrl for Surah ${widget.surahNumber}, Ayah ${widget.ayahNumber}');
        } catch (e) {
          debugPrint('Error fetching audio URL: $e');
          throw Exception('Could not load audio URL');
        }
      }

      // Stop any current playback
      await _audioPlayer.stop();

      // Set the audio source using AudioSource for better compatibility
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));

      // Validate the audio to ensure it's playable
      await _validateAudio();

      // Disable looping
      await _audioPlayer.setLoopMode(LoopMode.off);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
          _retryAttempts = 0;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');

      // Handle retries
      if (_retryAttempts < _maxRetryAttempts) {
        _retryAttempts++;
        debugPrint('Retrying audio load (${_retryAttempts}/$_maxRetryAttempts)');
        await Future.delayed(const Duration(seconds: 2));
        return _loadAudio();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading audio';
        });
      }
    }
  }

  // Validate audio is playable by checking duration
  Future<void> _validateAudio() async {
    int attempts = 0;
    const maxAttempts = 10;
    const waitTime = Duration(milliseconds: 100);

    while (attempts < maxAttempts) {
      final duration = _audioPlayer.duration;
      if (duration != null) {
        debugPrint('Audio duration: ${duration.inSeconds} seconds for Surah ${widget.surahNumber}, Ayah ${widget.ayahNumber}');

        // If duration is too short (less than 500ms), consider it invalid
        if (duration.inMilliseconds < 500) {
          debugPrint('Audio duration too short (${duration.inMilliseconds}ms), treating as invalid');
          throw Exception('Audio file invalid or too short');
        }
        return;
      }

      await Future.delayed(waitTime);
      attempts++;
    }

    // If we get here, we couldn't determine the duration
    debugPrint('Could not determine audio duration after $maxAttempts attempts');
    throw Exception('Could not determine audio duration');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              'Surah ${widget.surahNumber}, Ayah ${widget.ayahNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Column(
                children: [
                  Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: _loadAudio,
                    child: const Text("Retry"),
                  ),
                ],
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () async {
                      if (!_isInitialized) {
                        await _loadAudio();
                        return;
                      }

                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        // If audio was completed, seek back to start
                        if (_position >= _duration) {
                          await _audioPlayer.seek(Duration.zero);
                        }
                        await _audioPlayer.play();
                      }

                      if (mounted) {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: math.min(_position.inSeconds.toDouble(),
                          _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1),
                      min: 0,
                      max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                      onChanged: (value) {
                        final position = Duration(seconds: value.toInt());
                        _audioPlayer.seek(position);
                      },
                    ),
                  ),
                  Text(_formatDuration(_position)),
                  const Text(' / '),
                  Text(_formatDuration(_duration)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
