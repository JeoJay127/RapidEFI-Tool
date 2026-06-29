import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  1. 通常用于修复Intel 6～10代核显(这里不处理独显EDID)黑屏无信号问题(通常表现是键盘指示灯大小写灯亮,显示器黑屏无信号)
  2. 500系台式机主板(H510/B560/H570/Q570/Z590/W580)使用核显HDMI输出时,必须注入真实显示器EDID,否则大概率黑屏
  3. 如何获取显示器EDID:
     Windows环境使用RapidEFI工具或者hdinfo工具获取显示器EDID(也可以使用三方工具获取,但需要自行处理EDID格式):
     1). 打开RapidEFI-v4.x及以上版本,点击"配置EFI"-> "自动配置EFI"-> "详细配置"(如果使用hdinfo,点击"详细配置")
     2). 等待自动获取硬件信息完成,点击显示器右边EDID代码,即可获取EDID(会提示成功复制到剪切板)
     3). 返回此页面,粘贴EDID到输入框即可
  4. 注入EDID前,请先在"高级配置"中勾选需要注入的AAPL0X接口; 如果不确定接口,可按实际HDMI修复方案选择
  5. EDID数据通常为128字节(256位)或者256字节(512位),如果不是,请检查确认后再输入!
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
    return edid.replaceAll(RegExp(r'\s+'), '');
  }

  void _validateAndFormatEdid() {
    final originalText = _controller.text;
    final edidText = _cleanEdid(originalText);

    String? error;
    if (edidText.isNotEmpty) {
      final isHex = RegExp(r'^[0-9A-Fa-f]+$').hasMatch(edidText);
      if (!isHex) {
        error = 'EDID数据包含非十六进制字符,请检查!';
      } else if (edidText.length % 256 != 0) {
        error = '当前EDID数据长度为${edidText.length}位,非256位整数倍,请检查!';
      }
    }

    setState(() {
      _edidError = error;
      if (error == null && edidText != originalText) {
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
            '注入显示器EDID(通常为256位或512位):',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 3,
            expandWidth: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Fa-f0-9]')),
            ],
            keyboardType: TextInputType.text,
            hintText: '填写显示器EDID(通常为256位或512位,可以包含空格,换行符)',
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
                widget.onChanged?.call(cleanValue);
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
