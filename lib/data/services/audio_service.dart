import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlaying;
  bool _isPlaying = false;

  AudioService() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _currentlyPlaying = null;
    });
  }

  Future<void> playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      // If we're trying to play the same audio that was just stopped, start from beginning
      if (audioPath == _currentlyPlaying) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.resume();
      } else {
        // Otherwise play the new audio
        if (audioPath.startsWith('http')) {
          await _audioPlayer.play(UrlSource(audioPath));
        } else {
          await _audioPlayer.play(AssetSource(audioPath));
        }
        _currentlyPlaying = audioPath;
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    }
  }

  Future<void> stopAudio() async {
    if (_currentlyPlaying != null) {
      await _audioPlayer.stop();
      _currentlyPlaying = null;
    }
  }

  Future<void> resumeAudio() async {
    if (_currentlyPlaying != null && !_isPlaying) {
      await _audioPlayer.resume();
    }
  }

  bool get isPlaying => _isPlaying;
  String? get currentlyPlaying => _currentlyPlaying;

  void dispose() {
    _audioPlayer.dispose();
  }
}
