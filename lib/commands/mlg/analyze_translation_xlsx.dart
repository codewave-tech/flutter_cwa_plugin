part of mlg_command;

extension TranslationFileAnalyzer on ArchBuddyMLG {
  Map<String, AnalyzedLangugaeData> analyzeExcelFile(String path) {
    if (!File(path).existsSync()) {
      CWLogger.namedLog("Failed to analyze : File $path not found");
      exit(2);
    }
    Uint8List bytes = File(path).readAsBytesSync();
    Excel excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      CWLogger.i.stderr(
          "Missing the translation sheet!, please provide a valid file.");
      exit(2);
    }

    String table = excel.tables.keys.first;
    Sheet sheet = excel.tables[table]!;
    int maxColumns = excel.tables[table]!.maxColumns;
    int maxRows = excel.tables[table]!.maxRows;
    if (!_isFileValid(sheet)) {
      CWLogger.i.stderr(
          "Invalid file, unable to find auto generated content for mapping");
      exit(2);
    }

    Map<CellIndex, Map<String, String>> languageIndex =
        _traverseAndGetValidLanguageIdxs(
      sheet: sheet,
      maxColumn: maxColumns,
      maxRow: maxRows,
    );

    if (languageIndex.isEmpty) {
      CWLogger.namedLog(
        "No Tranlations has been found!! If you think this message is incorrect, please check the format of the file once, if not contact the CLI maintainer.",
        loggerColor: CWLoggerColor.yellow,
      );
      exit(2);
    }

    return generateAnalyzedLanguageHashMap(
      sheet: sheet,
      languageIndexMap: languageIndex,
      maxRow: maxRows,
    );
  }

  Map<String, AnalyzedLangugaeData> generateAnalyzedLanguageHashMap({
    required Sheet sheet,
    required Map<CellIndex, Map<String, String>> languageIndexMap,
    required int maxRow,
  }) {
    try {
      Map<String, AnalyzedLangugaeData> mp = {};
      languageIndexMap.forEach((key, value) {
        int rowIndex = key.rowIndex + 1;
        int colIdx = key.columnIndex;
        Map<String, String> varNameToContentMap = {};
        for (int idx = rowIndex; idx < maxRow; idx++) {
          String? varName = sheet.rows[idx][0]?.value.toString();
          String? content = sheet.rows[idx][colIdx]?.value.toString();
          if (varName == null || content == null) {
            CWLogger.namedLog(
              "Invalid content found at row : $idx, column : $colIdx",
              loggerColor: CWLoggerColor.red,
            );
            continue;
          }
          varNameToContentMap[varName] = content;
        }
        String code = value['code']!;
        mp[code] = AnalyzedLangugaeData(
          languageName: value['name']!,
          languageCode: code,
          varNameToContentMap: varNameToContentMap,
        );
      });
      print(mp);
      return mp;
    } catch (e) {
      CWLogger.i.stderr(e.toString());
      exit(2);
    }
  }

  Map<CellIndex, Map<String, String>> _traverseAndGetValidLanguageIdxs({
    required Sheet sheet,
    required int maxColumn,
    required int maxRow,
  }) {
    int rowIdx = 10;
    Map<CellIndex, Map<String, String>> idxMp = {};
    for (int idx = 2; idx < maxColumn; idx++) {
      Data? data = sheet.rows[rowIdx][idx];
      Map<String, String>? extractedData =
          extractLanguageDetails(data?.value.toString());
      if (_validLanguageHeader(extractedData)) {
        CellIndex cellIdx = CellIndex.indexByColumnRow(
          columnIndex: idx,
          rowIndex: rowIdx,
        );
        idxMp[cellIdx] = extractedData!;

        CWLogger.namedLog(
          'Found Translation \nLangauge : ${extractedData['name']}\ncode : ${extractedData['code']}',
          loggerColor: CWLoggerColor.green,
        );
      }
    }

    return idxMp;
  }

  bool _validLanguageHeader(Map<String, String>? extractedData) {
    return extractedData != null &&
        extractedData.containsKey('name') &&
        extractedData['name']!.isNotEmpty &&
        extractedData.containsKey('code') &&
        extractedData['code']!.isNotEmpty;
  }

  Map<String, String>? extractLanguageDetails(String? input) {
    if (input == null || input.isEmpty) return null;
    // Regular expression to match "Language Name (language_code)"
    final RegExp pattern = RegExp(r'^(.*?)\s*\((\w+)\)$');
    final match = pattern.firstMatch(input);

    if (match != null) {
      // Extracting the language name and code from the matched groups
      String languageName = match.group(1) ?? '';
      String languageCode = match.group(2) ?? '';
      return {'name': languageName, 'code': languageCode};
    } else {
      // Return an empty map if the input doesn't match the expected format
      return {};
    }
  }

  bool _isFileValid(Sheet sheet) {
    List<Data?> headerRow = sheet.rows[10];
    return _sanitizeAndMatch(headerRow[0]?.value.toString(), varHeaderName) &&
        _sanitizeAndMatch(
          headerRow[1]?.value.toString(),
          paramHeaderName,
        );
  }

  /// str1 ==> matching string
  /// str2 ==> to be matched with
  bool _sanitizeAndMatch(String? str1, String? str2) {
    str1 = str1?.toLowerCase().replaceAll(' ', '');
    str2 = str2?.toLowerCase().replaceAll(' ', '');
    return str1 != null && str2 != null && str2.contains(str1);
  }
}

class AnalyzedLangugaeData {
  final String languageName;
  final String languageCode;
  final Map<String, String> varNameToContentMap;

  AnalyzedLangugaeData({
    required this.languageName,
    required this.languageCode,
    required this.varNameToContentMap,
  });

  factory AnalyzedLangugaeData.fromAppStringContext(
      AppStringContext appStringContext) {
    return AnalyzedLangugaeData(
      languageName: appStringContext.defaultLanguageName,
      languageCode: appStringContext.defaultLanguageCode,
      varNameToContentMap: appStringContext.nodeHashMap.map(_valueMapper),
    );
  }

  static MapEntry<String, String> _valueMapper(String key, AppStringNode node) {
    if (node is ASNMethodNode) {
      return MapEntry(key, ArchBuddyMLG([]).removeQuotes(node.funcBody));
    }

    return MapEntry(key,
        ArchBuddyMLG([]).removeQuotes((node as ASNVariableNode).declaredValue));
  }
}
