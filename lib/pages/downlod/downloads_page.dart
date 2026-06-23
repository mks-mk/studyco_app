import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/downloads/save_controller.dart';
import '../pdf_viewer/pdf_view_page.dart';

class OfflineMaterialsPage extends StatelessWidget {
  const OfflineMaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadManager = Get.put(SecureDownloadManager());

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
            'Offline Materials',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () => _showClearAllDialog(downloadManager),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (!downloadManager.isInitialized.value) {
              return Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Storage Info
                _buildStorageInfo(downloadManager),

                // Active Downloads
                if (downloadManager.activeDownloads.isNotEmpty)
                  _buildActiveDownloads(downloadManager),

                // Downloaded Materials
                Expanded(
                  child: downloadManager.downloadedMaterials.isEmpty
                      ? _buildEmptyState()
                      : _buildMaterialsList(downloadManager),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStorageInfo(SecureDownloadManager downloadManager) {
    final totalSize = downloadManager.getTotalDownloadedSize();
    final formattedSize = _formatBytes(totalSize);
    final materialCount = downloadManager.downloadedMaterials.length;

    return Container(
      margin: EdgeInsets.all(16),
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
          Icon(Icons.storage, color: Color(0xFFFFBB00), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Storage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$materialCount materials • $formattedSize',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDownloads(SecureDownloadManager downloadManager) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Downloads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          ...downloadManager.activeDownloads.map((download) =>
              _buildDownloadProgressCard(download)
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDownloadProgressCard(DownloadProgress download) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  download.title,
                  style: TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(download.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: download.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              download.status == DownloadStatus.failed
                  ? Colors.red
                  : Color(0xFFFFBB00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList(SecureDownloadManager downloadManager) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: downloadManager.downloadedMaterials.length,
      itemBuilder: (context, index) {
        final material = downloadManager.downloadedMaterials[index];
        return _buildMaterialCard(material, downloadManager);
      },
    );
  }

  Widget _buildMaterialCard(DownloadedMaterial material, SecureDownloadManager downloadManager) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 150,
          decoration: BoxDecoration(
            color: _getMaterialColor(material.materialType),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: material.thumbnailPath != null && material.thumbnailPath!.isNotEmpty
                ? Image.file(
              File(material.thumbnailPath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if thumbnail fails to load
                return Icon(
                  _getMaterialIcon(material.materialType),
                  color: Colors.white,
                  size: 24,
                );
              },

            )
                : Icon(
              _getMaterialIcon(material.materialType),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        title: Text(
          material.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2),
            Row(
              children: [
                Text(
                  material.subject,
                  style: TextStyle(
                    color: Color(0xFFFFBB00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.download_done, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  _formatBytes(material.fileSize),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          color: Colors.white,
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 18),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'open') {
              await _openMaterial(material, downloadManager);
            } else if (value == 'delete') {
              await _deleteMaterial(material, downloadManager);
            }
          },
        ),
        onTap: () => _openMaterial(material, downloadManager),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Offline Materials',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Download materials to access them offline',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openMaterial(DownloadedMaterial material, SecureDownloadManager downloadManager) async {
    try {
      // Decrypt file for viewing
      final decryptedPath = await downloadManager.decryptFileForViewing(material.filePath);

      // Open with appropriate viewer based on material type
      if (material.materialType.toLowerCase() == 'pdf') {
        Get.to(() => PremiumPdfViewPage(
          url: decryptedPath,
          title: material.title,
          isOfflineFile: true,
        ));
      } else {
        // Handle other file types (video, audio, etc.)
        Get.snackbar(
          'Info',
          'Opening ${material.materialType} files will be available soon',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open material: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteMaterial(DownloadedMaterial material, SecureDownloadManager downloadManager) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await downloadManager.deleteMaterial(material.materialId);
    }
  }

  void _showClearAllDialog(SecureDownloadManager downloadManager) {
    Get.dialog(
      AlertDialog(
        title: Text('Clear All Downloads'),
        content: Text('This will delete all offline materials. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              downloadManager.clearAllDownloads();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Color _getMaterialColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'video':
        return Colors.blue;
      case 'audio':
        return Colors.green;
      case 'image':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      default:
        return Icons.file_present;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
