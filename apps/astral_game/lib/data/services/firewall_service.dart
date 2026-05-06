import 'package:astral_game/utils/logger.dart';

/// 防火墙服务
///
/// 负责管理 Windows 防火墙状态
/// 仅在 Windows 平台有效
class FirewallService {
  /// 获取防火墙状态
  ///
  /// [profileIndex] 配置文件索引: 1=域, 2=专用, 3=公用
  /// 返回防火墙是否启用
  Future<bool> getFirewallStatus({int profileIndex = 2}) async {
    try {
      // TODO: 调用 FFI 绑定的 get_firewall_status
      // final result = await AstralRustCore.getFirewallStatus(profileIndex: profileIndex);
      // return result;
      
      // 临时返回默认值，等待 FFI 绑定生成
      appLogger.w('[FirewallService] FFI 绑定尚未生成，请运行 flutter_rust_bridge_codegen generate');
      return false;
    } catch (e, stackTrace) {
      appLogger.e('[FirewallService] 获取防火墙状态失败: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 设置防火墙状态
  ///
  /// [profileIndex] 配置文件索引: 1=域, 2=专用, 3=公用
  /// [enable] 是否启用防火墙
  Future<void> setFirewallStatus(int profileIndex, bool enable) async {
    try {
      // TODO: 调用 FFI 绑定的 set_firewall_status
      // await AstralRustCore.setFirewallStatus(profileIndex: profileIndex, enable: enable);
      
      // 临时占位，等待 FFI 绑定生成
      appLogger.w('[FirewallService] FFI 绑定尚未生成，请运行 flutter_rust_bridge_codegen generate');
      appLogger.i('[FirewallService] 防火墙${enable ? '启用' : '禁用'} (profile: $profileIndex)');
    } catch (e, stackTrace) {
      appLogger.e('[FirewallService] 设置防火墙状态失败: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// 获取专用网络防火墙状态（最常用）
  Future<bool> getPrivateFirewallStatus() async {
    return getFirewallStatus(profileIndex: 2);
  }

  /// 设置专用网络防火墙状态（最常用）
  Future<void> setPrivateFirewallStatus(bool enable) async {
    await setFirewallStatus(2, enable);
  }
}
