part of mlg_command;

extension GenerateExcel on ArchBuddyMLG {
  Future<void> generateExcel(AppStringContext appStringContext,
      List<AppStringContext>? languagesContext) async {
    ExcelService excelService = ExcelService();

    excelService.createExcelFile(
      'codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx',
    );

    Sheet sheet = excelService.useSheet('Sheet1');

    createHeadings(sheet);

    _fillDefault(
      sheet,
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11),
      appStringContext.nodeHashMap.values.toList(),
    );

    _fillLanguages(
      sheet: sheet,
      appStringContext: appStringContext,
      langugesContext: languagesContext,
    );

    CWLogger.namedLog(
      'Excel file has been generated successfully : codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx',
      loggerColor: CWLoggerColor.green,
    );

    excelService.saveFile();

    CWLogger.i.stdout('Would you like to host this google sheet? (y/n)');
    String? response = stdin.readLineSync();
    if (response == null || response.toLowerCase() != 'y') return;

    CWLogger.i.progress('Hosting the google sheet');
    await NetworkCommunication.uploadFileToGoogleDrive(
      fileName:
          'codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx',
      filePath:
          './codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx',
    );
  }

  void _fillLanguages({
    required Sheet sheet,
    required AppStringContext appStringContext,
    required List<AppStringContext>? langugesContext,
  }) {
    bool useLanguageContext = false;
    // ignore: prefer_is_empty
    if (langugesContext != null && langugesContext.length > 0) {
      CWLogger.i.stdout(
          'app_localization files which were generated already are present, would you like to use all these languages to generate the excel? (y/n)');
      String? response = stdin.readLineSync();
      useLanguageContext = response != null && response.toLowerCase() == 'y';
    }
    if (!useLanguageContext || langugesContext == null) {
      _fillLanguage(
        sheet: sheet,
        cellIndex: CellIndex.indexByColumnRow(
          columnIndex: 2,
          rowIndex: 10,
        ),
        appStringContext: appStringContext,
      );
      return;
    }

    for (int idx = 0; idx < langugesContext.length; idx++) {
      _fillLanguage(
        sheet: sheet,
        cellIndex: CellIndex.indexByColumnRow(
          columnIndex: 2 + idx,
          rowIndex: 10,
        ),
        appStringContext: langugesContext[idx],
      );
    }
  }

  void _fillLanguage({
    required Sheet sheet,
    required CellIndex cellIndex,
    required AppStringContext appStringContext,
  }) {
    _writeHeading(
      sheet,
      cellIndex,
      "${appStringContext.defaultLanguageName} (${appStringContext.defaultLanguageCode})",
    );

    List<AppStringNode> nodes = appStringContext.nodeHashMap.values.toList();

    for (int idx = 0; idx < nodes.length; idx++) {
      Data data = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: cellIndex.columnIndex,
          rowIndex: cellIndex.rowIndex + idx + 1,
        ),
      );

      if (nodes[idx] is ASNVariableNode) {
        ASNVariableNode node = nodes[idx] as ASNVariableNode;
        data.value = TextCellValue(removeQuotes(node.declaredValue));
      } else {
        ASNMethodNode node = nodes[idx] as ASNMethodNode;
        data.value = TextCellValue(removeQuotes(node.funcBody));
      }
    }
  }

  // start writing variable name from the same index
  void _fillDefault(
      Sheet sheet, CellIndex cellIndex, List<AppStringNode> nodes) {
    int rowIndx = cellIndex.rowIndex;
    int colIdx = cellIndex.columnIndex;

    for (int idx = 0; idx < nodes.length; idx++) {
      Data name = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: colIdx,
          rowIndex: rowIndx + idx,
        ),
      );

      name.value = TextCellValue(nodes[idx].name);

      Data param = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: colIdx + 1,
          rowIndex: rowIndx + idx,
        ),
      );

      if (nodes[idx] is ASNVariableNode) {
        param.value = TextCellValue('-');
        param.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);
      } else {
        param.value = TextCellValue((nodes[idx] as ASNMethodNode).parameters);
      }

      // Data englishDefault = sheet.cell(
      //   CellIndex.indexByColumnRow(
      //     columnIndex: colIdx + 2,
      //     rowIndex: rowIndx + idx,
      //   ),
      // );

      // if (nodes[idx] is ASNVariableNode) {
      //   ASNVariableNode node = nodes[idx] as ASNVariableNode;
      //   englishDefault.value = TextCellValue(removeQuotes(node.declaredValue));
      // } else {
      //   ASNMethodNode node = nodes[idx] as ASNMethodNode;
      //   englishDefault.value = TextCellValue(removeQuotes(node.funcBody));
      // }
    }
  }

  void createHeadings(Sheet sheet) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(
        columnIndex: 9,
        rowIndex: 0,
      ),
    );
    Data title = sheet.cell(CellIndex.indexByString("A1"));
    title.value =
        TextCellValue("Codewave Multilingual Content Translation Template");
    title.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('FF004578'),
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );

    String instruction =
        "This document is designed to facilitate the accurate translation of application text strings into multiple languages. The first three columns—'Variable/Method Name', 'Parameters', and 'English (Default)'—are pre-populated with the essential data for our system's internal processing, including any dynamic content represented by \${param} or \$param. Please do not alter these columns. Your task is to provide translations in the subsequent columns, titled by language (e.g., 'French (fr)', 'Spanish (es)'). Ensure to replicate the dynamic content placeholders accurately within your translations. This precision is vital for the seamless integration of these translations into our application.";
    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 9,
        rowIndex: 9,
      ),
    );
    Data instructions = sheet.cell(CellIndex.indexByString("A2"));
    instructions.value = TextCellValue(instruction);
    instructions.cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFFFF4CE'),
      fontColorHex: ExcelColor.fromHexString('FF000000'),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    _writeHeading(sheet, CellIndex.indexByString("A11"), varHeaderName);

    _writeHeading(sheet, CellIndex.indexByString("B11"), paramHeaderName);

    // _writeHeading(sheet, "C11", "English (en)");

    // _writeHeading(sheet, "D11", "");
    // _writeHeading(sheet, "E11", "");
    // _writeHeading(sheet, "F11", "");
  }

  void _writeHeading(Sheet sheet, CellIndex cellIndex, String str) {
    Data data = sheet.cell(cellIndex);

    data.cellStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('FFEDEBE9'),
      fontColorHex: ExcelColor.fromHexString('FF000000'),
    );
    data.value = TextCellValue(str);
  }

  String removeQuotes(String input) {
    if (input.length < 2) {
      return input;
    }

    String firstChar = input[0];
    String lastChar = input[input.length - 1];
    if ((firstChar == lastChar) && (firstChar == '"' || firstChar == "'")) {
      return input.substring(1, input.length - 1);
    }
    return input;
  }
}
