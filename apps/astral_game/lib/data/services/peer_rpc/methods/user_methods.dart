import 'dart:convert';
import 'dart:typed_data';

import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_context.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_method.dart';
import 'package:astral_game/data/services/peer_rpc/peer_rpc_router.dart';

/// 一个用户的资料（昵称 + 头像字节流）。
///
/// `null` 字段含义：
/// - `name == null` 表示对端没设置自定义名（保持本端 hostname 即可）。
/// - `avatar == null` 表示对端没头像（用默认占位图）。
class UserProfile {
  final String? name;
  final Uint8List? avatar;

  const UserProfile({this.name, this.avatar});

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar': avatar == null ? null : base64Encode(avatar!),
      };

  static UserProfile fromJson(Object? raw) {
    if (raw is! Map) return const UserProfile();
    final name = raw['name'] as String?;
    final avatarStr = raw['avatar'] as String?;
    final avatar = (avatarStr == null || avatarStr.isEmpty)
        ? null
        : base64Decode(avatarStr);
    return UserProfile(name: name, avatar: avatar);
  }
}

/// `user.update` 的请求体；与 [`UserProfile`] 同结构，单独建一个名字方便业务读。
typedef UserUpdateRequest = UserProfile;

/// `user.update` 的响应体（最简，只表示成功与否）。
class UserUpdateAck {
  final bool success;
  const UserUpdateAck(this.success);
  Map<String, dynamic> toJson() => {'success': success};
  static UserUpdateAck fromJson(Object? raw) {
    if (raw is Map) return UserUpdateAck(raw['success'] == true);
    return const UserUpdateAck(false);
  }
}

/// 用户资料相关 RPC 方法定义。
///
/// 同一组 [`RpcMethod`] 同时给服务端 register / 客户端 invoke 使用——业务调用
/// 时不再写 channel 字符串，IDE 也能直接补全参数 / 返回值。
class UserRpc {
  UserRpc._();

  static final RpcMethod<void, UserProfile> getInfo = RpcMethod<void, UserProfile>(
    channel: 'user.getInfo',
    decodeParams: (_) {},
    encodeParams: (_) => null,
    encodeResult: (r) => r.toJson(),
    decodeResult: UserProfile.fromJson,
  );

  static final RpcMethod<UserUpdateRequest, UserUpdateAck> update =
      RpcMethod<UserUpdateRequest, UserUpdateAck>(
    channel: 'user.update',
    decodeParams: UserProfile.fromJson,
    encodeParams: (v) => v.toJson(),
    encodeResult: (v) => v.toJson(),
    decodeResult: UserUpdateAck.fromJson,
  );
}

/// 用户资料服务（服务端实现）。
class UserMethods {
  final AppSettingsService _settings;

  UserMethods(this._settings);

  /// 把所有方法打包成 [`RpcBinding`]，配合 `router.onAll(bindings)` 一次注册。
  List<RpcBindingBase> bindings() => [
        RpcBinding<void, UserProfile>(UserRpc.getInfo, _getInfo),
        RpcBinding<UserUpdateRequest, UserUpdateAck>(UserRpc.update, _update),
      ];

  UserProfile _getInfo(void _, RpcContext ctx) {
    final avatar = _settings.getAvatar();
    return UserProfile(
      name: _settings.getUsername(),
      avatar: avatar,
    );
  }

  Future<UserUpdateAck> _update(UserUpdateRequest req, RpcContext ctx) async {
    if (req.name != null && req.name!.isNotEmpty) {
      await _settings.setUsername(req.name!);
    }
    if (req.avatar != null) {
      await _settings.setAvatar(req.avatar!);
    }
    return const UserUpdateAck(true);
  }
}
