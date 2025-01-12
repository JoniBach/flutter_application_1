import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final _future = Supabase.instance.client.from('readings').select();

  @override
  Widget build(BuildContext context) {
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
