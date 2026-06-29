import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:xml/xml.dart';
import 'package:rapidefi/utils/config/presets/patches/patch_op.dart';
import 'package:rapidefi/utils/config/presets/patches/plist_typed_value.dart';

class XmlPlistEditor {
  final XmlDocument document;

  XmlElement get rootDict => document.rootElement.findElements('dict').first;

  final Map<XmlElement, Map<String, XmlElement>> _dictKeyCache = {};

  XmlPlistEditor._(this.document);

  static Future<XmlPlistEditor> fromFile(String path) async {
    final text = await File(path).readAsString();
    return XmlPlistEditor._(XmlDocument.parse(text));
  }

  Future<void> save(String path) async {
    await File(path).writeAsString(
      document.toXmlString(pretty: true, indent: '    '),
    );
  }

  void apply(PatchOp op) {
    switch (op.action) {
      case PatchAction.set:
        setValue(op.path, op.value, createIfMissing: op.createIfMissing);
        break;
      case PatchAction.remove:
        remove(op.path);
        break;
      case PatchAction.replaceArray:
        replaceArray(op.path, op.value as List<dynamic>,
            createIfMissing: op.createIfMissing);
        break;
      case PatchAction.mergeDict:
        mergeDict(op.path, op.value as Map<String, dynamic>,
            createIfMissing: op.createIfMissing);
        break;
      case PatchAction.appendArray:
        appendArray(op.path, op.value as List<dynamic>,
            createIfMissing: op.createIfMissing);
        break;
    }
  }

  XmlElement? findValueElement(List<String> path) {
    XmlElement currentDict = rootDict;

    for (int i = 0; i < path.length; i++) {
      final key = path[i];
      final keyElement = _keyElement(currentDict, key);
      if (keyElement == null) return null;

      final valueElement = _nextElement(keyElement);
      if (valueElement == null) return null;

      if (i == path.length - 1) {
        return valueElement;
      }

      if (valueElement.name.local != 'dict') {
        return null;
      }

      currentDict = valueElement;
    }

    return null;
  }

  void setValue(
    List<String> path,
    dynamic value, {
    bool createIfMissing = true,
  }) {
    final parentPath = path.sublist(0, path.length - 1);
    final key = path.last;

    final parentDict =
        _ensureDict(parentPath, createIfMissing: createIfMissing);
    if (parentDict == null) return;

    final oldKey = _keyElement(parentDict, key);
    final newValue = _valueToElement(value);

    if (oldKey == null) {
      if (!createIfMissing) return;

      parentDict.children.add(XmlText('\n    '));
      parentDict.children.add(XmlElement(XmlName('key'), [], [XmlText(key)]));
      parentDict.children.add(XmlText('\n    '));
      parentDict.children.add(newValue);
      _dictKeyCache.remove(parentDict);
      return;
    }

    final oldValue = _nextElement(oldKey);
    if (oldValue == null) return;

    final index = parentDict.children.indexOf(oldValue);
    parentDict.children[index] = newValue;
  }

  void replaceArray(
    List<String> path,
    List<dynamic> items, {
    bool createIfMissing = true,
  }) {
    setValue(path, items, createIfMissing: createIfMissing);
  }

  void appendArray(
    List<String> path,
    List<dynamic> items, {
    bool createIfMissing = true,
  }) {
    final arrayElement = findValueElement(path);

    if (arrayElement == null) {
      setValue(path, items, createIfMissing: createIfMissing);
      return;
    }

    if (arrayElement.name.local != 'array') {
      throw StateError('Path is not array: ${path.join(" -> ")}');
    }

    for (final item in items) {
      arrayElement.children.add(XmlText('\n        '));
      arrayElement.children.add(_valueToElement(item));
    }
  }

  void mergeDict(
    List<String> path,
    Map<String, dynamic> map, {
    bool createIfMissing = true,
  }) {
    final dictElement = _ensureDict(path, createIfMissing: createIfMissing);

    if (dictElement == null) return;

    for (final entry in map.entries) {
      setValue([...path, entry.key], entry.value,
          createIfMissing: createIfMissing);
    }
  }

  void remove(List<String> path) {
    final parentPath = path.sublist(0, path.length - 1);
    final key = path.last;

    final parentDict = _ensureDict(parentPath, createIfMissing: false);
    if (parentDict == null) return;

    final keyElement = _keyElement(parentDict, key);
    if (keyElement == null) return;

    final valueElement = _nextElement(keyElement);
    keyElement.remove();
    valueElement?.remove();

    _dictKeyCache.remove(parentDict);
  }

