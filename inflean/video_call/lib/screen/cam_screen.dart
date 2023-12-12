import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/const/agora.dart';

class CamScreen extends StatefulWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  @override
  void dispose() async {
    if (engine != null) {
      await engine!.leaveChannel(
        options: LeaveChannelOptions(),
      );

      engine!.release();
    }

    super.dispose();
  }

  // agora관련 기능을 하는 엔진
  RtcEngine? engine;

  // 내 ID
  int? uid = 0;

  // 상대 ID
  int? otherUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LIVE',
        ),
      ),
      body: FutureBuilder<bool>(
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          // 에러가 아니고 아직 데이터가 없다면 로딩중이라는 뜻
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    renderMainView(),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: Colors.grey,
                        height: 160,
                        width: 120,
                        child: renderSubView(),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (engine != null) {
                      await engine!.leaveChannel();
                      engine = null;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '채널 나가기',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  renderMainView() {
    // uid 가 null 이면 채널에 안들어와있다는 뜻
    if (uid == null) {
      return const Center(
        child: Text('채널에 참여해주세요'),
      );
    } else {
      // 채널에 참여하고 있을떄
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine!,
          canvas: const VideoCanvas(
            uid: 0,
          ),
        ),
      );
    }
  }

  renderSubView() {
    if (otherUid == null) {
      return const Center(
        child: Text(
          '채널에 유저가 없습니다.',
        ),
      );
    } else {
      // 상대방 화면 보여줄땐 remote 를 써야한다
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine!,
          canvas: VideoCanvas(uid: otherUid),
          connection: RtcConnection(channelId: channelName),
        ),
      );
    }
  }

  Future<bool> init() async {
    // 권한을 한꺼번에 요청함.
    final resp = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = resp[Permission.camera];
    final microphonePermission = resp[Permission.microphone];

    // 따로 분기해도 상관없다.
    if (cameraPermission != PermissionStatus.granted ||
        microphonePermission != PermissionStatus.granted) {
      // throw로 던져서 snapshot.error.toString()으로 바로 받아서 쓸 수 있다.
      throw '카메로 또는 마이크 권한이 없습니다.';
    }

    // engine이 초기화가 안되어있으면 초기화 해주기
    if (engine == null) {
      engine = createAgoraRtcEngine();

      // appId 할당
      await engine!.initialize(
        const RtcEngineContext(
          appId: appId,
        ),
      );

      // 이벤트 콜백함수 등록인거 같다.
      engine!.registerEventHandler(
        RtcEngineEventHandler(
          // 내가 채널에 입장했을때
          // connection -> 연결정보
          // elapsed -> 연결된 시간 (연결된지 얼마나 됐는지)
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('채널에 입장했습니다. uid: ${connection.localUid}');
            setState(() {
              // 원래 기본값으로 0으로 설정한 uid를
              // 실제로 배정받은 아이디로 덮어쓰기하기
              uid = connection.localUid;
            });
          },
          // 내가 채널에서 나갔을때
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('채널 퇴장');
            setState(() {
              uid == null;
            });
          },
          // 상대방 유저가 들어왔을때
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('상대가 채널에 입장했습니다. otherUid: ${remoteUid}');

            setState(() {
              otherUid = remoteUid;
            });
          },
          // 상대가 나갔을때
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print('상대가 채널에서 나갔습니다. otherUid: ${remoteUid}');

            setState(() {
              otherUid = null;
            });
          },
        ),
      );

      // 순서대로 실행
      // 카메라 활성화
      await engine!.enableVideo();
      // 카메라로 찍고 있는 모습을 내 휴대폰으로 송출해라는 뜻
      await engine!.startPreview();

      // 나중에 실제로 화상채팅앱을 만들어서 튜닝을 조금 하고 싶으면
      // 함수 들어가서 옵셔들마다 설명 다 나와있으니 알아서 써먹으면 된다.
      ChannelMediaOptions options = const ChannelMediaOptions();

      await engine!.joinChannel(
        token: tempToken,
        channelId: channelName,
        uid: 0,
        options: options,
      );
    }

    return true;
  }
}
