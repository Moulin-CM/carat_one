import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String updateMessage;
  final String updateUrl;
  final bool isForceUpdate;

  const ForceUpdateDialog({
    super.key,
    required this.updateMessage,
    required this.updateUrl,
    this.isForceUpdate = true,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isForceUpdate, // Prevent back button if force update
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              updateMessage.isEmpty
                  ? 'A new version of the app is available. Please update to continue using the app.'
                  : updateMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isForceUpdate
                          ? 'This update is mandatory to continue using the app.'
                          : 'We recommend updating to the latest version for the best experience.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Later',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () => _handleUpdate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 20),
                SizedBox(width: 8),
                Text(
                  'Update Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate(BuildContext context) async {
    if (updateUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update URL is not available. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Ensure URL has proper scheme (http/https)
      String urlToLaunch = updateUrl.trim();
      
      // Debug: Print the original URL
      print('Force Update - Original URL: $urlToLaunch');
      
      // Add https:// if no scheme is present
      if (!urlToLaunch.startsWith('http://') && !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
        print('Force Update - Added https:// prefix: $urlToLaunch');
      }

      Uri uri;
      try {
        uri = Uri.parse(urlToLaunch);
      } catch (e) {
        throw Exception('Invalid URL format: $e. URL: $urlToLaunch');
      }
      
      // Validate URI is valid
      if (!uri.hasScheme || uri.scheme.isEmpty) {
        throw Exception('Invalid URL: Missing scheme (http:// or https://)');
      }

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        throw Exception('Invalid URL scheme: ${uri.scheme}. Only http:// and https:// are supported.');
      }

      // Debug: Print the parsed URI
      print('Force Update - Parsed URI: ${uri.toString()}');
      print('Force Update - Scheme: ${uri.scheme}, Host: ${uri.host}');

      // Try to launch the URL directly - don't use canLaunchUrl as it's unreliable
      // Start with externalApplication which opens in browser
      bool launched = false;
      String? errorDetails;
      
      try {
        print('Force Update - Attempting to launch with externalApplication mode...');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('Force Update - Launch result: $launched');
      } catch (e) {
        errorDetails = e.toString();
        print('Force Update - externalApplication failed: $errorDetails');
        
        // If externalApplication fails, try platformDefault
        try {
          print('Force Update - Attempting to launch with platformDefault mode...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          print('Force Update - Launch result (platformDefault): $launched');
        } catch (e2) {
          errorDetails = e2.toString();
          print('Force Update - platformDefault failed: $errorDetails');
        }
      }

      if (launched) {
        print('Force Update - URL launched successfully');
        // Small delay to ensure the URL opens
        await Future.delayed(const Duration(milliseconds: 300));
        
        // If it's not a force update, close the dialog after launching
        if (!isForceUpdate && context.mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(errorDetails ?? 'Failed to launch URL. The system returned false.');
      }
    } catch (e) {
      print('Force Update - Error: $e');
      
      if (context.mounted) {
        // Show user-friendly error message with URL for debugging
        String errorMessage = 'Unable to open update URL.';
        
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('no activity found') || 
            errorString.contains('no application found') ||
            errorString.contains('resolveactivity')) {
          errorMessage = 'No browser found to open the URL. Please install a web browser (Chrome, Firefox, etc.) and try again.\n\nURL: $updateUrl';
        } else if (errorString.contains('network') || 
                   errorString.contains('socket') ||
                   errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('invalid url') || 
                   errorString.contains('malformed') ||
                   errorString.contains('invalid format')) {
          errorMessage = 'Invalid URL format. Please contact support.\n\nURL: $updateUrl\nError: ${e.toString()}';
        } else {
          errorMessage = 'Unable to open update URL.\n\nPlease try opening this URL manually in your browser:\n$updateUrl\n\nError: ${e.toString()}';
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    }
  }
}

