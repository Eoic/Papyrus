import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/powersync/library_row_mapper.dart';

void main() {
  final now = DateTime.utc(2026);
  final base = Shelf(id: 'shelf', name: 'Shelf', createdAt: now, updatedAt: now);
  const descriptorKeys = ['icon_code_point', 'icon_font_family', 'icon_font_package', 'icon_match_text_direction'];

  Map<String, Object?> descriptor(Map<String, Object?> row) => {for (final key in descriptorKeys) key: row[key]};

  test('all available constant icons round trip through shelf rows', () {
    for (final icon in Shelf.availableIcons) {
      final original = base.copyWith(icon: icon);
      final row = shelfRowMapper.toRow(original);
      final restored = shelfRowMapper.fromRow(row);
      expect(restored.icon, icon);
      expect(restored.displayIcon, icon);
      expect(shelfRowMapper.toRow(restored), row);
    }
  });

  test('unknown descriptor survives decode, unrelated edits, and encode', () {
    final row = {
      ...shelfRowMapper.toRow(base),
      'icon_code_point': 0xf1234,
      'icon_font_family': 'OtherFont',
      'icon_font_package': 'other_icons',
      'icon_match_text_direction': 1,
    };
    final restored = shelfRowMapper.fromRow(row);
    expect(restored.displayIcon, Icons.folder_outlined);
    final edited = restored.copyWith(name: 'Edited', description: 'Description', icon: restored.icon);
    expect(descriptor(shelfRowMapper.toRow(edited)), descriptor(row));
    final decodedAgain = Shelf.fromJson(edited.toJson());
    expect(descriptor(shelfRowMapper.toRow(decodedAgain)), descriptor(row));
  });

  test('font identity and text direction must match before using a known icon', () {
    final known = shelfRowMapper.toRow(base.copyWith(icon: Icons.menu_book));
    for (final overrides in [
      {'icon_font_family': 'AnotherFamily'},
      {'icon_font_package': 'another_package'},
      {'icon_match_text_direction': Icons.menu_book.matchTextDirection ? 0 : 1},
      {'icon_font_family': null},
    ]) {
      final row = {...known, ...overrides};
      final restored = shelfRowMapper.fromRow(row);
      expect(restored.displayIcon, Icons.folder_outlined);
      expect(descriptor(shelfRowMapper.toRow(restored.copyWith(name: 'Edited'))), descriptor(row));
    }
  });

  test('choosing another icon replaces an unsupported stored descriptor', () {
    final unknown = shelfRowMapper.fromRow({
      ...shelfRowMapper.toRow(base),
      'icon_code_point': 0xf1234,
      'icon_font_family': 'OtherFont',
      'icon_font_package': 'other_icons',
      'icon_match_text_direction': 1,
    });
    final updated = unknown.copyWith(icon: Icons.favorite_outline);
    final expected = base.copyWith(icon: Icons.favorite_outline);
    expect(descriptor(shelfRowMapper.toRow(updated)), descriptor(shelfRowMapper.toRow(expected)));
  });

  test('clearing an icon removes all retained identity fields', () {
    final unknown = shelfRowMapper.fromRow({
      ...shelfRowMapper.toRow(base),
      'icon_code_point': 0xf1234,
      'icon_font_family': 'OtherFont',
      'icon_font_package': 'other_icons',
      'icon_match_text_direction': 1,
    });
    final cleared = unknown.copyWith(clearIcon: true);
    expect(cleared.icon, isNull);
    expect(cleared.iconDescriptor, isNull);
    expect(descriptor(shelfRowMapper.toRow(cleared)), descriptor(shelfRowMapper.toRow(base)));
  });
}
