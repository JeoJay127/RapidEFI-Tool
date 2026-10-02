import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rapidefi/pages/shared/widgets/custom_textfield.dart';

class EDIDPage extends StatefulWidget {
  final String? edid;
  final ValueChanged<String>? onChanged;

  const EDIDPage({super.key, this.edid, this.onChanged});

  @override
  State<EDIDPage> createState() => _EDIDPageState();
}

class _EDIDPageState extends State<EDIDPage> {
  late final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final String tip = r'''
  1. 通常用于修复 Intel 6～10 代核显黑屏无信号问题（这里只处理核显 EDID）。
  2. 500 系台式机主板（H510/B560/H570/Q570/Z590/W580）使用核显 HDMI 输出时，必须注入真实显示器 EDID。
  3. 可在 Windows 版 RapidEFI 或 hdinfo 的显示器详情中复制 EDID。
  4. 注入前请先在“高级配置”中勾选需要注入的 AAPL0X 接口。
  5. EDID 通常为 256 位或 512 位十六进制数据。
  ''';

  String? _edidError;

  @override
  void initState() {
    super.initState();
    _initializeEDID();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant EDIDPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.edid != widget.edid && !_focusNode.hasFocus) {
      _initializeEDID();
    }
  }

  void _initializeEDID() {
    final edidText = _cleanEdid(widget.edid ?? '');
    _controller.text = edidText;
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _validateAndFormatEdid();
    }
  }

  String _cleanEdid(String edid) {
    return edid.replaceAll(RegExp(r'[\s,，]+'), '');
  }

  void _validateAndFormatEdid() {
    final originalText = _controller.text;
    final edidText = _cleanEdid(originalText);

    String? error;
    if (edidText.isNotEmpty) {
      final isHex = RegExp(r'^[0-9A-Fa-f]+$').hasMatch(edidText);
      if (!isHex) {
        error = 'EDID数据包含非十六进制字符,请检查!';
      } else if (edidText.length != 256 && edidText.length != 512) {
        error = 'EDID 数据长度只能是 256 或 512 位，当前为 ${edidText.length} 位';
      }
    }

    setState(() {
      _edidError = error;
      if (error == null && edidText.toUpperCase() != originalText) {
        _controller.text = edidText.toUpperCase();
      }
    });

    if (error != null) {
      showToast('EDID数据不正确,请检查确认后再输入!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '注入显示器 EDID（通常为 256 位或 512 位）：',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 3,
            expandWidth: true,
            keyboardType: TextInputType.text,
            hintText: '填写显示器 EDID（通常为 256 位或 512 位，自动处理换行、空格和逗号）',
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.red.shade600),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            forceErrorText: _edidError,
            errorStyle: TextStyle(color: Colors.red.shade600),
            onChanged: (value, _) {
              final cleanValue = _cleanEdid(value);
              if (cleanValue.isEmpty) {
                widget.onChanged?.call('');
              } else if (cleanValue.length == 256 || cleanValue.length == 512) {
                widget.onChanged?.call(cleanValue.toUpperCase());
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}
