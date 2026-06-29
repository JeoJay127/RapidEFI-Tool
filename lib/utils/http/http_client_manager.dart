//  HttpClientManager.dart
//  Created by JeoJay127
//
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// 取消令牌
class DownloadCancelToken {
  bool _isCancelled = false;
  final Completer<void> _cancelCompleter = Completer();

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      _cancelCompleter.complete();
    }
  }

  Future<void> get onCancel => _cancelCompleter.future;
}

class HttpClientManager {
  final String userAgent;
  final int chunkSize;

  HttpClientManager({
    this.userAgent = 'Mozilla/5.0 AppleWebKit/537.36 Chrome Safari',
    this.chunkSize = 1024 * 1024,
  });

  String getSize(
    int size, {
    String? suffix,
    bool use1024 = false,
    int roundTo = 2,
    bool stripZeroes = false,
  }) {
    if (size == -1) return 'Unknown';

    final ext = use1024
        ? ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB']
        : ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

    final div = use1024 ? 1024 : 1000;
    var s = size.toDouble();
    final sDict = <String, double>{};

    for (final e in ext) {
      sDict[e] = s;
      s /= div;
    }

    suffix = suffix != null
        ? ext.firstWhere(
            (x) => x.toLowerCase() == suffix?.toLowerCase(),
            orElse: () => '',
          )
        : null;

    final biggest =
        suffix ??
        ext.reversed.firstWhere((x) => sDict[x]! >= 1, orElse: () => 'B');

    roundTo = max(0, min(15, roundTo));
    var bval = double.parse(sDict[biggest]!.toStringAsFixed(roundTo));

    final parts = bval.toString().split('.');
    var a = parts[0];
    var b = parts.length > 1 ? parts[1] : '';

    if (stripZeroes) {
      b = b.replaceAll(RegExp(r'0+$'), '');
    } else if (roundTo > 0) {
      b = b.padRight(roundTo, '0');
    } else {
      b = '';
    }

    return '${int.parse(a)}${b.isNotEmpty ? '.$b' : ''} $biggest';
  }

