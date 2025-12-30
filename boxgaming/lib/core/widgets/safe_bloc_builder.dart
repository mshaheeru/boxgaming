import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SafeBlocBuilder<B extends BlocBase<S>, S> extends StatelessWidget {
  final Widget Function(BuildContext context, S state) builder;
  final B? bloc;
  final bool Function(S previous, S current)? buildWhen;

  const SafeBlocBuilder({
    super.key,
    required this.builder,
    this.bloc,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: bloc,
      buildWhen: (previous, current) {
        // Only rebuild if bloc is not closed
        final b = bloc ?? context.read<B>();
        if (b.isClosed) {
          return false;
        }
        // Apply custom buildWhen if provided
        if (buildWhen != null) {
          return buildWhen!(previous, current);
        }
        return true;
      },
      builder: (context, state) {
        final b = bloc ?? context.read<B>();
        if (b.isClosed) {
          return const SizedBox.shrink();
        }
        return builder(context, state);
      },
    );
  }
}

