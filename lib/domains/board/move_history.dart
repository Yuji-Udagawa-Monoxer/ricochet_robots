import 'dart:io';

import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';

class MoveHistory {
  final List<MoveRecord> records;
  final Map<int, int> recordMap;

  MoveHistory({
    required this.records,
  }) : recordMap = makeRecordMap(records);

  static Map<int, int> makeRecordMap(List<MoveRecord> records) {
    final recordMap = <int, int>{};
    for (var x in records) {
      recordMap[x.index] =
          recordMap.containsKey(x.index) ? recordMap[x.index]! + 1 : 1;
    }
    return recordMap;
  }

  @override
  String toString() => [
        records.length.toString(),
        ...records.map((record) => record.toString())
      ].join(" ");

  bool containsAll(MoveHistory other) {
    return other.recordMap.entries.every(
      (m) => m.value <= (recordMap[m.key] ?? 0),
    );
  }
}

class MoveRecord {
  final RobotColors color;
  final Directions direction;

  const MoveRecord({
    required this.color,
    required this.direction,
  });

  bool equal(MoveRecord other) =>
      color == other.color && direction == other.direction;

  int get index {
    return color.index * Directions.values.length + direction.index;
  }

  @override
  String toString() {
    final colorString = () {
      switch (color) {
        case RobotColors.red:
          return "R";
        case RobotColors.blue:
          return "B";
        case RobotColors.green:
          return "G";
        case RobotColors.yellow:
          return "Y";
      }
    }();
    final directionString = () {
      switch (direction) {
        case Directions.up:
          return "↑";
        case Directions.right:
          return "→";
        case Directions.down:
          return "↓";
        case Directions.left:
          return "←";
      }
    }();
    return colorString + directionString;
  }
}
