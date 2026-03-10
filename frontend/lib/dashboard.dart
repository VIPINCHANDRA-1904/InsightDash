import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isOfflineMode = false;
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
        _checkAndTriggerAlerts(summary);
      }
    } catch (e) {
      // Fallback: try to load offline data
      final prefs = await SharedPreferences.getInstance();
      final offlineData = prefs.getString('offline_dash_${widget.fileId}');
      if (offlineData != null) {
        if (mounted) {
          setState(() {
            _summaryData = jsonDecode(offlineData);
            _isLoading = false;
            _isOfflineMode = true;
          });
          _animController.forward();
          _checkAndTriggerAlerts(_summaryData!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viewing saved offline dashboard'), backgroundColor: Colors.orange),
          );
        }
      } else {
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
  }

  Future<void> _saveOffline() async {
    if (_summaryData != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('offline_dash_${widget.fileId}', jsonEncode(_summaryData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.download_done, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Dashboard saved for offline viewing!'),
                ],
              ), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save offline.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _checkAndTriggerAlerts(Map<String, dynamic> data) {
    // Basic Real-time Alert system based on missing values or outliers.
    final columnsInfo = data['columns_info'] as Map<String, dynamic>? ?? {};
    int missingColsCount = 0;
    
    columnsInfo.forEach((key, info) {
      if (info is Map && info['missing'] != null && (info['missing'] as num) > 0) {
        missingColsCount++;
      }
    });

    if (missingColsCount > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Real-Time Alert: Found $missingColsCount columns with missing data! Please check quality.')),
                ],
              ),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Real-Time Status: Data quality looks great. No missing values!'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildKPICard('Data Rows', '$totalRows', Icons.data_usage, const Color(0xFF3B82F6)),
          _buildKPICard('Features/Cols', '$totalColumns', Icons.view_column_outlined, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (_summaryData == null) return const SizedBox.shrink();

    final totalRows = _summaryData!['total_rows'] ?? 0;
    final totalColumns = _summaryData!['total_columns'] ?? 0;
    
    final columnsInfo = _summaryData!['columns_info'] as Map<String, dynamic>? ?? {};
    int missingColsCount = 0;
    columnsInfo.forEach((key, info) {
      if (info is Map && info['missing'] != null && (info['missing'] as num) > 0) {
        missingColsCount++;
      }
    });

    String description = "This comprehensive dataset analysis reveals a total of $totalRows records distributed across $totalColumns distinct features. ";
    
    if (missingColsCount > 0) {
      description += "Our data quality assessment identified $missingColsCount column(s) containing missing values that may require imputation or cleaning. ";
    } else {
      description += "The data quality appears robust with no missing values detected across any columns. ";
    }
    
    description += "You can swipe through the interactive charts below to visually explore key distributions and frequencies within the dataset.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 22),
                const SizedBox(width: 8),
                Text('Analysis Overview', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.6),
            ),
          ],
        ),
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

    List<Widget> chartSlides = [];

    summaryStats.forEach((colName, colStats) {
      if (colStats is Map && colStats.containsKey('top_values')) {
        final plotData = colStats['top_values'] as Map<String, dynamic>;
        
        List<BarChartGroupData> barGroups = [];
        int index = 0;
        List<String> labels = [];

        double maxY = 0;
        plotData.forEach((k, v) {
            if ((v as num).toDouble() > maxY) maxY = v.toDouble();
        });

        plotData.forEach((key, value) {
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
                    toY: maxY * 1.1 == 0 ? 1 : maxY * 1.1,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          );
          labels.add(key.toString());
          index++;
        });

        chartSlides.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Frequencies: $colName', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
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
          )
        );
      }
    });

    if (chartSlides.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Numerical charts not fully supported in current MVP iteration.', style: TextStyle(color: Colors.white54))
       );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 350, // Fixed height for PageView
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
          children: [
            Expanded(
              child: PageView(
                physics: const BouncingScrollPhysics(),
                children: chartSlides,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swipe, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text('Swipe for more visualizations', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            )
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
        actions: [
          IconButton(
            icon: Icon(
              _isOfflineMode ? Icons.cloud_off : Icons.save_alt, 
              color: _isOfflineMode ? Colors.orange : Colors.white,
            ),
            tooltip: _isOfflineMode ? 'Offline Mode' : 'Save for Offline',
            onPressed: () {
              if (!_isOfflineMode) {
                _saveOffline();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Currently viewing offline data.'), backgroundColor: Colors.orange),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
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
                    const SizedBox(height: 8),
                    _buildDescription(),
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
