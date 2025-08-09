import 'package:flutter/material.dart';
import '../../services/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final String text;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const GoogleSignInButton({
    super.key,
    required this.text,
    this.onSuccess,
    this.onError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await GoogleAuthService.signInWithGoogle();
      
      if (userCredential != null) {
        widget.onSuccess?.call();
      }
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              )
            : Image.network(
                'https://developers.google.com/identity/images/g-logo.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: Colors.red,
                  );
                },
              ),
        label: Text(
          _isLoading ? 'Giriş yapılıyor...' : widget.text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
