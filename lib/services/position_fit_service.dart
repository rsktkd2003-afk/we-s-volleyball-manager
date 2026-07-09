import '../models/player.dart';

class PositionFitService {
  static Map<String, double> calculate(Player player) {
    final heightScore = _scaleToScore(
      value: player.height,
      baseValue: 170,
      baseScore: 4,
      maxValue: 190,
      maxScore: 10,
    );

    final maxReachScore = _scaleToScore(
      value: player.maxReach,
      baseValue: 300,
      baseScore: 4,
      maxValue: 330,
      maxScore: 10,
    );

    final ws =
      player.spike * 0.30 +
      player.reception * 0.25 +
      player.dig * 0.15 +
      maxReachScore * 0.15 +
      player.serve * 0.10 +
      player.mobility * 0.05;

    double op =
      player.spike * 0.40 +
      maxReachScore * 0.20 +
      player.block * 0.15 +
      player.serve * 0.15 +
      player.dig * 0.10;

    final mb =
      player.block * 0.45 +
      maxReachScore * 0.20 +
      heightScore * 0.10 +
      player.mobility * 0.25;

    final setter =
        player.toss * 0.40 +
        player.dig * 0.20 +
        player.mobility * 0.20 +
        player.block * 0.10 +
        player.serve * 0.10;

    if (player.dominantHand == '左') {
      op += 5;
    }

    final libero =
        player.reception * 0.40 +
        player.dig * 0.35 +
        player.mobility * 0.15 +
        player.serve * 0.10;

    return {'WS': ws, 'MB': mb, 'S': setter, 'OP': op, 'L': libero};
  }

  static double _scaleToScore({
    required double value,
    required double baseValue,
    required double baseScore,
    required double maxValue,
    required double maxScore,
  }) {
    final score =
        baseScore +
        ((value - baseValue) / (maxValue - baseValue)) *
            (maxScore - baseScore);

    return score.clamp(0.0, 10.0);
  }

  static String bestPosition(Player player) {
    final scores = calculate(player);

    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}