  Future<HttpClientResponse?> _openUrl(
    String url,
    Map<String, String>? headers,
    Function(dynamic error)? onError, {
    Duration connectTimeout = const Duration(seconds: 10),
    Duration responseTimeout = const Duration(seconds: 10),
    DownloadCancelToken? cancelToken,
  }) async {
    HttpClient? client;
    HttpClientRequest? request;

    try {
      client = HttpClient();

      request = await client
          .getUrl(Uri.parse(url))
          .timeout(
            connectTimeout,
            onTimeout: () {
              onError?.call('连接服务器超时');
              throw TimeoutException('连接服务器超时');
            },
          );

      request.headers.add('User-Agent', userAgent);
      headers?.forEach((key, value) => request?.headers.add(key, value));

      if (cancelToken?.isCancelled ?? false) {
        onError?.call('下载已取消');
        request.abort();
        return null;
      }

      cancelToken?.onCancel.then((_) {
        onError?.call('下载已取消');
        request?.abort();
      });

      final response = await request.close().timeout(
        responseTimeout,
        onTimeout: () {
          onError?.call('读取响应超时');
          throw TimeoutException('读取响应超时');
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        onError?.call('获取服务器信息发生异常! 状态码: ${response.statusCode}');
        throw HttpException(
          '请求失败，状态码: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }

      return response;
    } catch (e) {
      onError?.call(e);
      return null;
    }
  }

  /// 剩余时间格式化
  String _formatRemainingTime(int totalSize, int bytesSoFar, double speed) {
    if (speed <= 0 || totalSize <= 0) return '??';

    final secondsLeft = (totalSize - bytesSoFar) / speed;
    if (!secondsLeft.isFinite) return '??';

    final days = (secondsLeft / 86400).floor();
    final hours = ((secondsLeft % 86400) / 3600).floor();
    final mins = ((secondsLeft % 3600) / 60).floor();
    final secs = (secondsLeft % 60).floor();

    return '${days > 0 ? '$days:' : ''}'
        '${hours.toString().padLeft(2, '0')}:'
        '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  /// 进度处理
  void _handleProgress(
    int bytesSoFar,
    int totalSize,
    int startTime,
    void Function(double percent, String speed, String remaining)? onProgress,
  ) {
    if (onProgress == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = (now - startTime) / 1000; // 秒

    // 用整体平均速度
    final double speed = elapsed > 0 ? bytesSoFar / elapsed : 0;

    final percent = totalSize > 0 ? (bytesSoFar / totalSize * 100) : 0;

    final speedStr = getSize(speed.toInt(), roundTo: 1);

    final remainingStr = _formatRemainingTime(totalSize, bytesSoFar, speed);

    onProgress(percent.toDouble(), '$speedStr/s', remainingStr);
  }

  Future<T?> _downloadCore<T>(
    String url, {
    required Future<void> Function(HttpClientResponse response) onStart,
    required void Function(List<int> chunk) onData,
    required Future<T?> Function() onFinish,
    Function(double percent, String speed, String remaining)? onProgress,
    Function(dynamic error)? onError,
    Map<String, String>? headers,
    DownloadCancelToken? cancelToken,
    int timeoutInSeconds = 10,
  }) async {
    Timer? idleTimer;

    void startIdleTimer() {
      idleTimer?.cancel();
      idleTimer = Timer(Duration(seconds: timeoutInSeconds), () {
        cancelToken?.cancel();
        onError?.call(TimeoutException('下载超时,$timeoutInSeconds秒无进度,任务取消'));
      });
    }

    try {
      final response = await _openUrl(
        url,
        headers,
        onError,
        cancelToken: cancelToken,
      );

      if (response == null) return null;

      await onStart(response);

      final totalSize =
          int.tryParse(response.headers.value('content-length') ?? '-1') ?? -1;

      int bytesSoFar = 0;
      final startTime = DateTime.now().millisecondsSinceEpoch;

      startIdleTimer();

      await for (final chunk in response) {
        if (cancelToken?.isCancelled ?? false) {
          idleTimer?.cancel();
          return null;
        }

        startIdleTimer();

        onData(chunk);
        bytesSoFar += chunk.length;

        _handleProgress(bytesSoFar, totalSize, startTime, onProgress);
      }

      idleTimer?.cancel();
      return await onFinish();
    } catch (e) {
      idleTimer?.cancel();
      onError?.call(e);
      return null;
    }
  }

  /// 下载文件 - 数据流方式
  Future<String?> streamToFile(
    String url,
    String filePath, {
    Function(double percent, String speed, String remaining)? onProgress,
    Function(dynamic error)? onError,
    Map<String, String>? headers,
    bool allowResume = false,
    Function(String filePath, bool success)? onFileDeleted,
    Function(String filePath, int expectedSize, int actualSize)?
    onFileSizeMismatch,
    DownloadCancelToken? cancelToken,
    int timeoutInSeconds = 10,
  }) async {
    IOSink? sink;
    final file = File(filePath);

    int bytesSoFar = 0;
    var mode = FileMode.write;

    return _downloadCore<String>(
      url,
      headers: headers,
      onProgress: onProgress,
      onError: onError,
      cancelToken: cancelToken,
      timeoutInSeconds: timeoutInSeconds,

      onStart: (response) async {
        // 续传
        if (allowResume && await file.exists()) {
          final existingSize = await file.length();
          headers = {...?headers, 'Range': 'bytes=$existingSize-'};
          mode = FileMode.append;
          bytesSoFar = existingSize;
        }

        final acceptRanges = response.headers.value('accept-ranges') == 'bytes';

        if (allowResume && bytesSoFar > 0 && !acceptRanges) {
          if (await file.exists()) {
            await file.delete();
            bytesSoFar = 0;
            mode = FileMode.write;
          }
        }

        sink = file.openWrite(mode: mode);
      },

      onData: (chunk) {
        sink?.add(chunk);
        bytesSoFar += chunk.length;
      },
      onFinish: () async {
        await sink?.close();
        return await file.exists() ? filePath : null;
      },
    ).catchError((e) async {
      await sink?.close();

      if (await file.exists()) {
        await file.delete();
        onFileDeleted?.call(filePath, true);
      }
      return null;
    });
  }

  /// 字节下载
  Future<Uint8List?> getBytes(
    String url, {
    Function(double percent, String speed, String? remaining)? onProgress,
    Function(dynamic error)? onError,
    Map<String, String>? headers,
    bool expandGzip = true,
    DownloadCancelToken? cancelToken,
    int timeoutInSeconds = 10,
  }) async {
    final builder = BytesBuilder();
    HttpClientResponse? resp;

    return _downloadCore<Uint8List>(
      url,
      headers: headers,
      onProgress: onProgress,
      onError: onError,
      cancelToken: cancelToken,
      timeoutInSeconds: timeoutInSeconds,

      onStart: (response) async {
        resp = response;
      },

      onData: (chunk) {
        builder.add(chunk);
      },

      onFinish: () {
        var result = builder.toBytes();

        if (expandGzip &&
            resp?.headers.value('content-encoding')?.toLowerCase() == 'gzip') {
          if (result.length >= 2 && result[0] == 0x1F && result[1] == 0x8B) {
            result = Uint8List.fromList(GZipDecoder().decodeBytes(result));
          }
        }
        return Future.value(result);
      },
    );
  }

  Future<String?> getString(
    String url, {
    Function(double percent, String speed, String? remaining)? onProgress,
    Function(dynamic error)? onError,
    Map<String, String>? headers,
    bool expandGzip = true,
    DownloadCancelToken? cancelToken,
  }) async {
    final bytes = await getBytes(
      url,
      onProgress: onProgress,
      onError: onError,
      headers: headers,
      expandGzip: expandGzip,
      cancelToken: cancelToken,
    );
    return bytes != null ? utf8.decode(bytes) : null;
  }
}
