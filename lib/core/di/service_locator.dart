import 'package:get_it/get_it.dart';

import '../services/permissions_service.dart';
import '../services/storage_service.dart';
import '../services/media_store_service.dart';
import '../services/filename_service.dart';
import '../services/ringtone_configuration_service.dart';
import '../services/ringtone_management_service.dart';
import '../network/api_client.dart';
import '../../features/downloads/data/datasources/download_local_ds.dart';
import '../../features/downloads/data/datasources/download_remote_ds.dart';
import '../../features/downloads/data/repositories/download_repository_impl.dart';
import '../../features/downloads/domain/repositories/download_repository.dart';
import '../../features/downloads/domain/usecases/download_tone.dart';
import '../../features/downloads/domain/usecases/get_downloaded_files.dart';
import '../../features/downloads/domain/usecases/is_file_downloaded.dart';
import '../../features/downloads/presentation/providers/downloads_provider.dart';
import '../../features/contacts/data/datasources/contacts_native_ds.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/domain/usecases/get_contacts.dart';
import '../../features/contacts/domain/usecases/request_contacts_permission.dart';
import '../../features/contacts/presentation/providers/contacts_provider.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Core services - ApiClient needs to be initialized asynchronously first
  final apiClient = await ApiClient.getInstance();
  sl.registerSingleton<ApiClient>(apiClient);
  
  sl.registerLazySingleton<PermissionsService>(
    () => PermissionsServiceImpl(),
  );
  
  sl.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(),
  );
  
  sl.registerLazySingleton<MediaStoreService>(
    () => MediaStoreServiceImpl(),
  );
  
  sl.registerLazySingleton<FilenameService>(
    () => FilenameServiceImpl(),
  );

  // Ringtone services
  sl.registerLazySingleton<RingtoneConfigurationService>(
    () => RingtoneConfigurationServiceImpl(),
  );

  sl.registerLazySingleton<RingtoneManagementService>(
    () => RingtoneManagementServiceImpl(
      permissionsService: sl(),
      ringtoneConfigurationService: sl(),
    ),
  );

  // Downloads - Data sources
  sl.registerLazySingleton<DownloadLocalDataSource>(
    () => DownloadLocalDataSourceImpl(),
  );
  
  sl.registerLazySingleton<DownloadRemoteDataSource>(
    () => DownloadRemoteDataSourceImpl(),
  );

  // Downloads - Repository
  sl.registerLazySingleton<DownloadRepository>(
    () => DownloadRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      permissionsService: sl(),
      storageService: sl(),
      mediaStoreService: sl(),
      filenameService: sl(),
    ),
  );

  // Downloads - Use cases
  sl.registerLazySingleton(() => DownloadTone(sl()));
  sl.registerLazySingleton(() => GetDownloadedFiles(sl()));
  sl.registerLazySingleton(() => IsFileDownloaded(sl()));

  // Downloads - Provider
  sl.registerFactory(
    () => DownloadsProvider(
      downloadTone: sl(),
      getDownloadedFiles: sl(),
      isFileDownloaded: sl(),
      downloadRepository: sl(),
    ),
  );

  // Contacts - Data sources
  sl.registerLazySingleton<ContactsNativeDataSource>(
    () => ContactsNativeDataSourceImpl(),
  );

  // Contacts - Repository
  sl.registerLazySingleton<ContactsRepository>(
    () => ContactsRepositoryImpl(
      nativeDataSource: sl(),
    ),
  );

  // Contacts - Use cases
  sl.registerLazySingleton(() => GetContacts(sl()));
  sl.registerLazySingleton(() => RequestContactsPermission(sl()));

  // Contacts - Provider
  sl.registerFactory(
    () => ContactsProvider(
      getContacts: sl(),
      requestContactsPermission: sl(),
    ),
  );
}