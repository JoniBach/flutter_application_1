import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

// Create a global key for the ScaffoldMessenger.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
    return MaterialApp(
      title: 'Readings',
      scaffoldMessengerKey: scaffoldMessengerKey, // Use the global key here.
      home: const HomePage(),
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

  // Updated pages list including the DevicesPage.
  static const List<Widget> _pages = <Widget>[
    TodayReadingsPage(),
    AllReadingsPage(),
    AllInsightsPage(),
    DataPage(),
    DevicesPage(),
    AuthPage(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Auth',
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

/// Displays authentication UI and user details.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Info')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('User ID: ${user.id}'),
              Text('Email: ${user.email}'),
              if (user.userMetadata != null)
                ...user.userMetadata!.entries
                    .map((entry) => Text('${entry.key}: ${entry.value}')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: Center(
        child: FocusScope(
          child: SupaEmailAuth(
            redirectTo: kIsWeb ? null : 'myapp://home',
            onSignInComplete: (response) {
              // Optionally trigger a UI refresh.
            },
            onSignUpComplete: (response) {
              // Optionally trigger a UI refresh.
            },
            metadataFields: [
              MetaDataField(
                prefixIcon: const Icon(Icons.person),
                label: 'Username',
                key: 'username',
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter something';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays readings for today.
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
            itemBuilder: (context, index) {
              final reading = readings[index];
              final createdAt = DateTime.parse(reading['created_at']);
              final formattedDate =
                  '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
              return ListTile(
                title: Text(formattedDate),
                subtitle: Text(
                  'Temperature: ${reading['temperature']}, '
                  'Humidity: ${reading['humidity']}, '
                  'Pressure: ${reading['pressure']}, '
                  'Gas Resistance: ${reading['gas_resistance']}, '
                  'Altitude: ${reading['altitude']}, '
                  'IIR Filter Coefficient: ${reading['iir_filter_coefficient']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Displays all readings.
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
            itemBuilder: (context, index) {
              final reading = readings[index];
              final createdAt = DateTime.parse(reading['created_at']);
              final formattedDate =
                  '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
              return ListTile(
                title: Text(formattedDate),
                subtitle: Text(
                  'Temperature: ${reading['temperature']}, '
                  'Humidity: ${reading['humidity']}, '
                  'Pressure: ${reading['pressure']}, '
                  'Gas Resistance: ${reading['gas_resistance']}, '
                  'Altitude: ${reading['altitude']}, '
                  'IIR Filter Coefficient: ${reading['iir_filter_coefficient']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Displays insights.
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
            itemBuilder: (context, index) {
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
                  'Sensor Health Status: ${insight['sensor_health_status']}',
                ),
              );
            },
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
    Map<String, List<FlSpot>> macAddressSpots = {};
    Map<String, List<DateTime>> macAddressDates = {};
    Map<String, Color> macAddressColors = {};

    List<Color> availableColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
    ];

    int colorIndex = 0;

    for (var reading in readings) {
      var value = reading[field];
      var dateStr = reading['created_at'];
      var macAddress = reading['mac_address'];

      if (value == null || dateStr == null || macAddress == null) continue;
      if (value is int) value = value.toDouble();

      if (value is double) {
        macAddressSpots.putIfAbsent(macAddress, () => []);
        macAddressDates.putIfAbsent(macAddress, () => []);
        DateTime date = DateTime.parse(dateStr);
        macAddressSpots[macAddress]!
            .add(FlSpot(date.millisecondsSinceEpoch.toDouble(), value));
        macAddressDates[macAddress]!.add(date);

        if (!macAddressColors.containsKey(macAddress)) {
          macAddressColors[macAddress] =
              availableColors[colorIndex % availableColors.length];
          colorIndex++;
        }
      }
    }

    List<LineChartBarData> lineBarsData = macAddressSpots.entries.map((entry) {
      return LineChartBarData(
        spots: entry.value,
        isCurved: true,
        barWidth: 3,
        color: macAddressColors[entry.key],
        belowBarData: BarAreaData(show: false),
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) => true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 2.0,
              color: macAddressColors[entry.key]!,
              strokeWidth: 0,
            );
          },
        ),
      );
    }).toList();

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
                lineBarsData: lineBarsData,
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
                        DateTime date =
                            DateTime.fromMillisecondsSinceEpoch(value.toInt());
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: macAddressColors.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: entry.value,
                  ),
                  const SizedBox(width: 4),
                  Text(entry.key),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// DevicesPage lists all devices from the "devices" table and includes an Add Device button.
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Devices')),
        body: const Center(
          child: Text('You need to be logged in to view devices.'),
        ),
      );
    }

    final future = Supabase.instance.client.from('devices').select();

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No devices found."));
          }

          final devices = snapshot.data as List<dynamic>;
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: const Icon(Icons.devices),
                title: Text(device['location']),
                subtitle: Text('ID: ${device['id']}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the AddDevicePage.
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddDevicePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// AddDevicePage provides a form to add a new device to the "devices" table.
class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _macAddressController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _addDevice() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSubmitting = true;
    });

    // Create a device map with the location and MAC address.
    final deviceData = {
      'location': _locationController.text,
      'mac_address': _macAddressController.text,
    };

    // Insert the device data.
    final response =
        await Supabase.instance.client.from('devices').insert(deviceData);

    setState(() {
      _isSubmitting = false;
    });

    if (response.error != null) {
      debugPrint("Insert error: ${response.error!.message}");
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${response.error!.message}')),
      );
    } else {
      debugPrint("Insert successful. Response: $response");
      // Show success message.
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Device added successfully.')),
      );
      // Wait for one second so the user can see the snack bar.
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _macAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Field for entering the device location.
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Field for entering the MAC address.
                    TextFormField(
                      controller: _macAddressController,
                      decoration: const InputDecoration(
                        labelText: 'MAC Address',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a MAC address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addDevice,
                      child: const Text('Add Device'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
