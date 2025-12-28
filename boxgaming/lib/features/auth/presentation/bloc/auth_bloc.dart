import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../../../core/error/failures.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;
  final ChangePasswordUseCase changePasswordUseCase;

  AuthBloc({
    required this.signUpUseCase,
    required this.signInUseCase,
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
    required this.changePasswordUseCase,
  }) : super(AuthInitial()) {
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
    on<ChangePasswordEvent>(_onChangePassword);
  }

  Future<void> _onSignUp(
    SignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final result = await signUpUseCase(event.email, event.password, event.name);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      emit(AuthError('Failed to sign up: ${e.toString()}'));
    }
  }

  Future<void> _onSignIn(
    SignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (isClosed) return;
    try {
      if (!isClosed) {
        emit(AuthLoading());
      }
      final result = await signInUseCase(event.email, event.password);
      if (isClosed) return;
      result.fold(
        (failure) {
          if (!isClosed) {
            emit(AuthError(failure.message));
          }
        },
        (user) {
          if (!isClosed) {
            print('🔐 Sign in successful - User ID: ${user.id}, Requires password change: ${user.requiresPasswordChange}');
            emit(AuthAuthenticated(user));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(AuthError('Failed to sign in: ${e.toString()}'));
      }
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Don't show loading for initial auth check to avoid spinner on app start
    final result = await getCurrentUserUseCase();
    result.fold(
      (failure) {
        // AuthFailure or ServerFailure with 401 means not authenticated - this is normal
        if (failure is AuthFailure || failure.message.contains('Unauthorized') || failure.message.contains('Session expired')) {
          emit(AuthUnauthenticated());
        } else {
          // Other errors - still show as unauthenticated but log the error
          print('Auth check error: ${failure.message}');
          emit(AuthUnauthenticated());
        }
      },
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(AuthLoading());
      final result = await changePasswordUseCase(event.currentPassword, event.newPassword);
      
      bool passwordChanged = false;
      result.fold(
        (failure) {
          if (!isClosed) {
            emit(AuthError(failure.message));
          }
        },
        (_) {
          passwordChanged = true;
        },
      );
      
      // If password change was successful, refresh user to get updated requires_password_change flag
      if (passwordChanged && !isClosed) {
        try {
          final userResult = await getCurrentUserUseCase();
          if (isClosed) return;
          userResult.fold(
            (failure) {
              if (!isClosed) {
                emit(AuthError('Password changed but failed to refresh user: ${failure.message}'));
              }
            },
            (user) {
              if (!isClosed) {
                emit(AuthAuthenticated(user));
              }
            },
          );
        } catch (e) {
          if (!isClosed) {
            emit(AuthError('Failed to refresh user after password change: ${e.toString()}'));
          }
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError('Failed to change password: ${e.toString()}'));
      }
    }
  }
}

