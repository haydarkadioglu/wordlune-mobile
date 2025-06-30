import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: screenWidth * 0.85,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.system_update,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Güncelleme Mevcut',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WordLune\'un yeni versiyonu mevcut!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.new_releases,
                              color: Theme.of(context).primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'v$newVersion',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Yeni özellikler\n• Hata düzeltmeleri\n• Performans iyileştirmeleri',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await _skipVersion(newVersion);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Sonra',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _downloadAndInstallUpdate(context, downloadLink);
                        },
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text(
                          'Güncelle',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(20),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'İndiriliyor...',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      
      // URL'yi aç (Multiple download strategies)
      List<String> downloadUrls = _generateDownloadUrls(downloadLink);
      bool downloadStarted = false;
      String lastError = '';
      
      for (String url in downloadUrls) {
        try {
          print('Trying URL: $url');
          final uri = Uri.parse(url);
          
          // Farklı launch modları dene
          List<LaunchMode> launchModes = [
            LaunchMode.externalApplication,
            LaunchMode.platformDefault,
            LaunchMode.externalNonBrowserApplication,
          ];
          
          bool urlLaunched = false;
          for (LaunchMode mode in launchModes) {
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: mode);
                urlLaunched = true;
                downloadStarted = true;
                print('Successfully launched: $url with mode: $mode');
                break;
              }
            } catch (modeError) {
              print('Failed to launch with mode $mode: $modeError');
              continue;
            }
          }
          
          if (urlLaunched) break;
          
        } catch (e) {
          lastError = e.toString();
          print('Failed to launch $url: $e');
          continue;
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
        
        if (downloadStarted) {
          // Başarılı indirme dialog'u
          _showSuccessDialog(context);
        } else {
          // Manual download dialog'u göster
          _showManualDownloadDialog(context, downloadLink, lastError);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
        _showManualDownloadDialog(context, downloadLink, e.toString());
      }
    }
  }
  
  /// Başarılı indirme dialog'u
  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_done,
                    color: Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'İndirme Başlatıldı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'APK dosyası indirilmeye başladı. İndirme tamamlandığında bildirimler panelinden dosyaya dokunarak yükleme işlemini tamamlayabilirsiniz.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Not: Bilinmeyen kaynaklardan uygulama yüklemeye izin vermeniz gerekebilir.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Hata dialog'u (şimdi manuel indirme dialog'u)
  static void _showManualDownloadDialog(BuildContext context, String downloadLink, String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    color: Colors.blue,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Manuel İndirme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Otomatik indirme başlatılamadı. Lütfen aşağıdaki linke tarayıcınızdan erişerek APK dosyasını manuel olarak indirin.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İndirme Linki:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      downloadLink,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hata detayı: $error',
                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Önce linki kopyala
                        await Clipboard.setData(ClipboardData(text: downloadLink));
                        
                        // Basit bir browser açma denemesi
                        try {
                          final uri = Uri.parse(downloadLink);
                          final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                          if (!launched) {
                            throw Exception('Browser açılamadı');
                          }
                          
                          // Başarılıysa kullanıcıya bilgi ver
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link panoya kopyalandı ve tarayıcı açıldı!'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          // Eğer bu da başarısız olursa, final instruction dialog'u göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link panoya kopyalandı!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          _showFinalInstructionDialog(context, downloadLink);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Tarayıcıda Aç'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Final instruction dialog
  static void _showFinalInstructionDialog(BuildContext context, String downloadLink) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'İndirme Talimatları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Güncellemeyi indirmek için:\n\n'
                '1. Aşağıdaki "Linki Kopyala" butonuna basın\n'
                '2. Tarayıcınızı açın\n'
                '3. Adres çubuğuna yapıştırın (Ctrl+V)\n'
                '4. APK dosyasını indirin\n'
                '5. İndirilen dosyaya dokunarak yükleyin',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(
                  downloadLink,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: downloadLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link panoya kopyalandı!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Linki Kopyala'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Tamam'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Eski hata dialog'u (artık kullanılmıyor ama uyumluluk için tutuldu)
  static void _showErrorDialog(BuildContext context, String downloadLink, String error) {
    _showManualDownloadDialog(context, downloadLink, error);
  }
  
  /// Farklı download URL'leri oluştur
  static List<String> _generateDownloadUrls(String originalUrl) {
    List<String> urls = [];
    
    // Google Drive linkiyse farklı formatları dene
    if (originalUrl.contains('drive.google.com')) {
      final fileId = _extractGoogleDriveFileId(originalUrl);
      if (fileId != null) {
        // En çok çalışan formatları önce dene
        urls.add('https://drive.google.com/u/0/uc?id=$fileId&export=download&confirm=t');
        urls.add('https://drive.google.com/uc?export=download&id=$fileId&confirm=t');
        urls.add('https://docs.google.com/uc?export=download&id=$fileId');
        urls.add('https://drive.google.com/uc?id=$fileId&export=download');
        
        // Backup olarak browser'da açılacak linkler
        urls.add('https://drive.google.com/file/d/$fileId/view?usp=sharing');
        urls.add('https://drive.google.com/open?id=$fileId');
      }
    }
    
    // Orijinal URL'yi en sona ekle
    urls.add(originalUrl);
    
    return urls;
  }
  
  /// Google Drive file ID'sini extract et
  static String? _extractGoogleDriveFileId(String url) {
    try {
      // Farklı Google Drive URL formatlarını destekle
      List<RegExp> patterns = [
        // https://drive.google.com/file/d/FILE_ID/view
        RegExp(r'/file/d/([a-zA-Z0-9_-]{25,})'),
        // https://drive.google.com/open?id=FILE_ID
        RegExp(r'[?&]id=([a-zA-Z0-9_-]{25,})'),
        // https://drive.google.com/uc?id=FILE_ID
        RegExp(r'[?&]id=([a-zA-Z0-9_-]{25,})'),
        // https://docs.google.com/document/d/FILE_ID
        RegExp(r'/document/d/([a-zA-Z0-9_-]{25,})'),
      ];
      
      for (RegExp pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null && match.group(1) != null) {
          print('Extracted file ID: ${match.group(1)}');
          return match.group(1);
        }
      }
      
      print('No file ID found in URL: $url');
      return null;
    } catch (e) {
      print('Error extracting Google Drive file ID: $e');
      return null;
    }
  }
  
  /// Manuel version kontrolü için (ayarlar ekranından)
  static Future<void> checkForUpdatesManually(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(20),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'Kontrol ediliyor...',
                  style: TextStyle(fontSize: 14),
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
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Güncel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
