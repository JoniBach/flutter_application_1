import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Readings',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    TodayReadingsPage(),
    AllReadingsPage(),
    AllInsightsPage(),
    DataPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Readings'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: 'Data',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}

class TodayReadingsPage extends StatelessWidget {
  const TodayReadingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final _future = Supabase.instance.client
        .from('readings')
        .select()
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final readings = snapshot.data!;
          return ListView.builder(
            itemCount: readings.length,
            itemBuilder: ((context, index) {
              final reading = readings[index];
              return ListTile(
                title: Text('Reading ${reading['id']}'),
                subtitle: Text('Temperature: ${reading['temperature']}, '
                    'Humidity: ${reading['humidity']}, '
                    'Pressure: ${reading['pressure']}, '
                    'Gas Resistance: ${reading['gas_resistance']}, '
                    'Altitude: ${reading['altitude']}, '
                    'IIR Filter Coefficient: ${reading['iir_filter_coefficient']}'),
              );
            }),
          );
        },
      ),
    );
  }
}

class AllReadingsPage extends StatelessWidget {
  const AllReadingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _future = Supabase.instance.client.from('readings').select();

    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final readings = snapshot.data!;
          return ListView.builder(
            itemCount: readings.length,
            itemBuilder: ((context, index) {
              final reading = readings[index];
              return ListTile(
                title: Text('Reading ${reading['id']}'),
                subtitle: Text('Temperature: ${reading['temperature']}, '
                    'Humidity: ${reading['humidity']}, '
                    'Pressure: ${reading['pressure']}, '
                    'Gas Resistance: ${reading['gas_resistance']}, '
                    'Altitude: ${reading['altitude']}, '
                    'IIR Filter Coefficient: ${reading['iir_filter_coefficient']}'),
              );
            }),
          );
        },
      ),
    );
  }
}

class AllInsightsPage extends StatelessWidget {
  const AllInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _future =
        Supabase.instance.client.from('daily_insights_raw').select();

    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final insights = snapshot.data!;
          return ListView.builder(
            itemCount: insights.length,
            itemBuilder: ((context, index) {
              final insight = insights[index];
              return ListTile(
                title: Text('Insight ${insight['id']}'),
                subtitle: Text(
                    'Air Quality Index: ${insight['air_quality_index']}, '
                    'Thermal Comfort Index: ${insight['thermal_comfort_index']}, '
                    'Mold Risk Index: ${insight['mold_risk_index']}, '
                    'Building Stress Index: ${insight['building_stress_index']}, '
                    'Pressure Variance: ${insight['pressure_variance']}, '
                    'VOC Exposure Score: ${insight['voc_exposure_score']}, '
                    'Sensor Health Status: ${insight['sensor_health_status']}'),
              );
            }),
          );
        },
      ),
    );
  }
}

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _future = Supabase.instance.client.from('readings').select();

    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final readings = snapshot.data! as List<dynamic>;
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildLineChart('Temperature', readings, 'temperature'),
                _buildLineChart('Humidity', readings, 'humidity'),
                _buildLineChart('Pressure', readings, 'pressure'),
                _buildLineChart('Gas Resistance', readings, 'gas_resistance'),
                _buildLineChart('Altitude', readings, 'altitude'),
                _buildLineChart('IIR Filter Coefficient', readings,
                    'iir_filter_coefficient'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineChart(String title, List readings, String field) {
    List<FlSpot> spots = [];
    List<DateTime> dates = []; // To store the corresponding dates

    for (var i = 0; i < readings.length; i++) {
      var value = readings[i][field];
      var dateStr =
          readings[i]['created_at']; // Assuming 'created_at' has the timestamp

      // Parse the date and convert value to double if necessary
      if (value == null || dateStr == null) continue;
      if (value is int) value = value.toDouble();

      if (value is double) {
        spots.add(FlSpot(i.toDouble(), value));
        dates.add(
            DateTime.parse(dateStr)); // Parse the date string into DateTime
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blue,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Convert index to date for the x-axis
                        int index = value.toInt();
                        if (index < 0 || index >= dates.length)
                          return const SizedBox();

                        DateTime date = dates[index];
                        String formattedDate =
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';

                        return Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
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
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black),
                    bottom: BorderSide(color: Colors.black),
                  ),
                ),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
