enum SyncStatus {
  synced('synced'),
  pendingCreate('pending_create'),
  pendingUpdate('pending_update');

  final String value;
  const SyncStatus(this.value);

  static SyncStatus fromString(String value) => SyncStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => SyncStatus.synced,
      );
}

enum SyncOperation {
  create('create'),
  update('update'),
  depot('depot'),
  retrait('retrait'),
  transfert('transfert');

  final String value;
  const SyncOperation(this.value);

  static SyncOperation fromString(String value) =>
      SyncOperation.values.firstWhere((o) => o.value == value);
}

enum SyncEntityType {
  client('client'),
  transaction('transaction'),
  compte('compte'),
  credit('credit');

  final String value;
  const SyncEntityType(this.value);
}

