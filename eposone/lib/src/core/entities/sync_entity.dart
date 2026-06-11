import 'package:isar/isar.dart';

/// Entidad base para todas las entidades de ePosOne.
/// Obligatorio: local_id, server_id, sync_status, created_at, updated_at, deleted_at
abstract class SyncEntity {
  /// ID local generado en el dispositivo (UUID v4)
  final String localId;

  /// ID del servidor (null hasta que se sincronice)
  final String? serverId;

  /// Estado de sincronización
  @enumerated
  final SyncStatus syncStatus;

  /// Fecha de creación local
  final DateTime createdAt;

  /// Fecha de última actualización local
  final DateTime updatedAt;

  /// Fecha de eliminación lógica (null si no está eliminada)
  final DateTime? deletedAt;

  const SyncEntity({
    required this.localId,
    this.serverId,
    this.syncStatus = SyncStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Marca la entidad como modificada localmente
  SyncEntity markAsModified();

  /// Marca la entidad como sincronizada con el servidor
  SyncEntity markAsSynced(String serverId);

  /// Marca la entidad para eliminación lógica
  SyncEntity markAsDeleted();

  /// Indica si la entidad está eliminada lógicamente
  bool get isDeleted => deletedAt != null;

  /// Indica si la entidad tiene cambios pendientes de sincronización
  bool get isPendingSync => syncStatus == SyncStatus.pending || syncStatus == SyncStatus.modified;

  /// Indica si la entidad ya fue sincronizada con el servidor
  bool get isSynced => syncStatus == SyncStatus.synced && serverId != null;
}

/// Estados de sincronización posibles
enum SyncStatus {
  /// Creado/Modificado localmente, pendiente de sincronizar
  pending,

  /// Sincronizado correctamente con el servidor
  synced,

  /// Modificado después de ser sincronizado, requiere re-sincronización
  modified,

  /// Error en la última sincronización
  error,
}