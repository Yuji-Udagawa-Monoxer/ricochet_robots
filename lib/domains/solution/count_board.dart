import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:tuple/tuple.dart';

import '../board/board.dart';
import '../board/move_history.dart';

class CountBoard {
  Board board;

  final MoveHistory moveHistory;

  CountBoard({required this.board, required this.moveHistory});

  // movedLength, robotCollisionNum, innerWallCollisionNum
  Tuple3<int, int, int> count() {
    var movedLength = 0;
    var robotCollisionNum = 0;
    var innerWallCollisionNum = 0;

    for (final moveRecord in moveHistory.records) {
      final currentPosition =
          board.robotPositions.position(color: moveRecord.color);
      board = board.moved(Robot(color: moveRecord.color), moveRecord.direction);
      final nextPosition =
          board.robotPositions.position(color: moveRecord.color);

      if (nextPosition.x == currentPosition.x) {
        movedLength += (nextPosition.y - currentPosition.y).abs();
      } else {
        movedLength += (nextPosition.x - currentPosition.x).abs();
      }
      if (board.grids
          .at(position: nextPosition)
          .canMove(moveRecord.direction)) {
        robotCollisionNum++;
      } else if (!board.grids.isOuter(position: nextPosition)) {
        innerWallCollisionNum++;
      }
    }

    return Tuple3(movedLength, robotCollisionNum, innerWallCollisionNum);
  }

  // [movedLength, robotCollisionNum, innerWallCollisionNum], difficulty
  Tuple2<Tuple3<int, int, int>, int> countAndDifficulty(
    int lengthWeightWhenSearchNewBoard,
    int robotCollisionWeightWhenSearchNewBoard,
    int innerWallCollisionWeightWhenSearchNewBoard,
  ) {
    final tuple = count();
    return Tuple2(
      tuple,
      tuple.item1 * lengthWeightWhenSearchNewBoard +
          tuple.item2 * robotCollisionWeightWhenSearchNewBoard +
          tuple.item3 * innerWallCollisionWeightWhenSearchNewBoard,
    );
  }
}
