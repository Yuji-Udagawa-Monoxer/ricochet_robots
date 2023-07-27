import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ricochet_robots/domains/board/board_quarter.dart';
import 'package:ricochet_robots/domains/board/defaultBoards/green/boards.dart';
import 'package:ricochet_robots/domains/board/defaultBoards/red/boards.dart';
import 'package:ricochet_robots/domains/board/defaultBoards/yellow/boards.dart';
import 'package:ricochet_robots/domains/board/goal.dart';
import 'package:ricochet_robots/domains/board/grid.dart';
import 'package:ricochet_robots/domains/board/grids.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/board/robot_positions.dart';

import 'defaultBoards/blue/boards.dart';

part 'board.freezed.dart';

@freezed
class Board with _$Board {
  const factory Board({
    required Grids grids,
    required List<Goal> goals,
    required RobotPositions robotPositions,
  }) = _Board;

  const Board._();

  static Board init({
    required Grids grids,
    required List<Goal> goals,
    RobotPositions? robotPositions,
  }) {
    return Board(
      grids: grids,
      goals: goals.isEmpty ? [Goal.random] : goals,
      robotPositions: robotPositions ?? RobotPositions.random(grids: grids),
    );
  }

  static Board random(int shuffleGridCount, int goalNumForNewBoard) {
    return synthesize(
      boardQuarterRed: randomRedBoard(),
      boardQuarterBlue: randomBlueBoard(),
      boardQuarterGreen: randomGreenBoard(),
      boardQuarterYellow: randomYellowBoard(),
      shuffleGridCount: shuffleGridCount,
      goalNumForNewBoard: goalNumForNewBoard,
    );
  }

  static Board synthesize({
    required BoardQuarterRed boardQuarterRed,
    required BoardQuarterBlue boardQuarterBlue,
    required BoardQuarterGreen boardQuarterGreen,
    required BoardQuarterYellow boardQuarterYellow,
    int shuffleGridCount = 0,
    int goalNumForNewBoard = 1,
  }) {
    final boardQuarters = [
      boardQuarterRed,
      boardQuarterBlue,
      boardQuarterGreen,
      boardQuarterYellow
    ]..shuffle();

    /// TODO: refactoring
    final topLeftGrids = boardQuarters[0].gridsQuarter.grids;
    final topRightGrids = boardQuarters[1].rotateRight.gridsQuarter.grids;
    final bottomRightGrids =
        boardQuarters[2].rotateRight.rotateRight.gridsQuarter.grids;
    final bottomLeftGrids =
        boardQuarters[3].rotateRight.rotateRight.rotateRight.gridsQuarter.grids;
    final leftHalfGrids = topLeftGrids + bottomLeftGrids;
    final rightHalfGrids = topRightGrids + bottomRightGrids;

    var newGrids = Grids(
      grids: fixQuarterBorder(
        List.generate(leftHalfGrids.length, (y) {
          return leftHalfGrids[y] + rightHalfGrids[y];
        }),
      ),
    );

    for (var i = 0; i < shuffleGridCount; ++i) {
      final nextGrids = newGrids.shuffleGrid();
      if (nextGrids == null) {
        --i;
      } else {
        newGrids = nextGrids;
      }
    }

    List<Goal> goals = [];
    for (var i = 0; i < goalNumForNewBoard; ++i) {
      final goalCandidate = Goal.random;
      if (goals.any((goal) => goal.color == goalCandidate.color)) {
        --i;
      } else {
        goals.add(goalCandidate);
      }
    }

    return init(
      grids: newGrids,
      goals: goals,
    );
  }

  static List<List<Grid>> fixQuarterBorder(List<List<Grid>> grids) {
    final halfLengthY = (grids.length / 2).floor();
    return List.generate(grids.length, (y) {
      final halfLengthX = (grids[y].length / 2).floor();
      return List.generate(grids[y].length, (x) {
        if (y == halfLengthY - 1) {
          return grids[y][x].setCanMove(
            directions: Directions.down,
            canMove: grids[y][x].canMoveDown && grids[y + 1][x].canMoveUp,
          );
        }
        if (y == halfLengthY) {
          return grids[y][x].setCanMove(
            directions: Directions.up,
            canMove: grids[y - 1][x].canMoveDown && grids[y][x].canMoveUp,
          );
        }
        if (x == halfLengthX - 1) {
          return grids[y][x].setCanMove(
            directions: Directions.right,
            canMove: grids[y][x].canMoveRight && grids[y][x + 1].canMoveLeft,
          );
        }
        if (x == halfLengthX) {
          return grids[y][x].setCanMove(
            directions: Directions.left,
            canMove: grids[y][x - 1].canMoveRight && grids[y][x].canMoveLeft,
          );
        }
        return grids[y][x];
      });
    });
  }

