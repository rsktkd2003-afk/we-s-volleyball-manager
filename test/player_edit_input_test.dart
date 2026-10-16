import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/player.dart';
import 'package:volleyball_app/utils/player_edit_input.dart';

import 'support/fake_repositories.dart';

void main() {
  late Player original;

  setUp(() {
    original = testPlayer(id: 'p1', name: '変更前')
      ..ownerUid = 'owner'
      ..linkedUid = 'linked'
      ..jump = 1
      ..power = 2
      ..speed = 3
      ..stamina = 4
      ..gameSense = 6;
  });

  Player convert({
    String number = '12',
    String height = '180.5',
    String spike = '7',
    String serve = '8',
    String reception = '9',
  }) {
    return playerFromEditInput(
      original: original,
      name: '  山田  ',
      number: number,
      position: ' MB ',
      dominantHand: ' 左 ',
      grade: ' 2年 ',
      height: height,
      weight: '70.2',
      standingReach: '230.1',
      maxReach: '310.4',
      blockReach: '300.3',
      spike: spike,
      serve: serve,
      reception: reception,
      dig: '6',
      toss: '5',
      block: '4',
      mobility: '3',
      roles: ['captain'],
    );
  }

  test('文字入力を変換し、編集対象外と元のPlayerを保持する', () {
    final result = convert();
    expect(result.toJson(), {
      ...original.toJson(),
      'name': '山田',
      'number': 12,
      'position': 'MB',
      'dominantHand': '左',
      'grade': '2年',
      'height': 180.5,
      'weight': 70.2,
      'standingReach': 230.1,
      'maxReach': 310.4,
      'blockReach': 300.3,
      'spike': 7,
      'serve': 8,
      'reception': 9,
      'dig': 6,
      'toss': 5,
      'block': 4,
      'mobility': 3,
      'roles': ['captain'],
    });
    expect(result.id, 'p1');
    expect(original.name, '変更前');
    expect(result.toEditableJson().containsKey('linkedUid'), isFalse);
    expect(result.toEditableJson().containsKey('ownerUid'), isFalse);
  });

  test('不正値・空欄と能力値の上下限は従来の規則を維持する', () {
    final result = convert(
      number: '不正',
      height: '',
      spike: '不正',
      serve: '0',
      reception: '11',
    );
    expect(result.number, 0);
    expect(result.height, 0.0);
    expect(result.spike, 5);
    expect(result.serve, 1);
    expect(result.reception, 10);
  });

  test('通常数値の負数を新たな検証で変更しない', () {
    final result = convert(number: '-1', height: '-2.5');
    expect(result.number, -1);
    expect(result.height, -2.5);
  });
}
