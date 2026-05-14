import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

// 1. Definisikan Provider menggunakan NotifierProvider
final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileState {
  final String name;
  final String avatarIcon;
  final int totalStars;

  ProfileState({
    required this.name,
    required this.avatarIcon,
    this.totalStars = 0,
  });

  ProfileState copyWith({
    String? name,
    String? avatarIcon,
    int? totalStars,
  }) {
    return ProfileState(
      name: name ?? this.name,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      totalStars: totalStars ?? this.totalStars,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  late Box<dynamic> _box;

  @override
  ProfileState build() {
    _box = Hive.box('settings');
    final name = _box.get('childName', defaultValue: 'Arsitek Kecil');
    final avatar = _box.get('selectedAvatar', defaultValue: '🦁');
    final stars = _box.get('totalStars', defaultValue: 0);

    return ProfileState(
      name: name as String,
      avatarIcon: avatar as String,
      totalStars: stars as int,
    );
  }

  void updateName(String newName) {
    state = state.copyWith(name: newName);
    _box.put('childName', newName);
  }

  void updateAvatar(String newAvatar) {
    state = state.copyWith(avatarIcon: newAvatar);
    _box.put('selectedAvatar', newAvatar);
  }

  void addStars(int amount) {
    final newStars = state.totalStars + amount;
    state = state.copyWith(totalStars: newStars);
    _box.put('totalStars', newStars);
  }
}
