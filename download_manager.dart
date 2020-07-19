import 'dart:io';

import 'package:dio/dio.dart';
// import 'package:down/flutter_helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DownloadManager {
  DownloadManager({
    @required this.downloadFolderUrl,
    @required this.fileStampJsonUrl,
    @required this.saveFolder,
    this.batch = 30,
    @required this.hiveBoxName,
    this.onProgress,
    this.onComplete,
    this.onVerify,
  }) {
    _download();
  }

  /// download folder url to download files from.
  /// URL without trailing slash(/)
  String downloadFolderUrl;

  /// JSON file url to get information of files and their stamps.
  String fileStampJsonUrl;

  /// local storage temporary folder name.
  /// Folder name without slashes(/)
  String saveFolder;

  /// [batch] int - how many files to download in one batch.
  /// If it's set to 30, then it will download 30 files at once using Future.wait
  int batch;

  /// [hiveBoxName] hive box name to save the file & stamp information
  String hiveBoxName;

  /// Update progress callback
  Function onProgress;

  /// when complete
  Function onComplete;

  /// [onVerify] is a callback that will inform whether download success or not.
  /// It only works when [verify] is set to true.
  /// The return is bool.
  /// - true if all files in files & stamp exists in local.
  Function onVerify;

  int _downloadPercentage = 0;

  Map<String, dynamic> _fileStamp;

  _download() async {
    await _updateFileStamp();
    await _downloadNewFiles();

    await _verify();
  }

  _updateFileStamp() async {
    Response response;
    Dio dio = new Dio();
    response = await dio.get(fileStampJsonUrl);
    _fileStamp = response.data;

    var box = Hive.box(hiveBoxName);
    for (String file in _fileStamp.keys) {
      int stamp = box.get(file, defaultValue: 0);
      // print('if ($stamp != ${response.data[file]}) {');

      /// If file stamp on server has changed, then set the value to `0` to download again.
      /// This means, if file is updated or added, it will download again.
      if (stamp != response.data[file]) {
        box.put(file, 0); // if stamp mismatches, then save 0.
      }
      // print('file: $file');
    }
  }

  /// [data] is the file & stamp from server
  _downloadNewFiles() async {
    var box = Hive.box(hiveBoxName);

    /// Get files to download in chunks (file string arrays with stamp 0)
    List<String> files = [];
    for (String file in box.keys) {
      // print('$file : ${box.get(file)}');
      if (box.get(file, defaultValue: 0) == 0) {
        files.add(file);
      }
    }

    int noOfDownloads = files.length;
    int noOfDone = _fileStamp.keys.length - noOfDownloads;
    int count = 0;
    int countSuccess = 0;
    List<dynamic> chunks = _chunk(files, batch);
    for (List<String> files in chunks) {
      count += files.length;
      var futures = <Future>[];

      for (String file in files) {
        futures.add(_downloadFile(file));
      }

      /// Do `Future.all`
      List res = await Future.wait(futures);

      /// If download success, then update the stamp.
      for (Map<String, bool> re in res) {
        String name = re.keys.first;
        if (re[name] == true) {
          box.put(name, _fileStamp[name]);
          countSuccess++;
          noOfDone++;
        }
      }
      _downloadPercentage = (count / noOfDownloads * 100).round();

      print(
          'Total files: ${_fileStamp.length}, No of downloads: $noOfDownloads, done: $noOfDone, success: $countSuccess');
      onProgress(_downloadPercentage);
    }
    onComplete();
  }

  _downloadFile(String file) async {
    var directory = await getTemporaryDirectory();
    var filePath = p.join(directory.path, saveFolder, file);

    String url = '$downloadFolderUrl/$file';

    // print('url: $url');
    // print('path: $filePath');
    var dio = Dio();
    try {
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // print((received / total * 100).toStringAsFixed(0) + "%");
          }
        },
      );
      return {file: true};
    } catch (e) {
      print(e);
      return {file: false};
    }
  }

  /// verifies if the files from backend are exists in local.
  _verify() async {
    if (onVerify == null) return;
    int count = 0;
    var directory = await getTemporaryDirectory();
    var dir = Directory(p.join(directory.path, saveFolder));
    try {
      var dirList = dir.list();
      await for (FileSystemEntity f in dirList) {
        if (f is File) {
          String name = f.path.split('/').last;
          if (_fileStamp[name] != null) {
            count++;
          }
        } else if (f is Directory) {}
      }
    } catch (e) {
      print(e.toString());
    }
    print('count: $count');
    if (count == _fileStamp.keys.length) {
      onVerify(true);
    } else {
      onVerify(false);
    }
  }

  List<T> _chunk<T>(List list, int chunkSize) {
    List<dynamic> chunks = [];
    int len = list.length;
    for (var i = 0; i < len; i += chunkSize) {
      int size = i + chunkSize;
      chunks.add(list.sublist(i, size > len ? len : size));
    }
    return chunks;
  }
}
