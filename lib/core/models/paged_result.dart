/// A single page of results from a paginated endpoint.
class PagedResult<T> {
  const PagedResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}