  XmlElement? _ensureDict(
    List<String> path, {
    required bool createIfMissing,
  }) {
    XmlElement currentDict = rootDict;

    for (final key in path) {
      final keyElement = _keyElement(currentDict, key);

      if (keyElement == null) {
        if (!createIfMissing) return null;

        final newDict = XmlElement(XmlName('dict'));

        currentDict.children.add(XmlText('\n    '));
        currentDict.children
            .add(XmlElement(XmlName('key'), [], [XmlText(key)]));
        currentDict.children.add(XmlText('\n    '));
        currentDict.children.add(newDict);

        _dictKeyCache.remove(currentDict);
        currentDict = newDict;
        continue;
      }

      final valueElement = _nextElement(keyElement);
      if (valueElement == null) return null;

      if (valueElement.name.local != 'dict') {
        if (!createIfMissing) return null;

        final newDict = XmlElement(XmlName('dict'));
        final index = currentDict.children.indexOf(valueElement);
        currentDict.children[index] = newDict;
        currentDict = newDict;
      } else {
        currentDict = valueElement;
      }
    }

    return currentDict;
  }

  XmlElement? _keyElement(XmlElement dict, String key) {
    final cached = _dictKeyCache[dict];
    if (cached != null) {
      return cached[key];
    }

    final map = <String, XmlElement>{};

    for (final child in dict.children.whereType<XmlElement>()) {
      if (child.name.local == 'key') {
        map[child.innerText] = child;
      }
    }

    _dictKeyCache[dict] = map;
    return map[key];
  }

  XmlElement? _nextElement(XmlElement element) {
    var node = element.nextSibling;
    while (node != null) {
      if (node is XmlElement) return node;
      node = node.nextSibling;
    }
    return null;
  }

  XmlElement _valueToElement(dynamic value) {
    if (value == null) {
      return XmlElement(XmlName('string'));
    }

    if (value is PlistTypedValue) {
      return _typedValueToElement(value);
    }

    if (value is bool) {
      return XmlElement(XmlName(value ? 'true' : 'false'));
    }

    if (value is int) {
      return XmlElement(
        XmlName('integer'),
        [],
        [XmlText(value.toString())],
      );
    }

    if (value is double) {
      return XmlElement(
        XmlName('real'),
        [],
        [XmlText(value.toString())],
      );
    }

    if (value is String) {
      return XmlElement(
        XmlName('string'),
        [],
        [XmlText(value)],
      );
    }

    if (value is Uint8List) {
      return _dataElement(value);
    }

    if (value is List<int>) {
      return _dataElement(Uint8List.fromList(value));
    }

    if (value is List) {
      final children = <XmlNode>[];

      for (final item in value) {
        children.add(XmlText('\n        '));
        children.add(_valueToElement(item));
      }

      if (children.isNotEmpty) {
        children.add(XmlText('\n    '));
      }

      return XmlElement(
        XmlName('array'),
        [],
        children,
      );
    }

    if (value is Map) {
      final children = <XmlNode>[];

      value.forEach((key, itemValue) {
        children.add(XmlText('\n        '));
        children.add(
          XmlElement(
            XmlName('key'),
            [],
            [XmlText(key.toString())],
          ),
        );
        children.add(XmlText('\n        '));
        children.add(_valueToElement(itemValue));
      });

      if (children.isNotEmpty) {
        children.add(XmlText('\n    '));
      }

      return XmlElement(
        XmlName('dict'),
        [],
        children,
      );
    }

    return XmlElement(
      XmlName('string'),
      [],
      [XmlText(value.toString())],
    );
  }

  XmlElement _dataElement(Uint8List bytes) {
    return XmlElement(
      XmlName('data'),
      [],
      [XmlText(base64Encode(bytes))],
    );
  }

  XmlElement _typedValueToElement(PlistTypedValue typedValue) {
    final type = typedValue.type.trim();
    final value = typedValue.value;

    switch (type) {
      case 'data':
        if (value == null) {
          return _dataElement(Uint8List(0));
        }

        if (value is Uint8List) {
          return _dataElement(value);
        }

        if (value is List<int>) {
          return _dataElement(Uint8List.fromList(value));
        }

        if (value is String) {
          try {
            return _dataElement(value.toBytes());
          } catch (_) {
            return _dataElement(Uint8List.fromList(utf8.encode(value)));
          }
        }

        return _dataElement(Uint8List.fromList(utf8.encode(value.toString())));

      case 'string':
        return XmlElement(
          XmlName('string'),
          [],
          [XmlText(value?.toString() ?? '')],
        );

      case 'integer':
        return XmlElement(
          XmlName('integer'),
          [],
          [XmlText(value?.toString() ?? '0')],
        );

      case 'real':
        return XmlElement(
          XmlName('real'),
          [],
          [XmlText(value?.toString() ?? '0')],
        );

      case 'bool':
        final enabled = value == true || value.toString() == 'true';
        return XmlElement(XmlName(enabled ? 'true' : 'false'));

      case 'true':
        return XmlElement(XmlName('true'));

      case 'false':
        return XmlElement(XmlName('false'));

      default:
        return XmlElement(
          XmlName(type.isEmpty ? 'string' : type),
          [],
          [XmlText(value?.toString() ?? '')],
        );
    }
  }
}
