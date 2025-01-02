import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ricochet_robots/domains/board/board_id.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/edit/edit.dart';
import 'package:ricochet_robots/domains/game/game_state.dart';

import '../board/position.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required BoardId? boardId,
    unlockSecretButton = false,
  }) : super(GameState.initialize(
          boardId: boardId,
          unlockSecretButton: unlockSecretButton,
        )) {
    on<SelectColorEvent>(
      (event, emit) => emit(state.onColorSelected(color: event.color)),
    );
    on<SelectDirectionEvent>(
      (event, emit) =>
          emit(state.onDirectionSelected(direction: event.direction)),
    );
    on<RedoEvent>((event, emit) => emit(state.onRedoPressed()));
    on<ReplayEvent>((event, emit) => emit(state.onReplay()));
    on<RestartEvent>((event, emit) =>
        emit(state.onRestart(isBoardRandom: event.isBoardRandom)));
    on<RestartConditionalEvent>((event, emit) => emit(
        state.onRestartConditional(
            isBoardRandom: event.isBoardRandom,
            isLowerWeight: event.isLowerWeight)));
    on<EditModeEvent>((event, emit) =>
        emit(state.onEditModeEvent(toEditMode: event.toEditMode)));
    on<EditBoardEvent>((event, emit) =>
        emit(state.onEditBoardEvent(editAction: event.editAction)));
    on<SolveEvent>((event, emit) async {
      emit(state.copyWith(mode: GameMode.wait));
      await Future.delayed(const Duration(milliseconds: 50)); // wait build ui
      emit(state.onSolve());
      emit(state.copyWith(mode: GameMode.play));
    });
    on<SetSearchCountEvent>(
        (event, emit) => emit(state.onSetSearchCount(event.searchCount)));
    on<SetShuffleGridCountEvent>((event, emit) =>
        emit(state.onSetShuffleGridCount(event.shuffleGridCount)));
    on<SetGoalNumForNewBoardEvent>((event, emit) =>
        emit(state.onSetGoalNumForNewBoard(event.goalNumForNewBoard)));
    on<SetMovedRobotNumWhenSearchNewBoardEvent>((event, emit) => emit(
        state.onSetMovedRobotNumWhenSearchNewBoard(
            event.movedRobotNumWhenSearchNewBoard)));
    on<SetMovedCountWhenSearchNewBoardEvent>((event, emit) => emit(
        state.onSetMovedCountWhenSearchNewBoard(
            event.movedCountWhenSearchNewBoard)));
    on<SetLengthWeightWhenSearchNewBoardEvent>((event, emit) => emit(
        state.onSetLengthWeightWhenSearchNewBoard(
            event.lengthWeightWhenSearchNewBoard)));
    on<SetRobotCollisionWeightWhenSearchNewBoardEvent>((event, emit) => emit(
        state.onSetRobotCollisionWeightWhenSearchNewBoard(
            event.robotCollisionWeightWhenSearchNewBoard)));
    on<SetInnerWallCollisionWeightWhenSearchNewBoardEvent>((event, emit) =>
        emit(state.onSetInnerWallCollisionWeightWhenSearchNewBoard(
            event.innerWallCollisionWeightWhenSearchNewBoard)));
    on<SetLowerWeightWhenSearchNewBoardEvent>((event, emit) => emit(
        state.onSetLowerWeightWhenSearchNewBoard(
            event.lowerWeightWhenSearchNewBoard)));
  }
}

abstract class GameEvent {
  const GameEvent();
}

class SelectColorEvent extends GameEvent {
  final RobotColors color;

  const SelectColorEvent({required this.color});
}

class SelectDirectionEvent extends GameEvent {
  final Directions direction;

  const SelectDirectionEvent({required this.direction});
}

class RedoEvent extends GameEvent {
  const RedoEvent();
}

class ReplayEvent extends GameEvent {
  const ReplayEvent();
}

class RestartEvent extends GameEvent {
  final bool isBoardRandom;

  const RestartEvent({required this.isBoardRandom});
}

class RestartConditionalEvent extends GameEvent {
  final bool isBoardRandom;
  final bool isLowerWeight;

  const RestartConditionalEvent(
      {required this.isBoardRandom, required this.isLowerWeight});
}

class EditModeEvent extends GameEvent {
  final bool toEditMode;

  const EditModeEvent({required this.toEditMode});
}

class EditBoardEvent extends GameEvent {
  final EditAction editAction;

  const EditBoardEvent({required this.editAction});
}

class SolveEvent extends GameEvent {
  const SolveEvent();
}

class SetSearchCountEvent extends GameEvent {
  final int searchCount;

  const SetSearchCountEvent({required this.searchCount});
}

class SetShuffleGridCountEvent extends GameEvent {
  final int shuffleGridCount;

  const SetShuffleGridCountEvent({required this.shuffleGridCount});
}

class SetGoalNumForNewBoardEvent extends GameEvent {
  final int goalNumForNewBoard;

  const SetGoalNumForNewBoardEvent({required this.goalNumForNewBoard});
}

class SetMovedRobotNumWhenSearchNewBoardEvent extends GameEvent {
  final int movedRobotNumWhenSearchNewBoard;

  const SetMovedRobotNumWhenSearchNewBoardEvent(
      {required this.movedRobotNumWhenSearchNewBoard});
}

class SetMovedCountWhenSearchNewBoardEvent extends GameEvent {
  final int movedCountWhenSearchNewBoard;

  const SetMovedCountWhenSearchNewBoardEvent(
      {required this.movedCountWhenSearchNewBoard});
}

class SetLengthWeightWhenSearchNewBoardEvent extends GameEvent {
  final int lengthWeightWhenSearchNewBoard;

  const SetLengthWeightWhenSearchNewBoardEvent(
      {required this.lengthWeightWhenSearchNewBoard});
}

class SetRobotCollisionWeightWhenSearchNewBoardEvent extends GameEvent {
  final int robotCollisionWeightWhenSearchNewBoard;

  const SetRobotCollisionWeightWhenSearchNewBoardEvent(
      {required this.robotCollisionWeightWhenSearchNewBoard});
}

class SetInnerWallCollisionWeightWhenSearchNewBoardEvent extends GameEvent {
  final int innerWallCollisionWeightWhenSearchNewBoard;

  const SetInnerWallCollisionWeightWhenSearchNewBoardEvent(
      {required this.innerWallCollisionWeightWhenSearchNewBoard});
}

class SetLowerWeightWhenSearchNewBoardEvent extends GameEvent {
  final int lowerWeightWhenSearchNewBoard;

  const SetLowerWeightWhenSearchNewBoardEvent(
      {required this.lowerWeightWhenSearchNewBoard});
}
