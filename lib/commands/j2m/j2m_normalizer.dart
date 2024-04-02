class J2mNormalizer {
  static void normalizeMap(
    Map<String, dynamic> originalMap,
    Map<String, dynamic> traversedMap,
    List<dynamic> accessor,
  ) {
    traversedMap.forEach((key, value) {
      if (value is Map) {
        normalizeMap(originalMap, traversedMap[key], [...accessor, key]);
      } else if (value is List) {
        if (value.isEmpty) {
          traversedMap[key] =
              _valReplacement(originalMap, List.from([...accessor, key]));
        }

        if (value.isNotEmpty && value[0] is Map) {
          normalizeMap(originalMap, value[0], [...accessor, key, 0]);
        }
      }
    });
  }

  static dynamic _valReplacement(
    Map<String, dynamic> traversedMap,
    List<dynamic> accessor,
  ) {
    List<int> traversalsleft = accessor.whereType<int>().toList();

    if (traversalsleft.isEmpty) {
      if (accessor.isNotEmpty) {
        dynamic _currentTraversal = traversedMap;
        for (int idx = 0; idx < accessor.length; idx++) {
          _currentTraversal = _currentTraversal[accessor[idx]];
        }
        return _currentTraversal;
      }

      return [];
    }

    int traversalIdx = -1;
    dynamic _currentTraversal = traversedMap;

    for (int idx = 0; idx < accessor.length; idx++) {
      if (accessor[idx] is int) {
        traversalIdx = idx;
        break;
      }

      _currentTraversal = _currentTraversal[accessor[idx]];
    }

    if (_currentTraversal is List) {
      for (int idx = 0; idx < _currentTraversal.length; idx++) {
        dynamic data = _valReplacement(
          _currentTraversal[idx],
          accessor.sublist(traversalIdx + 1),
        );
        if (data is List && data.isEmpty) continue;
        return data;
      }
    }
  }
}
