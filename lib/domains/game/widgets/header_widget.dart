import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ricochet_robots/domains/board/board.dart';
import 'package:ricochet_robots/domains/board/board_id.dart';
import 'package:ricochet_robots/domains/board/goal.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/edit/edit.dart';
import 'package:ricochet_robots/domains/edit/editable_icon.dart';
import 'package:ricochet_robots/domains/game/game_bloc.dart';
import 'package:ricochet_robots/domains/game/game_state.dart';
import 'package:ricochet_robots/domains/game/history.dart';

class HeaderWidget extends StatelessWidget {
  static const _iconSize = 24.0;

  final Board board;
  final List<History> histories;
  final GameMode currentMode;

  const HeaderWidget({
    Key? key,
    required this.board,
    required this.histories,
    required this.currentMode,
  }) : super(key: key);

  final _textStyle = const TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  Widget _target(Goal goal, BuildContext context) {
    final color = goal.color;
    if (color == null) {
      return Text(
        "Any Robot",
        style: _textStyle,
      );
    }
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        color: getActualColor(color),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: EditableIcon(
        iconData: Icons.android_outlined,
        color: Colors.white,
        size: 20,
        editAction: const EditAction(nextGoalColor: true),
        currentMode: currentMode,
      ),
    );
  }

  Widget _goal(Goal goal, BuildContext context) {
    final type = goal.type;
    final color = goal.color;
    if (type == null || color == null) {
      return EditableIcon(
        iconData: Icons.help,
        color: Colors.deepPurple,
        size: 20,
        editAction: const EditAction(nextGoalColor: true),
        currentMode: currentMode,
      );
    }
    return EditableIcon(
      iconData: getIcon(type),
      color: getActualColor(color),
      size: 20,
      editAction: const EditAction(nextGoalType: true),
      currentMode: currentMode,
    );
  }

  Future<void> _copyUrlToClipBoard() async {
    final id = BoardId.from(board: board);
    final base = Uri.parse(Uri.base.toString().replaceFirst("#", "sharp"));
    final created = base
        .replace(queryParameters: {...base.queryParameters, "id": id.encoded})
        .toString()
        .replaceFirst("sharp", "#");
    await Clipboard.setData(
      ClipboardData(text: created),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toEditMode = currentMode != GameMode.edit;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Row(
            children: [
              Text("Move ", style: _textStyle),
              _target(board.goal, context),
              Text(" to ", style: _textStyle),
              _goal(board.goal, context),
            ],
          ),
          const Expanded(child: SizedBox.shrink()),
          toEditMode
              ? IconButton(
                  onPressed: () => context
                      .read<GameBloc>()
                      .add(const SolveEvent(searchMaxCount: 5)),
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.grey,
                    size: _iconSize,
                  ),
                )
              : EditableIcon(
                  iconData: Icons.rotate_right,
                  color: Colors.grey,
                  size: 20,
                  editAction: const EditAction(rotateRightGrids: true),
                  currentMode: currentMode,
                ),
          Text("${histories.length.toString()} moves", style: _textStyle),
          const SizedBox(width: 8.0),
          IconButton(
            onPressed: () => context.read<GameBloc>().add(const RestartEvent()),
            icon: const Icon(
              Icons.refresh,
              color: Colors.grey,
              size: _iconSize,
            ),
          ),
          IconButton(
            onPressed: _copyUrlToClipBoard,
            icon: const Icon(
              Icons.link,
              color: Colors.grey,
              size: _iconSize,
            ),
          ),
          IconButton(
            onPressed: () => context
                .read<GameBloc>()
                .add(EditModeEvent(toEditMode: toEditMode)),
            icon: Icon(
              toEditMode ? Icons.edit : Icons.stop,
              color: Colors.grey,
              size: _iconSize,
            ),
          ),
          toEditMode
              ? const SizedBox.shrink()
              : Text("Edit Mode", style: _textStyle),
        ],
      ),
    );
  }
}
