import 'package:flutter/foundation.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/board_builder.dart';
import 'package:ricochet_robots/domains/board/goal.dart';
import 'package:ricochet_robots/domains/board/grid.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:tuple/tuple.dart';

class BoardId {
  final String baseId;
  final String normalGoalId;
  final String wildGoalId;
  final String robotId;
  final String goalId;

  const BoardId({
    required this.baseId,
    required this.normalGoalId,
    required this.wildGoalId,
    required this.robotId,
    required this.goalId,
  });

  static BoardId from({required Board board}) {
    return BoardId(
      baseId: toBaseId(board: board),
      normalGoalId: toNormalGoalId(board: board),
      wildGoalId: toWildGoalId(board: board),
      robotId: toRobotId(board: board),
      goalId: toGoalId(board: board),
    );
  }

  String get encoded => to64based(
        from: baseId + normalGoalId + wildGoalId + robotId + goalId,
      );

  static const _baseIdStart = 0;
  static const _baseIdLength = rowLength * rowLength;
  static const _normalGoalIdStart = _baseIdStart + _baseIdLength;
  static const _normalGoalIdLength = 4 * 4 * 2;
  static const _wildGoalIdStart = _normalGoalIdStart + _normalGoalIdLength;
  static const _wildGoalIdLength = 2;
  static const _robotIdStart = _wildGoalIdStart + _wildGoalIdLength;
  static const _robotIdLength = 4 * 2;
  static const _goalIdStart = _robotIdStart + _robotIdLength;
  static const _goalIdLengthOldVersion = 2;
  static const _goalIdLength = 8;
  static const _idLength = _baseIdLength +
      _normalGoalIdLength +
      _wildGoalIdLength +
      _robotIdLength +
      _goalIdLength;

  static BoardId? tryParse({required String encoded}) {
    final is64based = encoded.split('').every((c) => base64Set.contains(c));
    if (!is64based) {
      return null;
    }
    final id = to16based(from: encoded);
    if (!(_idLength - (_goalIdLength - _goalIdLengthOldVersion) <= id.length &&
        id.length <= _idLength)) {
      return null;
    }
    return BoardId(
      baseId: id.substring(_baseIdStart, _baseIdStart + _baseIdLength),
      normalGoalId: id.substring(
          _normalGoalIdStart, _normalGoalIdStart + _normalGoalIdLength),
      wildGoalId:
          id.substring(_wildGoalIdStart, _wildGoalIdStart + _wildGoalIdLength),
      robotId: id.substring(_robotIdStart, _robotIdStart + _robotIdLength),
      goalId: id.substring(_goalIdStart).padRight(8, '9').substring(0, 8),
    );
  }
}

@visibleForTesting
String toBaseId({required Board board}) {
  return List.generate(rowLength, (y) {
    return List.generate(
      rowLength,
      (x) => toGridId(grid: board.grids.at(position: Position(x: x, y: y))),
    ).join();
  }).join();
}

@visibleForTesting
String toGridId({required Grid grid}) {
  return [
    Tuple2(grid.canMoveUp, canMoveUpBit),
    Tuple2(grid.canMoveRight, canMoveRightBit),
    Tuple2(grid.canMoveDown, canMoveDownBit),
    Tuple2(grid.canMoveLeft, canMoveLeftBit),
  ]
      .fold<int>(0, (value, pair) => pair.item1 ? (value | pair.item2) : value)
      .toRadixString(16);
}

String toNormalGoalId({required Board board}) {
  return List.generate(GoalTypes.values.length, (i) {
    return List.generate(
      RobotColors.values.length,
      (j) => toNormalGoalPositionId(
        board: board,
        goalType: GoalTypes.values[i],
        color: RobotColors.values[j],
      ),
    ).join();
  }).join();
}

String toNormalGoalPositionId({
  required Board board,
  required GoalTypes goalType,
  required RobotColors color,
}) {
  final position = List.generate(rowLength, (y) {
    return List.generate(rowLength, (x) {
      final grid = board.grids.at(position: Position(x: x, y: y));
      if (grid is NormalGoalGrid &&
          grid.color == color &&
          grid.type == goalType) {
        return Position(x: x, y: y);
      }
      return null;
    });
  }).expand((list) => list).whereType<Position>().firstWhere(
      ((element) => true),
      orElse: () => const Position(x: 0, y: 0));
  return positionToId(position: position);
}

String positionToId({required Position position}) =>
    position.x.toRadixString(16) + position.y.toRadixString(16);

String toWildGoalId({required Board board}) {
  final position = List.generate(rowLength, (y) {
    return List.generate(rowLength, (x) {
      final grid = board.grids.at(position: Position(x: x, y: y));
      if (grid is WildGoalGrid) {
        return Position(x: x, y: y);
      }
      return null;
    });
  }).expand((list) => list).whereType<Position>().first;
  return positionToId(position: position);
}

String toRobotId({required Board board}) {
  return RobotColors.values
      .map((color) =>
          positionToId(position: board.robotPositions.position(color: color)))
      .join();
}

String toGoalId({required Board board}) {
  return board.goals.map((goal) => _toGoalId(goal)).join().padRight(8, '9');
}

String _toGoalId(Goal goal) {
  final goalType = goal.type;
  final goalColor = goal.color;
  if (goalType == null && goalColor == null) {
    return '44';
  } else if (goalType == null || goalColor == null) {
    return '00';
  }
  return GoalTypes.values.indexOf(goalType).toString() +
      RobotColors.values.indexOf(goalColor).toString();
}

final boardIdChars = [
  /// '0' to '9'
  ...(List.generate(10, (i) => i.toString())),

  /// 'a' to 'z'
  ...(List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i))),

  /// 'A' to 'Z'
  ...(List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i))),

  '_',
  '-',
];

final base16Set = boardIdChars.take(16).toSet();
final base64Set = boardIdChars.toSet();

@visibleForTesting
String to64based({required String from}) {
  final is16based = from.split('').every((c) => base16Set.contains(c));
  assert(is16based);
  if (!is16based) {
    throw Exception('Failed to convert to 64based string');
  }
  var value = BigInt.parse(from, radix: 16);
  final result = List.empty(growable: true);
  while (value > BigInt.zero) {
    final i = value % BigInt.from(64);
    result.add(boardIdChars[i.toInt()]);
    value ~/= BigInt.from(64);
  }
  return result.reversed.join();
}

@visibleForTesting
String to16based({required String from}) {
  final is64based = from.split('').every((c) => base64Set.contains(c));
  assert(is64based);
  if (!is64based) {
    throw Exception('Failed to convert to 16based string');
  }
  var value = BigInt.zero;
  for (final char in from.split('')) {
    final i = boardIdChars.indexOf(char);
    assert(0 <= i && i < 64);
    value *= BigInt.from(64);
    value += BigInt.from(i);
  }
  return value.toRadixString(16);
}
