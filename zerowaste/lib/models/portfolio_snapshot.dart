import 'market_activity.dart';

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.balanceEth,
    required this.portfolioValueEth,
    required this.watchlistCount,
    required this.createdCount,
    required this.trendingScores,
    required this.activities,
  });

  final double balanceEth;
  final double portfolioValueEth;
  final int watchlistCount;
  final int createdCount;
  final List<int> trendingScores;
  final List<MarketActivity> activities;

  factory PortfolioSnapshot.fromMap(Map<String, dynamic> map) {
    final scores = map['trending_scores'];
    final activities = map['activities'];

    return PortfolioSnapshot(
      balanceEth: _toDouble(map['balance_eth']),
      portfolioValueEth: _toDouble(map['portfolio_value_eth']),
      watchlistCount: (map['watchlist_count'] as num?)?.round() ?? 0,
      createdCount: (map['created_count'] as num?)?.round() ?? 0,
      trendingScores: scores is List
          ? scores.map((value) => (value as num).round()).toList()
          : const [],
      activities: activities is List
          ? activities
              .map(
                (activity) => MarketActivity.fromMap(
                  Map<String, dynamic>.from(activity as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
