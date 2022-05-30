import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/board/robot_positions.dart';

class RobotPositionsMutable {
  List<Position> positions = List.generate(
      RobotColors.values.length, (index) => const Position(x: 0, y: 0));

  static get init => RobotPositionsMutable(
        red: const Position(x: 0, y: 0),
        blue: const Position(x: 16, y: 16),
        green: const Position(x: 16, y: 16),
        yellow: const Position(x: 16, y: 16),
      );

  RobotPositionsMutable({
    required red,
    required blue,
    required green,
    required yellow,
  }) {
    positions[RobotColors.red.index] = red;
    positions[RobotColors.blue.index] = blue;
    positions[RobotColors.green.index] = green;
    positions[RobotColors.yellow.index] = yellow;
  }

  void set(RobotPositions robotPositionsImmutable) {
    positions[RobotColors.red.index] = robotPositionsImmutable.red;
    positions[RobotColors.blue.index] = robotPositionsImmutable.blue;
    positions[RobotColors.green.index] = robotPositionsImmutable.green;
    positions[RobotColors.yellow.index] = robotPositionsImmutable.yellow;
  }

  void move({
    required RobotColors color,
    required Position to,
  }) {
    positions[color.index] = to;
  }

  int toHash() {
    int hash = 0;
    for (final color in RobotColors.values) {
      hash = (hash << 4) + positions[color.index].x;
      hash = (hash << 4) + positions[color.index].y;
    }
    return hash;
  }

  void fromHash(int hash) {
    positions[RobotColors.red.index] = Position(
      x: (hash >> 28) % 16,
      y: (hash >> 24) % 16,
    );
    positions[RobotColors.blue.index] = Position(
      x: (hash >> 20) % 16,
      y: (hash >> 16) % 16,
    );
    positions[RobotColors.green.index] = Position(
      x: (hash >> 12) % 16,
      y: (hash >> 8) % 16,
    );
    positions[RobotColors.yellow.index] = Position(
      x: (hash >> 4) % 16,
      y: (hash >> 0) % 16,
    );
  }
}
