import 'package:flutter_cwa_plugin/utils/pluralize/src/pluralize.dart';

class J2mNameConverter {
  /// Converts a given string to a valid Dart class name, with options for array handling.
  static String toClassName(String input, {bool isArray = false}) {
    // Early return for empty input.
    if (input.isEmpty) return "";

    String result = input;

    // Convert to singular if it's marked as an array and is plural.
    if (isArray && Pluralize().isPlural(input)) {
      result = Pluralize().singular(input);
    }

    // Convert underscores/hyphens to CamelCase and ensure the first letter is uppercase.
    result = _toCamelCase(result);
    result = _capitalizeFirstLetter(result);

    return result;
  }

  /// Converts strings with underscores/hyphens to CamelCase.
  static String _toCamelCase(String input) {
    return input.splitMapJoin(
      RegExp(r'[_\-]'),
      onMatch: (_) => '',
      onNonMatch: (n) => n.substring(0, 1).toUpperCase() + n.substring(1),
    );
  }

  static String toPropertyName(String input) {
    if (input.length <= 2) return input;
    String str = _toCamelCase(input);
    return str[0].toLowerCase() + str.substring(1);
  }

  /// Capitalizes the first letter of a string.
  static String _capitalizeFirstLetter(String input) {
    return input[0].toUpperCase() + input.substring(1);
  }
}
