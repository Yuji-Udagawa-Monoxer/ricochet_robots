import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/move_history.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/board/robot_positions.dart';

class StateMemo {
  final int robotPositionsHash;
  final int moveCount;
  final int? lastRobotPositionsHash;
  final MoveRecord? lastMove;

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
  final int searchFinishedCount;
  final bool isFinishedIfFound;
  final List<MoveHistory> answers = [];
  static const int _searchMaxCount = 20;
  final List<Queue<int>> queueList =
      List.generate(_searchMaxCount, (index) => Queue());
  final Map<int, StateMemo> stateMemo = HashMap();
  final List<List<List<Position>>> movedNext = List.generate(
    16,
    (x) => List.generate(
      16,
      (y) => List.generate(
        Directions.values.length,
        (direction) => Position(x: x, y: y),
      ),
    ),
  );
  final List<List<ShortestGoalMemo>> shortestGoalMemo = List.generate(
    16,
    (x) => List.generate(
      16,
      (y) => ShortestGoalMemo(
        current: Position(x: x, y: y),
      ),
    ),
  );

  int searchStateNum = 0;
  final stopwatch = Stopwatch();

  SolveBoard({
    required Board board,
    searchFinishedCount = -1,
  })  : board = board.copyWith(),
        searchFinishedCount = searchFinishedCount < 0
            ? _searchMaxCount
            : min(searchFinishedCount, _searchMaxCount),
        isFinishedIfFound = searchFinishedCount < 0 {
    stopwatch.start();
    _init();
    _solve();
    stopwatch.stop();
    _resultLog();
  }

  void _init() {
    final startRobotPositionsHash = RobotPositions.toHash(board.robotPositions);
    stateMemo[startRobotPositionsHash] = StateMemo(
      robotPositionsHash: startRobotPositionsHash,
      moveCount: 0,
      lastRobotPositionsHash: null,
      lastMove: null,
    );
    queueList[0].addLast(startRobotPositionsHash);

    _makeShortestGoalMemo();

    _makeMovedNext();
  }

  void _makeShortestGoalMemo() {
    // FIXME
  }

  void _makeMovedNext() {
    board = board.copyWith(
      robotPositions: const RobotPositions(
        red: Position(x: 0, y: 0),
        blue: Position(x: 16, y: 16),
        green: Position(x: 16, y: 16),
        yellow: Position(x: 16, y: 16),
      ),
    );
    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        for (final direction in Directions.values) {
          board = board.copyWith(
            robotPositions: board.robotPositions.copyWith(
              red: Position(x: x, y: y),
            ),
          );
          board = board.movedLight(
            robot: const Robot(color: RobotColors.red),
            direction: direction,
          );
          movedNext[x][y][direction.index] =
              board.robotPositions.red.copyWith();
        }
      }
    }
  }

  void _solve() {
    for (var index = 0; index < searchFinishedCount; ++index) {
      final queue = queueList[index];
      while (queue.isNotEmpty) {
        _solveInner(queue.removeFirst());
      }
    }
  }

  void _solveInner(int currentHash) {
    // assert(stateMemo.containsKey(currentHash));

    for (final robotColor in RobotColors.values) {
      for (final direction in Directions.values) {
        // Move
        _restore(currentHash); // 1/4 of the total throughput
        final nextRobotPositions = _moved(
          // 3/4 of the total throughput
          robotColor: robotColor,
          direction: direction,
        );

        // Already searched
        final nextHash = RobotPositions.toHash(nextRobotPositions);
        final nextMoveCount = stateMemo[currentHash]!.moveCount + 1;
        final nextStateMemo = stateMemo[nextHash];
        if (nextStateMemo != null) {
          if (nextStateMemo.moveCount <= nextMoveCount) {
            continue;
          }
        }

        // add memo
        stateMemo[nextHash] = StateMemo(
          robotPositionsHash: nextHash,
          moveCount: nextMoveCount,
          lastRobotPositionsHash: currentHash,
          lastMove: MoveRecord(color: robotColor, direction: direction),
        );

        // IsGoal
        final nextRobotPosition =
            nextRobotPositions.position(color: robotColor);
        if (board.isGoal(nextRobotPosition, Robot(color: robotColor))) {
          final newHistory = _makeMoveHistory(nextHash);
          if (_isDifferentHistory(newHistory)) {
            answers.add(newHistory);
            if (isFinishedIfFound) {
              for (final queue in queueList) {
                queue.clear();
              }
              return;
            }
          }
          continue;
        }

        // add nextSearch
        final nextKeys = nextMoveCount;
        if (nextKeys > queueList.length) {
          continue;
        }
        queueList[nextKeys].addLast(nextHash);
        ++searchStateNum;
      }
    }
  }

  bool _isDifferentHistory(MoveHistory newHistory) {
    return answers.every((history) => !newHistory.containsAll(history));
  }

  MoveHistory _makeMoveHistory(int robotPositionsHash) {
    final List<MoveRecord> moveRecords = [];
    var current = robotPositionsHash;
    while (true) {
      // assert(stateMemo.containsKey(current));
      final state = stateMemo[current]!;
      if (state.moveCount == 0) {
        break;
      }
      // assert(state.lastMove != null);
      // assert(state.lastRobotPositionsHash != null);
      moveRecords.add(state.lastMove!);
      current = state.lastRobotPositionsHash!;
    }
    return MoveHistory(records: moveRecords.reversed.toList());
  }

  void _restore(int robotPositionsHash) {
    board = board.copyWith(
        robotPositions: RobotPositions.fromHash(robotPositionsHash));
  }

  RobotPositions _moved({
    required RobotColors robotColor,
    required Directions direction,
  }) {
    var currentPositions = board.robotPositions;
    var current = currentPositions.position(color: robotColor);
    final candidatesRobotPositions = RobotColors.values
        .where((c) => c != robotColor)
        .map((c) => currentPositions.position(color: c))
        .where((position) => current.isStraightDirection(position, direction))
        .map((position) =>
            position.next(Directions.values[(direction.index + 2) % 4]))
        .toList();
    candidatesRobotPositions
        .add(movedNext[current.x][current.y][direction.index]);
    final toPosition = () {
      switch (direction) {
        case Directions.right:
          return Position(
              y: current.y,
              x: candidatesRobotPositions.fold(
                  16, (int previousValue, e) => min(previousValue, e.x)));
        case Directions.down:
          return Position(
              x: current.x,
              y: candidatesRobotPositions.fold(
                  16, (int previousValue, e) => min(previousValue, e.y)));
        case Directions.left:
          return Position(
              y: current.y,
              x: candidatesRobotPositions.fold(
                  0, (int previousValue, e) => max(previousValue, e.x)));
        case Directions.up:
        default:
          return Position(
              x: current.x,
              y: candidatesRobotPositions.fold(
                  0, (int previousValue, e) => max(previousValue, e.y)));
      }
    }();
    return board.robotPositions
        .copyWith()
        .move(color: robotColor, to: toPosition);
  }

  void _resultLog() {
    debugPrint("SearchNum: $searchStateNum");
    debugPrint("Time: ${stopwatch.elapsedMilliseconds} [msec]");
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
