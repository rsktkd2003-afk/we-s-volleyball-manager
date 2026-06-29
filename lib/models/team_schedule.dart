import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamSchedule {
  TeamSchedule({
    this.id,
    required this.title,
    required this.location,
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.color,
    this.createdBy,
  });

  final String? id;
  final String title;
  final String location;
  final DateTime start;
  final DateTime end;
  final int durationMinutes;
  final Color color;
  final String? createdBy;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'durationMinutes': durationMinutes,
      'createdBy': createdBy,
    };
  }

  factory TeamSchedule.fromJson(Map<String, dynamic> json, String id) {
    return TeamSchedule(
      id: id,
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      start: (json['start'] as Timestamp).toDate(),
      end: (json['end'] as Timestamp).toDate(),
      durationMinutes: json['durationMinutes'] ?? 0,
      color: Colors.blue,
      createdBy: json['createdBy'],
    );
  }
}
