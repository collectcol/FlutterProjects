import 'package:calendar_scheduler/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // 만약에 runApp을 실행하기 전에 다른 코드를 실행해서 플러터와 관련된 코드를 실행을한다?
  // flutterFrameWork가 준비된 상태인지를 확인을 해야한다.
  // 초기화가 되었는지 확인하는 함수.
  // 이 함수를 실행하면 flutterFrameWork가 준비가 될때까지 기다릴 수 있다.
  WidgetsFlutterBinding.ensureInitialized();

  // Intel패키지 안에 있는 모든 언어들을 다 사용할 수 있게 된다. 특히 날짜에 관련된것들
  await initializeDateFormatting();

  // 원래는 runApp을 실행하면 WidgetsFlutterBinding.ensureInitialized()가 실행된다.
  // 하지만 우리는 그 사이에 initializeDateFormatting()을 실행시켜주기 위해
  // 선언을 따로 해주는 것이다.
  runApp(
    MaterialApp(
      theme: ThemeData(
        fontFamily: 'NotoSans',
      ),
      home: HomeScreen(),
    ),
  );
}
