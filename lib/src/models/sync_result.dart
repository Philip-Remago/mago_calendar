class SyncResult<T> {
  const SyncResult({
    required this.upserts,
    required this.removedIds,
    this.nextToken,
  });

  final List<T> upserts;
  final List<String> removedIds;
  final String? nextToken;
}
