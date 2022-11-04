import 'dart:io';
import 'package:collection/collection.dart';
import 'package:native_dio_client/native_dio_client.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache_lts/dio_http_cache_lts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:revanced_manager/models/patch.dart';
import 'package:revanced_manager/utils/check_for_gms.dart';
import 'package:timeago/timeago.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_dio/sentry_dio.dart';

@lazySingleton
class RevancedAPI {
  late Dio _dio = Dio();
  final DioCacheManager _dioCacheManager = DioCacheManager(CacheConfig());
  final Options _cacheOptions = buildCacheOptions(
    const Duration(hours: 6),
    maxStale: const Duration(days: 1),
  );

  Future<void> initialize(String apiUrl) async {
    try {
      bool isGMSInstalled = await checkForGMS();

      if (!isGMSInstalled) {
        _dio = Dio(BaseOptions(
          baseUrl: apiUrl,
        ));
        print('ReVanced API: Using default engine + $isGMSInstalled');
      } else {
        _dio = Dio(BaseOptions(
          baseUrl: apiUrl,
        ))
          ..httpClientAdapter = NativeAdapter();
        print('ReVanced API: Using CronetEngine + $isGMSInstalled');
      }
      _dio.interceptors.add(_dioCacheManager.interceptor);
      _dio.addSentry(
        captureFailedRequests: true,
      );
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }
  }

  Future<void> clearAllCache() async {
    try {
      await _dioCacheManager.clearAll();
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }
  }

  Future<Map<String, List<dynamic>>> getContributors() async {
    Map<String, List<dynamic>> contributors = {};
    try {
      var response = await _dio.get('/contributors', options: _cacheOptions);
      List<dynamic> repositories = response.data['repositories'];
      for (Map<String, dynamic> repo in repositories) {
        String name = repo['name'];
        contributors[name] = repo['contributors'];
      }
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return {};
    }
    return contributors;
  }

  Future<List<Patch>> getPatches() async {
    try {
      var response = await _dio.get('/patches', options: _cacheOptions);
      List<dynamic> patches = response.data;
      return patches.map((patch) => Patch.fromJson(patch)).toList();
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return List.empty();
    }
  }

  Future<Map<String, dynamic>?> _getLatestRelease(
    String extension,
    String repoName,
  ) async {
    try {
      var response = await _dio.get('/tools', options: _cacheOptions);
      List<dynamic> tools = response.data['tools'];
      return tools.firstWhereOrNull(
        (t) =>
            t['repository'] == repoName &&
            (t['name'] as String).endsWith(extension),
      );
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return null;
    }
  }

  Future<String?> getLatestReleaseVersion(
    String extension,
    String repoName,
  ) async {
    try {
      Map<String, dynamic>? release = await _getLatestRelease(
        extension,
        repoName,
      );
      if (release != null) {
        return release['version'];
      }
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return null;
    }
    return null;
  }

  Future<File?> getLatestReleaseFile(String extension, String repoName) async {
    try {
      Map<String, dynamic>? release = await _getLatestRelease(
        extension,
        repoName,
      );
      if (release != null) {
        String url = release['browser_download_url'];
        return await DefaultCacheManager().getSingleFile(url);
      }
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return null;
    }
    return null;
  }

  Future<String?> getLatestReleaseTime(
    String extension,
    String repoName,
  ) async {
    try {
      Map<String, dynamic>? release = await _getLatestRelease(
        extension,
        repoName,
      );
      if (release != null) {
        DateTime timestamp = DateTime.parse(release['timestamp'] as String);
        return format(timestamp, locale: 'en_short');
      }
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return null;
    }
    return null;
  }
}
