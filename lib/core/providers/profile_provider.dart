import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});

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
  late Box box;

  @override
  ProfileState build() {
    box = Hive.box('settings');
    final name = box.get('childName', defaultValue: 'Arsitek Kecil');
    final avatar = box.get('selectedAvatar', defaultValue: '🦁');
    final stars = box.get('totalStars', defaultValue: 0);

    return ProfileState(
      name: name,
      avatarIcon: avatar,
      totalStars: stars,
    );
  }

  void updateName(String newName) {
    state = state.copyWith(name: newName);
    box.put('childName', newName);
  }

  void updateAvatar(String newAvatar) {
    state = state.copyWith(avatarIcon: newAvatar);
    box.put('selectedAvatar', newAvatar);
  }

  void addStars(int amount) {
    final newStars = state.totalStars + amount;
    state = state.copyWith(totalStars: newStars);
    box.put('totalStars', newStars);
  }
}
