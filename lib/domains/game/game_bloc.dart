import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ricochet_robots/domains/board/board_id.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/edit/edit.dart';
import 'package:ricochet_robots/domains/game/game_state.dart';

import '../board/position.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({required BoardId? boardId})
      : super(GameState.initialize(boardId: boardId)) {
    on<SelectColorEvent>(
      (event, emit) => emit(state.onColorSelected(color: event.color)),
    );
    on<SelectDirectionEvent>(
      (event, emit) =>
          emit(state.onDirectionSelected(direction: event.direction)),
    );
    on<RedoEvent>((event, emit) => emit(state.onRedoPressed()));
    on<ReplayEvent>((event, emit) => emit(state.onReplay()));
    on<RestartEvent>((event, emit) => emit(state.onRestart()));
    on<EditModeEvent>((event, emit) =>
        emit(state.onEditModeEvent(toEditMode: event.toEditMode)));
    on<EditBoardEvent>((event, emit) =>
        emit(state.onEditBoardEvent(editAction: event.editAction)));
    on<SolveEvent>((event, emit) => emit(state.onSolve(event.searchMaxCount)));
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
  const RestartEvent();
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
  final int searchMaxCount;

  const SolveEvent({this.searchMaxCount = -1});
}
