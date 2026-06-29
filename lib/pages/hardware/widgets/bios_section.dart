import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';

class BiosSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;

  const BiosSection(this.rawInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    final bios = rawInfo['BIOS'] as Map<String, dynamic>?;
    if (bios == null) return const SizedBox.shrink();
    final colors = hardwareThemeColors(context);

    final secureBoot = _setting(bios, 'Secure Boot');
    final csm = _setting(bios, 'CSM');
    final ahci = _setting(bios, 'AHCI');
    final resizableBar = _setting(bios, 'Resizable BAR');
    final above4g = _setting(bios, 'Above 4G Decoding');

    final items = <Widget>[
      if (secureBoot != null)
        _status('安全启动: ${secureBoot ? '已开启' : '已关闭'}', good: !secureBoot),
      if (csm != null) _status('CSM: ${csm ? '已开启' : '已关闭'}', good: !csm),
      if (resizableBar != null)
        _status('Resizable BAR: ${resizableBar ? '已开启' : '已关闭'}',
            good: !resizableBar),
      if (above4g != null)
        _status('Above 4G Decoding: ${above4g ? '已开启' : '已关闭'}', good: above4g),
      ahci == null
          ? _unknown('AHCI: 未知')
          : _status('AHCI: ${ahci ? '已开启' : '已关闭'}', good: ahci),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: colors.cardColor,
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: double.infinity,
          child: Text('当前BIOS设置',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textColor, fontSize: 14)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 30, runSpacing: 6, children: items),
        const SizedBox(height: 8),
        Text(_biosNote,
            style:
                TextStyle(fontSize: 12, height: 1.45, color: colors.textColor)),
      ]),
    );
  }

  static const _biosNote = '黑苹果注意事项：\n'
      '1.所有红色文字，请留意在BIOS中将其关闭或开启保持蓝色\n'
      '2.所有蓝色文字，绝大多数情况表示合适的设置\n'
      '\n'
      '安全启动(Secure Boot):  必须关闭(否则无法正常启动未签名的固件程序，比如OC引导)\n'
      'CSM(兼容性支持)：大多数情况建议关闭(Intel 4，5代移动端核显平台，X99平台，以及部分RX460等显卡可能需要开启CSM,否则花屏或无法启动)\n'
      'Resizable BAR： 建议在BIOS中关闭(如果BIOS没有关闭，请确保在Booter->Quirks中将ResizeAppleGpuBars设置为0，以避免启动问题)\n'
      'Above 4G Decoding：建议在BIOS中开启，同时去掉工具自动勾选的npci=0x2000参数。若BIOS设置中没有此项，建议勾选添加启动参数npci=0x2000或npci=0x3000。注意BIOS中Above 4G Decoding设置与启动参数npci=0x2000或npci=0x3000，两者二选一!\n'
      'AHCI(SATA磁盘模式)：必须开启(若不开启，可能无法识别硬盘或出现禁止符号，无法进一步安装)';

  Widget _status(String text, {required bool good}) {
    return SelectableText(text,
        style: TextStyle(
          fontSize: 12,
          color: good ? const Color(0xFF2A91FF) : const Color(0xFFD94B4B),
          fontWeight: FontWeight.w600,
        ));
  }

  Widget _unknown(String text) {
    return SelectableText(text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFFFB627),
          fontWeight: FontWeight.w600,
        ));
  }

  bool? _setting(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) return isTruthyOrNull(data[key]);
    return null;
  }
}
