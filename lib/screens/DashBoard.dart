import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HealthDashboard extends StatefulWidget {
  @override
  _HealthDashboardState createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final DatabaseReference _collectingDataRef =
      FirebaseDatabase.instance.ref().child('CollectingData');
  final DatabaseReference _treatmentPlanRef =
      FirebaseDatabase.instance.ref().child('TreatmentPlan');

  String selectedMonth = 'This Month';
  int? actScore;
  IconData actIcon = Icons.sentiment_neutral;
  Color actIconColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchACTScore();
  }

  void _fetchACTScore() {
    _collectingDataRef.once().then((snapshot) {
      if (snapshot.snapshot.value != null) {
        Map<String, dynamic> data =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        data.forEach((key, value) {
          String treatmentPlanID = value['treatmentPlan_ID'];
          _treatmentPlanRef
              .child(treatmentPlanID)
              .once()
              .then((treatmentSnapshot) {
            if (treatmentSnapshot.snapshot.value != null) {
              Map<String, dynamic> treatmentData = Map<String, dynamic>.from(
                  treatmentSnapshot.snapshot.value as Map);

              int act = treatmentData['ACT'];
              setState(() {
                actScore = act;
                if (act >= 20) {
                  actIcon = Icons.emoji_emotions; // Happy face
                  actIconColor = Colors.yellow;
                } else {
                  actIcon = Icons.sentiment_dissatisfied; // Sad face
                  actIconColor = Colors.yellow;
                }
              });
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors
                    .white, // Set the background color of the dropdown list
              ),
              child: DropdownButton<String>(
                value: selectedMonth,
                items: <String>[
                  'This Month',
                  '1 Month Ago',
                  '2 Months Ago',
                  '3 Months Ago'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedMonth = newValue!;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF4A678B),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            right:
                                20.0), // Add right padding to the first Text widget
                        child: Text('ACT SCORE',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right:
                                20.0), // Add right padding to the second Text widget
                        child: Text(
                          actScore != null ? actScore.toString() : 'Loading...',
                          style: TextStyle(
                              color: Color(0xFFB4E1F2),
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right:
                                20.0), // Add right padding to the third Text widget
                        child: Text(
                          actScore != null && actScore! >= 20
                              ? 'Well Controlled'
                              : 'Not Well Controlled',
                          style:
                              TextStyle(color: Color(0xFFB4E1F2), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    actIcon,
                    color: actIconColor,
                    size: 60,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _collectingDataRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return Center(child: Text('No data available'));
                }

                Map<String, dynamic> data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                List<FlSpot> temperatureSpots = [];
                List<FlSpot> heartRateSpots = [];
                List<FlSpot> oxygenSpots = [];
                List<FlSpot> coughNightSpots = [];
                List<FlSpot> coughDaySpots = [];
                List<FlSpot> sleepPatternSpots = [];
                List<FlSpot> respiratoryRateSpots = [];

                List<String> xLabels = [];
                DateTime now = DateTime.now();
                int index = 0;

                data.forEach((key, value) {
                  DateTime date =
                      DateTime.fromMillisecondsSinceEpoch(int.parse(key));
                  String formattedDate =
                      DateFormat('MM/dd\nHH:mm').format(date);
                  xLabels.add(formattedDate);

                  // Filter data based on the selected month
                  if (shouldIncludeData(date)) {
                    temperatureSpots.add(FlSpot(
                        index.toDouble(), value['temperature'].toDouble()));
                    heartRateSpots.add(FlSpot(
                        index.toDouble(), value['heartRate'].toDouble()));
                    oxygenSpots.add(FlSpot(index.toDouble(),
                        value['oxygenSaturation'].toDouble()));
                    coughNightSpots.add(FlSpot(
                        index.toDouble(), value['coughInNight'].toDouble()));
                    coughDaySpots.add(FlSpot(
                        index.toDouble(), value['coughInDay'].toDouble()));
                    sleepPatternSpots.add(FlSpot(
                        index.toDouble(), value['sleepPattern'].toDouble()));
                    respiratoryRateSpots.add(FlSpot(
                        index.toDouble(), value['respiratoryRate'].toDouble()));
                    index++;
                  }
                });

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildChartCard('Temperature', temperatureSpots,
                          Colors.red, false, xLabels),
                      _buildChartCard('Heart Rate', heartRateSpots, Colors.blue,
                          true, xLabels),
                      _buildChartCard('Oxygen Saturation', oxygenSpots,
                          Colors.green, false, xLabels),
                      _buildChartCard('Cough Night', coughNightSpots,
                          Colors.orange, true, xLabels),
                      _buildChartCard('Cough Day', coughDaySpots, Colors.purple,
                          false, xLabels),
                      _buildChartCard('Sleep Pattern', sleepPatternSpots,
                          Colors.brown, true, xLabels),
                      _buildChartCard('Respiratory Rate', respiratoryRateSpots,
                          Colors.teal, false, xLabels),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filter data based on the selected month
  bool shouldIncludeData(DateTime date) {
    DateTime now = DateTime.now();
    switch (selectedMonth) {
      case 'This Month':
        return date.month == now.month && date.year == now.year;
      case '1 Month Ago':
        return date.month == now.subtract(Duration(days: 30)).month &&
            date.year == now.subtract(Duration(days: 30)).year;
      case '2 Months Ago':
        return date.month == now.subtract(Duration(days: 60)).month &&
            date.year == now.subtract(Duration(days: 60)).year;
      case '3 Months Ago':
        return date.month == now.subtract(Duration(days: 90)).month &&
            date.year == now.subtract(Duration(days: 90)).year;
      default:
        return true;
    }
  }

  Widget _buildChartCard(String title, List<FlSpot> spots, Color color,
      bool isCurved, List<String> xLabels) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            (value + 1).toInt().toString(),
                            style: TextStyle(fontSize: 10),
                          );
                        }),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          meta: meta, // ✅ Required
                          fitInside: SideTitleFitInsideData(
                            enabled:
                                false, // Set to true if you want the text inside the chart
                            axisPosition: 0, // Position of the title
                            parentAxisSize: 30, // Adjust based on the axis size
                            distanceFromEdge:
                                0, // Adjust spacing from edge if needed
                          ),

                          child: Transform.rotate(
                            angle: -1.5708, // Rotate text vertically
                            child: Text(
                              xLabels[value.toInt()],
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: isCurved,
                    color: color,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData:
                        BarAreaData(show: true, color: color.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
