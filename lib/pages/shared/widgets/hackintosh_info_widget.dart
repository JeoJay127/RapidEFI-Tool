import 'package:rapidefi/extension/list_extension.dart';
import 'package:rapidefi/pages/manual/model/platform_entity.dart';
import 'package:flutter/material.dart';

class HackintoshInfoWidget extends StatelessWidget {
  final PlatformEntity platformEntity;
  const HackintoshInfoWidget({super.key, required this.platformEntity});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "原生支持的macOS最初版本:  ${platformEntity.initialSupport}",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          "原生支持的macOS最后版本:  ${platformEntity.lastSupported}",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        platformEntity.oclpSupported.isEmpty
            ? const SizedBox.shrink()
            : Text(
                "补丁支持的macOS版本:  ${platformEntity.oclpSupported}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
        const SizedBox(
          height: 10,
        ),
        Text(
          "[CPU信息]: \n${platformEntity.note.descriptionList}",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          "[Bios官方推荐开启项]: \n${platformEntity.config.bios.enable.ch.toList().descriptionList}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          "[Bios官方推荐关闭项]: \n${platformEntity.config.bios.disable.ch.toList().descriptionList}",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
