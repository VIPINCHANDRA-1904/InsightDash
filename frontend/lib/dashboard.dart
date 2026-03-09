import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api_service.dart';

class DashboardScreen extends StatefulWidget {
  final int fileId;
  final String fileName;

  const DashboardScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadSummary();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _apiService.getAnalyticsSummary(widget.fileId);
      if (mounted) {
        setState(() {
          _summaryData = summary;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // slate-800
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summaryData == null) return const SizedBox.shrink();

    final totalRows = _summaryData!['total_rows'] ?? 0;
    final totalColumns = _summaryData!['total_columns'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildKPICard('Data Rows', '$totalRows', Icons.data_usage, const Color(0xFF3B82F6)),
          _buildKPICard('Features/Cols', '$totalColumns', Icons.view_column_outlined, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    if (_summaryData == null) return const SizedBox.shrink();

    final summaryStats = _summaryData!['summary_stats'] as Map<String, dynamic>?;
    if (summaryStats == null || summaryStats.isEmpty) {
       return const Padding(
         padding: EdgeInsets.all(16.0),
         child: Text('No statistical data available for charts.', style: TextStyle(color: Colors.white54))
       );
    }

    String? plottableColumn;
    Map<String, dynamic>? plotData;

    for (final key in summaryStats.keys) {
      if (summaryStats[key] is Map && summaryStats[key].containsKey('top_values')) {
        plottableColumn = key;
        plotData = summaryStats[key]['top_values'] as Map<String, dynamic>;
        break;
      }
    }

    if (plottableColumn == null || plotData == null) {
      return const Padding(
         padding: EdgeInsets.all(16.0),
         child: Text('Numerical charts not fully supported in current MVP iteration.', style: TextStyle(color: Colors.white54))
      );
    }

    List<BarChartGroupData> barGroups = [];
    int index = 0;
    List<String> labels = [];

    final topValues = plotData;
    topValues.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: (value as num).toDouble(),
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 22,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: topValues.values.reduce((a, b) => (a as num) > (b as num) ? a : b).toDouble() * 1.1,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
      labels.add(key.toString());
      index++;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text(
                  'Top Frequencies: $plottableColumn', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                labels[value.toInt()],
                                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) {
                            return const SizedBox.shrink(); 
                          }
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.fileName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6))))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildCharts(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
