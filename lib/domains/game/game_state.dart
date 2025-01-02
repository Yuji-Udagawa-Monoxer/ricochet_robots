import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/board_builder.dart';
import 'package:ricochet_robots/domains/board/board_id.dart';
import 'package:ricochet_robots/domains/board/move_history.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/edit/edit.dart';
import 'package:ricochet_robots/domains/game/history.dart';
import 'package:ricochet_robots/domains/solution/solve_board.dart';

import '../solution/count_board.dart';

part 'game_state.freezed.dart';

enum GameMode { play, showResult, edit, wait }

@freezed
class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    required GameMode mode,
    required Board board,
    required List<History> histories,
    required Robot focusedRobot,
    required Position? selectedGridForEdit,
    required List<MoveHistory> answerHistories,
    required int searchCount,
    required bool unlockSecretButton,
    required int shuffleGridCount,
    required int goalNumForNewBoard,
    required int movedRobotNumWhenSearchNewBoard,
    required int movedCountWhenSearchNewBoard,
    required int lengthWeightWhenSearchNewBoard,
    required int robotCollisionWeightWhenSearchNewBoard,
    required int innerWallCollisionWeightWhenSearchNewBoard,
    required int lowerDifficultyWhenSearchNewBoard,
  }) = _GameState;

  bool get shouldShowResult => mode == GameMode.showResult;
  bool get shouldWait => mode == GameMode.wait;

  static GameState initialize({
    required BoardId? boardId,
    bool unlockSecretButton = false,
  }) {
    final board =
        boardId != null ? toBoard(boardId: boardId) : Board.random(0, 1);
    return init(board: board, unlockSecretButton: unlockSecretButton);
  }

  /// Reset state and returns new state.
  @visibleForTesting
  static GameState init({
    required Board board,
    bool unlockSecretButton = false,
  }) {
    return GameState(
      mode: GameMode.play,
      board: board,
      histories: [],
      focusedRobot: const Robot(color: RobotColors.red),
      selectedGridForEdit: null,
      answerHistories: [],
      searchCount: -1,
      unlockSecretButton: unlockSecretButton,
      shuffleGridCount: 0,
      goalNumForNewBoard: 1,
      movedRobotNumWhenSearchNewBoard: 2,
      movedCountWhenSearchNewBoard: 7,
      lengthWeightWhenSearchNewBoard: 1,
      robotCollisionWeightWhenSearchNewBoard: 20,
      innerWallCollisionWeightWhenSearchNewBoard: 10,
      lowerDifficultyWhenSearchNewBoard: 100,
    );
  }

  GameState onColorSelected({required RobotColors color}) =>
      copyWith(focusedRobot: Robot(color: color));

  GameState onDirectionSelected({required Directions direction}) {
    final currentPosition =
        board.robotPositions.position(color: focusedRobot.color);
    final nextBoard = board.moved(focusedRobot, direction);
    final nextPosition =
        nextBoard.robotPositions.position(color: focusedRobot.color);
    final history = History(
      color: focusedRobot.color,
      position: currentPosition,
    );
    final nextHistories =
        nextPosition != currentPosition ? [...histories, history] : histories;
    if (board.isGoals(nextBoard.robotPositions.positions)) {
      return copyWith(
        mode: GameMode.showResult,
        board: nextBoard,
        histories: nextHistories,
      );
    }
    return copyWith(board: nextBoard, histories: nextHistories);
  }

  GameState onRedoPressed() {
    if (histories.isEmpty) {
      return this;
    }
    final prevHistory = histories.last;
    return copyWith(
      histories: histories.take(histories.length - 1).toList(),
      board: board.movedTo(
        Robot(color: prevHistory.color),
        prevHistory.position,
      ),
    );
  }

  GameState onReplay() => copyWith(mode: GameMode.play);

  GameState onRestart({required bool isBoardRandom}) => copyWith(
        board: Board.random(
          shuffleGridCount,
          goalNumForNewBoard,
          newBoard: isBoardRandom ? null : board,
        ),
      ).initialized;

  GameState onRestartConditional({
    required bool isBoardRandom,
    required bool isLowerDifficulty,
  }) {
    isBoardRequired(
      board,
      movedRobotNumWhenSearchNewBoard,
      movedCountWhenSearchNewBoard,
      lengthWeightWhenSearchNewBoard,
      robotCollisionWeightWhenSearchNewBoard,
      innerWallCollisionWeightWhenSearchNewBoard,
      lowerDifficultyWhenSearchNewBoard,
    ) {
      final solveBoard = SolveBoard(board: board);
      final answerHistories = solveBoard.solve(isLog: false);
      if (answerHistories.isEmpty) {
        return false;
      }
      final answerMoveHistory = answerHistories[0];

      final colorCount = answerMoveHistory.records
          .map((record) => record.color)
          .toSet()
          .length;
      if (!(colorCount >= movedRobotNumWhenSearchNewBoard &&
          answerMoveHistory.records.length >= movedCountWhenSearchNewBoard)) {
        return false;
      }

      final tuple =
          CountBoard(board: board, moveHistory: answerMoveHistory).count();
      final movedLength = tuple.item1;
      final robotCollisionNum = tuple.item2;
      final innerWallCollisionNum = tuple.item3;
      final difficulty = movedLength * lengthWeightWhenSearchNewBoard +
          robotCollisionNum * robotCollisionWeightWhenSearchNewBoard +
          innerWallCollisionNum * innerWallCollisionWeightWhenSearchNewBoard;
      if (difficulty < lowerDifficultyWhenSearchNewBoard) {
        return false;
      }

      return true;
    }

    createRandomBoard() {
      return Board.random(
        shuffleGridCount,
        goalNumForNewBoard,
        newBoard: isBoardRandom ? null : board,
      );
    }

    Board newBoard = createRandomBoard();
    const maxTryCount = 100;
    for (var i = 0; i < maxTryCount; i++) {
      if (isBoardRequired(
        newBoard,
        movedRobotNumWhenSearchNewBoard,
        movedCountWhenSearchNewBoard,
        lengthWeightWhenSearchNewBoard,
        robotCollisionWeightWhenSearchNewBoard,
        innerWallCollisionWeightWhenSearchNewBoard,
        isLowerDifficulty ? lowerDifficultyWhenSearchNewBoard : 0,
      )) {
        debugPrint(
            "Tried ${i + 1} times and found a board that met the requirements");
        break;
      }
      newBoard = createRandomBoard();
      if (i == maxTryCount - 1) {
        debugPrint(
            "Tried 100 times and could not find a board that met the requirements");
      }
    }

    return copyWith(board: newBoard).initialized;
  }

  GameState onEditModeEvent({required bool toEditMode}) =>
      copyWith(mode: toEditMode ? GameMode.edit : GameMode.play);

  GameState onEditBoardEvent({required EditAction editAction}) {
    final newSelectedGridForEdit =
        selectedGridForEdit == null ? editAction.position : null;
    return copyWith(
      board: EditFunction.update(board, editAction, selectedGridForEdit),
      selectedGridForEdit: newSelectedGridForEdit,
    );
  }

  GameState onSolve() {
    final solveBoard =
        SolveBoard(board: board, searchFinishedCount: searchCount);
    final answerHistories = solveBoard.solve();

    final tuple = CountBoard(
      board: board,
      moveHistory: answerHistories[0],
    ).countAndDifficulty(
      lengthWeightWhenSearchNewBoard,
      robotCollisionWeightWhenSearchNewBoard,
      innerWallCollisionWeightWhenSearchNewBoard,
    );
    debugPrint("Difficulty: ${tuple.item2}=${tuple.item1}");

    return copyWith(answerHistories: answerHistories);
  }

  GameState onSetSearchCount(int searchCount) =>
      copyWith(searchCount: searchCount);

  GameState onSetShuffleGridCount(int shuffleGridCount) =>
      copyWith(shuffleGridCount: shuffleGridCount);

  GameState onSetGoalNumForNewBoard(int goalNumForNewBoard) =>
      copyWith(goalNumForNewBoard: goalNumForNewBoard);

  GameState onSetMovedRobotNumWhenSearchNewBoard(
          int movedRobotNumWhenSearchNewBoard) =>
      copyWith(
          movedRobotNumWhenSearchNewBoard: movedRobotNumWhenSearchNewBoard);

  GameState onSetMovedCountWhenSearchNewBoard(
          int movedCountWhenSearchNewBoard) =>
      copyWith(movedCountWhenSearchNewBoard: movedCountWhenSearchNewBoard);

  GameState onSetLengthWeightWhenSearchNewBoard(
          int lengthWeightWhenSearchNewBoard) =>
      copyWith(lengthWeightWhenSearchNewBoard: lengthWeightWhenSearchNewBoard);

  GameState onSetRobotCollisionWeightWhenSearchNewBoard(
          int robotCollisionWeightWhenSearchNewBoard) =>
      copyWith(
          robotCollisionWeightWhenSearchNewBoard:
              robotCollisionWeightWhenSearchNewBoard);

  GameState onSetInnerWallCollisionWeightWhenSearchNewBoard(
          int innerWallCollisionWeightWhenSearchNewBoard) =>
      copyWith(
          innerWallCollisionWeightWhenSearchNewBoard:
              innerWallCollisionWeightWhenSearchNewBoard);

  GameState onSetLowerDifficultyWhenSearchNewBoard(
          int lowerDifficultyWhenSearchNewBoard) =>
      copyWith(
          lowerDifficultyWhenSearchNewBoard: lowerDifficultyWhenSearchNewBoard);

  GameState get initialized => copyWith(
        mode: GameMode.play,
        histories: [],
        answerHistories: [],
      );
}
