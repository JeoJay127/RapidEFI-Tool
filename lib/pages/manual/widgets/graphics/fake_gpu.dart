import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:rapidefi/pages/shared/widgets/device_id_textfield.dart';
import 'package:rapidefi/pages/shared/widgets/path_textfield.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';

class FakeGPU extends StatefulWidget {
  const FakeGPU({
    super.key,
    this.onChanged,
    this.dgpuPath,
    this.dgpuFakeID,
  });

  final String? dgpuPath;
  final String? dgpuFakeID;
  final Function(String, String)? onChanged;

  @override
  State<FakeGPU> createState() => _FakeGPUState();
}

class _FakeGPUState extends State<FakeGPU> {
  late String dgpuPath = widget.dgpuPath ?? '';
  late String dgpuFakeID = widget.dgpuFakeID ?? '';
  late final TextEditingController _controllerPci =
      TextEditingController(text: dgpuPath);
  late final TextEditingController _controllerFakeId =
      TextEditingController(text: dgpuFakeID);
  final FocusNode _focusNodePci = FocusNode();
  final FocusNode _focusNodeFakeId = FocusNode();
  final String placeholder = '选择需要仿冒的显卡设备';
  String? _selectedComboBoxValue;
  late final Future<void> _gpuCompatibilityFuture =
      GpuCompatibilityData.ensureLoaded();

  final String tip = r'''
  AMD 独显仿冒(设备属性):
   1. 需要补充填写显卡PCI路径,例如: PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)
   2. 需要填写显卡仿冒设备ID(4位16进制),例如: 73BF
   3. 显卡仿冒后,仍然需要考虑AMD显卡所需启动参数(可以在独显配置->AMD独显->按需勾选)
   4. 工具预制了部分显卡设备ID,如果没有,请自行查找或者联系作者补充
  ''';

  @override
  void initState() {
    super.initState();
    _selectedComboBoxValue = placeholder;
    _syncSelectedComboBoxValue();
  }

  @override
  void didUpdateWidget(covariant FakeGPU oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPath = widget.dgpuPath ?? '';
    final nextFakeId = widget.dgpuFakeID ?? '';
    final keepLocalFakeId = dgpuFakeID.isNotEmpty && nextFakeId.isEmpty;
    if (nextPath == dgpuPath &&
        (nextFakeId == dgpuFakeID || keepLocalFakeId)) {
      return;
    }

    dgpuPath = nextPath;
    _controllerPci.text = dgpuPath;
    if (!keepLocalFakeId) {
      dgpuFakeID = nextFakeId;
      _controllerFakeId.text = dgpuFakeID;
      _syncSelectedComboBoxValue();
    }
  }

  @override
  void dispose() {
    _controllerPci.dispose();
    _controllerFakeId.dispose();
    _focusNodePci.dispose();
    _focusNodeFakeId.dispose();
    super.dispose();
  }

  void _syncSelectedComboBoxValue({
    List<GpuCompatibilityRecord>? records,
  }) {
    if (dgpuFakeID.isEmpty) {
      _selectedComboBoxValue = placeholder;
      return;
    }

    final normalizedFakeId = dgpuFakeID.toUpperCase();
    final candidates = records ??
        (GpuCompatibilityData.isLoaded
            ? GpuCompatibilityData.amdIdentityOverrideRecordsSync()
            : const <GpuCompatibilityRecord>[]);
    for (final record in candidates) {
      if (record.id == _selectedComboBoxValue &&
          (record.spoofDeviceIdPart ?? '').toUpperCase() ==
              normalizedFakeId) {
        return;
      }
    }

    for (final record in candidates) {
      if ((record.spoofDeviceIdPart ?? '').toUpperCase() == normalizedFakeId) {
        _selectedComboBoxValue = record.id;
        return;
      }
    }

    _selectedComboBoxValue = placeholder;
  }

  void _emitChanged() {
    widget.onChanged?.call(_controllerPci.text, _controllerFakeId.text);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tip,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 15,
              children: [
                const Text(
                  '显卡PCI路径:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 600,
                      ),
                      child: PathTextField(
                        pathType: PathType.pci,
                        hintText: '填写PCI路径',
                        onChanged: (value, _) {
                          _controllerPci.text = value;
                          _emitChanged();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 15,
                children: [
                  const Text(
                    ' 仿冒显卡ID:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  DeviceIdTextField(
                    controller: _controllerFakeId,
                    focusNode: _focusNodeFakeId,
                    onChanged: (value, _) {
                      setState(() {
                        dgpuFakeID = value;
                        _selectedComboBoxValue = placeholder;
                      });
                      _emitChanged();
                    },
                  ),
                  const SizedBox(width: 20),
                  Flexible(child: _buildIdentityOverrideGpuCombo()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityOverrideGpuCombo() {
    return FutureBuilder<void>(
      future: _gpuCompatibilityFuture,
      builder: (context, snapshot) {
        final records = snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError &&
                GpuCompatibilityData.isLoaded
            ? GpuCompatibilityData.amdIdentityOverrideRecordsSync()
            : const <GpuCompatibilityRecord>[];

        if (records.isNotEmpty &&
            _selectedComboBoxValue == placeholder &&
            dgpuFakeID.isNotEmpty) {
          _syncSelectedComboBoxValue(records: records);
        }

        final value = records.any((record) => record.id == _selectedComboBoxValue)
            ? _selectedComboBoxValue
            : placeholder;
        final placeholderText =
            snapshot.hasError ? '显卡仿冒数据加载失败' : placeholder;

        return ComboBox<String>(
          isExpanded: false,
          value: value,
          items: [
            ComboBoxItem(
              value: placeholder,
              child: Text(placeholderText),
            ),
            ...records.map((record) {
              final gpuName = record.name.isNotEmpty ? record.name : record.id;
              final label = '$gpuName  :  [${record.id}]';
              return ComboBoxItem(
                value: record.id,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (info) {
            GpuCompatibilityRecord? record;
            if (info != null && info != placeholder) {
              for (final item in records) {
                if (item.id == info) {
                  record = item;
                  break;
                }
              }
            }
            setState(() {
              _selectedComboBoxValue = info ?? placeholder;
              dgpuFakeID = record?.spoofDeviceIdPart ?? '';
              _controllerFakeId.text = dgpuFakeID;
            });
            _emitChanged();
          },
        );
      },
    );
  }
}
