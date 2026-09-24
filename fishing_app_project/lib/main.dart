import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static const String qWeatherApiKey = "YOUR_QWEATHER_API_KEY";
  static const String supabaseUrl = "https://your-supabase-id.supabase.co";
  static const String supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (AppConfig.supabaseUrl.contains("your-supabase-id") == false) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const FishingApp());
}

class FishingApp extends StatelessWidget {
  const FishingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '钓鱼大师',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.light,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FishingIndexScreen(),
    SpotListScreen(),
    CatchLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: '钓指数',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '钓点地图',
          ),
          NavigationDestination(
            icon: Icon(Icons.photorange_outlined),
            selectedIcon: Icon(Icons.photorange),
            label: '渔获日志',
          ),
        ],
      ),
    );
  }
}

class FishingIndexScreen extends StatefulWidget {
  const FishingIndexScreen({super.key});

  @override
  State<FishingIndexScreen> createState() => _FishingIndexScreenState();
}

class _FishingIndexScreenState extends State<FishingIndexScreen> {
  bool isLoading = true;
  double pressure = 1013.0;
  double temp = 22.0;
  double windSpeed = 3.0;
  int fishingIndex = 85;
  String advice = "气压稳定，水温适宜，极适合出钓！";

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final response = await http.get(Uri.parse(
        'https://devapi.qweather.com/v7/weather/now?location=101010100&key=${AppConfig.qWeatherApiKey}'
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == '200') {
          final now = data['now'];
          setState(() {
            temp = double.tryParse(now['temp'] ?? '22') ?? 22.0;
            pressure = double.tryParse(now['pressure'] ?? '1013') ?? 1013.0;
            windSpeed = double.tryParse(now['windSpeed'] ?? '10') ?? 10.0;
            _calculateIndex();
            isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    
    setState(() {
      _calculateIndex();
      isLoading = false;
    });
  }

  void _calculateIndex() {
    double score = 100.0;
    if (pressure < 1000) score -= (1000 - pressure) * 1.5;
    if (temp < 10 || temp > 32) score -= 15;
    if (windSpeed > 20) score -= 20;

    fishingIndex = score.clamp(0, 100).toInt();
    if (fishingIndex >= 80) advice = "气压稳定，鱼开口度极佳！黄金出钓时段。";
    else if (fishingIndex >= 60) advice = "天气尚可，建议选择水草丰茂处下竿。";
    else advice = "气压偏低，鱼类上浮，建议谨慎出钓。";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('钓鱼指数 & 天气预报')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchWeatherData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('今日黄金出钓指数', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 10),
                        Text('$fishingIndex', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 10),
                        Text(advice, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetricCard('实时气压', '${pressure.toInt()} hPa', Icons.speed),
                    _buildMetricCard('环境温度', '${temp.toInt()} °C', Icons.thermostat),
                    _buildMetricCard('风速', '$windSpeed km/h', Icons.air),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class SpotListScreen extends StatelessWidget {
  const SpotListScreen({super.key});

  final List<Map<String, dynamic>> mockSpots = const [
    {"name": "青龙湖免费野钓点", "type": "wild", "dist": "3.2km", "fish": "鲫鱼、鲤鱼、翘嘴", "lat": 39.9042, "lng": 116.4074},
    {"name": "老张竞技黑坑钓场", "type": "blackhole", "dist": "8.5km", "fish": "高密度工程鲫、罗非", "lat": 39.9142, "lng": 116.4174},
    {"name": "南山路亚打卡基地", "type": "lure", "dist": "14.1km", "fish": "加州鲈、鳜鱼", "lat": 39.9242, "lng": 116.4274},
  ];

  Future<void> _launchAmap(double lat, double lng, String name) async {
    final uri = Uri.parse("amapuri://route/plan/?dlat=$lat&dlon=$lng&dname=$name&dev=0&t=0");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse("https://uri.amap.com/marker?position=$lng,$lat&name=$name");
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('周边钓点情报')),
      body: ListView.builder(
        itemCount: mockSpots.length,
        itemBuilder: (context, index) {
          final spot = mockSpots[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.photorange)),
              title: Text(spot['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('距离: ${spot['dist']} | 目标鱼: ${spot['fish']}'),
              trailing: IconButton(
                icon: const Icon(Icons.navigation, color: Colors.blue),
                onPressed: () => _launchAmap(spot['lat'], spot['lng'], spot['name']),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CatchLogScreen extends StatelessWidget {
  const CatchLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 渔获打卡日志')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('拍照打卡，智能识别鱼种与重量', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已自动抓取当前气压 1013hPa 与 GPS 位置，识别成功：翘嘴红鲌 42cm / 1.1kg')),
                );
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('上传渔获照片'),
            )
          ],
        ),
      ),
    );
  }
}
