import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Version check model
  static const String _versionCollection = 'versions';
  static const String _androidAppDoc = 'android-app-link';
  static const String _lastCheckKey = 'last_version_check';
  static const String _skipVersionKey = 'skip_version';
  
  /// Ana version kontrol fonksiyonu - uygulama açılışında çağrılır
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Günde bir kez kontrol et
      if (!await _shouldCheckToday()) {
        return;
      }
      
      final currentVersion = await _getCurrentVersion();
      final versionData = await _getVersionDataFromFirestore();
      
      if (versionData == null) {
        print('Version data not found in Firestore');
        return;
      }
      
      final latestVersion = versionData['version'] as String?;
      final downloadLink = versionData['link'] as String?;
      
      if (latestVersion == null || downloadLink == null) {
        print('Invalid version data structure');
        return;
      }
      
      // Skip edilen version mı kontrol et
      final skipVersion = await _getSkippedVersion();
      if (skipVersion == latestVersion) {
        return;
      }
      
      // Version karşılaştırması
      if (_isNewerVersion(currentVersion, latestVersion)) {
        await _markVersionCheckDate();
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, downloadLink);
        }
      }
    } catch (e) {
      print('Version check error: $e');
    }
  }
  
  /// Firestore'dan version bilgisini al
  static Future<Map<String, dynamic>?> _getVersionDataFromFirestore() async {
    try {
      final doc = await _firestore
          .collection(_versionCollection)
          .doc(_androidAppDoc)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching version data: $e');
      return null;
    }
  }
  
  /// Mevcut uygulama versiyonunu al
  static Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Error getting current version: $e');
      return '1.0.0';
    }
  }
  
  /// Version karşılaştırması yap
  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);
      
      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) {
          return true;
        } else if (latest[i] < current[i]) {
          return false;
        }
      }
      return false; // Versions are equal
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
  
  /// Version string'ini parse et
  static List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }
  
  /// Günde bir kez kontrol edilmesi için
  static Future<bool> _shouldCheckToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastCheckKey);
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      return lastCheck != today;
    } catch (e) {
      return true; // Hata durumunda kontrol et
    }
  }
  
  /// Version kontrol tarihini kaydet
  static Future<void> _markVersionCheckDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString(_lastCheckKey, today);
    } catch (e) {
      print('Error marking version check date: $e');
    }
  }
  
  /// Skip edilen versiyonu al
  static Future<String?> _getSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_skipVersionKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Versiyonu skip olarak işaretle
  static Future<void> _skipVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skipVersionKey, version);
    } catch (e) {
      print('Error skipping version: $e');
    }
  }
  
  /// Güncelleme dialog'unu göster
  static void _showUpdateDialog(BuildContext context, String newVersion, String downloadLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.system_update,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Güncelleme Mevcut',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WordLune\'un yeni versiyonu mevcut!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.new_releases,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Versiyon $newVersion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '• Yeni özellikler ve iyileştirmeler\n'
                  '• Hata düzeltmeleri\n'
                  '• Performans optimizasyonları',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  await _skipVersion(newVersion);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Daha Sonra',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _downloadAndInstallUpdate(context, downloadLink);
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text(
                  'Güncelleştir',
                  style: TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// APK indirme ve yükleme işlemi
  static Future<void> _downloadAndInstallUpdate(BuildContext context, String downloadLink) async {
    try {
      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          contentPadding: const EdgeInsets.all(24),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Güncelleme indiriliyor...',
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      
      // URL'yi aç (Google Drive link)
      final uri = Uri.parse(downloadLink);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (context.mounted) {
          Navigator.pop(context); // Loading dialog'unu kapat
          
          // Bilgilendirme dialog'u
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              title: const Text(
                'İndirme Başlatıldı',
                style: TextStyle(fontSize: 18),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: const Text(
                    'APK dosyası indirilmeye başladı. İndirme tamamlandığında dosyaya dokunarak yükleme işlemini tamamlayabilirsiniz.\n\n'
                    'Not: Bilinmeyen kaynaklardan uygulama yüklemeye izin vermeniz gerekebilir.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('URL açılamadı');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () => _downloadAndInstallUpdate(context, downloadLink),
            ),
          ),
        );
      }
    }
  }
  
  /// Manuel version kontrolü için (ayarlar ekranından)
  static Future<void> checkForUpdatesManually(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          contentPadding: const EdgeInsets.all(24),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Güncelleme kontrol ediliyor...',
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      
      final currentVersion = await _getCurrentVersion();
      final versionData = await _getVersionDataFromFirestore();
      
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
      }
      
      if (versionData == null) {
        _showNoUpdateDialog(context, 'Versiyon bilgisi alınamadı');
        return;
      }
      
      final latestVersion = versionData['version'] as String?;
      final downloadLink = versionData['link'] as String?;
      
      if (latestVersion == null || downloadLink == null) {
        _showNoUpdateDialog(context, 'Geçersiz versiyon bilgisi');
        return;
      }
      
      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, downloadLink);
        }
      } else {
        _showNoUpdateDialog(context, 'Uygulamanız güncel!');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
        _showNoUpdateDialog(context, 'Hata: $e');
      }
    }
  }
  
  /// Güncelleme yok dialog'u
  static void _showNoUpdateDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Güncelleme Durumu',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Text(
            message,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
