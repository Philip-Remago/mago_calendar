import 'package:flutter/material.dart';

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final time = TimeOfDay.fromDateTime(local);
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(time.hour)}:${_two(time.minute)}';
}

String formatTime(DateTime value) {
  final local = value.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:${_two(local.minute)} $period';
}

String _two(int value) => value.toString().padLeft(2, '0');
