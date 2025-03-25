import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// dynamic patient id -------------------------
enum ChartType { line, bar, dot, wave }

class HealthDashboard extends StatefulWidget {
  final String patientId; // Add this line

  HealthDashboard({required this.patientId}); // Constructor with patientId

  @override
  _HealthDashboardState createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final DatabaseReference _collectingDataRef =
      FirebaseDatabase.instance.ref().child('CollectingData');
  final DatabaseReference _snapshotsRef =
      FirebaseDatabase.instance.ref().child('Snapshots');
  final DatabaseReference _treatmentPlanRef =
      FirebaseDatabase.instance.ref().child('TreatmentPlan');
  final DatabaseReference _patientRef =
      FirebaseDatabase.instance.ref().child('Patient');
  final DatabaseReference _sleepResultRef =
      FirebaseDatabase.instance.ref().child('Sleep_result');

  DateTime _now = DateTime.now(); // Add this in _HealthDashboardState
  String? collectingDataKey;
  String? treatmentPlanId;
  String selectedMonth = 'This Month';

  int? actScore;
  IconData actIcon = Icons.sentiment_neutral;
  Color actIconColor = Colors.grey;

  int takenCount = 0;
  int missedCount = 0;
  int totalWakeCount = 0;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now(); // Cache current time
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchPatient1Info();
    if (treatmentPlanId != null) {
      await _fetchACTScore(treatmentPlanId!);
    }
    await _fetchMedicalHistoryFromPatient();
    setState(() {});
  }

  Future<void> _fetchPatient1Info() async {
    final snapshot = await _collectingDataRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in data.entries) {
        final entryData = Map<String, dynamic>.from(entry.value);
        if (entryData['patient_ID']?.toString() == widget.patientId) {
          // dynamic patient id ---------------------
          collectingDataKey = entry.key;
          treatmentPlanId = entryData['treatmentPlan_ID']?.toString();
          break;
        }
      }
    }
  }

  Future<void> _fetchACTScore(String treatmentPlanId) async {
    final treatmentSnapshot =
        await _treatmentPlanRef.child(treatmentPlanId).get();
    if (treatmentSnapshot.exists) {
      final treatmentData =
          Map<String, dynamic>.from(treatmentSnapshot.value as Map);

      String lastUpdatedStr = treatmentData['lastUpdated']?.toString() ?? '';
      if (shouldIncludeTime(lastUpdatedStr)) {
        double act = double.tryParse(treatmentData['ACT'].toString()) ?? 0;
        int roundedAct = act.round();
        setState(() {
          actScore = roundedAct;
          actIcon = roundedAct >= 20
              ? Icons.emoji_emotions
              : Icons.sentiment_dissatisfied;
          actIconColor = roundedAct >= 20
              ? const Color.fromARGB(255, 252, 252, 252)
              : const Color.fromARGB(255, 253, 253, 253);
        });
      } else {
        setState(() {
          actScore = null; // Hide or show 'No ACT data for this month'
        });
      }
    }
  }

  Future<void> _fetchMedicalHistoryFromPatient() async {
    final historySnapshot = await _patientRef
        .child(widget.patientId)
        .child('MedicationHistory')
        .get(); // dynamic patient id -----------

    int taken = 0, missed = 0;

    if (historySnapshot.exists) {
      final data = Map<String, dynamic>.from(historySnapshot.value as Map);
      data.forEach((key, value) {
        final entry = Map<String, dynamic>.from(value);
        String status = entry['status']?.toString().toLowerCase() ?? '';
        String dateStr = entry['date']?.toString() ?? '';
        if (shouldIncludeTime(dateStr)) {
          if (status == 'taken') taken++;
          if (status == 'missed') missed++;
        }
      });
    }

    setState(() {
      takenCount = taken;
      missedCount = missed;
    });
  }

  bool shouldIncludeTime(String timeStr) {
    DateTime dataDate = DateTime.tryParse(timeStr) ?? DateTime.now();
    int monthDiff =
        _now.month - dataDate.month + (12 * (_now.year - dataDate.year));

    switch (selectedMonth) {
      case 'This Month':
        return _now.year == dataDate.year && _now.month == dataDate.month;
      case '1 Month Ago':
        return monthDiff == 1;
      case '2 Months Ago':
        return monthDiff == 2;
      case '3 Months Ago':
        return monthDiff == 3;
      default:
        return false;
    }
  }

  Future<Map<String, double>> _fetchMetricData(String metric) async {
    Map<String, double> dataMap = {};
    if (collectingDataKey == null) return dataMap;

    int offset = 0;
    switch (selectedMonth) {
      case 'This Month':
        offset = 0;
        break;
      case '1 Month Ago':
        offset = 1;
        break;
      case '2 Months Ago':
        offset = 2;
        break;
      case '3 Months Ago':
        offset = 3;
        break;
    }

    DateTime targetDate = DateTime(_now.year, _now.month - offset, 1);
    int daysInMonth = DateTime(targetDate.year, targetDate.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(targetDate.year, targetDate.month, day);
      String label = DateFormat('dd/MM').format(date);
      dataMap[label] = 0;
    }

    final snapshot =
        await _snapshotsRef.child(collectingDataKey!).child(metric).get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      Map<String, List<double>> tempData = {};

      data.forEach((timeKey, value) {
        DateTime dateTime = DateTime.tryParse(timeKey) ?? DateTime.now();
        if (dateTime.year == targetDate.year &&
            dateTime.month == targetDate.month) {
          String dateLabel = DateFormat('dd/MM').format(dateTime);
          double parsedValue = double.tryParse(value.toString()) ?? 0;

          if (!tempData.containsKey(dateLabel)) {
            tempData[dateLabel] = [];
          }
          tempData[dateLabel]!.add(parsedValue);
        }
      });

      tempData.forEach((dateLabel, values) {
        double avg = values.reduce((a, b) => a + b) / values.length;
        dataMap[dateLabel] = avg;
      });
    }

    return dataMap;
  }

  ///---------------------SleepPattern---------------------
  Future<Map<String, double>> _fetchSleepTransitionData() async {
    Map<String, double> dataMap = {};

    final resultSnapshot = await _sleepResultRef
        .child(widget.patientId)
        .get(); // dynamic patient id =========

    if (!resultSnapshot.exists) return dataMap;

    int offset = 0;
    switch (selectedMonth) {
      case 'This Month':
        offset = 0;
        break;
      case '1 Month Ago':
        offset = 1;
        break;
      case '2 Months Ago':
        offset = 2;
        break;
      case '3 Months Ago':
        offset = 3;
        break;
    }

    DateTime targetDate = DateTime(_now.year, _now.month - offset, 1);
    int daysInMonth = DateTime(targetDate.year, targetDate.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(targetDate.year, targetDate.month, day);
      String label = DateFormat('dd/MM').format(date);
      dataMap[label] = 0;
    }

    final resultData = resultSnapshot.value as Map;
    final List<dynamic>? timestamps = resultData['timestamp'] as List<dynamic>?;
    final List<dynamic>? transitions =
        resultData['transitions'] as List<dynamic>?;

    if (timestamps != null && transitions != null) {
      for (int i = 0; i < timestamps.length; i++) {
        String timestampStr = timestamps[i].toString();
        DateTime? dateTime = DateTime.tryParse(timestampStr);

        if (dateTime != null &&
            dateTime.year == targetDate.year &&
            dateTime.month == targetDate.month) {
          String dateLabel = DateFormat('dd/MM').format(dateTime);
          double transitionValue = 0;

          if (i < transitions.length) {
            transitionValue = double.tryParse(transitions[i].toString()) ?? 0;
          }

          dataMap[dateLabel] = transitionValue;
        }
      }
    }

    return dataMap;
  }

  Future<int> _fetchTotalWakeupsByPatientID() async {
    int totalWakeups = 0;
    final snapshot = await _collectingDataRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in data.entries) {
        final entryData = Map<String, dynamic>.from(entry.value);
        if (entryData['patient_ID']?.toString() == widget.patientId) {
          String? timeStr = entryData['timestamp']?.toString();
          if (timeStr != null && shouldIncludeTime(timeStr)) {
            int wake =
                int.tryParse(entryData['sleepPattern']?.toString() ?? '0') ?? 0;
            totalWakeups += wake;
          }
        }
      }
    }
    return totalWakeups;
  }

  ///-----------------------------------------------------
  ///----------------Cough totla ----------------------------
  Future<int> _fetchTotalCoughsByPatientID() async {
    int totalCoughs = 0;
    final snapshot = await _collectingDataRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in data.entries) {
        final entryData = Map<String, dynamic>.from(entry.value);
        if (entryData['patient_ID']?.toString() == widget.patientId) {
          String? timeStr = entryData['timestamp']?.toString();
          if (timeStr != null && shouldIncludeTime(timeStr)) {
            int cough =
                int.tryParse(entryData['totalcough']?.toString() ?? '0') ?? 0;
            totalCoughs += cough;
          }
        }
      }
    }
    return totalCoughs;
  }

