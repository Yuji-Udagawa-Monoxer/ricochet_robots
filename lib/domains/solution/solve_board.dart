import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
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
  final Set<Position> needRobot = {}; // or, empty => not need
  int otherRobotWallPriority = 1 << 30;

  ShortestGoalMemo({
    required this.current,
  });

  @override
  String toString() =>
      "$current $shortestCount $needRobot $otherRobotWallPriority";
}

class SolveBoard {
  Board board;

  final int searchFinishedCount;
  final bool isFinishedIfFound;
  final int searchOption;

  final List<MoveHistory> answers = [];

  static const int _searchMaxCount = 30;
  static const int _moveCountDigitValue = 4294967296; // 1 << 32

  final PriorityQueue<int> _queueMoveCountAndHash = PriorityQueue();
  final Map<int, StateMemo> _stateMemo = {};
  final RobotPositionsMutable _robotPositions = RobotPositionsMutable.init;
  final List<List<List<Position>>> _movedNext;
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
        isFinishedIfFound = searchFinishedCount < 0,
        searchOption = searchFinishedCount == -2 ? 1 : 0,
        _movedNext = board.makeMovedNext;

  List<MoveHistory> solve() {
    stopwatch.start();
    _init();
    _solve();
    stopwatch.stop();
    _resultLog();
    return answers;
  }

  void _init() {
    _makeShortestGoalMemo();

    _robotPositions.set(board.robotPositions);
    final startRobotPositionsHash = _robotPositions.toHash();

    _addStateMemo(_robotPositions, startRobotPositionsHash, 0, null, null);

    _addToQueueMoveCountAndHash(0, startRobotPositionsHash, 0);
  }

