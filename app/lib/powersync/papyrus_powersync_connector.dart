import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/auth_repository.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/powersync/powersync_book_mapper.dart';
import 'package:papyrus/powersync/library_row_mapper.dart';
import 'package:powersync/powersync.dart';

class PapyrusPowerSyncConnector extends PowerSyncBackendConnector {
  final AuthRepository authRepository;
  final PapyrusApiConfig config;
  final Future<void> Function()? onUploadComplete;

  PapyrusPowerSyncConnector({required this.authRepository, required this.config, this.onUploadComplete});

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    try {
      final token = await authRepository.createPowerSyncToken();

      return PowerSyncCredentials(
        endpoint: config.powerSyncServiceUri.toString(),
        token: token.token,
        expiresAt: DateTime.now().add(Duration(seconds: token.expiresIn)),
      );
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        return null;
      }

      rethrow;
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    while (true) {
      final transaction = await database.getNextCrudTransaction();

      if (transaction == null) {
        return;
      }

      final batch = powerSyncUploadBatchFromCrud(transaction.crud);

      if (batch.isEmpty) {
        await transaction.complete();
        continue;
      }

      await authRepository.uploadPowerSyncBatch(batch);
      await transaction.complete();
      await onUploadComplete?.call();
    }
  }
}

List<Map<String, dynamic>> powerSyncUploadBatchFromCrud(List<CrudEntry> entries) {
  return entries.map(powerSyncCrudEntryToJson).toList();
}

Map<String, dynamic> powerSyncCrudEntryToJson(CrudEntry entry) {
  final json = entry.toJson();

  if (entry.table == 'books') {
    json['data'] = PowerSyncBookMapper.decodeUploadData(entry.opData);
  } else if (entry.opData != null) {
    json['data'] = decodeLibraryRow(entry.opData!);
  }

  return json;
}
