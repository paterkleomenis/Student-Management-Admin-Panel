import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'language_service.dart';

class PermissionService {
  factory PermissionService() => _instance;
  PermissionService._internal();

  static final PermissionService _instance = PermissionService._internal();

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), check MANAGE_EXTERNAL_STORAGE
      if (await _isAndroid11OrHigher()) {
        return Permission.manageExternalStorage.isGranted;
      }
      // For older Android versions, check WRITE_EXTERNAL_STORAGE
      return Permission.storage.isGranted;
    }
    // Desktop platforms (Windows, macOS, Linux) and iOS don't need explicit storage permissions
    return true;
  }

  /// Request storage permissions
  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final langService = Provider.of<LanguageService>(context, listen: false);

      // For Android 11+ (API 30+)
      if (await _isAndroid11OrHigher()) {
        if (!context.mounted) return false;
        return _requestManageExternalStorage(context, langService);
      }

      // For older Android versions
      if (!context.mounted) return false;
      return _requestWriteExternalStorage(context, langService);
    }

    // Desktop platforms (Windows, macOS, Linux) and iOS don't need explicit storage permissions
    return true;
  }

  /// Check if device is Android 11 or higher
  Future<bool> _isAndroid11OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // This is a simplified check - in production you might want to use
      // device_info_plus package for more accurate version detection
      final status = await Permission.manageExternalStorage.status;
      return status.isGranted || status.isDenied || status.isPermanentlyDenied;
    } catch (e) {
      // If MANAGE_EXTERNAL_STORAGE is not available, it's likely older Android
      return false;
    }
  }

  /// Request MANAGE_EXTERNAL_STORAGE permission for Android 11+
  Future<bool> _requestManageExternalStorage(
    BuildContext context,
    LanguageService langService,
  ) async {
    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Show explanation dialog
      if (!context.mounted) return false;
      final shouldRequest = await _showPermissionDialog(
        context,
        langService,
        title: langService.getString('permissions.storage_title'),
        message: langService.getString('permissions.manage_storage_message'),
      );

      if (!shouldRequest) return false;
      if (!context.mounted) return false;

      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(context, langService);
      return false;
    }

    // Request permission
    final result = await Permission.manageExternalStorage.request();
    return result.isGranted;
  }

  /// Request WRITE_EXTERNAL_STORAGE permission for older Android versions
  Future<bool> _requestWriteExternalStorage(
    BuildContext context,
    LanguageService langService,
  ) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Show explanation dialog
      if (!context.mounted) return false;
      final shouldRequest = await _showPermissionDialog(
        context,
        langService,
        title: langService.getString('permissions.storage_title'),
        message: langService.getString('permissions.storage_message'),
      );

      if (!shouldRequest) return false;
      if (!context.mounted) return false;

      final result = await Permission.storage.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(context, langService);
      return false;
    }

    // Request permission
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// Show permission explanation dialog
  Future<bool> _showPermissionDialog(
    BuildContext context,
    LanguageService langService, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop(false);
            },
            child: Text(langService.getString('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop(true);
            },
            child: Text(langService.getString('permissions.grant_permission')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show settings dialog for permanently denied permissions
  Future<void> _showSettingsDialog(
    BuildContext context,
    LanguageService langService,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(langService.getString('permissions.permission_required')),
        content: Text(langService.getString('permissions.settings_message')),
        actions: [
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(langService.getString('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(langService.getString('permissions.open_settings')),
          ),
        ],
      ),
    );
  }

  /// Request storage permission with user-friendly handling
  Future<bool> requestStoragePermissionWithFeedback(
    BuildContext context,
  ) async {
    final langService = Provider.of<LanguageService>(context, listen: false);

    try {
      if (await hasStoragePermission()) {
        return true;
      }

      if (!context.mounted) return false;
      final granted = await requestStoragePermission(context);

      if (!context.mounted) return false;
      if (granted) {
        _showSuccessSnackBar(context, langService);
        return true;
      } else {
        _showErrorSnackBar(context, langService);
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      _showErrorSnackBar(context, langService, error: e.toString());
      return false;
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, LanguageService langService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(langService.getString('permissions.permission_granted')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(
    BuildContext context,
    LanguageService langService, {
    String? error,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error != null
              ? langService.getString(
                  'permissions.permission_error_details',
                  params: {'error': error},
                )
              : langService.getString('permissions.permission_denied'),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: langService.getString('permissions.try_again'),
          textColor: Colors.white,
          onPressed: () {
            requestStoragePermissionWithFeedback(context);
          },
        ),
      ),
    );
  }

  /// Check and request permissions before file operations
  Future<bool> ensureStoragePermission(BuildContext context) async {
    if (await hasStoragePermission()) {
      return true;
    }

    if (!context.mounted) return false;
    return requestStoragePermissionWithFeedback(context);
  }
}
