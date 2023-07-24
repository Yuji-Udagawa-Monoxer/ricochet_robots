import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/grids.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';

part 'robot_positions.freezed.dart';

@freezed
class RobotPositions with _$RobotPositions {
  const RobotPositions._();

  const factory RobotPositions({
    required Position red,
    required Position blue,
    required Position green,
    required Position yellow,
  }) = _RobotPositions;

  static RobotPositions random({required Grids grids}) {
    final red = Position.random(grids: grids, used: {});
    final blue = Position.random(grids: grids, used: {red});
    final green = Position.random(grids: grids, used: {red, blue});
    final yellow = Position.random(grids: grids, used: {red, blue, green});
    return RobotPositions(red: red, blue: blue, green: green, yellow: yellow);
  }

  Position position({required RobotColors color}) {
    switch (color) {
      case RobotColors.red:
        return red;
      case RobotColors.blue:
        return blue;
      case RobotColors.green:
        return green;
      case RobotColors.yellow:
        return yellow;
    }
  }

  List<Position> get positions => [red, blue, green, yellow];

  Set<Position> others({required RobotColors color}) => RobotColors.values
      .where((c) => c != color)
      .map((c) => position(color: c))
      .toSet();

  RobotPositions movedAsPossible({
    required Board board,
    required Robot robot,
    required Directions direction,
  }) {
    final current = position(color: robot.color);
    final otherRobotPositions = others(color: robot.color);
    if (!board.grids.at(position: current).canMove(direction)) {
      return this;
    }
    final nextPosition = current.next(direction);
    final canMoveOpposite = board.grids
        .at(position: nextPosition)
        .canMove(opposite(direction: direction));
    if (otherRobotPositions.contains(nextPosition) || !canMoveOpposite) {
      return this;
    }
    return move(color: robot.color, to: nextPosition).movedAsPossible(
      board: board,
      robot: robot,
      direction: direction,
    );
  }

  RobotPositions movedAsPossibleLight({
    required Board board,
    required Robot robot,
    required Directions direction,
    required bool isCollideOtherRobot,
  }) {
    var current = position(color: robot.color);
    var nextPosition = current.next(direction);
    final otherRobotPositions = RobotColors.values
        .where((c) => c != robot.color)
        .map((c) => position(color: c))
        .where((position) => current.isStraightDirection(position, direction));

    bool _canMove(Position current, Position nextPosition) {
      return board.grids.at(position: current).canMove(direction) &&
          (!isCollideOtherRobot || !otherRobotPositions.contains(nextPosition));
      /* final canMoveOpposite = board.grids
        .at(position: nextPosition)
        .canMove(opposite(direction: direction)); */
    }

    if (!_canMove(current, nextPosition)) {
      return this;
    }

    do {
      final tmpPosition = current.next(direction);
      current = nextPosition;
      nextPosition = tmpPosition;
    } while (_canMove(current, nextPosition));

    return move(color: robot.color, to: current);
  }

  RobotPositions move({required RobotColors color, required Position to}) {
    return RobotPositions(
      red: color == RobotColors.red ? to : red,
      blue: color == RobotColors.blue ? to : blue,
      green: color == RobotColors.green ? to : green,
      yellow: color == RobotColors.yellow ? to : yellow,
    );
  }

  RobotPositions swap(Position a, Position b) {
    return copyWith(
      red: red == a ? b : (red == b ? a : red),
      blue: blue == a ? b : (blue == b ? a : blue),
      green: green == a ? b : (green == b ? a : green),
      yellow: yellow == a ? b : (yellow == b ? a : yellow),
    );
  }

  RobotPositions get rotateRight {
    return copyWith(
      red: red.rotateRight,
      blue: blue.rotateRight,
      green: green.rotateRight,
      yellow: yellow.rotateRight,
    );
  }

  static int toHash(RobotPositions positions) {
    int hash = 0;
    hash = (hash << 4) + positions.red.x;
    hash = (hash << 4) + positions.red.y;
    hash = (hash << 4) + positions.blue.x;
    hash = (hash << 4) + positions.blue.y;
    hash = (hash << 4) + positions.green.x;
    hash = (hash << 4) + positions.green.y;
    hash = (hash << 4) + positions.yellow.x;
    hash = (hash << 4) + positions.yellow.y;
    return hash;
  }

  static RobotPositions fromHash(int hash) {
    return RobotPositions(
      red: Position(
        x: (hash >> 28) % 16,
        y: (hash >> 24) % 16,
      ),
      blue: Position(
        x: (hash >> 20) % 16,
        y: (hash >> 16) % 16,
      ),
      green: Position(
        x: (hash >> 12) % 16,
        y: (hash >> 8) % 16,
      ),
      yellow: Position(
        x: (hash >> 4) % 16,
        y: (hash >> 0) % 16,
      ),
    );
  }

  Robot? getRobotIfExists({required Position position}) {
    if (position == red) {
      return Robot.red;
    }
    if (position == blue) {
      return Robot.blue;
    }
    if (position == green) {
      return Robot.green;
    }
    if (position == yellow) {
      return Robot.yellow;
    }
    return null;
  }
}
