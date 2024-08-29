import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/grid.dart';
import 'package:ricochet_robots/domains/board/move_history.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
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

enum _RobotGoalType {
  none,
  normal,
  wild,
}

class ShortestGoalMemo {
  final RobotColors color;
  final Position current;
  int shortestCount = 1 << 30;

  ShortestGoalMemo({
    required this.color,
    required this.current,
  });

  @override
  String toString() => "$color $current $shortestCount";
}

class SolveBoard {
  Board board;

  final int searchFinishedCount;
  final bool isFinishedIfFound;

  final List<MoveHistory> answers = [];

  static const int _searchMaxCount = 30;
  static const int _moveCountDigitValue = 4294967296; // 1 << 32

  final PriorityQueue<int> _queueMoveCountAndHash = PriorityQueue();
  final Map<int, StateMemo> _stateMemo = {};
  final RobotPositionsMutable _robotPositions = RobotPositionsMutable.init;
  final List<List<List<Position>>> _movedNext;
  final List<_RobotGoalType> _robotGoalType =
      List.generate(RobotColors.values.length, (index) => _RobotGoalType.none);
  final List<List<List<ShortestGoalMemo>>> _shortestGoalMemo = List.generate(
    RobotColors.values.length,
    (colorIndex) => List.generate(
      16,
      (x) => List.generate(
        16,
        (y) => ShortestGoalMemo(
          color: RobotColors.values[colorIndex],
          current: Position(x: x, y: y),
        ),
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
        _movedNext = board.makeMovedNext;

  List<MoveHistory> solve({bool isLog = true}) {
    stopwatch.start();
    _init();
    _solve();
    stopwatch.stop();
    if (isLog) _resultLog();
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
    final startPositions = List.generate(
      RobotColors.values.length,
      (index) => Position.invalid,
    );

    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        final position = Position(x: x, y: y);
        if (board.grids.at(position: position) is WildGoalGrid) {
          if (board.isGoalOne(position, const Robot(color: RobotColors.red))) {
            for (final goalColor in RobotColors.values) {
              startPositions[goalColor.index] = position;
              _robotGoalType[goalColor.index] = _RobotGoalType.wild;
            }
          }
        }
      }
    }

    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        final position = Position(x: x, y: y);
        if (board.grids.at(position: position) is NormalGoalGrid) {
          for (final goalColor in RobotColors.values) {
            if (board.isGoalOne(position, Robot(color: goalColor))) {
              startPositions[goalColor.index] = position;
              _robotGoalType[goalColor.index] = _RobotGoalType.normal;
            }
          }
        }
      }
    }

    for (final goalColor in RobotColors.values) {
      final position = startPositions[goalColor.index];
      if (!position.isInvalid) {
        _makeShortestGoalMemoInner(goalColor, position);
      }
    }
  }

  void _makeShortestGoalMemoInner(
    RobotColors goalColor,
    Position startPosition,
  ) {
    final Queue<Position> queue = Queue();
    _shortestGoalMemo[goalColor.index][startPosition.x][startPosition.y]
        .shortestCount = 0;
    queue.add(startPosition);

    while (queue.isNotEmpty) {
      final firstPosition = queue.removeFirst();
      final memo =
          _shortestGoalMemo[goalColor.index][firstPosition.x][firstPosition.y];

      _robotPositions.setOneColor(goalColor, firstPosition);

      for (final direction in Directions.values) {
        var current = firstPosition;
        while (board.grids.grids[current.y][current.x].canMove(direction)) {
          current = current.next(direction);
          final nextMemo =
              _shortestGoalMemo[goalColor.index][current.x][current.y];
          if (nextMemo.shortestCount > memo.shortestCount + 1) {
            nextMemo.shortestCount = memo.shortestCount + 1;
            queue.add(current);
          }
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
          // debugPrint("candidate: ${newHistory.toString()}");
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
        _addToQueueMoveCountAndHash(
            estimatedShortestMoveCount, nextHash, estimatedShortestMoveCount);
      }
    }
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
      final memo = _shortestGoalMemo[color.index][position.x][position.y];
      return memo.shortestCount;
    }

    int wildCount = 1 << 30;
    int sumNormalCount = 0;
    for (final color in RobotColors.values) {
      switch (_robotGoalType[color.index]) {
        case _RobotGoalType.none:
          break;
        case _RobotGoalType.normal:
          sumNormalCount += _count(color);
          break;
        case _RobotGoalType.wild:
          wildCount = min(wildCount, _count(color));
          break;
      }
    }
    return (wildCount == 1 << 30 ? 0 : wildCount) + sumNormalCount;
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
