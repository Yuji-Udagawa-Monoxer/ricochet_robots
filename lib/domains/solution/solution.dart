import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/move_history.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';

class Solution {
  final Board board;

  Solution({
    required Board board,
  }) : board = board.copyWith();

  List<MoveHistory> solve() {
    final List<MoveHistory> answers = [];

    // TODO

    return answers;
  }

  List<MoveHistory> sample() => [
        const MoveHistory(records: [
          MoveRecord(
            color: RobotColors.green,
            direction: Directions.down,
          ),
          MoveRecord(
            color: RobotColors.red,
            direction: Directions.up,
          ),
        ]),
        const MoveHistory(records: [
          MoveRecord(
            color: RobotColors.blue,
            direction: Directions.right,
          ),
          MoveRecord(
            color: RobotColors.blue,
            direction: Directions.left,
          ),
          MoveRecord(
            color: RobotColors.yellow,
            direction: Directions.up,
          ),
        ]),
      ];
}