//--------------------------------------------------------

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      drawHorizontalLine: true,
      getDrawingHorizontalLine: (value) =>
          FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
      getDrawingVerticalLine: (value) =>
          FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
    );
  }

  FlTitlesData _buildTitlesData(List<String> sortedLabels, double yInterval) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: yInterval,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < sortedLabels.length && index % 5 == 0) {
              return Transform.rotate(
                angle: -0.5, // Rotate ~28 degrees
                child: Text(
                  sortedLabels[index],
                  style: TextStyle(fontSize: 10),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Colors.grey, width: 1),
        left: BorderSide(color: Colors.grey, width: 1),
        right: BorderSide.none,
        top: BorderSide.none,
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    List<FlSpot> spots,
    Color color,
    List<String> sortedLabels,
    ChartType chartType,
  ) {
    double maxYValue = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 0.0;
    double yInterval = (maxYValue / 5).ceilToDouble().clamp(1.0, 20.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: chartType == ChartType.bar
                  ? BarChart(
                      BarChartData(
                        backgroundColor: Colors.white, // Chart background
                        maxY: maxYValue + yInterval,
                        barGroups: spots.map((spot) {
                          return BarChartGroupData(x: spot.x.toInt(), barRods: [
                            BarChartRodData(
                              toY: spot.y,
                              width: 8,
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.8), // Top solid color
                                  Colors.transparent, // Bottom transparent
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ]);
                        }).toList(),
                        titlesData: _buildTitlesData(sortedLabels, yInterval),
                        gridData: _buildGridData(),
                        borderData: _buildBorderData(),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        backgroundColor: Colors.white,
                        minY: 0,
                        maxY: maxYValue + yInterval,
                        gridData: _buildGridData(),
                        titlesData: _buildTitlesData(sortedLabels, yInterval),
                        borderData: _buildBorderData(),
                        minX: 0,
                        maxX: sortedLabels.length.toDouble() - 1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: chartType == ChartType.wave,
                            color: color,
                            barWidth: 2,
                            dotData:
                                FlDotData(show: chartType == ChartType.dot),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (spot) => Colors.blueGrey,
                          ),
                        ),
                        clipData: FlClipData.all(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white, // Dropdown background color
      ),
      child: DropdownButton<String>(
        value: selectedMonth,
        dropdownColor:
            Colors.white, // Menu background color (for newer Flutter versions)
        style: TextStyle(color: Colors.black), // Text color inside dropdown
        iconEnabledColor: Colors.black, // Dropdown icon color
        items: ['This Month', '1 Month Ago', '2 Months Ago', '3 Months Ago']
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ))
            .toList(),
        onChanged: (newValue) {
          setState(() {
            selectedMonth = newValue!;
            _initializeData(); // Refresh data on change
          });
        },
      ),
    );
  }

  Future<Map<String, Map<String, double>>> _fetchAllMetrics() async {
    final heartRateData = await _fetchMetricData('heartRate');
    final respiratoryData = await _fetchMetricData('respiratoryRate');
    final tempData = await _fetchMetricData('temperature');
    return {
      'Heart Rate': heartRateData,
      'Respiratory Rate': respiratoryData,
      'Temperature': tempData,
    };
  }

  Widget _buildMedicalHistoryCard() {
    int total = takenCount + missedCount;
    double takenPercent = total > 0 ? takenCount / total : 0;
    double missedPercent = total > 0 ? missedCount / total : 0;

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medication History',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: takenPercent,
                center: Text(
                  '${(takenPercent * 100).toStringAsFixed(1)}%\nTaken',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                progressColor: Colors.greenAccent,
                backgroundColor: Colors.black12,
              ),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: missedPercent,
                center: Text(
                  '${(missedPercent * 100).toStringAsFixed(1)}%\nMissed',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                progressColor: Colors.redAccent,
                backgroundColor: Colors.black12,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildACTCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = (screenWidth * 0.12).clamp(40.0, 60.0);
    double fontSize = (screenWidth * 0.04).clamp(14.0, 20.0);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A678B), Color(0xFF5AA9C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(actIcon, color: Colors.white, size: iconSize),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'ACT Score: ${actScore != null ? actScore : 'No data this month'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth * 0.12;
    double fontSize = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DASHBOARD',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        actions: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.black, size: 20),
              SizedBox(width: 4),
              _buildDropdown(),
              SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildACTCard(context),
              SizedBox(height: 8),
              _buildMedicalHistoryCard(),
              SizedBox(height: 8),
              FutureBuilder<Map<String, double>>(
                future: _fetchSleepTransitionData(),
                builder: (context, sleepSnapshot) {
                  if (sleepSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (sleepSnapshot.hasError) {
                    return Center(child: Text('Error loading sleep data'));
                  } else if (!sleepSnapshot.hasData ||
                      sleepSnapshot.data!.isEmpty) {
                    return Center(child: Text('No sleep data available'));
                  }

                  List<String> sortedLabels = sleepSnapshot.data!.keys.toList()
                    ..sort();
                  List<FlSpot> sleepSpots = [];
                  for (int i = 0; i < sortedLabels.length; i++) {
                    sleepSpots.add(FlSpot(
                        i.toDouble(), sleepSnapshot.data![sortedLabels[i]]!));
                  }

                  return FutureBuilder<int>(
                    future: _fetchTotalWakeupsByPatientID(),
                    builder: (context, wakeSnapshot) {
                      int wakeups = wakeSnapshot.data ?? 0;

                      return FutureBuilder<int>(
                        future: _fetchTotalCoughsByPatientID(),
                        builder: (context, coughSnapshot) {
                          int coughs = coughSnapshot.data ?? 0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      margin: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 3),
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.deepPurpleAccent,
                                              Colors.purple
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.nightlight_round,
                                                size: 36, color: Colors.white),
                                            SizedBox(height: 8),
                                            Text("Total Wakeups",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white70)),
                                            SizedBox(height: 4),
                                            Text("$wakeups",
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Card(
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      margin: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 3),
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orangeAccent,
                                              Colors.deepOrange
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.sick,
                                                size: 36, color: Colors.white),
                                            SizedBox(height: 8),
                                            Text("Total Coughs",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white70)),
                                            SizedBox(height: 4),
                                            Text("$coughs",
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              _buildChartCard(
                                'Monthly Wake-Up Frequency',
                                sleepSpots,
                                Colors.purple,
                                sortedLabels,
                                ChartType.wave,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 8),
              FutureBuilder<Map<String, Map<String, double>>>(
                future: _fetchAllMetrics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading data'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No data available'));
                  }

                  List<Widget> chartCards = [];
                  final colors = {
                    'Heart Rate': Colors.red,
                    'Respiratory Rate': Colors.green,
                    'Temperature': Colors.blue,
                  };

                  snapshot.data!.forEach((metric, dataMap) {
                    List<String> sortedLabels = dataMap.keys.toList()..sort();
                    List<FlSpot> spots = [];
                    for (int i = 0; i < sortedLabels.length; i++) {
                      spots
                          .add(FlSpot(i.toDouble(), dataMap[sortedLabels[i]]!));
                    }

                    ChartType chartType;
                    if (metric == 'Heart Rate') {
                      chartType = ChartType.dot;
                    } else if (metric == 'Respiratory Rate') {
                      chartType = ChartType.bar;
                    } else {
                      chartType = ChartType.line;
                    }

                    chartCards.add(_buildChartCard(
                      metric,
                      spots,
                      colors[metric]!,
                      sortedLabels,
                      chartType,
                    ));
                  });

                  return Column(children: chartCards);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
