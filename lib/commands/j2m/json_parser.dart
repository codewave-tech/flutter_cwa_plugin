// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:cwa_plugin_core/cwa_plugin_core.dart';

JsonParser parseJson(Map? j) => JsonParser(j);

typedef Converter<T> = T? Function(dynamic value);

Converter<T> _converter<T>(Converter<T>? convert) => convert ?? ((v) => v as T);

class JsonParser {
  final Map? _json;

  JsonParser(Map? json) : _json = json;

  List<T?> list<T>(String fieldName, {Converter<T>? create}) {
    final List? l = _getField<List>(fieldName);
    return l != null ? l.map(_converter(create)).toList(growable: false) : [];
  }

  T? single<T>(String fieldName, {Converter<T>? create}) {
    final j = _getField(fieldName);
    try {
      T? val = j != null ? _converter(create)(j) : null;
      return val;
    } catch (e) {
      CWLogger.namedLog('$fieldName expects type $T but got ${j.runtimeType}');
      return null;
    }
  }

  Map<K, V> mapValues<K, V>(String fieldName,
      [Converter<V>? convertValue, Converter<K>? convertKey]) {
    final Map? m = _getField<Map>(fieldName);

    if (m == null) {
      return {};
    }

    Converter<K> _convertKey = _converter(convertKey);
    Converter<V> _convertValue = _converter(convertValue);

    Map<K, V> result = <K, V>{};
    m.forEach((k, v) {
      K? _key = _convertKey(k);
      V? _value = _convertValue(v);
      if (_key != null && _value != null) {
        result[_convertKey(k)!] = _convertValue(v)!;
      }
    });

    return result;
  }

  Map<K, V> mapEntries<K, V, T>(
      String fieldName, V Function(K k, T v) convert) {
    final Map? m = _getField(fieldName);

    if (m == null) {
      return {};
    }

    Map<K, V> result = <K, V>{};
    m.forEach((k, v) {
      result[k] = convert(k, v);
    });

    return result;
  }

  T? _getField<T>(String fieldName) {
    return _json?[fieldName] as T?;
  }
}
