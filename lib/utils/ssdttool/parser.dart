//  parser.dart
//  Created by JeoJay127
//
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';

enum PlistParseStatus { success, fileNotFound, parseError }

class PlistParseResult {
  final PlistParseStatus status;
  final Map<String, dynamic>? data;
  final String message;

  PlistParseResult({required this.status, this.data, this.message = ''});
}

class PlistParser {
  /// 加载并解析 plist 文件
  PlistParseResult loadPlist(
    String filePath, {
    Function(dynamic error)? onError,
  }) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return PlistParseResult(
          status: PlistParseStatus.fileNotFound,
          data: {},
          message: "文件不存在: $filePath",
        );
      }
      final content = file.readAsStringSync();
      return _parsePlist(content);
    } catch (e) {
      onError?.call("加载 $filePath 文件时出错: $e");
      return PlistParseResult(
        status: PlistParseStatus.parseError,
        data: {},
        message: "加载 $filePath 文件时出错: $e",
      );
    }
  }

  /// 保存 plist 文件
  bool savePlist(
    String path,
    Map<String, dynamic> plist, {
    Function(dynamic error)? onError,
  }) {
    try {

      Directory(path).parent.createSync(recursive: true);
      final document = XmlDocument([
        XmlDeclaration([
          XmlAttribute(XmlName('version'), '1.0'),
          XmlAttribute(XmlName('encoding'), 'UTF-8'),
        ]),
        XmlDoctype(
          'plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
          '"http://www.apple.com/DTDs/PropertyList-1.0.dtd"',
        ),
        XmlElement(
          XmlName('plist'),
          [XmlAttribute(XmlName('version'), '1.0')],
          [_buildDictElement(plist, onError: onError)],
        ),
      ]);

      final xmlString = document.toXmlString(
        pretty: true,
        preserveWhitespace: (node) =>
            node.parent is XmlElement &&
            (node.parent as XmlElement).localName == 'string',
      );

      File(path).writeAsStringSync(xmlString);
      return true;
    } catch (e) {
      onError?.call("写入文件失败! 失败原因: $e");
      return false;
    }
  }

  /// 解析 plist 内容
  PlistParseResult _parsePlist(
    String content, {
    Function(dynamic error)? onError,
  }) {
    try {
      final document = XmlDocument.parse(content);
      final dictElement = document.findAllElements('dict').firstOrNull;
      if (dictElement == null) {
        throw ArgumentError('未找到根字典元素');
      }
      final data = _parseDict(dictElement);
      return PlistParseResult(status: PlistParseStatus.success, data: data);
    } catch (e) {
      onError?.call('解析plist失败! 失败原因: $e');
      return PlistParseResult(
        status: PlistParseStatus.parseError,
        data: {},
        message: "解析文件内容时出错: $e",
      );
    }
  }

  /// 解析数组元素
  List<dynamic> _parseArray(XmlElement arrayElement) {
    final List<dynamic> result = [];
    for (final element in arrayElement.children) {
      if (element is XmlElement) {
        result.add(_parseValue(element));
      }
    }
    return result;
  }

  /// 解析字典元素
  Map<String, dynamic> _parseDict(
    XmlElement dictElement, {
    Function(dynamic error)? onError,
  }) {
    final Map<String, dynamic> result = {};
    final keys = dictElement.findElements('key').toList();
    final values = dictElement
        .findElements('key')
        .map((key) => key.nextElementSibling)
        .toList();

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i].innerText;
      final valueElement = values[i];
      final value = _parseValue(valueElement!, onError: onError);
      result[key] = value;
    }

    return result;
  }

  /// 解析值元素
  dynamic _parseValue(
    XmlElement valueElement, {
    Function(dynamic error)? onError,
  }) {
    switch (valueElement.name.local) {
      case 'dict':
        return _parseDict(valueElement);
      case 'array':
        return _parseArray(valueElement);
      case 'string':
        return valueElement.innerText;
      case 'integer':
        return int.parse(valueElement.innerText);
      case 'real':
        return double.parse(valueElement.innerText);
      case 'true':
        return true;
      case 'false':
        return false;
      case 'data':
        return base64.decode(valueElement.innerText);
      case 'date':
        return DateTime.parse(valueElement.innerText);
      default:
        onError?.call(
          'Unsupported plist value type: ${valueElement.runtimeType}',
        );
        throw ArgumentError(
          'Unsupported plist value type: ${valueElement.name.local}',
        );
    }
  }

  /// 递归构建字典元素
  XmlElement _buildDictElement(Map dict, {Function(dynamic error)? onError}) {
    final dictElement = XmlElement(XmlName('dict'));
    dict.forEach((key, value) {
      final keyElement = XmlElement(XmlName('key'));
      keyElement.innerText = key;
      dictElement.children.add(keyElement);

      final valueElement = _buildValueElement(value, onError: onError);
      dictElement.children.add(valueElement);
    });
    return dictElement;
  }

  /// 构建值元素
  XmlElement _buildValueElement(
    dynamic value, {
    Function(dynamic error)? onError,
  }) {
    if (value is Map) {
      return _buildDictElement(value, onError: onError);
    } else if (value is List<int>) {
      final dataElement = XmlElement(XmlName('data'));
      dataElement.innerText = base64.encode(value);
      return dataElement;
    } else if (value is List<dynamic>) {
      final arrayElement = XmlElement(XmlName('array'));
      // ignore: avoid_function_literals_in_foreach_calls
      value.forEach((element) {
        final elementValue = _buildValueElement(element, onError: onError);
        arrayElement.children.add(elementValue);
      });
      return arrayElement;
    } else if (value is String) {
      final stringElement = XmlElement(XmlName('string'));
      stringElement.innerText = value;
      return stringElement;
    } else if (value is int) {
      final integerElement = XmlElement(XmlName('integer'));
      integerElement.innerText = value.toString();
      return integerElement;
    } else if (value is double) {
      final realElement = XmlElement(XmlName('real'));
      realElement.innerText = value.toString();
      return realElement;
    } else if (value is bool) {
      final boolElement = XmlElement(XmlName(value ? 'true' : 'false'));
      return boolElement;
    } else if (value is DateTime) {
      final dateElement = XmlElement(XmlName('date'));
      dateElement.innerText = value.toIso8601String();
      return dateElement;
    } else {
      onError?.call('Unsupported plist value type: ${value.runtimeType}');
      throw ArgumentError('Unsupported plist value type: ${value.runtimeType}');
    }
  }
}
