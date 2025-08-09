import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/version_check_service.dart';
import '../services/google_auth_service.dart';
import '../services/language_preference_service.dart';
import '../services/migration_service.dart';
import '../providers/language_provider.dart';
import '../generated/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _appVersion = '';
  String _buildNumber = '';
  String _selectedLanguage = 'Turkish';
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadLanguagePreference();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('Error loading app info: $e');
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final language = await LanguagePreferenceService.getSelectedLanguage();
      setState(() {
        _selectedLanguage = language;
      });
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : user?.email?[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Account Settings
          _buildSectionTitle('Account Settings'),
          const SizedBox(height: 8),
          
          _buildSettingsCard([
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: 'Change Name',
              subtitle: 'Update your display name',
              onTap: _showChangeNameDialog,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account security',
              onTap: _showChangePasswordDialog,
            ),
          ]),
          
          const SizedBox(height: 16),
          
          // Learning Language Settings
          _buildSectionTitle('Learning Language'),
          const SizedBox(height: 8),
          
          _buildSettingsCard([
            _buildSettingsItem(
              icon: Icons.language,
              title: 'Selected Language',
              subtitle: _selectedLanguage,
              onTap: _showLanguageSelectionDialog,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.sync,
              title: 'Migrate Data',
              subtitle: 'Migrate existing data to new structure',
              onTap: _showMigrationDialog,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.update,
              title: 'Update Language Tags',
              subtitle: 'Add language tags to existing data',
              onTap: _updateLanguageTags,
            ),
          ]),
          
          const SizedBox(height: 16),
          
          // Interface Language Settings
          _buildSectionTitle('Interface Language'),
          const SizedBox(height: 8),
          
          _buildSettingsCard([
            _buildSettingsItem(
              icon: Icons.translate,
              title: 'App Language',
              subtitle: context.watch<LanguageProvider>().isEnglish ? 'English' : 'Türkçe',
              onTap: _showInterfaceLanguageDialog,
            ),
          ]),
          
          const SizedBox(height: 16),
          
          // App Settings
          _buildSectionTitle('App'),
          const SizedBox(height: 8),
          
          _buildSettingsCard([
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: 'v$_appVersion ($_buildNumber)',
              onTap: null,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.system_update_outlined,
              title: 'Check for Updates',
              subtitle: 'Check for new version',
              onTap: () => VersionCheckService.checkForUpdatesManually(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.contact_support_outlined,
              title: 'Contact',
              subtitle: 'Support and feedback',
              onTap: _showContactDialog,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How your data is protected',
              onTap: _showPrivacyPolicy,
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Logout Button
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _showLogoutDialog,
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[300]
              : Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
  
  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey[300],
    );
  }
  
  void _showChangeNameDialog() {
    final nameController = TextEditingController(text: _auth.currentUser?.displayName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await _auth.currentUser?.updateDisplayName(newName);
                  await _auth.currentUser?.reload();
                  
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {}); // Refresh UI
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text;
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;
              
              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                final user = _auth.currentUser;
                final credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPassword,
                );
                
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
  
  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WordLune Support Team'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text('info@notiral.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.language, size: 20),
                SizedBox(width: 8),
                Text('www.wordlune.notiral.com'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Feel free to contact us for questions, suggestions, or technical support.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showInterfaceLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select App Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: context.watch<LanguageProvider>().isEnglish 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                final provider = context.read<LanguageProvider>();
                await provider.setLocale(const Locale('en'));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App language changed to English'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Türkçe'),
              trailing: context.watch<LanguageProvider>().isTurkish 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                final provider = context.read<LanguageProvider>();
                await provider.setLocale(const Locale('tr'));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Uygulama dili Türkçe olarak değiştirildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Learning Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: LanguagePreferenceService.availableLanguages.length,
                itemBuilder: (context, index) {
                  final language = LanguagePreferenceService.availableLanguages[index];
                  return ListTile(
                    title: Text(language),
                    trailing: languageProvider.selectedLanguage == language 
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () async {
                      await languageProvider.setLanguage(language);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Learning language changed to $language'),
                            backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMigrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate Data'),
        content: const Text(
          'This will migrate your existing words and lists to the new language-based structure. '
          'This process is irreversible. Do you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performMigration();
            },
            child: const Text('Migrate'),
          ),
        ],
      ),
    );
  }

  Future<void> _performMigration() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Migrating data...'),
            ],
          ),
        ),
      );

      // Check if migration is needed
      final needsMigration = await MigrationService.isMigrationNeeded();
      
      if (!needsMigration) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to migrate'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Perform migration
      await MigrationService.migrateToLanguageBasedStructure();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data migrated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLanguageTags() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Updating language tags...'),
            ],
          ),
        ),
      );

      // This feature is temporarily disabled
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language tags update feature is temporarily disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language tags: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WordLune Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Data Collection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Account information (email, name)'),
              Text('• Word and list data'),
              Text('• App usage statistics'),
              SizedBox(height: 12),
              Text(
                'Data Usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Service provision and improvement'),
              Text('• Enhancing user experience'),
              Text('• Security and authentication'),
              SizedBox(height: 12),
              Text(
                'Data Security:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• All data is encrypted and stored securely'),
              Text('• Firebase security protocols'),
              Text('• Regular security updates'),
              SizedBox(height: 16),
              Text(
                'Your data is never shared with third parties.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Google ile giriş yapılmışsa Google'dan da çıkış yap
                if (GoogleAuthService.isSignedInWithGoogle()) {
                  await GoogleAuthService.signOut();
                } else {
                  await _auth.signOut();
                }
                
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yaparken hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