  void _makeShortestGoalMemo() {
    final Queue<Position> queue = Queue();
    // TODO GOALS
    final goalColor = board.goals[0].color ?? RobotColors.red;

    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        final position = Position(x: x, y: y);
        if (board.isGoalOne(position, Robot(color: goalColor))) {
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
          if (nextMemo.shortestCount > memo.shortestCount + 1 ||
              (nextMemo.shortestCount == memo.shortestCount + 1 &&
                  nextMemo.needRobot.isNotEmpty)) {
            if (need == null) {
              if (memo.needRobot.isEmpty) {
                nextMemo.needRobot.clear();
              } else {
                nextMemo.needRobot.addAll(memo.needRobot);
              }
            } else {
              nextMemo.needRobot.add(need); // or memo.needRobot
            }
          }
          if (nextMemo.shortestCount > memo.shortestCount + 1) {
            nextMemo.shortestCount = memo.shortestCount + 1;
            queue.add(current);
          }
        }
      }
    }

    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        final memo = _shortestGoalMemo[x][y];
        if (memo.needRobot.isEmpty) {
          memo.otherRobotWallPriority = 0;
          queue.add(memo.current);
        }
      }
    }
    while (queue.isNotEmpty) {
      final firstPosition = queue.removeFirst();
      final memo = _shortestGoalMemo[firstPosition.x][firstPosition.y];
      for (final direction in Directions.values) {
        if (!board.grids.grids[memo.current.y][memo.current.x]
            .canMove(direction)) {
          continue;
        }
        final nextPosition = firstPosition.next(direction);
        final nextMemo = _shortestGoalMemo[nextPosition.x][nextPosition.y];
        if (nextMemo.otherRobotWallPriority > memo.otherRobotWallPriority + 1) {
          nextMemo.otherRobotWallPriority = memo.otherRobotWallPriority + 1;
          queue.add(nextPosition);
        }
      }
    }
  }

  void _addToQueueMoveCountAndHash(
      int moveCount, int robotPositionhash, int priority) {
    if (moveCount <= searchFinishedCount) {
      _queueMoveCountAndHash
          .add((priority * _moveCountDigitValue) + robotPositionhash);
    }
  }

  void _solve() {
    while (_queueMoveCountAndHash.isNotEmpty) {
      final hash = _queueMoveCountAndHash.removeFirst() % _moveCountDigitValue;
      _solveInner(hash);
    }
  }

  void _solveInner(int currentHash) {
    // assert(_stateMemo.containsKey(currentHash));

    ++searchStateNum;

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
        final currentMoveCount = _stateMemo[currentHash]!.moveCount;
        final nextMoveCount = currentMoveCount + 1;
        if (_getNextHashStateMemoMoveCount(_robotPositions, nextHash) <=
            nextMoveCount) {
          continue;
        }

        // add memo
        _addStateMemo(_robotPositions, nextHash, nextMoveCount, currentHash,
            MoveRecord(color: robotColor, direction: direction));

        // IsGoals
        if (board.isGoals(_robotPositions.positions)) {
          final newHistory = _makeMoveHistory(nextHash);
          if (_isDifferentHistory(newHistory)) {
            answers.add(newHistory);
            if (isFinishedIfFound) {
              _queueMoveCountAndHash.clear();
              return;
            }
          }
          continue;
        }

        // add nextSearch
        final estimatedShortestMoveCount = nextMoveCount +
            _findShortestCount(searchFinishedCount - nextMoveCount);
        final priority = estimatedShortestMoveCount +
            (((searchOption & 1) == 1) ? _calcPriority(_robotPositions) : 0);
        _addToQueueMoveCountAndHash(
            estimatedShortestMoveCount, nextHash, priority);
      }
    }
  }

  int _calcPriority(RobotPositionsMutable robotPosition) {
    int otherRobotPoint = 10;
    for (final color in RobotColors.values) {
      // TODO GOALS
      if (color != board.goals[0].color) {
        final position = robotPosition.positions[color.index];
        final memo = _shortestGoalMemo[position.x][position.y];
        if (memo.otherRobotWallPriority > 0) {
          otherRobotPoint = min(otherRobotPoint, memo.otherRobotWallPriority);
        }
      }
    }
    return otherRobotPoint;
  }

  int _getNextHashStateMemoMoveCount(
      RobotPositionsMutable robotPosition, int nextHash) {
    final nextStateMemo = _stateMemo[nextHash];
    return nextStateMemo != null ? nextStateMemo.moveCount : 1 << 30;
  }

  void _addStateMemo(RobotPositionsMutable robotPosition, int nextHash,
      int nextMoveCount, int? currentHash, MoveRecord? lastMoveRecord) {
    _stateMemo[nextHash] = StateMemo(
      robotPositionsHash: nextHash,
      moveCount: nextMoveCount,
      lastRobotPositionsHash: currentHash,
      lastMove: lastMoveRecord,
    );
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

  int _findShortestCount(int leftMoveCount) {
    int _count(RobotColors color) {
      final position = _robotPositions.positions[color.index];
      final memo = _shortestGoalMemo[position.x][position.y];
      var alreadyWall = true;
      if (isFinishedIfFound || memo.shortestCount == leftMoveCount) {
        if (memo.needRobot.isNotEmpty) {
          alreadyWall = false;
          for (final robotPosition in _robotPositions.positions) {
            if (memo.needRobot.contains(robotPosition)) {
              alreadyWall = true;
              break;
            }
          }
        }
      }
      return memo.shortestCount + (alreadyWall ? 0 : 1);
    }

    // TODO GOALS
    final goalColor = board.goals[0].color;
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
    for (final answer in answers) {
      debugPrint(answer.toString());
    }
  }

  List<MoveHistory> sample() => [
        MoveHistory(records: [
          const MoveRecord(
            color: RobotColors.green,
            direction: Directions.down,
          ),
          const MoveRecord(
            color: RobotColors.red,
            direction: Directions.up,
          ),
        ]),
        MoveHistory(records: [
          const MoveRecord(
            color: RobotColors.blue,
            direction: Directions.right,
          ),
          const MoveRecord(
            color: RobotColors.blue,
            direction: Directions.left,
          ),
          const MoveRecord(
            color: RobotColors.yellow,
            direction: Directions.up,
          ),
        ]),
      ];
}
