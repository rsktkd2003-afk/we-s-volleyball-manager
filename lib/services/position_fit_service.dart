import '../models/player.dart';

class PositionFitService {
  static Map<String, double> calculate(Player player) {
    final ws =
        player.spike * 0.25 +
        player.reception * 0.25 +
        player.dig * 0.10 +
        player.maxReach * 0.25 +
        player.serve * 0.10 +
        player.mobility * 0.05;

    final mb =
        player.block * 0.35 +
        player.maxReach * 0.30 +
        player.height * 0.20 +
        player.mobility * 0.15;

    final setter =
        player.toss * 0.40 +
        player.dig * 0.20 +
        player.mobility * 0.20 +
        player.block * 0.10 +
        player.serve * 0.10;

    double op =
        player.spike * 0.35 +
        player.maxReach * 0.30 +
        player.block * 0.15 +
        player.serve * 0.15 +
        player.dig * 0.05;

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

  static String bestPosition(Player player) {
    final scores = calculate(player);

    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
