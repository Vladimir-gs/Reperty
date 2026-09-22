import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

extension DateFormatting on DateTime {
  String toShortEs() => DateFormat('EEE d MMM', 'es').format(this);
}

extension FirestoreParsing on Map<String, dynamic> {
  DateTime dateTime(String key) {
    final v = this[key];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
