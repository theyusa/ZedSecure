class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdate;
  final int configCount;
  final int? upload;
  final int? download;
  final int? total;
  final DateTime? expire;
  final String? webPageUrl;
  final String? supportUrl;
  final bool forceResolve;

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdate,
    this.configCount = 0,
    this.upload,
    this.download,
    this.total,
    this.expire,
    this.webPageUrl,
    this.supportUrl,
    this.forceResolve = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      configCount: json['configCount'] as int? ?? 0,
      upload: json['upload'] as int?,
      download: json['download'] as int?,
      total: json['total'] as int?,
      expire: json['expire'] != null ? DateTime.parse(json['expire'] as String) : null,
      webPageUrl: json['webPageUrl'] as String?,
      supportUrl: json['supportUrl'] as String?,
      forceResolve: json['forceResolve'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'lastUpdate': lastUpdate.toIso8601String(),
      'configCount': configCount,
      'upload': upload,
      'download': download,
      'total': total,
      'expire': expire?.toIso8601String(),
      'webPageUrl': webPageUrl,
      'supportUrl': supportUrl,
      'forceResolve': forceResolve,
    };
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    DateTime? lastUpdate,
    int? configCount,
    int? upload,
    int? download,
    int? total,
    DateTime? expire,
    String? webPageUrl,
    String? supportUrl,
    bool? forceResolve,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      configCount: configCount ?? this.configCount,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      total: total ?? this.total,
      expire: expire ?? this.expire,
      webPageUrl: webPageUrl ?? this.webPageUrl,
      supportUrl: supportUrl ?? this.supportUrl,
      forceResolve: forceResolve ?? this.forceResolve,
    );
  }

  bool get isExpired => expire != null && expire!.isBefore(DateTime.now());
  
  int get consumption => (upload ?? 0) + (download ?? 0);
  
  double get ratio => total != null && total! > 0 ? (consumption / total!).clamp(0.0, 1.0) : 0.0;
  
  Duration? get remaining => expire?.difference(DateTime.now());
  
  bool get hasTrafficInfo => upload != null && download != null && total != null;
  
  bool get hasExpireInfo => expire != null;
}

