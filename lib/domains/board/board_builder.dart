import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/board_id.dart';
import 'package:ricochet_robots/domains/board/goal.dart';
import 'package:ricochet_robots/domains/board/grid.dart';
import 'package:ricochet_robots/domains/board/grids.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/board/robot_positions.dart';
import 'package:tuple/tuple.dart';

import 'grids.dart';

Board toBoard({required BoardId boardId}) => Board(
      grids: toGrids(boardId: boardId),
      robotPositions: toRobotPositions(boardId: boardId),
      goals: toGoals(boardId: boardId),
    );

@visibleForTesting
Grids toGrids({required BoardId boardId}) {
  final baseGrids = addEdges(grids: toNormalGrids(id: boardId.baseId));
  final gridsWithNormalGoal = putNormalGoals(
    baseGrids: baseGrids,
    normalGoalId: boardId.normalGoalId,
  );
  final grids = putWildGoalGrid(
    grids: gridsWithNormalGoal,
    wildGoalId: boardId.wildGoalId,
  );
  return Grids(grids: grids);
}

const canMoveUpBit = 1 << 0;
const canMoveRightBit = 1 << 1;
const canMoveDownBit = 1 << 2;
const canMoveLeftBit = 1 << 3;

const rowLength = 16;

@visibleForTesting
List<List<NormalGrid>> toNormalGrids({required String id}) {
  return intoChunks(id: id, chunkSize: rowLength)
      .map((id) => toNormalGridRow(id: id))
      .toList();
}

@visibleForTesting
List<String> intoChunks({
  required String id,
  required int chunkSize,
  List<String> result = const [],
}) {
  if (id.length <= chunkSize) {
    return [...result, id];
  }
  return intoChunks(
    id: id.substring(chunkSize),
    chunkSize: chunkSize,
    result: [...result, id.substring(0, chunkSize)],
  );
}

List<NormalGrid> toNormalGridRow({required String id}) {
  assert(id.length == 16);
  return id.split('').map((char) => charToNormalGrid(char: char)).toList();
}

@visibleForTesting
NormalGrid charToNormalGrid({required String char}) {
  final value = boardIdChars.indexOf(char);
  if (value < 0 || rowLength <= value) {
    /// Unexpected.
    return NormalGrid();
  }
  return NormalGrid(
    canMoveUp: value & canMoveUpBit > 0,
    canMoveRight: value & canMoveRightBit > 0,
    canMoveDown: value & canMoveDownBit > 0,
    canMoveLeft: value & canMoveLeftBit > 0,
  );
}

@visibleForTesting
List<List<NormalGrid>> addEdges({required List<List<NormalGrid>> grids}) {
  return List.generate(rowLength, (y) {
    return List.generate(rowLength, (x) {
      final grid = grids[y][x];
      return NormalGrid(
        canMoveUp: grid.canMoveUp && y - 1 >= 0,
        canMoveRight: grid.canMoveRight && x + 1 < 16,
        canMoveDown: grid.canMoveDown && y + 1 < 16,
        canMoveLeft: grid.canMoveLeft && x - 1 >= 0,
      );
    });
  });
}

@visibleForTesting
List<List<Grid>> putNormalGoals({
  required List<List<NormalGrid>> baseGrids,
  required String normalGoalId,
}) {
  return getNormalGoalPositions(normalGoalId: normalGoalId)
      .fold<List<List<Grid>>>(baseGrids, (grids, tuple) {
    return putNormalGoalGrid(
      grids: grids,
      goalType: tuple.item1,
      color: tuple.item2,
      position: tuple.item3,
    );
  });
}

@visibleForTesting
List<Tuple3<GoalTypes, RobotColors, Position>> getNormalGoalPositions({
  required String normalGoalId,
}) {
  return List.generate(GoalTypes.values.length, (i) {
    return List.generate(RobotColors.values.length, (j) {
      final start = (i * RobotColors.values.length + j) * 2;
      return Tuple3(
        GoalTypes.values[i],
        RobotColors.values[j],
        getPosition(id: normalGoalId.substring(start, start + 2)),
      );
    });
  }).expand((list) => list).toList();
}

@visibleForTesting
Position getPosition({required String id}) {
  assert(id.length == 2);
  final x = boardIdChars.indexOf(id[0]);
  final y = boardIdChars.indexOf(id[1]);
  assert(0 <= x && x < rowLength);
  assert(0 <= y && y < rowLength);
  return Position(x: x, y: y);
}

List<List<Grid>> putNormalGoalGrid({
  required List<List<Grid>> grids,
  required RobotColors color,
  required GoalTypes goalType,
  required Position position,
}) {
  return List.generate(rowLength, (y) {
    return List.generate(rowLength, (x) {
      if (position.x != x || position.y != y) {
        return grids[y][x];
      }
      return NormalGoalGrid(
        type: goalType,
        color: color,
        canMoveUp: grids[y][x].canMoveUp,
        canMoveRight: grids[y][x].canMoveRight,
        canMoveDown: grids[y][x].canMoveDown,
        canMoveLeft: grids[y][x].canMoveLeft,
      );
    });
  });
}

List<List<Grid>> putWildGoalGrid({
  required List<List<Grid>> grids,
  required String wildGoalId,
}) {
  final position = getPosition(id: wildGoalId);
  return List.generate(rowLength, (y) {
    return List.generate(rowLength, (x) {
      if (position.x != x || position.y != y) {
        return grids[y][x];
      }
      return WildGoalGrid(
        canMoveUp: grids[y][x].canMoveUp,
        canMoveRight: grids[y][x].canMoveRight,
        canMoveDown: grids[y][x].canMoveDown,
        canMoveLeft: grids[y][x].canMoveLeft,
      );
    });
  });
}

RobotPositions toRobotPositions({required BoardId boardId}) {
  final positions = List.generate(
    RobotColors.values.length,
    (i) => getPosition(id: boardId.robotId.substring(i * 2, i * 2 + 2)),
  );
  return RobotPositions(
    red: positions[0],
    blue: positions[1],
    green: positions[2],
    yellow: positions[3],
  );
}

List<Goal> toGoals({required BoardId boardId}) {
  final goalIds = List.generate(
    boardId.goalId.length ~/ 2,
    (index) => boardId.goalId.substring(index * 2, (index + 1) * 2),
  );
  return goalIds.map((goalId) => _toGoal(goalId)).whereType<Goal>().toList();
}

Goal? _toGoal(String goalId) {
  final goalIndex = int.tryParse(goalId[0]);
  final colorIndex = int.tryParse(goalId[1]);
  if (goalIndex == 4 && colorIndex == 4) {
    return const Goal();
  }
  if (goalIndex == null ||
      goalIndex < 0 ||
      GoalTypes.values.length <= goalIndex) {
    return null;
  }
  if (colorIndex == null ||
      colorIndex < 0 ||
      RobotColors.values.length <= colorIndex) {
    return null;
  }
  return Goal(
    type: GoalTypes.values[goalIndex],
    color: RobotColors.values[colorIndex],
  );
}
