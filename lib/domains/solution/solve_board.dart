import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/move_history.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/board/robot_positions.dart';
import 'package:ricochet_robots/domains/board/robot_positions_mutable.dart';

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
  final Set<Position> needRobot = HashSet(); // or, empty => not need

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
  final Map<int, StateMemo> _stateMemo = HashMap();
  final RobotPositionsMutable _robotPositions = RobotPositionsMutable.init;
  final List<List<List<Position>>> _movedNext = List.generate(
    16,
    (x) => List.generate(
      16,
      (y) => List.generate(
        Directions.values.length,
        (direction) => Position(x: x, y: y),
      ),
    ),
  );
  final List<List<ShortestGoalMemo>> _shortestGoalMemo = List.generate(
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
    required this.board,
    searchFinishedCount = -1,
  })  : searchFinishedCount = searchFinishedCount < 0
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
    _robotPositions.set(board.robotPositions);
    final startRobotPositionsHash = _robotPositions.toHash();

    _makeMovedNext(startRobotPositionsHash);

    _makeShortestGoalMemo();

    _robotPositions.set(board.robotPositions);
    _stateMemo[startRobotPositionsHash] = StateMemo(
      robotPositionsHash: startRobotPositionsHash,
      moveCount: 0,
      lastRobotPositionsHash: null,
      lastMove: null,
    );
    queueList[0].addLast(startRobotPositionsHash);
  }

  void _makeMovedNext(int originalHash) {
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
          _movedNext[x][y][direction.index] =
              board.robotPositions.red.copyWith();
        }
      }
    }

    board = board.copyWith(
      robotPositions: RobotPositions.fromHash(originalHash),
    );
  }

  void _makeShortestGoalMemo() {
    final Queue<Position> queue = Queue();
    final goalColor = board.goal.color ?? RobotColors.red;
    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        final position = Position(x: x, y: y);
        if (board.isGoal(position, Robot(color: goalColor))) {
          _shortestGoalMemo[x][y].shortestCount = 0;
          queue.add(position);
        }
      }
    }
    while (queue.isNotEmpty) {
      final firstPosition = queue.removeFirst();
      final memo = _shortestGoalMemo[firstPosition.x][firstPosition.y];

      _robotPositions.setOneColor(goalColor, firstPosition);

      for (final direction in Directions.values) {
        var current = firstPosition;
        final reverseDirection = Directions.values[(direction.index + 2) % 4];
        final Position? need = board
                .grids.grids[firstPosition.y][firstPosition.x]
                .canMove(reverseDirection)
            ? current.next(reverseDirection)
            : null;
        while (board.grids.grids[current.y][current.x].canMove(direction)) {
          current = current.next(direction);
          final nextMemo = _shortestGoalMemo[current.x][current.y];
          if (nextMemo.shortestCount > memo.shortestCount + 1) {
            nextMemo.shortestCount = memo.shortestCount + 1;
            queue.add(current);
          }
          if (nextMemo.shortestCount >= memo.shortestCount + 1) {
            if (need == null) {
              nextMemo.needRobot.addAll(memo.needRobot);
            } else {
              nextMemo.needRobot.add(need); // or memo.needRobot
            }
          }
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
    // assert(_stateMemo.containsKey(currentHash));

    for (final robotColor in RobotColors.values) {
      for (final direction in Directions.values) {
        // Move
        _robotPositions.fromHash(currentHash); // 1/4 of the total throughput
        _moved(
          robotColor: robotColor,
          direction: direction,
        ); // 3/4 of the total throughput

        // Already searched
        final nextHash = _robotPositions.toHash();
        final nextMoveCount = _stateMemo[currentHash]!.moveCount + 1;
        final nextStateMemo = _stateMemo[nextHash];
        if (nextStateMemo != null) {
          if (nextStateMemo.moveCount <= nextMoveCount) {
            continue;
          }
        }

        // add memo
        _stateMemo[nextHash] = StateMemo(
          robotPositionsHash: nextHash,
          moveCount: nextMoveCount,
          lastRobotPositionsHash: currentHash,
          lastMove: MoveRecord(color: robotColor, direction: direction),
        );

        // IsGoal
        if (board.isGoal(
          _robotPositions.positions[robotColor.index],
          Robot(color: robotColor),
        )) {
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
        final estimatedShortestMoveCount = nextMoveCount + _findShortestCount();
        if (estimatedShortestMoveCount > queueList.length) {
          continue;
        }
        queueList[estimatedShortestMoveCount].addLast(nextHash);
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
      // assert(_stateMemo.containsKey(current));
      final state = _stateMemo[current]!;
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

  int _findShortestCount() {
    int _count(RobotColors color) {
      final position = _robotPositions.positions[color.index];
      final memo = _shortestGoalMemo[position.x][position.y];
      var alreadyWall = memo.needRobot.isEmpty;
      if (!alreadyWall) {
        for (final robotPosition in _robotPositions.positions) {
          if (memo.needRobot.contains(robotPosition)) {
            alreadyWall = true;
            break;
          }
        }
      }
      return memo.shortestCount - 1 + (alreadyWall ? 0 : 1);
    }

    final goalColor = board.goal.color;
    int minCount = 1 << 30;
    if (goalColor == null) {
      for (final color in RobotColors.values) {
        minCount = min(minCount, _count(color));
      }
    } else {
      minCount = _count(goalColor);
    }
    return minCount;
  }

  void _moved({
    required RobotColors robotColor,
    required Directions direction,
  }) {
    var current = _robotPositions.positions[robotColor.index];
    final candidatesRobotPositions = [];
    // INFO: If you use map/where, it slows down
    for (final color in RobotColors.values) {
      if (color == robotColor) {
        continue;
      }
      final position = _robotPositions.positions[color.index];
      if (!current.isStraightDirection(position, direction)) {
        continue;
      }
      candidatesRobotPositions
          .add(position.next(Directions.values[(direction.index + 2) % 4]));
    }
    candidatesRobotPositions
        .add(_movedNext[current.x][current.y][direction.index]);
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
    _robotPositions.move(color: robotColor, to: toPosition);
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
