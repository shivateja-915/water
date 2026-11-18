import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeveloperDashboardMetrics {
  final String searchQuery;
  final bool isRefreshing;
  final String environment; // Debug / Release
  final String flutterVersion;
  final String buildNumber;
  final String appVersion;

  const DeveloperDashboardMetrics({
    this.searchQuery = '',
    this.isRefreshing = false,
    this.environment = 'Debug',
    this.flutterVersion = '3.27.0',
    this.buildNumber = '100',
    this.appVersion = 'V1.0.0',
  });

  DeveloperDashboardMetrics copyWith({
    String? searchQuery,
    bool? isRefreshing,
    String? environment,
  }) {
    return DeveloperDashboardMetrics(
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      environment: environment ?? this.environment,
      flutterVersion: flutterVersion,
      buildNumber: buildNumber,
      appVersion: appVersion,
    );
  }
}

class DeveloperDashboardNotifier extends StateNotifier<DeveloperDashboardMetrics> {
  DeveloperDashboardNotifier() : super(const DeveloperDashboardMetrics());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim().toLowerCase());
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isRefreshing: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isRefreshing: false);
  }
}

final developerDashboardProvider =
    StateNotifierProvider<DeveloperDashboardNotifier, DeveloperDashboardMetrics>((ref) {
  return DeveloperDashboardNotifier();
});
