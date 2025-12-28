import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  const SignUpEvent(this.email, this.password, [this.name]);

  @override
  List<Object> get props => [email, password, name ?? ''];
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;
  const SignInEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class ChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  const ChangePasswordEvent(this.currentPassword, this.newPassword);

  @override
  List<Object> get props => [currentPassword, newPassword];
}


