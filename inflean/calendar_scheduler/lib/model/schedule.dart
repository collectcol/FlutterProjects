import 'package:drift/drift.dart';

class Schedules extends Table {
  // PRIMARY KEY
  // ID, CONTENT, DATE, STARTTIME, ENDTIME, COLORID, CREATEDAT
  IntColumn get id => integer().autoIncrement()();

  // 내용
  TextColumn get content => text()();

  // 일정 날짜
  DateTimeColumn get date => dateTime()();

  // 시작 시간
  IntColumn get startTime => integer()();

  // 끝 시간
  IntColumn get endTime => integer()();

  // Category Color Table ID
  IntColumn get colorId => integer()();

  // 생성날짜 -> 항상 DateTime.now()가 실행이 된다.
  // 만약에 값을 넣어준다면 넣어준값으로 대체가 된다.
  DateTimeColumn get createAt => dateTime().clientDefault(
        () => DateTime.now(),
      )();
}
