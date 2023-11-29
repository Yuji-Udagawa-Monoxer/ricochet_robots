import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ricochet_robots/domains/board/widgets/board_widget.dart';
import 'package:ricochet_robots/domains/game/game_bloc.dart';
import 'package:ricochet_robots/domains/game/game_state.dart';
import 'package:ricochet_robots/domains/game/widgets/control_buttons.dart';
import 'package:ricochet_robots/domains/game/widgets/header_widget.dart';
import 'package:ricochet_robots/domains/game/widgets/result_dialog.dart';
import 'package:ricochet_robots/domains/game/widgets/wait_dialog.dart';

class GameWidget extends StatelessWidget {
  const GameWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final bloc = context.read<GameBloc>();
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Card(
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  constraints: const BoxConstraints(
                    maxWidth: 800,
                    maxHeight: 1000,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      HeaderWidget(
                        board: state.board,
                        histories: state.histories,
                        currentMode: state.mode,
                      ),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: BoardWidget(board: state.board),
                        ),
                      ),
                      const ControlButtons(),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: state.shouldShowResult,
                child: ResultDialog(
                  moves: state.histories.length,
                  onPressCancel: () => bloc.add(const ReplayEvent()),
                  onPressButton: () =>
                      bloc.add(const RestartEvent(isBoardRandom: true)),
                ),
              ),
              Visibility(
                visible: state.shouldWait,
                child: const WaitDialog(),
              ),
            ],
          ),
        );
      },
    );
  }
}
