import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ricochet_robots/domains/board/board_id.dart';
import 'package:ricochet_robots/domains/game/game_bloc.dart';
import 'package:ricochet_robots/domains/game/widgets/game_widget.dart';
import 'package:ricochet_robots/domains/security/security.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ricochet robots trainer',
      theme: ThemeData(primarySwatch: Colors.grey),
      onGenerateRoute: (settings) {
        final params = Uri.parse(settings.name ?? '/').queryParameters;

        /// Read id from query parameters.
        final id = params['id'] ?? '';

        /// Read pass from query parameters.
        final pass = params['pass'] ?? '';
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (BuildContext context) => GameBloc(
              boardId: BoardId.tryParse(encoded: id),
              unlockSecretButton: verifyPassword(pass),
            ),
            child: const Home(title: 'Ricochet Robots Trainer'),
          ),
        );
      },
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GameWidget(),
    );
  }
}
