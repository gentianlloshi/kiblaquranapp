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
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _errorMessage = '';
  final QuranAudioService _audioService = QuranAudioService();

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();

    try {
      // Get the actual audio URL from the service if not provided
      String audioUrl = widget.audioUrl;
      if (audioUrl.isEmpty) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          audioUrl = await _audioService.getVerseAudioUrl(
            widget.surahNumber, 
            widget.ayahNumber
          );
          print('Fetched audio URL: $audioUrl');
        } catch (e) {
          print('Error fetching audio URL: $e');
          setState(() {
            _errorMessage = 'Could not load audio';
            _isLoading = false;
          });
          return;
        }
      }

      // Set the audio source and disable looping
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.setLoopMode(LoopMode.off);
      _duration = _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing audio player: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading audio';
      });
    }
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
              Center(
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
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
