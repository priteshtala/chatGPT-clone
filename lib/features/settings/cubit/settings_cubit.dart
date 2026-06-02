import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  SettingsState copyWith({ThemeMode? themeMode}) {
    return SettingsState(themeMode: themeMode ?? this.themeMode);
  }

  @override
  List<Object?> get props => [themeMode];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._preferences) : super(const SettingsState());

  static const _themeKey = 'theme_mode';
  final SharedPreferences _preferences;

  void load() {
    final value = _preferences.getString(_themeKey);
    emit(SettingsState(themeMode: _parseThemeMode(value)));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _preferences.setString(_themeKey, themeMode.name);
    emit(state.copyWith(themeMode: themeMode));
  }

  ThemeMode _parseThemeMode(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
