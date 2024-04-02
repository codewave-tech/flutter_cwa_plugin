import 'dart:io';

void pluginEntry() {
  print("please enter name");
  String? example = stdin.readLineSync();
  print(example);
  print(Directory.current.path);
}
