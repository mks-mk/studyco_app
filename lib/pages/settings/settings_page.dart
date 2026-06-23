import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart'; // Add this import
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String appVersion = 'Loading...';
  String buildNumber = 'Loading...';
  String cacheSize = 'Calculating...';
  bool isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _calculateCacheSize();
  }

  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        appVersion = 'Unknown';
        buildNumber = 'Unknown';
      });
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      int totalSize = 0;

      // FIXED: Use path_provider to get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        totalSize += await _getTotalSizeOfFilesInDir(tempDir);
      }

      // FIXED: Get application documents directory for app cache
      Directory appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        totalSize += await _getTotalSizeOfFilesInDir(appDir);
      }

      // Get DefaultCacheManager cache directory
      try {
        await DefaultCacheManager().emptyCache();
        // Reset cache manager to get fresh cache info
        final cacheManager = DefaultCacheManager();
        // Note: DefaultCacheManager doesn't expose cache directory directly
        // So we'll estimate based on temporary directory
      } catch (e) {
        print('Cache manager error: $e');
      }

      setState(() {
        cacheSize = _formatBytes(totalSize);
      });
    } catch (e) {
      setState(() {
        cacheSize = 'Unable to calculate';
      });
      print('Error calculating cache size: $e');
    }
  }

  // ADDED: Helper method to calculate directory size recursively
  Future<int> _getTotalSizeOfFilesInDir(Directory directory) async {
    int totalSize = 0;
    try {
      if (await directory.exists()) {
        await for (FileSystemEntity entity in directory.list(recursive: true)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              // Some files might be inaccessible, skip them
            }
          }
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return totalSize;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _clearCache() async {
    setState(() {
      isClearing = true;
    });

    try {
      // Clear DefaultCacheManager cache
      await DefaultCacheManager().emptyCache();

      // FIXED: Clear temporary directory using path_provider
      Directory tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await _deleteDirectoryContents(tempDir);
      }

      // FIXED: Clear application documents directory (be careful with this)
      // Only clear cache-related files, not all app data
      Directory appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        // Only clear specific cache folders, not the entire app directory
        await _clearCacheFiles(appDir);
      }

      // Recalculate cache size
      await _calculateCacheSize();

      Get.snackbar(
        'Success',
        'Cache cleared successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear cache: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isClearing = false;
      });
    }
  }

  // ADDED: Safely delete directory contents
  Future<void> _deleteDirectoryContents(Directory directory) async {
    try {
      if (await directory.exists()) {
        await for (FileSystemEntity entity in directory.list()) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            // Some files might be in use, skip them
            print('Could not delete ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error deleting directory contents: $e');
    }
  }

  // ADDED: Clear only cache-related files from app directory
  Future<void> _clearCacheFiles(Directory directory) async {
    try {
      if (await directory.exists()) {
        await for (FileSystemEntity entity in directory.list()) {
          try {
            // Only delete files/folders that are clearly cache-related
            if (entity.path.contains('cache') ||
                entity.path.contains('temp') ||
                entity.path.contains('tmp')) {
              if (entity is File) {
                await entity.delete();
              } else if (entity is Directory) {
                await entity.delete(recursive: true);
              }
            }
          } catch (e) {
            print('Could not delete cache file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error clearing cache files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.6,
          colors: [Color(0xFFDDCFAF), Color(0xFFFFFFFF)],
          stops: [0.05, 0.80],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Settings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Information Section
                _buildSectionHeader('App Information'),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: 'v$appVersion',
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFBB00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Creation $buildNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                _buildInfoCard(
                  icon: Icons.shield_rounded,
                  title: 'Privacy & Policy',
                  subtitle: 'Redirect to privacy policy',
                ),

                SizedBox(height: 24),

                // Storage Section
                _buildSectionHeader('Storage Management'),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.storage,
                  title: 'Cache Size',
                  subtitle: cacheSize,
                  trailing: ElevatedButton(
                    onPressed: isClearing ? null : _showClearCacheDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isClearing
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text('Clear'),
                  ),
                ),

                _buildInfoCard(
                  icon: Icons.refresh,
                  title: 'Refresh Cache Info',
                  subtitle: 'Recalculate cache size',
                  onTap: _calculateCacheSize,
                  trailing: Icon(
                    Icons.refresh,
                    color: Color(0xFFFFBB00),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black,
                    size: 20,
                  ),
                ),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Clear Cache',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'This will clear all cached data including images and temporary files. This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearCache();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Clear Cache',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
