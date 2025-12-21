import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final InitiatePaymentUseCase initiatePaymentUseCase;

  PaymentsBloc({required this.initiatePaymentUseCase}) : super(PaymentsInitial()) {
    on<InitiatePaymentEvent>(_onInitiatePayment);
  }

  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(PaymentsLoading());
    final result = await initiatePaymentUseCase(event.bookingId, event.gateway);
    result.fold(
      (failure) => emit(PaymentsError(failure.message)),
      (payment) => emit(PaymentInitiated(payment)),
    );
  }
}


