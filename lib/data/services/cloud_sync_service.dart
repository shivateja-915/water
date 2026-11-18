import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder_settings.dart';
import 'supabase_service.dart';

class SyncReport {
  final int localRevision;
  final int remoteRevision;
  final bool pendingUploads;
  final bool pendingDownloads;
  final String conflictState;
  final String? lastUpload;
  final String? lastDownload;

  const SyncReport({
    required this.localRevision,
    required this.remoteRevision,
    required this.pendingUploads,
    required this.pendingDownloads,
    required this.conflictState,
    this.lastUpload,
    this.lastDownload,
  });
}

/// CloudSyncService:
/// Dedicated solely to cloud communication (upload, download, conflict resolution, retry).
/// Does NOT touch local device OS scheduling or notification plugins.
class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  SupabaseClient get _client => SupabaseService.client;
  static const String _syncReportKey = 'cloud_sync_last_report';

  int _lastRemoteRevision = 0;
  String? _lastUploadIso;
  String? _lastDownloadIso;
  String _conflictState = 'NONE';
  bool _pendingUploads = false;
  bool _pendingDownloads = false;

  /// Uploads reminder settings to Supabase cloud storage.
  /// Never throws an error that interrupts local device flow.
  Future<bool> uploadReminderSettings(ReminderSettings settings) async {
    final user = _client.auth.currentUser;
    final activeId = user?.id ?? settings.userId;
    if (activeId.isEmpty || activeId == 'guest') {
      debugPrint('CloudSyncService: Guest user, skipping cloud upload.');
      return false;
    }

    try {
      _pendingUploads = true;
      final payload = settings.toSupabaseJson();
      payload['user_id'] = activeId;
      payload['id'] = activeId;

      await _client.from('reminder_settings').upsert(payload);

      _lastUploadIso = DateTime.now().toIso8601String();
      _pendingUploads = false;
      _conflictState = 'SYNCED';
      _saveReportState(settings.revision, settings.revision);
      debugPrint('✓ CloudSyncService: Upload completed (Revision ${settings.revision})');
      return true;
    } catch (e) {
      _pendingUploads = true;
      _conflictState = 'PENDING_UPLOAD_OFFLINE';
      debugPrint('ℹ CloudSyncService: Cloud upload postponed (offline/error): $e');
      return false;
    }
  }

  /// Downloads reminder settings from Supabase cloud storage.
  Future<ReminderSettings?> downloadReminderSettings(String userId) async {
    if (userId.isEmpty || userId == 'guest') return null;

    try {
      _pendingDownloads = true;
      final response = await _client
          .from('reminder_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      _pendingDownloads = false;
      if (response != null) {
        final remote = ReminderSettings.fromJson(response);
        _lastRemoteRevision = remote.revision;
        _lastDownloadIso = DateTime.now().toIso8601String();
        debugPrint('✓ CloudSyncService: Downloaded remote revision ${remote.revision}');
        return remote;
      }
    } catch (e) {
      _pendingDownloads = false;
      debugPrint('ℹ CloudSyncService: Download failed or offline: $e');
    }
    return null;
  }

  /// Conflict Resolution Rule:
  /// - If Local Revision > Remote: return Local (Upload needed)
  /// - If Remote Revision > Local: return Remote (Download needed)
  /// - If Equal: return Local (No Action)
  ReminderSettings resolveConflicts(
    ReminderSettings local,
    ReminderSettings remote,
  ) {
    debugPrint(
        'CloudSyncService: Resolving conflict -> Local Rev: ${local.revision} vs Remote Rev: ${remote.revision}');
    if (remote.revision > local.revision) {
      _conflictState = 'RESOLVED_REMOTE_WINNER';
      return remote;
    } else if (local.revision > remote.revision) {
      _conflictState = 'RESOLVED_LOCAL_WINNER';
      return local;
    } else {
      // If revisions match, compare updatedAt timestamps
      final localDt = DateTime.tryParse(local.updatedAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final remoteDt = DateTime.tryParse(remote.updatedAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (remoteDt.isAfter(localDt)) {
        _conflictState = 'RESOLVED_REMOTE_TIMESTAMP';
        return remote;
      }
      _conflictState = 'RESOLVED_EQUAL_OR_LOCAL';
      return local;
    }
  }

  /// Coordinates background synchronization without blocking UI or local OS alarms.
  Future<ReminderSettings> syncReminderSettings(ReminderSettings localSettings) async {
    final activeId = _client.auth.currentUser?.id ?? localSettings.userId;
    if (activeId.isEmpty || activeId == 'guest') return localSettings;

    final remoteSettings = await downloadReminderSettings(activeId);
    if (remoteSettings == null) {
      // Upload local if cloud has no record
      unawaited(uploadReminderSettings(localSettings));
      return localSettings;
    }

    final resolved = resolveConflicts(localSettings, remoteSettings);
    if (resolved == remoteSettings && remoteSettings.revision > localSettings.revision) {
      debugPrint('✓ CloudSyncService: Newer remote version detected. Adopting revision ${remoteSettings.revision}.');
      _saveReportState(localSettings.revision, remoteSettings.revision);
      return remoteSettings;
    } else if (localSettings.revision > remoteSettings.revision) {
      debugPrint('✓ CloudSyncService: Local revision is newer. Uploading local revision ${localSettings.revision}.');
      unawaited(uploadReminderSettings(localSettings));
    }
    _saveReportState(localSettings.revision, remoteSettings.revision);
    return localSettings;
  }

  /// Verifies cloud state against local revision
  Future<bool> verifyCloudState(String userId, int expectedRevision) async {
    final remote = await downloadReminderSettings(userId);
    if (remote == null) return false;
    return remote.revision == expectedRevision;
  }

  void _saveReportState(int localRev, int remoteRev) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'local_revision': localRev,
        'remote_revision': remoteRev,
        'pending_uploads': _pendingUploads,
        'pending_downloads': _pendingDownloads,
        'conflict_state': _conflictState,
        'last_upload': _lastUploadIso,
        'last_download': _lastDownloadIso,
      };
      await prefs.setString(_syncReportKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<SyncReport> getSyncReport(int currentLocalRevision) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_syncReportKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return SyncReport(
          localRevision: currentLocalRevision,
          remoteRevision: map['remote_revision'] as int? ?? _lastRemoteRevision,
          pendingUploads: _pendingUploads || (map['pending_uploads'] as bool? ?? false),
          pendingDownloads: _pendingDownloads || (map['pending_downloads'] as bool? ?? false),
          conflictState: _conflictState.isEmpty ? (map['conflict_state'] as String? ?? 'NONE') : _conflictState,
          lastUpload: _lastUploadIso ?? map['last_upload'] as String?,
          lastDownload: _lastDownloadIso ?? map['last_download'] as String?,
        );
      }
    } catch (_) {}

    return SyncReport(
      localRevision: currentLocalRevision,
      remoteRevision: _lastRemoteRevision,
      pendingUploads: _pendingUploads,
      pendingDownloads: _pendingDownloads,
      conflictState: _conflictState,
      lastUpload: _lastUploadIso,
      lastDownload: _lastDownloadIso,
    );
  }
}
