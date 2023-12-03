import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool choolCheckDone = false;
  GoogleMapController? mapController;
  // latitude - 위도, longitude - 경도
  static const LatLng companyLatLng = LatLng(
    35.16236,
    129.1128,
  );
  static const CameraPosition initialPosition = CameraPosition(
    target: companyLatLng,
    zoom: 15,
  );
  static const double okDistance = 100;
  static final Circle withinDistanceCircle = Circle(
    circleId: const CircleId('withinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.blue,
    strokeWidth: 1,
  );
  static final Circle notWithinDistanceCircle = Circle(
    circleId: const CircleId('notWithinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,
    strokeWidth: 1,
  );
  static final Circle checkDoneCircle = Circle(
    circleId: const CircleId('checkDoneCircle'),
    center: companyLatLng,
    fillColor: Colors.green.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.green,
    strokeWidth: 1,
  );
  static const Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder<String>(
        future: checkPermission(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // print(snapshot.connectionState);
          // print(snapshot.data);

          // 1. future의 함수가 로딩중일때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. future의 함수가 끝나고 반환값을 사용할때
          if (snapshot.data == '위치 권한이 허가되었습니다.') {
            return StreamBuilder<Position>(
              stream:
                  // 현재 위치가 바뀔때 마다 새로 빌드가 된다.
                  // snapshot이 바뀌기때문에
                  Geolocator.getPositionStream(),
              builder: (context, snapshot) {
                bool isWithinRange = false;

                if (snapshot.hasData) {
                  final start = snapshot.data!; // 나의 위치
                  const end = companyLatLng; // 회사의 위치

                  final distance = Geolocator.distanceBetween(
                    start.latitude,
                    start.longitude,
                    end.latitude,
                    end.longitude,
                  );

                  if (distance < okDistance) {
                    // 100m 보다 작다면
                    isWithinRange = true;
                  }
                }
                return Column(
                  children: [
                    _CustomGoogleMap(
                      initialPosition: initialPosition,
                      circle: choolCheckDone
                          ? checkDoneCircle
                          : isWithinRange
                              ? withinDistanceCircle
                              : notWithinDistanceCircle,
                      marker: marker,
                      onMapCreated: onMapCreated,
                    ),
                    _ChoolcheckButton(
                      isWithinRange: isWithinRange,
                      choolCheckDone: choolCheckDone,
                      onPressed: onChoolCheckPressed,
                    ),
                  ],
                );
              },
            );
          }

          return Center(
            child: Text(snapshot.data),
          );
        },
      ),
    );
  }

  onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  onChoolCheckPressed() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '출근하기',
          ),
          content: const Text(
            '출근을 하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                '취소',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                '출근하기',
              ),
            ),
          ],
        );
      },
    );

    if (result) {
      setState(() {
        choolCheckDone = true;
      });
    }
  }

  Future<String> checkPermission() async {
    // 휴대폰 내에 사용하는 위치서비스 사용여부
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      return '위치 서비스를 활성화 해주세요';
    }

    // 현재 앱이 갖고 있는 위치서비스에 대한 권한이 어떻게 설정되어 있는지 알 수 있다.
    LocationPermission checkedPermission = await Geolocator.checkPermission();

    if (checkedPermission == LocationPermission.denied) {
      checkedPermission = await Geolocator.requestPermission();

      if (checkedPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요.';
      }
    }

    if (checkedPermission == LocationPermission.deniedForever) {
      return '앱의 위치 권한을 세팅에서 허가해주세요.';
    }

    return '위치 권한이 허가되었습니다.';
  }

  AppBar renderAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        '오늘도 출근',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () async {
            if (mapController == null) {
              return;
            }

            final location = await Geolocator.getCurrentPosition();

            mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(
                  location.latitude,
                  location.longitude,
                ),
              ),
            );
          },
          color: Colors.blue,
          icon: const Icon(
            Icons.my_location,
          ),
        )
      ],
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated;

  const _CustomGoogleMap({
    required this.initialPosition,
    required this.circle,
    required this.marker,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: {circle}, // Set.from([circle]),
        markers: {marker}, // Set.from([marker]),
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _ChoolcheckButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool choolCheckDone;
  const _ChoolcheckButton({
    required this.isWithinRange,
    required this.onPressed,
    required this.choolCheckDone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 60,
            color: choolCheckDone
                ? Colors.green
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
          ),
          const SizedBox(
            height: 20.0,
          ),
          if (!choolCheckDone && isWithinRange)
            TextButton(
              onPressed: onPressed,
              child: const Text(
                '출근하기',
              ),
            ),
        ],
      ),
    );
  }
}
