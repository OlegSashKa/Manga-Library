class WorldTime {
  final DateTime datetime;
  final String timezone;
  final String location;

  const WorldTime({
    required this.datetime,
    required this.timezone,
    required this.location,
  });

  String get formattedTime {
    final hour = datetime.hour.toString().padLeft(2, '0');
    final minute = datetime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get displayText {
    return '$location время: $formattedTime $timezone';
  }
}