import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/position.dart';

import '../board/goal.dart';

part 'edit.freezed.dart';

@freezed
class EditAction with _$EditAction {
  const factory EditAction({
    @Default(false) bool nextGoalColor,
    @Default(false) bool nextGoalType,
    @Default(false) bool rotateRightGrids,
    @Default(false) bool addGoal,
    Position? position,
    Position? topBorder,
    Position? rightBorder,
    Position? downBorder,
    Position? leftBorder,
    int? index,
  }) = _EditAction;
}

class EditFunction {
  static Board update(
    Board board,
    EditAction action,
    Position? prePosition,
  ) {
    var newBoard = board.copyWith();
    final goals = newBoard.goals;
    if (action.nextGoalColor && action.index != null) {
      newBoard = newBoard.copyWith(
        goals: List.generate(
          goals.length,
          (i) => i == action.index ? goals[i].nextColor : goals[i],
        ),
      );
    }
    if (action.nextGoalType && action.index != null) {
      newBoard = newBoard.copyWith(
        goals: List.generate(
          goals.length,
          (i) => i == action.index ? goals[i].nextType : goals[i],
        ),
      );
    }
    if (prePosition != null && action.position != null) {
      newBoard = newBoard.copyWith(
        grids: newBoard.grids.swap(prePosition, action.position!),
        robotPositions:
            newBoard.robotPositions.swap(prePosition, action.position!),
      );
    }
    if (action.rotateRightGrids) {
      newBoard = newBoard.copyWith(
        grids: newBoard.grids.rotateRight,
        robotPositions: newBoard.robotPositions.rotateRight,
      );
    }
    if (action.addGoal) {
      newBoard = newBoard.copyWith(
        goals: List.generate(
          newBoard.goals.length + 1,
          (index) => index < newBoard.goals.length
              ? newBoard.goals[index]
              : const Goal(),
        ),
      );
    }
    if (action.topBorder != null) {
      newBoard = newBoard.copyWith(
        grids: newBoard.grids.toggleCanMoveUp(action.topBorder!),
      );
    }
    if (action.rightBorder != null) {
      newBoard = newBoard.copyWith(
        grids: newBoard.grids.toggleCanMoveLeft(
            Position(x: action.rightBorder!.x + 1, y: action.rightBorder!.y)),
      );
    }
    if (action.downBorder != null) {
      newBoard = newBoard.copyWith(
        grids: newBoard.grids.toggleCanMoveUp(
            Position(x: action.downBorder!.x, y: action.downBorder!.y + 1)),
      );
    }
    if (action.leftBorder != null) {
      newBoard = newBoard.copyWith(
        grids: newBoard.grids.toggleCanMoveLeft(action.leftBorder!),
      );
    }
    return newBoard;
  }
}
