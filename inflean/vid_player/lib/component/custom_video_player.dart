import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final XFile video;
  final VoidCallback onNewVideoPressed;
  const CustomVideoPlayer({
    required this.video,
    required this.onNewVideoPressed,
    super.key,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? videoController;
  Duration currentPosition = const Duration();
  bool showControls = false;

  @override
  void initState() {
    super.initState();

    // XFile 타입은 이미지 피커에서만 사용하는 커스텀 파일 타입
    // XFIle 타입을 Flutter의 파일 타입으로 변형을 해줘야 한다.
    // videoController = VideoPlayerController.file(
    // File 참조할때 html 말고 io를 참조 해야한다.
    // 앱 제작할 때는 무조건 .io 패키지에 있는걸 쓴다.
    // File(widget.video.path),
    // 이미지 피커에서 골라온 이 비디오의 path를 넣어준다.
    // File생성자의 파라미터는 String path이다.
    // );

    // iniState는 절대로 async 함수로 만들 수 없다.
    // await videoController.initialize();

    // 차이점은 컨트롤러가 끝날 때까지 기다리지 않는점
    initializeController();
  }

  @override
  void didUpdateWidget(covariant CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video.path != widget.video.path) {
      initializeController();
    }
  }

  initializeController() async {
    currentPosition = const Duration();
    videoController = VideoPlayerController.file(
      File(widget.video.path),
    );

    videoController!.addListener(() {
      final currentPosition = videoController!.value.position;

      setState(() {
        this.currentPosition = currentPosition;
      });
    });

    await videoController!.initialize();

    // setState를 실행하는 이유
    // 비디오 컨트롤러를 생성을 했으니, 비디오 컨트롤러에 맞게 우리가 UI를 새로 빌드를 해라는 뜻
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 처음 화면이 실행될때 videoController가 만들어 질때까지 기다리지 않으므로
    // null이 올 수 있다. 그러므로 if문을 사용하여 로딩바를 리턴해줘서 기다리게 만든다.
    if (videoController == null) {
      return const CircularProgressIndicator();
    }

    // videoPlayer를 그냥 렌더링 하면 비디오가 휴대폰의 크기에 맞춰서 비율이 깨진채로 나오게 된다.
    // 이를 방지하기 위해 AspectRatio 위젯을 사용한다.
    // aspectRatio 파라미터에 videoController!.value.aspectRatio를 설정한다.
    // 그러면 해당 비디오의 비율이 그대로 휴대폰 화면에 나오게 된다.
    return AspectRatio(
      aspectRatio: videoController!.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() {
          showControls = !showControls;
        }),
        child: Stack(
          children: [
            VideoPlayer(
              videoController!,
            ),
            if (showControls)
              _Controls(
                onReversePressed: onReversePressed,
                onPlayPressed: onPlayPressed,
                onForwardPressed: onForwardPressed,
                isPlaying: videoController!.value.isPlaying,
              ),
            // 위치를 지정해주는 위젯
            // 아이콘 버튼 위젯을 전체 위치를 기준으로 했을 때 오른쪽 끝에 위치해주고 싶다면
            // right : 0
            if (showControls)
              _NewVideo(
                onPressed: widget.onNewVideoPressed,
              ),

            _SliderBottom(
                currentPosition: currentPosition,
                videoController: videoController,
                onSliderChanged: onSliderChanged),
          ],
        ),
      ),
    );
  }

  void onSliderChanged(double val) {
    videoController!.seekTo(
      Duration(
        seconds: val.toInt(),
      ),
    );
  }

  void onReversePressed() {
    final currentPosition = videoController!.value.position;

    Duration position = const Duration(); // 기본 0초이다.

    if (currentPosition.inSeconds > 3) {
      position = currentPosition - const Duration(seconds: 3);
    }

    videoController!.seekTo(position);
  }

  void onPlayPressed() {
    setState(
      () {
        // 이미 실행중이면 정지
        // 실행중이 아니면 실행
        if (videoController!.value.isPlaying) {
          videoController!.pause();
        } else {
          videoController!.play();
        }
      },
    );
  }

  void onForwardPressed() {
    final maxPosition = videoController!.value.duration;
    final currentPosition = videoController!.value.position;

    Duration position = maxPosition; // 최대영상 시간을 넣어준다.

    // 전체 영상의 길이의 duration에서 3초를 뺀것을 초로 가져왔을때
    // 그 길이가 만약에 현재 포지션 보다 길다면
    if ((maxPosition - const Duration(seconds: 3)).inSeconds >
        currentPosition.inSeconds) {
      position = currentPosition + const Duration(seconds: 3);
    }

    videoController!.seekTo(position);
  }
}

class _SliderBottom extends StatelessWidget {
  const _SliderBottom({
    required this.currentPosition,
    required this.videoController,
    required this.onSliderChanged,
  });

  final Duration currentPosition;
  final VideoPlayerController? videoController;
  final ValueChanged<double> onSliderChanged;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Row(
          children: [
            Text(
              '${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Slider(
                value: currentPosition.inSeconds.toDouble(),
                onChanged: onSliderChanged,
                max: videoController!.value.duration.inSeconds.toDouble(),
                min: 0,
              ),
            ),
            Text(
              '${videoController!.value.duration.inMinutes}:${(videoController!.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VoidCallback onPlayPressed;
  final VoidCallback onReversePressed;
  final VoidCallback onForwardPressed;
  final bool isPlaying;

  const _Controls({
    required this.onPlayPressed,
    required this.onReversePressed,
    required this.onForwardPressed,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      height: MediaQuery.of(context).size.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          renderIconButton(
            onPressed: onReversePressed,
            iconData: Icons.rotate_left,
          ),
          renderIconButton(
            onPressed: onPlayPressed,
            iconData: isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          renderIconButton(
            onPressed: onForwardPressed,
            iconData: Icons.rotate_right,
          ),
        ],
      ),
    );
  }

  Widget renderIconButton({
    required VoidCallback onPressed,
    required IconData iconData,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 30.0,
      color: Colors.white,
      icon: Icon(
        iconData,
      ),
    );
  }
}

class _NewVideo extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewVideo({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0, // 오른쪽 끝에서부터 0 픽셀 이동을 시킨다는 뜻.
      child: IconButton(
        onPressed: onPressed,
        color: Colors.white,
        iconSize: 30.0,
        icon: const Icon(
          Icons.photo_camera_back,
        ),
      ),
    );
  }
}
