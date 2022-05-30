import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';

class MoveHistory {
  final List<MoveRecord> records;

  const MoveHistory({
    required this.records,
  });

  @override
  String toString() => records.map((record) => record.toString()).join(" ");

  bool containsAll(MoveHistory other) {
    return other.records.every(
        (otherRecord) => records.any((record) => record.equal(otherRecord)));
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
