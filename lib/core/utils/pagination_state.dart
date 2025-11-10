/// Generic pagination state for managing cursor-based pagination
class PaginationState<T> {
  final List<T> items;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaginationState({
    this.items = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasMore => nextCursor != null;
  bool get isEmpty => items.isEmpty && !isLoading;
  bool get hasError => error != null;
}

