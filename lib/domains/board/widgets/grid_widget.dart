import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ricochet_robots/domains/board/goal.dart';
import 'package:ricochet_robots/domains/board/grid.dart';
import 'package:ricochet_robots/domains/board/position.dart';
import 'package:ricochet_robots/domains/board/robot.dart';
import 'package:ricochet_robots/domains/edit/edit.dart';
import 'package:ricochet_robots/domains/edit/editable_icon.dart';
import 'package:ricochet_robots/domains/game/game_bloc.dart';
import 'package:ricochet_robots/domains/game/game_state.dart';

class GridWidget extends StatefulWidget {
  final Grid grid;
  final Position position;
  final Robot? robot;

  const GridWidget({
    Key? key,
    required this.grid,
    required this.position,
    this.robot,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<GridWidget> {
  bool get hasRobot => widget.robot != null;
  bool get isGoal =>
      widget.grid is NormalGoalGrid || widget.grid is WildGoalGrid;
  bool get hasItem => hasRobot || isGoal || widget.grid.isInactiveGrid;
  bool get isTappable => widget.grid.isInactiveGrid;

  Border _buildBorder(Grid grid) {
    const wall = BorderSide(width: 1.0, color: Colors.grey);
    const border = BorderSide(
      width: 0.5,
      color: Color.fromRGBO(230, 230, 230, 1.0), // TODO: adjust color.
    );
    return Border(
      top: grid.canMove(Directions.up) ? border : wall,
      bottom: grid.canMove(Directions.down) ? border : wall,
      right: grid.canMove(Directions.right) ? border : wall,
      left: grid.canMove(Directions.left) ? border : wall,
    );
  }

  Widget _buildGoal(Grid grid, GameMode currentMode) {
    if (grid is NormalGoalGrid) {
      final iconData = getIcon(grid.type);
      // TODO: change icon to image.
      return LayoutBuilder(builder: (context, constraint) {
        return EditableIcon(
          iconData: iconData,
          color: getActualColor(grid.color),
          size: constraint.biggest.height,
          editAction: EditAction(position: widget.position),
          currentMode: currentMode,
        );
      });
    }
    if (grid is WildGoalGrid) {
      return LayoutBuilder(builder: (context, constraint) {
        return EditableIcon(
          iconData: Icons.help,
          color: Colors.deepPurple,
          size: constraint.biggest.height,
          editAction: EditAction(position: widget.position),
          currentMode: currentMode,
        );
      });
    }
    return const SizedBox.shrink();
  }

  Widget _buildRobot(Robot? robot, GameMode currentMode) {
    if (robot != null) {
      return Container(
        decoration: BoxDecoration(
          color: getActualColor(robot.color),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: LayoutBuilder(builder: (context, constraint) {
          return EditableIcon(
            iconData: Icons.android_outlined,
            color: Colors.white,
            size: constraint.biggest.height,
            editAction: EditAction(position: widget.position),
            currentMode: currentMode,
          );
        }),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBlank(GameMode currentMode, bool isSelecterdForEdit) {
    if (currentMode != GameMode.edit) {
      return const SizedBox.shrink();
    }
    if (!isSelecterdForEdit &&
        (widget.robot != null || widget.grid is GoalGrid)) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: EditableIcon(
            iconData: Icons.circle_outlined,
            color: isSelecterdForEdit ? Colors.black : Colors.grey.shade100,
            size: constraint.biggest.height * 0.6,
            editAction: EditAction(position: widget.position),
            currentMode: currentMode,
          ),
        );
      },
    );
  }

  Widget _buildBorderButton(GameMode currentMode) {
    if (currentMode != GameMode.edit) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        final wallWidth = constraint.biggest.width * 0.25;
        return Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: constraint.biggest.width,
              height: wallWidth,
              child: InkWell(
                onTap: () => context.read<GameBloc>().add(EditBoardEvent(
                    editAction: EditAction(topBorder: widget.position))),
                child: Container(color: Colors.grey.shade100),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: wallWidth,
              height: constraint.biggest.height,
              child: InkWell(
                onTap: () => context.read<GameBloc>().add(EditBoardEvent(
                    editAction: EditAction(leftBorder: widget.position))),
                child: Container(color: Colors.grey.shade100),
              ),
            ),
            Positioned(
              left: 0,
              top: constraint.biggest.height - wallWidth,
              width: constraint.biggest.width,
              height: wallWidth,
              child: InkWell(
                onTap: () => context.read<GameBloc>().add(EditBoardEvent(
                    editAction: EditAction(downBorder: widget.position))),
                child: Container(color: Colors.grey.shade100),
              ),
            ),
            Positioned(
              left: constraint.biggest.width - wallWidth,
              top: 0,
              width: wallWidth,
              height: constraint.biggest.height,
              child: InkWell(
                onTap: () => context.read<GameBloc>().add(EditBoardEvent(
                    editAction: EditAction(rightBorder: widget.position))),
                child: Container(color: Colors.grey.shade100),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _gridColor(Grid grid) {
    if (grid.isInactiveGrid) {
      return Colors.grey;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: _gridColor(widget.grid),
                border: _buildBorder(widget.grid),
              ),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: _buildGoal(widget.grid, state.mode),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: _buildRobot(widget.robot, state.mode),
                    ),
                  ),
                  Positioned.fill(
                    child: _buildBlank(
                        state.mode,
                        state.selectedGridForEdit != null &&
                            widget.position == state.selectedGridForEdit),
                  ),
                  Positioned.fill(
                    child: _buildBorderButton(state.mode),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
