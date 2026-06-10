class NavigationTabIndexResolver {
  const NavigationTabIndexResolver(this._mainTabRoutes);

  final List<String> _mainTabRoutes;

  int resolve(String location) {
    final index = _mainTabRoutes.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }
}
