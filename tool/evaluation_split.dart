// The sealed 70/30 split (#26), pure Dart so tool/build_evaluation_set.dart runs without Flutter.
import 'dart:convert';

/// A template is sealed when its FNV-1a hash ends in 0-2, so the 30% split never moves when rows are added.
bool isSealedTemplate(String template) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(template)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash % 10 < 3;
}
