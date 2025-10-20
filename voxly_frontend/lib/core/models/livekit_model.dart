class MatchData {
  final String roomName;
  final String liveKitUrl;
  final String token;
  final String partner;

  MatchData({
    required this.roomName,
    required this.liveKitUrl,
    required this.token,
    required this.partner,
  });

  factory MatchData.fromJson(Map<String, dynamic> json) {
    return MatchData(
      roomName: json['roomName'] as String,
      liveKitUrl: json['liveKitUrl'] as String,
      token: json['token'] as String,
      partner: json['partner'] as String,
    );
  }
}
