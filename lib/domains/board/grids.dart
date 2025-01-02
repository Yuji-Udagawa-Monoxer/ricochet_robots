import 'dart:math';

import 'package:ricochet_robots/domains/board/grid.dart';
import 'package:ricochet_robots/domains/board/position.dart';

class Grids {
  final List<List<Grid>> grids;

  const Grids({required this.grids});

  bool canPlaceRobotTo({required Position position}) =>
      grids[position.y][position.x].canPlaceRobot;

  Grid at({required Position position}) => grids[position.y][position.x];

  bool _isCorner({required Position position}) {
    if (position.y == 0 &&
        (position.x == 0 || position.x == grids[position.y].length - 1)) {
      return true;
    }
    if (position.y == grids.length - 1 &&
        (position.x == 0 || position.x == grids[position.y].length - 1)) {
      return true;
    }
    return false;
  }

  bool isOuter({required Position position}) {
    if (position.y == 0 || position.y == grids.length - 1) {
      return true;
    }
    if (position.x == 0 || position.x == grids[position.y].length - 1) {
      return true;
    }
    return false;
  }

  Directions? _wallDirection({required Position position}) {
    if (position.y == 0) {
      return Directions.up;
    } else if (position.x == grids[position.y].length - 1) {
      return Directions.right;
    } else if (position.y == grids.length - 1) {
      return Directions.down;
    } else if (position.x == 0) {
      return Directions.left;
    }
    return null;
  }

  Grid? _safeAt({required Position position}) {
    if (position.y < 0 || position.y >= grids.length) {
      return null;
    }
    if (position.x < 0 || position.x >= grids[position.y].length) {
      return null;
    }
    return at(position: position);
  }

  int get length => grids.length;

  List<Grid> row({required int y}) => grids[y];

  Grids swap(Position a, Position b) {
    final newGrids = List.generate(grids.length, (y) {
      return List.generate(grids[y].length, (x) {
        final position = Position(x: x, y: y);
        if (position == a) {
          return at(position: b).copyWithCanMoveOnly(at(position: a));
        }
        if (position == b) {
          return at(position: a).copyWithCanMoveOnly(at(position: b));
        }
        return at(position: position);
      });
    });
    return Grids(grids: newGrids);
  }

  Grids swapWithWall(Position a, Position b) {
    directionToNextGridFunction(Directions direction) {
      switch (direction) {
        case Directions.up:
          return (Grid a, Grid b) => a.copyWith(canMoveDown: b.canMoveUp);
        case Directions.right:
          return (Grid a, Grid b) => a.copyWith(canMoveLeft: b.canMoveRight);
        case Directions.down:
          return (Grid a, Grid b) => a.copyWith(canMoveUp: b.canMoveDown);
        case Directions.left:
          return (Grid a, Grid b) => a.copyWith(canMoveRight: b.canMoveLeft);
      }
    }

    final newGrids = List.generate(grids.length, (y) {
      return List.generate(grids[y].length, (x) {
        final position = Position(x: x, y: y);
        if (position == a) {
          return at(position: b);
        }
        if (position == b) {
          return at(position: a);
        }
        var grid = at(position: position);
        for (final direction in Directions.values) {
          if (position == a.next(direction)) {
            grid = directionToNextGridFunction(direction)(
              grid,
              at(position: b),
            );
          }
          if (position == b.next(direction)) {
            grid = directionToNextGridFunction(direction)(
              grid,
              at(position: a),
            );
          }
        }
        return grid;
      });
    });
    return Grids(grids: newGrids);
  }

  bool canMoveToGrid(Position prev, Position next) {
    if (_wallDirection(position: prev) != null) {
      return canMoveToGridAlongWall(prev, next);
    }
    for (var x = next.x - 1; x <= next.x + 1; ++x) {
      for (var y = next.y - 1; y <= next.y + 1; ++y) {
        final grid = _safeAt(position: Position(x: x, y: y));
        if (grid == null) {
          return false;
        }
        if (grid is! NormalGrid) {
          return false;
        }
        if (x == next.x && !(grid.canMoveRight && grid.canMoveLeft)) {
          return false;
        }
        if (y == next.y && !(grid.canMoveUp && grid.canMoveDown)) {
          return false;
        }
      }
    }
    return true;
  }

