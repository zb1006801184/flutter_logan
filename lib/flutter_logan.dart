/*
 * Copyright (c) 2018-present, 美团点评
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'dart:core';
import 'dart:io';

import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';

class FlutterLogan {
  static const MethodChannel _channel = const MethodChannel('flutter_logan');

  /// 初始化
  /// [aseKey] 加密key
  /// [aesIv] 加密iv
  /// [maxFileLen] 最大文件长度 1024 * 1024 * 10 = 10MB
  /// [maxDate] 最大过期时间(天)
  ///
  static Future<bool> init(String aseKey, String aesIv, int maxFileLen,
      {int maxDate = 7}) async {
    final bool result = await _channel.invokeMethod('init', {
      'aesKey': aseKey,
      'aesIv': aesIv,
      'maxFileLen': maxFileLen,
    });

    if (Platform.isAndroid) {
      deleteExpiredLogs(maxDate);
    }
    return result;
  }

  /// 写入日志
  /// [type] (2:调试, 3:信息/埋点, 4:错误, 5:警告 6：严重错误/崩溃  7：网络请求  8: 性能指标)
  /// [log] 日志内容
  static Future<void> log(int type, String log) async {
    await _channel.invokeMethod('log', {
      'type': type,
      'log': log,
    });
  }

  static Future<String?> getUploadPath(String date) async {
    final String? result =
        await _channel.invokeMethod('getUploadPath', {'date': date});
    return result;
  }

  /// 上传日志
  /// [serverUrl] 服务器地址
  /// [date] 日期
  /// [appId] 应用ID
  /// [unionId] 用户ID
  /// [deviceId] 设备ID
  static Future<bool> upload(
    String serverUrl,
    String date,
    String appId,
    String unionId,
    String deviceId,
  ) async {
    final bool result = await _channel.invokeMethod('upload', {
      'date': date,
      'serverUrl': serverUrl,
      'appId': appId,
      'unionId': unionId,
      'deviceId': deviceId
    });
    return result;
  }

  /// 刷新日志
  static Future<void> flush() async {
    await _channel.invokeMethod('flush');
  }

  /// 清除所有日志
  static Future<void> cleanAllLogs() async {
    await _channel.invokeMethod('cleanAllLogs');
  }

  /// 获取日志目录路径
  static Future<List<File>?> _getLogDirPath() async {
    try {
      // 获取应用文档目录
      var time = DateTime.now();
      final date =
          "${time.year.toString()}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}";
      final documentsDirectory = await getUploadPath(date);
      if ((documentsDirectory?.length ?? 0) < 14) {
        return null;
      }
      final logDirectory = Directory(
          '${documentsDirectory?.substring(0, documentsDirectory.length - 14)}');

      // 检查 log 目录是否存在
      if (!await logDirectory.exists()) {
        return null;
      }

      // 扫描 log 目录下的所有文件
      final logFiles = await logDirectory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      return logFiles;
    } catch (e) {
      print('获取日志目录路径失败: $e');
      return null;
    }
  }

  ///删除过期日志
  static Future<void> deleteExpiredLogs(int maxDate) async {
    if (maxDate <= 0) {
      return;
    }
    try {
      // 1.获取缓存路径下的所有日志文件
      final List<File>? logFiles = await _getLogDirPath();
      if (logFiles == null || logFiles.isEmpty) {
        return;
      }
      logFiles.forEach((element) {
        final String fileName = element.path.split('/').last;
        if (_isDateFormatFileName(fileName)) {
          final DateTime? fileDate = _parseDateFromFileName(fileName);
          if (fileDate != null) {
            final int daysDifference =
                DateTime.now().difference(fileDate).inDays;
            if (daysDifference > maxDate) {
              element.delete();
            }
          }
        }
      });
    } catch (e) {}
  }

  /// 判断文件名是否为13 位时间戳
  static bool _isDateFormatFileName(String fileName) {
    return fileName.length == 13;
  }

  /// 从文件名中解析日期
  static DateTime? _parseDateFromFileName(String fileName) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(fileName));
    } catch (e) {
      print('解析文件名日期失败: $fileName, 错误: $e');
    }
    return null;
  }
}
