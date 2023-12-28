import 'package:flutter/material.dart';
import 'package:gif_view/src/git_frame.dart';
import 'package:quiver/cache.dart';

final _cache = MapCache<String, List<GifFrame>>.lru(maximumSize: 50);//cache gif data size

enum GifStatus { loading, playing, stoped, paused, reversing }

class GifController extends ChangeNotifier {
  // Set<String> keys = {};
  List<GifFrame> _frames = [];
  int currentIndex = 0;
  GifStatus status = GifStatus.loading;

  final bool autoPlay;
  final VoidCallback? onFinish;
  final VoidCallback? onStart;
  final ValueChanged<int>? onFrame;

  bool loop;
  bool _inverted;

  GifController({
    this.autoPlay = true,
    this.loop = true,
    bool inverted = false,
    this.onStart,
    this.onFinish,
    this.onFrame,
  }) : _inverted = inverted;

  void _run() {
    switch (status) {
      case GifStatus.playing:
      case GifStatus.reversing:
        _runNextFrame();
        break;

      case GifStatus.stoped:
        onFinish?.call();
        // currentIndex = 0;
        break;
      case GifStatus.loading:
      case GifStatus.paused:
    }
  }

  void _runNextFrame() async {
    if (status == GifStatus.reversing) {
      if (currentIndex > 0) {
        currentIndex--;
      } else if (loop) {
        currentIndex = _frames.length - 1;
      } else {
        status = GifStatus.stoped;
      }
    } else {
      if (currentIndex < _frames.length - 1) {
        currentIndex++;
      } else if (loop) {
        currentIndex = 0;
      } else {
        status = GifStatus.stoped;
      }
    }

    if(status != GifStatus.stoped){
      await Future.delayed(_frames[currentIndex].duration);
      onFrame?.call(currentIndex);
      notifyListeners();
    }

    _run();
  }

  GifFrame get currentFrame => _frames[currentIndex];
  int get countFrames => _frames.length;

  void play({bool? inverted, int? initialFrame}) {
    print('play status: ${status.name}');
    if (status == GifStatus.loading) return;
    _inverted = inverted ?? _inverted;

    if (status == GifStatus.stoped || status == GifStatus.paused) {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;

      bool isValidInitialFrame = initialFrame != null &&
          initialFrame > 0 &&
          initialFrame < _frames.length - 1;

      if (isValidInitialFrame) {
        currentIndex = initialFrame;
      } else {
        currentIndex = status == GifStatus.reversing ? _frames.length - 1 : 0;
      }
      onStart?.call();
      onFrame?.call(currentIndex);
      _run();
    } else {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;
    }
  }

  void stop() {
    status = GifStatus.stoped;
  }

  void pause() {
    status = GifStatus.paused;
  }

  void seek(int index) {
    currentIndex = index;
    notifyListeners();
  }

  @override
  void dispose(){
    super.dispose();
    _frames = [];
    // _disposeImages();
  }

  void configure(List<GifFrame> frames, {bool updateFrames = false}) {
    _frames = frames;
    if (!updateFrames) {
      status = GifStatus.stoped;
      if (autoPlay) {
        play();
      }
      notifyListeners();
    }
  }

  Future<List<GifFrame>?> getCache(String key) async{
    return _cache.get(key);
  }


  Future<void> setCache(String key, List<GifFrame> value)async {
    // keys.add(key);
    _cache.set(key, value);
  }


  // Future<void> _disposeImages() async {
  //   print('_disposeImages');
  //   for (var k in keys) {
  //     var v = await _cache.get(k);
  //     if (null != v) {
  //       print('_disposeImages gif: $k');
  //       for (var element in v) {
  //         element.imageInfo.dispose();
  //       }
  //     }
  //     _cache.invalidate(k);
  //   }
  //
  //   keys.clear();
  // }
}