  Board moved(Robot robot, Directions direction) {
    return copyWith(
      robotPositions: robotPositions.movedAsPossible(
        board: this,
        robot: robot,
        direction: direction,
      ),
    );
  }

  Board movedLight({
    required Robot robot,
    required Directions direction,
    isCoolideOtherOrbot = true,
  }) {
    return copyWith(
      robotPositions: robotPositions.movedAsPossibleLight(
        board: this,
        robot: robot,
        direction: direction,
        isCollideOtherRobot: isCoolideOtherOrbot,
      ),
    );
  }

  Board movedTo(Robot robot, Position position) {
    return copyWith(
      robotPositions: robotPositions.move(color: robot.color, to: position),
    );
  }

  bool isGoals(List<Position> positions) {
    return goals.every(
      (goal) => RobotColors.values.any(
        (color) => _isGoal(goal, positions[color.index], Robot(color: color)),
      ),
    );
  }

  bool isGoalOne(Position position, Robot robot) {
    return goals.any((goal) => _isGoal(goal, position, robot));
  }

  bool _isGoal(Goal goal, Position position, Robot robot) {
    return grids.at(position: position).isGoal(goal, robot);
  }

  bool hasRobotOnGrid(Position position) =>
      robotPositions.getRobotIfExists(position: position) != null;

  bool hasGoalOnGrid(Position position) =>
      getGoalGridIfExists(position) != null;

  GoalGrid? getGoalGridIfExists(Position position) {
    final grid = grids.at(position: position);
    if (grid is NormalGoalGrid) {
      return grid;
    }
    if (grid is WildGoalGrid) {
      return grid;
    }
    return null;
  }

  Robot? getRobotIfExists({required Position position}) =>
      robotPositions.getRobotIfExists(position: position);

  Board get goalShuffled {
    return copyWith(goals: [Goal.random]);
  }

  Board get robotShuffled {
    return copyWith(robotPositions: RobotPositions.random(grids: grids));
  }

  List<List<List<Position>>> get makeMovedNext {
    final List<List<List<Position>>> moveNext = List.generate(
      16,
      (x) => List.generate(
        16,
        (y) => List.generate(
          Directions.values.length,
          (direction) => Position(x: x, y: y),
        ),
      ),
    );

    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        for (final direction in Directions.values) {
          final board = copyWith(
            robotPositions: robotPositions.copyWith(
              red: Position(x: x, y: y),
              blue: const Position(x: 16, y: 16),
              green: const Position(x: 16, y: 16),
              yellow: const Position(x: 16, y: 16),
            ),
          );
          final nextBoard = board.movedLight(
            robot: const Robot(color: RobotColors.red),
            direction: direction,
          );
          moveNext[x][y][direction.index] =
              nextBoard.robotPositions.red.copyWith();
        }
      }
    }
    return moveNext;
  }

  String get toBoardText {
    final List<int> output = [];

    for (final goal in goals) {
      for (var x = 0; x < 16; ++x) {
        for (var y = 0; y < 16; ++y) {
          final goalGrid = getGoalGridIfExists(Position(x: x, y: y));
          final robot =
              Robot(color: goal.color == null ? RobotColors.red : goal.color!);
          if (goalGrid != null && goalGrid.isGoal(goal, robot)) {
            output.add(x);
            output.add(y);

            int colorHex(color) {
              return (goal.color == color || goal.color == null) ? 1 : 0;
            }

            var goalColor = 0;
            goalColor = (goalColor << 1) + colorHex(RobotColors.yellow);
            goalColor = (goalColor << 1) + colorHex(RobotColors.green);
            goalColor = (goalColor << 1) + colorHex(RobotColors.blue);
            goalColor = (goalColor << 1) + colorHex(RobotColors.red);
            output.add(goalColor);
            break;
          }
        }
      }
    }
    while (output.length < 12) {
      output.add(0);
    }

    output.add(robotPositions.red.x);
    output.add(robotPositions.red.y);
    output.add(robotPositions.blue.x);
    output.add(robotPositions.blue.y);
    output.add(robotPositions.green.x);
    output.add(robotPositions.green.y);
    output.add(robotPositions.yellow.x);
    output.add(robotPositions.yellow.y);

    final moveNext = makeMovedNext;
    for (var x = 0; x < 16; ++x) {
      for (var y = 0; y < 16; ++y) {
        for (final direction in Directions.values) {
          output.add(moveNext[x][y][direction.index].x);
          output.add(moveNext[x][y][direction.index].y);
        }
      }
    }

    return output.map((c) => c.toRadixString(16)).join();
  }
}
