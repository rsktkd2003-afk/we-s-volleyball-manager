class Player {
  String id;

  // 基本情報
  String name;
  int number;
  String position;
  String dominantHand;
  String grade;

  // 身体データ
  double height;
  double weight;
  double standingReach;
  double maxReach;
  double blockReach;

  // 能力値
  int spike;
  int serve;
  int reception;
  int dig;
  int toss;
  int block;
  int mobility;

  // パラメーター
  int jump;
  int power;
  int speed;
  int stamina;
  int gameSense;

  Player({
    this.id = '',
    required this.name,
    required this.number,
    required this.position,
    required this.dominantHand,
    required this.grade,
    required this.height,
    required this.weight,
    required this.standingReach,
    required this.maxReach,
    required this.blockReach,
    this.spike = 5,
    this.serve = 5,
    this.reception = 5,
    this.dig = 5,
    this.toss = 5,
    this.block = 5,
    this.mobility = 5,

    // 追加
    this.jump = 5,
    this.power = 5,
    this.speed = 5,
    this.stamina = 5,
    this.gameSense = 5,
  });

  double get jumpHeight => maxReach - standingReach;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'position': position,
      'dominantHand': dominantHand,
      'grade': grade,
      'height': height,
      'weight': weight,
      'standingReach': standingReach,
      'maxReach': maxReach,
      'blockReach': blockReach,
      'spike': spike,
      'serve': serve,
      'reception': reception,
      'dig': dig,
      'toss': toss,
      'block': block,
      'mobility': mobility,

      // 追加
      'jump': jump,
      'power': power,
      'speed': speed,
      'stamina': stamina,
      'gameSense': gameSense,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json, {String id = ''}) {
    return Player(
      id: id,
      name: json['name'] ?? '',
      number: json['number'] ?? 0,
      position: json['position'] ?? '未設定',
      dominantHand: json['dominantHand'] ?? '右',
      grade: json['grade'] ?? 'その他',
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      standingReach: (json['standingReach'] ?? 0).toDouble(),
      maxReach: (json['maxReach'] ?? 0).toDouble(),
      blockReach: (json['blockReach'] ?? 0).toDouble(),
      spike: json['spike'] ?? 5,
      serve: json['serve'] ?? 5,
      reception: json['reception'] ?? 5,
      dig: json['dig'] ?? 5,
      toss: json['toss'] ?? 5,
      block: json['block'] ?? 5,
      mobility: json['mobility'] ?? 5,

      // 追加
      jump: json['jump'] ?? 5,
      power: json['power'] ?? 5,
      speed: json['speed'] ?? 5,
      stamina: json['stamina'] ?? 5,
      gameSense: json['gameSense'] ?? 5,
    );
  }
}
