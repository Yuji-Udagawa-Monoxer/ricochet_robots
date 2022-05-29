import 'dart:collection';

import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/move_history.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/board/robot_positions.dart';

class StateMemo {
  final int robotPositionsHash;
  final int moveCount;
  final int lastRobotPositionsHash;
  final MoveRecord lastMove;

  const StateMemo({
    required this.robotPositionsHash,
    required this.moveCount,
    required this.lastRobotPositionsHash,
    required this.lastMove,
  });
}

class ShortestGoalMemo {
  final Position current;
  int shortestCount = 1 << 30;
  final List<Position> needRobot = []; // or, empty => not need

  ShortestGoalMemo({
    required this.current,
  });
}

class SolveBoard {
  Board board;
  final int searchMaxCount; // -1: finish when shortest count found

  final List<MoveHistory> answers = [];
  final List<List<int>> queue =
      List.generate(20, (index) => []); // Search Max: 20
  final Map<int, StateMemo> stateMemo = HashMap();
  final List<List<ShortestGoalMemo>> shortestGoalMemo = List.generate(
      16,
      (x) => List.generate(
          16,
          (y) => ShortestGoalMemo(
                current: Position(x: x, y: y),
              )));

  SolveBoard({
    required Board board,
    this.searchMaxCount = -1,
  }) : board = board.copyWith() {
    _init();
    _solve();
  }

  void _init() {
    _makeShortestGoalMemo();

    queue[0].add(RobotPositions.toHash(board.robotPositions));
  }

  void _solve() {
    // TODO
  }

  void _addDifferentHistory(MoveHistory newHistory) {
    if (answers.every((history) => !newHistory.containsAll(history))) {
      answers.add(newHistory);
    }
  }

  void _restore(int robotPositionsHash) {
    board = board.copyWith(
        robotPositions: RobotPositions.fromHash(robotPositionsHash));
  }

  void _makeShortestGoalMemo() {
    // TODO
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
