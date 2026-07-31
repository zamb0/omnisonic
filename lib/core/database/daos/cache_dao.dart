import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import '../../entities/cache_entry.dart';

part 'cache_dao.g.dart';

@DriftAccessor(tables: [CacheEntriesTable])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

  // Convert between entity and database models
  CacheEntry _fromData(CacheEntryData data) {
    return CacheEntry(
      trackId: data.trackId,
      filePath: data.filePath,
      fileSize: data.fileSize,
      cachedAt: data.cachedAt,
      lastAccessed: data.lastAccessed,
      isComplete: data.isComplete,
      isPinned: data.isPinned,
    );
  }

  CacheEntriesTableCompanion _toCompanion(CacheEntry entry) {
    return CacheEntriesTableCompanion(
      trackId: Value(entry.trackId),
      filePath: Value(entry.filePath),
      fileSize: Value(entry.fileSize),
      cachedAt: Value(entry.cachedAt),
      lastAccessed: Value(entry.lastAccessed),
      isComplete: Value(entry.isComplete),
      isPinned: Value(entry.isPinned),
    );
  }

  // CRUD operations
  Future<List<CacheEntry>> getAllCacheEntries() async {
    final data = await select(cacheEntriesTable).get();
    return data.map(_fromData).toList();
  }

  Future<CacheEntry?> getCacheEntryByTrackId(String trackId) async {
    final data = await (select(
      cacheEntriesTable,
    )..where((tbl) => tbl.trackId.equals(trackId))).getSingleOrNull();
    return data != null ? _fromData(data) : null;
  }

  Future<List<CacheEntry>> getCompleteCacheEntries() async {
    final data = await (select(
      cacheEntriesTable,
    )..where((tbl) => tbl.isComplete.equals(true))).get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getIncompleteCacheEntries() async {
    final data = await (select(
      cacheEntriesTable,
    )..where((tbl) => tbl.isComplete.equals(false))).get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getPinnedCacheEntries() async {
    final data = await (select(
      cacheEntriesTable,
    )..where((tbl) => tbl.isPinned.equals(true))).get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getUnpinnedCacheEntries() async {
    final data = await (select(
      cacheEntriesTable,
    )..where((tbl) => tbl.isPinned.equals(false))).get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getCacheEntriesOrderedByLastAccessed({
    bool ascending = false,
  }) async {
    final query = select(cacheEntriesTable)
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.lastAccessed,
          mode: ascending ? OrderingMode.asc : OrderingMode.desc,
        ),
      ]);
    final data = await query.get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getCacheEntriesOrderedBySize({
    bool ascending = true,
  }) async {
    final query = select(cacheEntriesTable)
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.fileSize,
          mode: ascending ? OrderingMode.asc : OrderingMode.desc,
        ),
      ]);
    final data = await query.get();
    return data.map(_fromData).toList();
  }

  Future<void> insertCacheEntry(CacheEntry entry) async {
    await into(cacheEntriesTable).insert(_toCompanion(entry));
  }

  Future<void> updateCacheEntry(CacheEntry entry) async {
    await update(cacheEntriesTable).replace(_toCompanion(entry));
  }

  Future<void> updateCacheEntryLastAccessed(
    String trackId,
    DateTime lastAccessed,
  ) async {
    await (update(cacheEntriesTable)
          ..where((tbl) => tbl.trackId.equals(trackId)))
        .write(CacheEntriesTableCompanion(lastAccessed: Value(lastAccessed)));
  }

  Future<void> updateCacheEntryCompletion(
    String trackId,
    bool isComplete,
  ) async {
    await (update(cacheEntriesTable)
          ..where((tbl) => tbl.trackId.equals(trackId)))
        .write(CacheEntriesTableCompanion(isComplete: Value(isComplete)));
  }

  Future<void> updateCacheEntryPinned(String trackId, bool isPinned) async {
    await (update(cacheEntriesTable)
          ..where((tbl) => tbl.trackId.equals(trackId)))
        .write(CacheEntriesTableCompanion(isPinned: Value(isPinned)));
  }

  Future<void> deleteCacheEntry(String trackId) async {
    await (delete(
      cacheEntriesTable,
    )..where((tbl) => tbl.trackId.equals(trackId))).go();
  }

  Future<void> deleteCacheEntries(List<String> trackIds) async {
    await (delete(
      cacheEntriesTable,
    )..where((tbl) => tbl.trackId.isIn(trackIds))).go();
  }

  // Cache management operations
  Future<int> getTotalCacheSize() async {
    final query = selectOnly(cacheEntriesTable)
      ..addColumns([cacheEntriesTable.fileSize.sum()]);

    final result = await query.getSingleOrNull();
    return result?.read(cacheEntriesTable.fileSize.sum()) ?? 0;
  }

  Future<int> getPinnedCacheSize() async {
    final query = selectOnly(cacheEntriesTable)
      ..addColumns([cacheEntriesTable.fileSize.sum()])
      ..where(cacheEntriesTable.isPinned.equals(true));

    final result = await query.getSingleOrNull();
    return result?.read(cacheEntriesTable.fileSize.sum()) ?? 0;
  }

  Future<int> getCacheEntryCount() async {
    final query = selectOnly(cacheEntriesTable)..addColumns([countAll()]);

    final result = await query.getSingle();
    return result.read(countAll())!;
  }

  Future<int> getPinnedCacheEntryCount() async {
    final query = selectOnly(cacheEntriesTable)
      ..addColumns([countAll()])
      ..where(cacheEntriesTable.isPinned.equals(true));

    final result = await query.getSingle();
    return result.read(countAll())!;
  }

  Future<List<CacheEntry>> getLeastRecentlyAccessedEntries(int limit) async {
    final query = select(cacheEntriesTable)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.lastAccessed)])
      ..limit(limit);

    final data = await query.get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getOldestCacheEntries(int limit) async {
    final query = select(cacheEntriesTable)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.cachedAt)])
      ..limit(limit);

    final data = await query.get();
    return data.map(_fromData).toList();
  }

  Future<List<CacheEntry>> getLargestCacheEntries(int limit) async {
    final query = select(cacheEntriesTable)
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.fileSize, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    final data = await query.get();
    return data.map(_fromData).toList();
  }

  // Cleanup operations
  Future<void> deleteOldCacheEntries(DateTime cutoffDate) async {
    await (delete(
      cacheEntriesTable,
    )..where((tbl) => tbl.cachedAt.isSmallerThanValue(cutoffDate))).go();
  }

  Future<void> deleteIncompleteCacheEntries() async {
    await (delete(
      cacheEntriesTable,
    )..where((tbl) => tbl.isComplete.equals(false))).go();
  }

  Future<void> clearAllCacheEntries() async {
    await delete(cacheEntriesTable).go();
  }

  // Watch for changes
  Stream<List<CacheEntry>> watchAllCacheEntries() {
    return select(
      cacheEntriesTable,
    ).watch().map((data) => data.map(_fromData).toList());
  }

  Stream<CacheEntry?> watchCacheEntryByTrackId(String trackId) {
    return (select(cacheEntriesTable)
          ..where((tbl) => tbl.trackId.equals(trackId)))
        .watchSingleOrNull()
        .map((data) => data != null ? _fromData(data) : null);
  }

  Stream<int> watchTotalCacheSize() {
    final query = selectOnly(cacheEntriesTable)
      ..addColumns([cacheEntriesTable.fileSize.sum()]);

    return query.watchSingle().map(
      (result) => result.read(cacheEntriesTable.fileSize.sum()) ?? 0,
    );
  }
}
