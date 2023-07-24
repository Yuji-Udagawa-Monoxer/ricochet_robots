import 'package:ricochet_robots/domains/board/goal.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';

abstract class Rotatable {
  Grid get rotateRight;
  Grid copyWithCanMoveOnly(Grid grid);
  Grid copyWith({
    bool? canMoveUp,
    bool? canMoveRight,
    bool? canMoveDown,
    bool? canMoveLeft,
  });
}

abstract class Grid implements Rotatable {
  final bool canMoveUp;
  final bool canMoveRight;
  final bool canMoveDown;
  final bool canMoveLeft;

  const Grid({
    this.canMoveUp = false,
    this.canMoveRight = false,
    this.canMoveDown = false,
    this.canMoveLeft = false,
  });

  bool canMove(Directions directions) {
    switch (directions) {
      case Directions.up:
        return canMoveUp;
      case Directions.right:
        return canMoveRight;
      case Directions.down:
        return canMoveDown;
      case Directions.left:
        return canMoveLeft;
    }
  }

  bool isGoal(Goal goal, Robot robot) => false;

  bool get canPlaceRobot {
    if (this is! NormalGrid) {
      return false;
    }
    return canMoveUp || canMoveRight || canMoveDown || canMoveLeft;
  }

  /// Use for center grid.
  bool get isInactiveGrid {
    return (this is NormalGrid) &&
        !canMoveUp &&
        !canMoveRight &&
        !canMoveDown &&
        !canMoveLeft;
  }

  Grid setCanMove({
    required Directions directions,
    required bool canMove,
  });
}

class NormalGrid extends Grid {
  const NormalGrid({
    bool canMoveUp = true,
    bool canMoveDown = true,
    bool canMoveLeft = true,
    bool canMoveRight = true,
  }) : super(
          canMoveUp: canMoveUp,
          canMoveRight: canMoveRight,
          canMoveDown: canMoveDown,
          canMoveLeft: canMoveLeft,
        );

  @override
  NormalGrid get rotateRight => NormalGrid(
        canMoveUp: canMoveLeft,
        canMoveRight: canMoveUp,
        canMoveDown: canMoveRight,
        canMoveLeft: canMoveDown,
      );

  @override
  NormalGrid copyWithCanMoveOnly(Grid grid) {
    return NormalGrid(
      canMoveUp: grid.canMoveUp,
      canMoveRight: grid.canMoveRight,
      canMoveDown: grid.canMoveDown,
      canMoveLeft: grid.canMoveLeft,
    );
  }

  @override
  NormalGrid setCanMove({
    required Directions directions,
    required bool canMove,
  }) {
    return NormalGrid(
      canMoveUp: directions == Directions.up ? canMove : canMoveUp,
      canMoveRight: directions == Directions.right ? canMove : canMoveRight,
      canMoveDown: directions == Directions.down ? canMove : canMoveDown,
      canMoveLeft: directions == Directions.left ? canMove : canMoveLeft,
    );
  }

  @override
  NormalGrid copyWith({
    bool? canMoveUp,
    bool? canMoveRight,
    bool? canMoveDown,
    bool? canMoveLeft,
  }) {
    return NormalGrid(
      canMoveUp: canMoveUp ?? this.canMoveUp,
      canMoveRight: canMoveRight ?? this.canMoveRight,
      canMoveDown: canMoveDown ?? this.canMoveDown,
      canMoveLeft: canMoveLeft ?? this.canMoveLeft,
    );
  }
}

abstract class GoalGrid extends Grid {
  const GoalGrid({
    required bool canMoveUp,
    required bool canMoveDown,
    required bool canMoveLeft,
    required bool canMoveRight,
  }) : super(
          canMoveUp: canMoveUp,
          canMoveRight: canMoveRight,
          canMoveDown: canMoveDown,
          canMoveLeft: canMoveLeft,
        );
}

class NormalGoalGrid extends GoalGrid {
  final RobotColors color;
  final GoalTypes type;

