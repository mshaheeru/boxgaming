import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/venues/presentation/bloc/venues_bloc.dart';
import '../../features/venues/domain/usecases/get_venues_usecase.dart';
import '../../features/venues/domain/usecases/get_venue_details_usecase.dart';
import '../../features/venues/domain/repositories/venues_repository.dart';
import '../../features/venues/data/repositories/venues_repository_impl.dart';
import '../../features/venues/data/datasources/venues_remote_datasource.dart';
import '../../features/bookings/presentation/bloc/bookings_bloc.dart';
import '../../features/bookings/domain/usecases/get_available_slots_usecase.dart';
import '../../features/bookings/domain/usecases/create_booking_usecase.dart';
import '../../features/bookings/domain/usecases/get_my_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/get_booking_details_usecase.dart';
import '../../features/bookings/domain/usecases/cancel_booking_usecase.dart';
import '../../features/bookings/domain/repositories/bookings_repository.dart';
import '../../features/bookings/data/repositories/bookings_repository_impl.dart';
import '../../features/bookings/data/datasources/bookings_remote_datasource.dart';
import '../../features/payments/presentation/bloc/payments_bloc.dart';
import '../../features/payments/domain/usecases/initiate_payment_usecase.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/data/datasources/payments_remote_datasource.dart';
import '../../features/owner/presentation/bloc/owner_bloc.dart';
import '../../features/owner/domain/usecases/get_today_bookings_usecase.dart';
import '../../features/owner/domain/usecases/mark_booking_started_usecase.dart';
import '../../features/owner/domain/usecases/mark_booking_completed_usecase.dart';
import '../../features/owner/domain/repositories/owner_repository.dart';
import '../../features/owner/data/repositories/owner_repository_impl.dart';
import '../../features/owner/data/datasources/owner_remote_datasource.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Core - Initialize storage first
  sl.registerLazySingleton(() => LocalStorage());
  sl.registerLazySingleton(() => SecureStorage());
  
  //! Core - Network
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiClient(sl()));

  //! Features - Auth
  // Bloc (Factory - new instance each time)
  sl.registerFactory(
    () => AuthBloc(
      signUpUseCase: sl(),
      signInUseCase: sl(),
      getCurrentUserUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use cases (LazySingleton - single instance)
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository (LazySingleton)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources (LazySingleton)
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl(),
      localStorage: sl(),
    ),
  );

  //! Features - Venues
  sl.registerFactory(
    () => VenuesBloc(
      getVenuesUseCase: sl(),
      getVenueDetailsUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetVenuesUseCase(sl()));
  sl.registerLazySingleton(() => GetVenueDetailsUseCase(sl()));
  sl.registerLazySingleton<VenuesRepository>(
    () => VenuesRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<VenuesRemoteDataSource>(
    () => VenuesRemoteDataSourceImpl(sl()),
  );

  //! Features - Bookings
  sl.registerFactory(
    () => BookingsBloc(
      getAvailableSlotsUseCase: sl(),
      createBookingUseCase: sl(),
      getMyBookingsUseCase: sl(),
      getBookingDetailsUseCase: sl(),
      cancelBookingUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetAvailableSlotsUseCase(sl()));
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBookingsUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingDetailsUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton<BookingsRepository>(
    () => BookingsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<BookingsRemoteDataSource>(
    () => BookingsRemoteDataSourceImpl(sl()),
  );

  //! Features - Payments
  sl.registerFactory(
    () => PaymentsBloc(initiatePaymentUseCase: sl()),
  );
  sl.registerLazySingleton(() => InitiatePaymentUseCase(sl()));
  sl.registerLazySingleton<PaymentsRepository>(
    () => PaymentsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<PaymentsRemoteDataSource>(
    () => PaymentsRemoteDataSourceImpl(sl()),
  );

  //! Features - Owner
  sl.registerFactory(
    () => OwnerBloc(
      getTodayBookingsUseCase: sl(),
      markBookingStartedUseCase: sl(),
      markBookingCompletedUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetTodayBookingsUseCase(sl()));
  sl.registerLazySingleton(() => MarkBookingStartedUseCase(sl()));
  sl.registerLazySingleton(() => MarkBookingCompletedUseCase(sl()));
  sl.registerLazySingleton<OwnerRepository>(
    () => OwnerRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<OwnerRemoteDataSource>(
    () => OwnerRemoteDataSourceImpl(sl()),
  );
}

