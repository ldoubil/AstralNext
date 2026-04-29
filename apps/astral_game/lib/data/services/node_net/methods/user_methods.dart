import 'dart:convert';

import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/node_net/node_net_server.dart';

/// 用户相关方法
class UserMethods {
  final AppSettingsService _settings;

  UserMethods(this._settings);

  /// 获取用户信息
  Map<String, dynamic> getInfo(dynamic params) {
    final avatar = _settings.getAvatar();
    return {
      'name': _settings.getUsername(),
      'avatar': avatar != null ? base64Encode(avatar) : null,
    };
  }

  /// 更新用户信息
  Future<Map<String, dynamic>> update(dynamic params) async {
    if (params is Map) {
      if (params['name'] != null) {
        await _settings.setUsername(params['name'] as String);
      }

      if (params['avatar'] != null) {
        final avatarBase64 = params['avatar'] as String;
        await _settings.setAvatar(base64Decode(avatarBase64));
      }
    }

    return {'success': true};
  }

  /// 获取所有方法
  Map<String, MethodHandler> get methods => {
        'user.getInfo': getInfo,
        'user.update': update,
      };
}
