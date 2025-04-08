import 'dart:io';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final Logger _logger = Logger('HydratedBlocStorage');

/// Service responsible for initializing HydratedBloc storage
class HydratedBlocStorage {
  static const String storageDirName = 'bloc_storage';

  /// Initializes HydratedBloc storage
  Future<void> initialize() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String storagePath = p.join(appDir.path, storageDirName);

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storagePath),
    );

    _logger.config('HydratedBloc storage initialized at: $storagePath');
  }
}
