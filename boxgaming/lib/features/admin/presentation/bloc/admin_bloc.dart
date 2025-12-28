import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_owner_usecase.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import 'admin_event.dart';
import 'admin_state.dart';
import '../../../../core/di/injection_container.dart' as di;

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final CreateOwnerUseCase createOwnerUseCase;
  final AdminRemoteDataSource adminRemoteDataSource;

  AdminBloc({
    required this.createOwnerUseCase,
    required this.adminRemoteDataSource,
  }) : super(AdminInitial()) {
    on<CreateOwnerEvent>(_onCreateOwner);
    on<LoadAdminDashboardEvent>(_onLoadDashboard);
    on<LoadOwnersEvent>(_onLoadOwners);
    on<ResetOwnerPasswordEvent>(_onResetOwnerPassword);
  }

  Future<void> _onCreateOwner(
    CreateOwnerEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final result = await createOwnerUseCase(
        email: event.email,
        tenantName: event.tenantName,
        name: event.name,
        temporaryPassword: event.temporaryPassword,
      );
      result.fold(
        (failure) {
          print('❌ Create owner failed: ${failure.message}');
          emit(AdminError(failure.message));
        },
        (response) {
          print('✅ Owner created! Email: ${response.email}, Password: ${response.temporaryPassword}');
          emit(OwnerCreatedSuccess(
            email: response.email,
            temporaryPassword: response.temporaryPassword,
          ));
        },
      );
    } catch (e) {
      print('❌ Exception creating owner: ${e.toString()}');
      emit(AdminError('Failed to create owner: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDashboard(
    LoadAdminDashboardEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final dashboardData = await adminRemoteDataSource.getDashboardStats();
      emit(AdminDashboardLoaded(
        totalTenants: dashboardData['totalTenants'] ?? 0,
        totalOwners: dashboardData['totalOwners'] ?? 0,
        activeVenues: dashboardData['activeVenues'] ?? 0,
        totalBookings: dashboardData['totalBookings'] ?? 0,
      ));
    } catch (e) {
      emit(AdminError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOwners(
    LoadOwnersEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final owners = await adminRemoteDataSource.getAllOwners();
      emit(OwnersLoaded(owners));
    } catch (e) {
      emit(AdminError('Failed to load owners: ${e.toString()}'));
    }
  }

  Future<void> _onResetOwnerPassword(
    ResetOwnerPasswordEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(AdminLoading());
      final result = await adminRemoteDataSource.resetOwnerPassword(event.tenantId);
      emit(PasswordResetSuccess(
        email: result['email'] ?? '',
        temporaryPassword: result['temporaryPassword'] ?? '',
      ));
      // Reload owners to show updated password
      add(LoadOwnersEvent());
    } catch (e) {
      emit(AdminError('Failed to reset password: ${e.toString()}'));
    }
  }
}

