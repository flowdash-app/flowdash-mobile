import 'package:flowdash_mobile/core/utils/pagination_state.dart';

/// Helper mixin for managing pagination state in widgets
mixin PaginationHelper<T> {
  PaginationState<T> _paginationState = PaginationState<T>();

  PaginationState<T> get paginationState => _paginationState;

  /// Initialize pagination state
  void initPagination() {
    _paginationState = PaginationState<T>();
  }

  /// Update pagination state
  void updatePaginationState(PaginationState<T> newState) {
    _paginationState = newState;
  }

  /// Load initial page
  Future<void> loadInitial({
    required Future<({List<T> data, String? nextCursor})> Function() fetchData,
    void Function(PaginationState<T>)? onStateChanged,
  }) async {
    if (_paginationState.isLoading) return;

    _paginationState = _paginationState.copyWith(
      isLoading: true,
      items: [],
      nextCursor: null,
      clearError: true,
    );
    onStateChanged?.call(_paginationState);

    try {
      final result = await fetchData();
      _paginationState = _paginationState.copyWith(
        items: result.data,
        nextCursor: result.nextCursor,
        isLoading: false,
      );
      onStateChanged?.call(_paginationState);
    } catch (e) {
      _paginationState = _paginationState.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      onStateChanged?.call(_paginationState);
      rethrow;
    }
  }

  /// Load more items (next page)
  Future<void> loadMore({
    required Future<({List<T> data, String? nextCursor})> Function(String cursor) fetchData,
    void Function(PaginationState<T>)? onStateChanged,
  }) async {
    if (!_paginationState.hasMore || _paginationState.isLoadingMore) return;

    _paginationState = _paginationState.copyWith(isLoadingMore: true);
    onStateChanged?.call(_paginationState);

    try {
      final result = await fetchData(_paginationState.nextCursor!);
      _paginationState = _paginationState.copyWith(
        items: [..._paginationState.items, ...result.data],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
      );
      onStateChanged?.call(_paginationState);
    } catch (e) {
      _paginationState = _paginationState.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
      onStateChanged?.call(_paginationState);
      rethrow;
    }
  }

  /// Refresh pagination (reload from start)
  Future<void> refresh({
    required Future<({List<T> data, String? nextCursor})> Function() fetchData,
    void Function(PaginationState<T>)? onStateChanged,
  }) async {
    _paginationState = PaginationState<T>();
    await loadInitial(fetchData: fetchData, onStateChanged: onStateChanged);
  }
}

