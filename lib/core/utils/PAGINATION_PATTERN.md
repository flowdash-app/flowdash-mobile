# Pagination Pattern

This document describes the reusable pagination pattern used throughout the FlowDash mobile app.

## Overview

The pagination pattern provides a consistent way to handle cursor-based pagination across the app. It consists of:

1. **`PaginationState<T>`** - Generic state class for pagination
2. **`PaginationHelper<T>`** - Mixin for easy pagination management in widgets

## Usage

### 1. Use the Mixin in Your Widget

```dart
class _MyPageState extends ConsumerState<MyPage> 
    with PaginationHelper<MyItem> {
  
  @override
  void initState() {
    super.initState();
    initPagination();
    _loadItems();
  }

  Future<void> _loadItems({bool loadMore = false}) async {
    final repository = ref.read(myRepositoryProvider);
    
    if (loadMore) {
      await this.loadMore(
        fetchData: (cursor) => repository.getItems(
          cursor: cursor,
          limit: 20,
        ),
        onStateChanged: (state) => setState(() {}),
      );
    } else {
      await this.loadInitial(
        fetchData: () => repository.getItems(
          cursor: null,
          limit: 20,
        ),
        onStateChanged: (state) => setState(() {}),
      );
    }
  }
}
```

### 2. Access Pagination State in UI

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      // Show items
      ...paginationState.items.map((item) => ItemCard(item)),
      
      // Show "Load More" button
      if (paginationState.hasMore)
        OutlinedButton(
          onPressed: paginationState.isLoadingMore
              ? null
              : () => _loadItems(loadMore: true),
          child: Text(paginationState.isLoadingMore 
              ? 'Loading...' 
              : 'Load More'),
        ),
    ],
  );
}
```

### 3. Handle Loading and Error States

```dart
if (paginationState.isLoading && paginationState.items.isEmpty)
  // Show loading indicator
else if (paginationState.hasError && paginationState.items.isEmpty)
  // Show error message with retry button
else if (paginationState.items.isEmpty)
  // Show empty state
else
  // Show items list
```

## PaginationState Properties

- `items: List<T>` - Accumulated items from all loaded pages
- `nextCursor: String?` - Cursor for the next page (null if no more pages)
- `isLoading: bool` - True when loading initial page
- `isLoadingMore: bool` - True when loading next page
- `error: String?` - Error message if loading failed

## Helper Methods

- `initPagination()` - Initialize/reset pagination state
- `loadInitial()` - Load first page
- `loadMore()` - Load next page (appends to existing items)
- `refresh()` - Reset and reload from start

## Backend Requirements

Your repository methods should return:
```dart
Future<({List<T> data, String? nextCursor})> getItems({
  String? cursor,
  int limit = 20,
});
```

## Example: Workflow Executions

See `WorkflowDetailsPage` for a complete example of using the pagination pattern.