  const NormalGoalGrid({
    required this.color,
    required this.type,
    bool canMoveUp = true,
    bool canMoveDown = true,
    bool canMoveLeft = true,
    bool canMoveRight = true,
  }) : super(
          canMoveUp: canMoveUp,
          canMoveRight: canMoveRight,
          canMoveDown: canMoveDown,
          canMoveLeft: canMoveLeft,
        );

  @override
  bool isGoal(Goal goal, Robot robot) {
    return goal.color == color && goal.type == type && robot.color == color;
  }

  @override
  NormalGoalGrid get rotateRight => NormalGoalGrid(
        color: color,
        type: type,
        canMoveUp: canMoveLeft,
        canMoveRight: canMoveUp,
        canMoveDown: canMoveRight,
        canMoveLeft: canMoveDown,
      );

  @override
  NormalGoalGrid copyWithCanMoveOnly(Grid grid) {
    return NormalGoalGrid(
      color: color,
      type: type,
      canMoveUp: grid.canMoveUp,
      canMoveRight: grid.canMoveRight,
      canMoveDown: grid.canMoveDown,
      canMoveLeft: grid.canMoveLeft,
    );
  }

  @override
  NormalGoalGrid setCanMove({
    required Directions directions,
    required bool canMove,
  }) {
    return NormalGoalGrid(
      color: color,
      type: type,
      canMoveUp: directions == Directions.up ? canMove : canMoveUp,
      canMoveRight: directions == Directions.right ? canMove : canMoveRight,
      canMoveDown: directions == Directions.down ? canMove : canMoveDown,
      canMoveLeft: directions == Directions.left ? canMove : canMoveLeft,
    );
  }

  @override
  NormalGoalGrid copyWith({
    bool? canMoveUp,
    bool? canMoveRight,
    bool? canMoveDown,
    bool? canMoveLeft,
  }) {
    return NormalGoalGrid(
      color: color,
      type: type,
      canMoveUp: canMoveUp ?? this.canMoveUp,
      canMoveRight: canMoveRight ?? this.canMoveRight,
      canMoveDown: canMoveDown ?? this.canMoveDown,
      canMoveLeft: canMoveLeft ?? this.canMoveLeft,
    );
  }
}

class WildGoalGrid extends GoalGrid {
  const WildGoalGrid({
    bool canMoveUp = true,
    bool canMoveDown = true,
    bool canMoveLeft = true,
    bool canMoveRight = true,
  }) : super(
          canMoveUp: canMoveUp,
          canMoveRight: canMoveRight,
          canMoveDown: canMoveDown,
          canMoveLeft: canMoveLeft,
        );

  @override
  bool isGoal(Goal goal, Robot robot) => goal.isWild;

  @override
  WildGoalGrid get rotateRight => WildGoalGrid(
        canMoveUp: canMoveLeft,
        canMoveRight: canMoveUp,
        canMoveDown: canMoveRight,
        canMoveLeft: canMoveDown,
      );

  @override
  WildGoalGrid copyWithCanMoveOnly(Grid grid) {
    return WildGoalGrid(
      canMoveUp: grid.canMoveUp,
      canMoveRight: grid.canMoveRight,
      canMoveDown: grid.canMoveDown,
      canMoveLeft: grid.canMoveLeft,
    );
  }

  @override
  WildGoalGrid setCanMove({
    required Directions directions,
    required bool canMove,
  }) {
    return WildGoalGrid(
      canMoveUp: directions == Directions.up ? canMove : canMoveUp,
      canMoveRight: directions == Directions.right ? canMove : canMoveRight,
      canMoveDown: directions == Directions.down ? canMove : canMoveDown,
      canMoveLeft: directions == Directions.left ? canMove : canMoveLeft,
    );
  }

  @override
  WildGoalGrid copyWith({
    bool? canMoveUp,
    bool? canMoveRight,
    bool? canMoveDown,
    bool? canMoveLeft,
  }) {
    return WildGoalGrid(
      canMoveUp: canMoveUp ?? this.canMoveUp,
      canMoveRight: canMoveRight ?? this.canMoveRight,
      canMoveDown: canMoveDown ?? this.canMoveDown,
      canMoveLeft: canMoveLeft ?? this.canMoveLeft,
    );
  }
}
