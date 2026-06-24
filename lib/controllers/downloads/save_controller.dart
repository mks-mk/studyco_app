import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SecureDownloadManager extends GetxController {
  static SecureDownloadManager get instance => Get.find();

  // FIXED: Make database nullable instead of late
  Database? _database;
  final Dio _dio = Dio();

  // Observable lists
  var downloadedMaterials = <DownloadedMaterial>[].obs;
  var activeDownloads = <DownloadProgress>[].obs;
  var isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    // FIXED: Initialize database first, then load materials
    _initializeDatabase();
  }

  // FIXED: Initialize database and then load materials
  Future<void> _initializeDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = '${documentsDirectory.path}/secure_downloads.db';

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            '''CREATE TABLE downloads(
              id TEXT PRIMARY KEY,
              materialId TEXT NOT NULL,
              title TEXT NOT NULL,
              subject TEXT NOT NULL,
              fileName TEXT NOT NULL,
              filePath TEXT NOT NULL,
              fileSize INTEGER NOT NULL,
              downloadDate TEXT NOT NULL,
              materialType TEXT NOT NULL,
              thumbnailPath TEXT,
              isEncrypted INTEGER DEFAULT 1
            )''',
          );
        },
      );

      isInitialized.value = true;
      print('Secure download database initialized');

      // FIXED: Load materials AFTER database is initialized
      await _loadDownloadedMaterials();

    } catch (e) {
      print('Database initialization error: $e');
    }
  }

  // FIXED: Check if database is initialized before using
  Future<void> _loadDownloadedMaterials() async {
    try {
      // FIXED: Check if database is initialized
      if (_database == null) {
        print('Database not initialized yet');
        return;
      }

      final List<Map<String, dynamic>> maps = await _database!.query('downloads');

      downloadedMaterials.value = maps.map((map) => DownloadedMaterial.fromMap(map)).toList();

      // Verify files still exist
      await _verifyDownloadedFiles();

      print('Loaded ${downloadedMaterials.length} downloaded materials');
    } catch (e) {
      print('Error loading downloaded materials: $e');
    }
  }

  // FIXED: Check database initialization in all database operations
  Future<void> _verifyDownloadedFiles() async {
    if (_database == null) return;

    final List<DownloadedMaterial> validMaterials = [];

    for (final material in downloadedMaterials) {
      final file = File(material.filePath);
      if (await file.exists()) {
        validMaterials.add(material);
      } else {
        // Remove from database if file doesn't exist
        await _database!.delete('downloads', where: 'id = ?', whereArgs: [material.id]);
      }
    }

    downloadedMaterials.value = validMaterials;
  }

  // FIXED: Check database initialization before download
  Future<bool> downloadMaterial({
    required String materialId,
    required String title,
    required String subject,
    required String downloadUrl,
    required String materialType,
    String? thumbnailUrl,
  }) async {
    try {
      // FIXED: Wait for database initialization
      if (_database == null) {
        await _initializeDatabase();
      }

      // Check if already downloaded
      if (isMaterialDownloaded(materialId)) {
        Get.snackbar('Info', 'Material already downloaded');
        return false;
      }

      // Create secure directory
      final secureDir = await _getSecureDownloadDirectory();
      final fileName = _generateSecureFileName(materialId, title, materialType);
      final filePath = '${secureDir.path}/$fileName';

      final downloadProgress = DownloadProgress(
        materialId: materialId,
        title: title,
        progress: 0.0,
        status: DownloadStatus.downloading,
      );
      activeDownloads.add(downloadProgress);

      // Download file with progress tracking
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final index = activeDownloads.indexWhere((d) => d.materialId == materialId);
            if (index != -1) {
              activeDownloads[index] = downloadProgress.copyWith(progress: progress);
            }
          }
        },
      );

      // Encrypt file for security
      final encryptedPath = await _encryptFile(filePath);

      // Download thumbnail if available
      String? thumbnailPath;
      if (thumbnailUrl != null) {
        thumbnailPath = await _downloadThumbnail(materialId, thumbnailUrl, secureDir);
      }

      // Get file size
      final file = File(encryptedPath);
      final fileSize = await file.length();

      // Save to database
      final downloadedMaterial = DownloadedMaterial(
        id: _generateId(),
        materialId: materialId,
        title: title,
        subject: subject,
        fileName: fileName,
        filePath: encryptedPath,
        fileSize: fileSize,
        downloadDate: DateTime.now(),
        materialType: materialType,
        thumbnailPath: thumbnailPath,
        isEncrypted: true,
      );

      // FIXED: Check database before insert
      if (_database != null) {
        await _database!.insert('downloads', downloadedMaterial.toMap());
        downloadedMaterials.add(downloadedMaterial);
      }

      // Update download status
      final index = activeDownloads.indexWhere((d) => d.materialId == materialId);
      if (index != -1) {
        activeDownloads[index] = downloadProgress.copyWith(
          progress: 1.0,
          status: DownloadStatus.completed,
        );

        // Remove from active downloads after delay
        Future.delayed(Duration(seconds: 2), () {
          activeDownloads.removeAt(index);
        });
      }

      Get.snackbar(
        'Success',
        'Material downloaded successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      // Update download status to failed
      final index = activeDownloads.indexWhere((d) => d.materialId == materialId);
      if (index != -1) {
        activeDownloads[index] = activeDownloads[index].copyWith(
          status: DownloadStatus.failed,
        );
      }

      Get.snackbar(
        'Error',
        'Failed to download material: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      print('Download error: $e');
      return false;
    }
  }

  Future<bool> deleteMaterial(String materialId) async {
    try {
      if (_database == null) return false;

      final material = getDownloadedMaterial(materialId);
      if (material == null) return false;

      // Delete file
      final file = File(material.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete thumbnail
      if (material.thumbnailPath != null) {
        final thumbnailFile = File(material.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // Remove from database
      await _database!.delete('downloads', where: 'materialId = ?', whereArgs: [materialId]);

      // Remove from list
      downloadedMaterials.removeWhere((m) => m.materialId == materialId);

      Get.snackbar(
        'Success',
        'Material deleted successfully',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  // FIXED: Check database initialization before clear
  Future<void> clearAllDownloads() async {
    try {
      if (_database == null) return;

      // Delete all files
      for (final material in downloadedMaterials) {
        final file = File(material.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        if (material.thumbnailPath != null) {
          final thumbnailFile = File(material.thumbnailPath!);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }
      }

      // Clear database
      await _database!.delete('downloads');

      // Clear lists
      downloadedMaterials.clear();
      activeDownloads.clear();

      Get.snackbar(
        'Success',
        'All downloads cleared',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Clear all error: $e');
    }
  }

  // Rest of your methods remain the same...
  Future<Directory> _getSecureDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final secureDir = Directory('${appDir.path}/secure_materials');

    if (!await secureDir.exists()) {
      await secureDir.create(recursive: true);
    }

    return secureDir;
  }

  String _generateSecureFileName(String materialId, String title, String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$materialId$title$timestamp')).toString();
    final extension = _getFileExtension(type);
    return '${hash.substring(0, 16)}.$extension.secure';
  }

  String _getFileExtension(String materialType) {
    switch (materialType.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'video':
        return 'mp4';
      case 'audio':
        return 'mp3';
      case 'image':
        return 'jpg';
      default:
        return 'dat';
    }
  }

  Future<String> _encryptFile(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      final bytes = await originalFile.readAsBytes();

      final key = utf8.encode('StudyCoSecureKey2024');
      final encryptedBytes = Uint8List(bytes.length);

      for (int i = 0; i < bytes.length; i++) {
        encryptedBytes[i] = bytes[i] ^ key[i % key.length];
      }

      final encryptedPath = '$originalPath.encrypted';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      await originalFile.delete();

      return encryptedPath;
    } catch (e) {
      print('Encryption error: $e');
      return originalPath;
    }
  }

  Future<String> decryptFileForViewing(String encryptedPath) async {
    try {
      final encryptedFile = File(encryptedPath);
      final encryptedBytes = await encryptedFile.readAsBytes();

      final key = utf8.encode('StudyCoSecureKey2024');
      final decryptedBytes = Uint8List(encryptedBytes.length);

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes[i] = encryptedBytes[i] ^ key[i % key.length];
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes);

      return tempPath;
    } catch (e) {
      print('Decryption error: $e');
      rethrow;
    }
  }

  Future<String?> _downloadThumbnail(String materialId, String thumbnailUrl, Directory secureDir) async {
    try {
      final thumbnailPath = '${secureDir.path}/thumb_$materialId.jpg';
      await _dio.download(thumbnailUrl, thumbnailPath);
      return thumbnailPath;
    } catch (e) {
      print('Thumbnail download error: $e');
      return null;
    }
  }

  bool isMaterialDownloaded(String materialId) {
    return downloadedMaterials.any((material) => material.materialId == materialId);
  }

  DownloadedMaterial? getDownloadedMaterial(String materialId) {
    try {
      return downloadedMaterials.firstWhere((material) => material.materialId == materialId);
    } catch (e) {
      return null;
    }
  }

  int getTotalDownloadedSize() {
    return downloadedMaterials.fold(0, (sum, material) => sum + material.fileSize);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Your existing data models remain the same...
class DownloadedMaterial {
  final String id;
  final String materialId;
  final String title;
  final String subject;
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime downloadDate;
  final String materialType;
  final String? thumbnailPath;
  final bool isEncrypted;

  DownloadedMaterial({
    required this.id,
    required this.materialId,
    required this.title,
    required this.subject,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.downloadDate,
    required this.materialType,
    this.thumbnailPath,
    this.isEncrypted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialId': materialId,
      'title': title,
      'subject': subject,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'downloadDate': downloadDate.toIso8601String(),
      'materialType': materialType,
      'thumbnailPath': thumbnailPath,
      'isEncrypted': isEncrypted ? 1 : 0,
    };
  }

  factory DownloadedMaterial.fromMap(Map<String, dynamic> map) {
    return DownloadedMaterial(
      id: map['id'],
      materialId: map['materialId'],
      title: map['title'],
      subject: map['subject'],
      fileName: map['fileName'],
      filePath: map['filePath'],
      fileSize: map['fileSize'],
      downloadDate: DateTime.parse(map['downloadDate']),
      materialType: map['materialType'],
      thumbnailPath: map['thumbnailPath'],
      isEncrypted: map['isEncrypted'] == 1,
    );
  }
}

class DownloadProgress {
  final String materialId;
  final String title;
  final double progress;
  final DownloadStatus status;

  DownloadProgress({
    required this.materialId,
    required this.title,
    required this.progress,
    required this.status,
  });

  DownloadProgress copyWith({
    String? materialId,
    String? title,
    double? progress,
    DownloadStatus? status,
  }) {
    return DownloadProgress(
      materialId: materialId ?? this.materialId,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}

enum DownloadStatus {
  downloading,
  completed,
  failed,
  paused,
}
