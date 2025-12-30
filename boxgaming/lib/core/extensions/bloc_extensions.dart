import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension SafeBlocContextExtension on BuildContext {
  void safeReadBlocAdd<B extends BlocBase, E>(
    E event,
  ) {
    if (!mounted) return;
    final bloc = read<B>();
    if (!bloc.isClosed) {
      // BlocBase doesn't have add, but Bloc does
      // Check if it's a Bloc and use the add method
      if (bloc is Bloc) {
        // Cast to Bloc to access add method - using dynamic for the type parameters
        // since we don't know the exact Event/State types at compile time
        final typedBloc = bloc as Bloc<dynamic, dynamic>;
        typedBloc.add(event);
      }
    }
  }
}

