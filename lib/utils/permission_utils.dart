import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A utility class for handling permissions in a sequential and user-friendly way
class PermissionUtils {
  /// Request multiple permissions sequentially with proper user feedback
  /// 
  /// This method will request each permission one by one, showing appropriate
  /// dialogs to explain why each permission is needed before requesting it.
  /// 
  /// Returns a map with each permission and its granted status
  static Future<Map<Permission, bool>> requestPermissionsSequentially({
    required BuildContext context,
    required List<Permission> permissions,
    required Map<Permission, String> rationales,
    bool showSettings = true,
  }) async {
    final Map<Permission, bool> results = {};
    
    for (final permission in permissions) {
      // Check if permission is already granted
      final status = await permission.status;
      
      if (status.isGranted) {
        results[permission] = true;
        continue;
      }
      
      // Show rationale dialog if needed
      if (rationales.containsKey(permission)) {
        final shouldProceed = await _showRationaleDialog(
          context: context,
          message: rationales[permission]!,
          permission: permission,
        );
        
        if (!shouldProceed) {
          results[permission] = false;
          continue;
        }
      }
      
      // Request the permission
      final result = await permission.request();
      results[permission] = result.isGranted;
      
      // If permission is permanently denied, show settings dialog
      if (result.isPermanentlyDenied && showSettings) {
        await _showSettingsDialog(context);
      }
    }
    
    return results;
  }
  
  /// Shows a dialog explaining why a permission is needed
  static Future<bool> _showRationaleDialog({
    required BuildContext context,
    required String message,
    required Permission permission,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Continue'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Shows a dialog prompting the user to open app settings
  static Future<void> _showSettingsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text('This feature requires permissions that you have denied. '
            'Please open settings to enable these permissions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Check if all required permissions are granted
  static Future<bool> checkPermissions(List<Permission> permissions) async {
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }
}
