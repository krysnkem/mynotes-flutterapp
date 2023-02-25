import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/views/verfiy_email_view.dart';

import 'login_view.dart';
import 'notes/notes_view.dart';

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//         future: AuthService.firebase().initialze(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Text('error occured');
//           }
//           switch (snapshot.connectionState) {
//             case ConnectionState.done:
//               final user = AuthService.firebase().currentUser;
//               if (user != null) {
//                 if (user.isEmailVerified) {
//                   return const NotesView();
//                 } else {
//                   return const VerifyEmailView();
//                 }
//               } else {
//                 return const LoginView();
//               }

//             default:
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//           }
//         });
//   }
// }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learning Bloc'),
        ),
        body: BlocConsumer<CounterBloc, CounterState>(
          builder: (context, state) {
            final invaidValue =
                (state is CounterStateInvalid) ? state.invalidValue : " ";
            return Column(
              children: [
                Text('Statevalue is => ${state.value}'),
                Visibility(
                  visible: state is CounterStateInvalid,
                  child: Text('invalid value => $invaidValue'),
                ),
                TextField(
                  controller: _textEditingController,
                  decoration:
                      const InputDecoration(hintText: 'Enter number here'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        context
                            .read<CounterBloc>()
                            .add(DecreamentEvent(_textEditingController.text));
                      },
                      child: const Text('-'),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<CounterBloc>()
                            .add(IncreamentEvent(_textEditingController.text));
                      },
                      child: const Text('+'),
                    )
                  ],
                )
              ],
            );
          },
          listener: (context, state) {
            _textEditingController.clear();
          },
        ),
      ),
    );
  }
}

@immutable
abstract class CounterState {
  final int value;
  const CounterState(this.value);
}

class CounterStateValid extends CounterState {
  const CounterStateValid(final int value) : super(value);
}

class CounterStateInvalid extends CounterState {
  final String invalidValue;
  final int previousValue;
  const CounterStateInvalid({
    required this.invalidValue,
    required this.previousValue,
  }) : super(previousValue);
}

@immutable
abstract class CounterEvent {
  const CounterEvent(final String value);
}

class IncreamentEvent extends CounterEvent {
  final String value;
  const IncreamentEvent(this.value) : super(value);
}

class DecreamentEvent extends CounterEvent {
  final String value;
  const DecreamentEvent(this.value) : super(value);
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterStateValid(0)) {
    on<IncreamentEvent>(
      (event, emit) {
        final input = int.tryParse(event.value);
        if (input == null) {
          emit(
            CounterStateInvalid(
                invalidValue: event.value, previousValue: state.value),
          );
        } else {
          emit(CounterStateValid(state.value + input));
        }
      },
    );
    on<DecreamentEvent>(
      (event, emit) {
        final input = int.tryParse(event.value);
        if (input == null) {
          emit(
            CounterStateInvalid(
                invalidValue: event.value, previousValue: state.value),
          );
        } else {
          emit(CounterStateValid(state.value - input));
        }
      },
    );
  }
}