  bool canMoveToGridAlongWall(Position prev, Position next) {
    if (_isCorner(position: prev)) {
      return false;
    }
    final direction = _wallDirection(position: prev);
    switch (direction) {
      case Directions.up:
        if (!at(position: prev).canMoveDown) {
          return false;
        }
        break;
      case Directions.right:
        if (!at(position: prev).canMoveLeft) {
          return false;
        }
        break;
      case Directions.down:
        if (!at(position: prev).canMoveUp) {
          return false;
        }
        break;
      case Directions.left:
        if (!at(position: prev).canMoveRight) {
          return false;
        }
        break;
      case null:
        return false;
    }
    if (direction != _wallDirection(position: next)) {
      return false;
    }
    if (direction == Directions.up || direction == Directions.down) {
      for (var x = next.x - 1; x <= next.x + 1; ++x) {
        final grid = _safeAt(position: Position(x: x, y: next.y));
        if (grid != null && !(grid.canMoveRight && grid.canMoveLeft)) {
          return false;
        }
        final gridOne = _safeAt(
            position: Position(x: x, y: next.y == 0 ? next.y + 1 : next.y - 1));
        if (gridOne != null && gridOne is! NormalGrid) {
          return false;
        }
      }
    }
    if (direction == Directions.right || direction == Directions.left) {
      for (var y = next.y - 1; y <= next.y + 1; ++y) {
        final grid = _safeAt(position: Position(x: next.x, y: y));
        if (grid != null && !(grid.canMoveUp && grid.canMoveDown)) {
          return false;
        }
        final gridOne = _safeAt(
            position: Position(x: next.x == 0 ? next.x + 1 : next.x - 1, y: y));
        if (gridOne != null && gridOne is! NormalGrid) {
          return false;
        }
      }
    }
    return true;
  }

  Grids get rotateRight {
    final newGrids = List.generate(grids.length, (y) {
      return List.generate(grids[y].length, (x) {
        final position = Position(x: x, y: y).rotateLeft;
        return at(position: position).rotateRight;
      });
    });
    return Grids(grids: newGrids);
  }

  Grids toggleCanMoveUp(Position lowerPosition) {
    final upperPosition = Position(x: lowerPosition.x, y: lowerPosition.y - 1);
    final upperGrid = _safeAt(position: upperPosition);
    final lowerGrid = _safeAt(position: lowerPosition);
    if (upperGrid == null || lowerGrid == null) {
      return this;
    }
    final newGrids = List.generate(grids.length, (y) {
      return List.generate(grids[y].length, (x) {
        final position = Position(x: x, y: y);
        if (position == upperPosition) {
          return upperGrid.setCanMove(
            directions: Directions.down,
            canMove: !lowerGrid.canMoveUp,
          );
        }
        if (position == lowerPosition) {
          return lowerGrid.setCanMove(
            directions: Directions.up,
            canMove: !lowerGrid.canMoveUp,
          );
        }
        return at(position: position);
      });
    });
    return Grids(grids: newGrids);
  }

  Grids toggleCanMoveLeft(Position rightPosition) {
    final leftPosition = Position(x: rightPosition.x - 1, y: rightPosition.y);
    final rightGrid = _safeAt(position: rightPosition);
    final leftGrid = _safeAt(position: leftPosition);
    if (rightGrid == null || leftGrid == null) {
      return this;
    }
    final newGrids = List.generate(grids.length, (y) {
      return List.generate(grids[y].length, (x) {
        final position = Position(x: x, y: y);
        if (position == rightPosition) {
          return rightGrid.setCanMove(
            directions: Directions.left,
            canMove: !rightGrid.canMoveLeft,
          );
        }
        if (position == leftPosition) {
          return leftGrid.setCanMove(
            directions: Directions.right,
            canMove: !rightGrid.canMoveLeft,
          );
        }
        return at(position: position);
      });
    });
    return Grids(grids: newGrids);
  }

  bool _notShuffleTargetGrid(Position position) {
    if (_isCorner(position: position)) {
      return true;
    }
    final grid = at(position: position);
    switch (_wallDirection(position: position)) {
      case null:
        return grid is NormalGrid;
      case Directions.up:
      case Directions.down:
        return grid.canMoveRight && grid.canMoveLeft;
      case Directions.right:
      case Directions.left:
        return grid.canMoveUp && grid.canMoveDown;
    }
  }

  Grids? shuffleGrid() {
    final rand = Random();

    final yLength = grids.length;
    final halfYLength = yLength ~/ 2;
    final xLength = grids[0].length;
    final halfXLength = xLength ~/ 2;

    final prevPosition =
        Position(x: rand.nextInt(xLength), y: rand.nextInt(yLength));
    if (_notShuffleTargetGrid(prevPosition)) {
      return null;
    }

    final nextPosition = (Position nextPosition, Position prevPosition) {
      switch (_wallDirection(position: prevPosition)) {
        case Directions.up:
        case Directions.down:
          return Position(
              x: nextPosition.x >= halfXLength
                  ? nextPosition.x + 1
                  : nextPosition.x - 1,
              y: prevPosition.y);
        case Directions.right:
        case Directions.left:
          return Position(
              x: prevPosition.x,
              y: nextPosition.y >= halfYLength
                  ? nextPosition.y + 1
                  : nextPosition.y - 1);
        case null:
          return nextPosition;
      }
    }(
      Position(
        x: rand.nextInt(halfXLength) +
            (prevPosition.x ~/ halfXLength) * halfXLength,
        y: rand.nextInt(halfYLength) +
            (prevPosition.y ~/ halfYLength) * halfYLength,
      ),
      prevPosition,
    );
    if (_safeAt(position: nextPosition) == null) {
      return null;
    }

    if (!canMoveToGrid(prevPosition, nextPosition)) {
      return null;
    }

    return swapWithWall(prevPosition, nextPosition);
  }
}
