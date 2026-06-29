import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';

class KextGroup {
  final String id;
  final String title;
  final String description;
  final List<KernelKext> kexts;
  const KextGroup({
    required this.id,
    required this.title,
    this.description = '',
    required this.kexts,
  });

  factory KextGroup.single(KernelKext kext) {
    return KextGroup(
      id: kext.bundlePath,
      title: kext.function.isNotEmpty ? kext.function : kext.bundlePath,
      description: kext.note.where((item) => item.trim().isNotEmpty).join(' '),
      kexts: [kext],
    );
  }

  List<String> get bundlePaths => kexts.map((kext) => kext.bundlePath).toList();

  List<String> get bundleNames =>
      kexts.map((kext) => bundleNameFromPath(kext.bundlePath)).toList();

  static String bundleNameFromPath(String bundlePath) {
    final path = bundlePath.trim();
    if (path.isEmpty) {
      return '';
    }

    return path.split('/').last;
  }

  bool containsAny(Iterable<KernelKext> selectedKexts) {
    final selectedBundlePaths =
        selectedKexts.map((kext) => kext.bundlePath).toSet();
    return kexts.any((kext) => selectedBundlePaths.contains(kext.bundlePath));
  }

  bool containsAll(Iterable<KernelKext> selectedKexts) {
    final selectedBundlePaths =
        selectedKexts.map((kext) => kext.bundlePath).toSet();
    return kexts.every((kext) => selectedBundlePaths.contains(kext.bundlePath));
  }

  static List<KernelKext> expand(Iterable<KextGroup> groups) {
    return uniqueKexts(groups.expand((group) => group.kexts));
  }

  static List<KernelKext> uniqueKexts(Iterable<KernelKext> kexts) {
    final result = <KernelKext>[];
    final bundlePaths = <String>{};

    for (final kext in kexts) {
      if (bundlePaths.add(kext.bundlePath)) {
        result.add(kext);
      }
    }

    return List<KernelKext>.unmodifiable(result);
  }

  static List<KextGroup> selectedByAny(
    Iterable<KextGroup> groups,
    Iterable<KernelKext> selectedKexts,
  ) {
    return groups.where((group) => group.containsAny(selectedKexts)).toList();
  }

  static List<KextGroup> selectedByExactCoveredSet({
    required Iterable<KextGroup> groups,
    required Iterable<KernelKext> selectedKexts,
    Iterable<KernelKext>? removableKexts,
  }) {
    final removableBundlePaths =
        removableKexts?.map((kext) => kext.bundlePath).toSet();
    final selectedBundlePaths = selectedKexts
        .where((kext) =>
            removableBundlePaths == null ||
            removableBundlePaths.contains(kext.bundlePath))
        .map((kext) => kext.bundlePath)
        .toSet();

    if (selectedBundlePaths.isEmpty) {
      return const [];
    }

    for (final group in groups) {
      final groupBundlePaths = group.bundlePaths.toSet();
      if (_sameStringSet(groupBundlePaths, selectedBundlePaths)) {
        return [group];
      }
    }

    return const [];
  }

  static bool _sameStringSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KextGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
