import 'dart:async';
import 'dart:io';
import 'dart:convert'; // Untuk baca JSON
import 'package:http/http.dart' as http; // Untuk request ke server
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMKS Airlangga CBT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const KioskGuardian(),
    );
  }
}

class KioskGuardian extends StatefulWidget {
  const KioskGuardian({super.key});

  @override
  State<KioskGuardian> createState() => _KioskGuardianState();
}

class _KioskGuardianState extends State<KioskGuardian> {
  bool _isBypass = false;

  void _activateBypass() {
    setState(() {
      _isBypass = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBypass) {
      return const ExamPage(isBypassMode: true);
    }

    return StreamBuilder<KioskMode>(
      stream: watchKioskMode(),
      builder: (context, snapshot) {
        final mode = snapshot.data;

        if (mode == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (mode == KioskMode.enabled) {
          return const ExamPage(isBypassMode: false);
        }

        return WarningPage(onBypass: _activateBypass);
      },
    );
  }
}

class WarningPage extends StatefulWidget {
  final VoidCallback onBypass;
  const WarningPage({super.key, required this.onBypass});

  @override
  State<WarningPage> createState() => _WarningPageState();
}

class _WarningPageState extends State<WarningPage> {
  String _brand = "";
  String _guideText = "Buka Pengaturan > Keamanan > Screen Pinning > ON";
  String _errorMessage = "";
  String _serverPassword = "jujur2025";

  @override
  void initState() {
    super.initState();
    _detectDeviceBrand();
    _fetchServerConfig();
  }

  Future<void> _fetchServerConfig() async {
    try {
      final response = await http.get(
        Uri.parse("https://ujian.smkairlanggabpn.sch.id/app-config.json"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _serverPassword = data['emergency_password'].toString();
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil config server, pakai default.");
    }
  }

  Future<void> _detectDeviceBrand() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _brand = androidInfo.manufacturer.toLowerCase();
        _setGuideText(_brand);
      });
    }
  }

  void _setGuideText(String brand) {
    if (brand.contains('oppo') || brand.contains('realme')) {
      _guideText =
          "1. Pengaturan > Kata Sandi & Keamanan > Keamanan Sistem\n2. Cari 'Penyematan Layar' -> ON\n3. WAJIB Matikan Gesture Usap, ganti ke Tombol Navigasi.";
    } else if (brand.contains('vivo')) {
      _guideText =
          "1. Pengaturan > Keamanan & Privasi > More Security Settings\n2. Aktifkan 'Penyematan Layar'.\n3. Gunakan Tombol Navigasi Biasa.";
    } else if (brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco')) {
      _guideText =
          "1. Setelan > Sandi & Keamanan > Privasi > Penyematan Layar.\n2. Matikan Fullscreen Gesture.";
    } else if (brand.contains('samsung')) {
      _guideText =
          "1. Pengaturan > Biometrik & Keamanan > Pengaturan Keamanan Lainnya > Sematkan Jendela.";
    }
  }

  Future<void> _openSecuritySettings() async {
    const intent = AndroidIntent(action: 'android.settings.SECURITY_SETTINGS');
    await intent.launch();
  }

  Future<void> _showEmergencyDialog() async {
    final TextEditingController passController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Mode Darurat (Guru Only)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Gunakan ini HANYA jika HP siswa tidak support Screen Pinning.\n\nSiswa tetap diawasi oleh sistem Anti-Floating App.",
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Pengawas",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (passController.text == _serverPassword) {
                  Navigator.pop(context);
                  widget.onBypass();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password Salah!")),
                  );
                }
              },
              child: const Text(
                "Masuk Paksa",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 70, color: Colors.red),
              const SizedBox(height: 15),
              const Text(
                "MODE UJIAN BELUM AKTIF",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "HP Terdeteksi: ${_brand.toUpperCase()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Text(
                        "PANDUAN AKTIVASI:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text(
                        _guideText,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text("Buka Pengaturan"),
                        onPressed: _openSecuritySettings,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text("SAYA SUDAH ATUR, MULAI"),
                onPressed: () async {
                  try {
                    setState(() => _errorMessage = "");
                    await startKioskMode();
                    // throw Exception("Simulasi Pinning Gagal");
                  } catch (e) {
                    setState(
                      () => _errorMessage =
                          "Gagal Mengunci. HP ini mungkin tidak support.",
                    );
                    if (context.mounted) {
                      _showEmergencyDialog();
                    }
                  }
                },
              ),
              // const SizedBox(height: 40),
              // TextButton(
              //   onPressed: _showEmergencyDialog,
              //   child: const Text(
              //     "HP Tidak Support? Klik di sini",
              //     style: TextStyle(
              //       color: Colors.redAccent,
              //       fontSize: 12,
              //       decoration: TextDecoration.underline,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExamPage extends StatefulWidget {
  final bool isBypassMode;
  const ExamPage({super.key, this.isBypassMode = false});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  // bool _isObscured = false;
  bool _isRefreshing = false;
  bool _isViolationLocked = false;
  String _serverPassword = "jujur2025";

  final String _examUrl = "https://ujian.smkairlanggabpn.sch.id/";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSecurity();
    _initWebView();
    _fetchServerConfig();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    String? currentUrl = await _controller.currentUrl();
    bool isInsideExamRoom =
        currentUrl != null && currentUrl.contains('/siswa/exams/room/');
    if (_isRefreshing) return;
    if (state != AppLifecycleState.resumed) {
      // setState(() {
      // _isObscured = true;
      // });
      // setState(() {
      //   _isViolationLocked = true;
      // });

      if (isInsideExamRoom) {
        setState(() {
          _isViolationLocked = true; // KUNCI LAYAR MERAH
        });
        // debugPrint("Pelanggaran di Ruang Ujian: Terkunci.");
      } else {
        // debugPrint("Pelanggaran di Luar Ruang Ujian: Tidak dikunci.");
      }
    } else {
      // setState(() {
      //   _isObscured = false;
      // });
    }
  }

  Future<void> _fetchServerConfig() async {
    try {
      final response = await http.get(
        Uri.parse("https://ujian.smkairlanggabpn.sch.id/app-config.json"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _serverPassword = data['violation_password'].toString();
        });
      }
    } catch (e) {
      // debugPrint("Gagal ambil config server, pakai default.");
    }
  }

  Future<void> _unlockViolation() async {
    final TextEditingController passController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("⚠️ PELANGGARAN TERDETEKSI"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Siswa terdeteksi meninggalkan aplikasi / notifikasi / floating app.\n\nMasukkan Password dari panitia untuk membuka kembali.",
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Panitia",
                ),
              ),
            ],
          ),
          actions: [
            // Tombol Keluar (Kalau siswa nyerah)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            // Tombol Buka Kunci
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Memverifikasi Password ke Server..."),
                    duration: Duration(seconds: 1),
                  ),
                );
                await _fetchServerConfig();
                if (passController.text == _serverPassword) {
                  Navigator.pop(context); // Tutup Dialog
                  setState(() {
                    _isViolationLocked = false; // BUKA KUNCI
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ujian Dilanjutkan. JANGAN ULANGI LAGI!"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password Salah!")),
                  );
                }
              },
              child: const Text(
                "BUKA BLOKIR",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initSecurity() async {
    WakelockPlus.enable();
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.preventScreenshotOn();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() {
            _isLoading = false;
            _isRefreshing = false;
          }),
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
            // if (error.errorCode < 0) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       backgroundColor: Colors.redAccent,
            //       duration: const Duration(seconds: 10),
            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             "Gagal Terhubung!",
            //             style: TextStyle(fontWeight: FontWeight.bold),
            //           ),
            //           Text(
            //             "${error.description}",
            //             style: const TextStyle(fontSize: 12),
            //           ),
            //         ],
            //       ),
            //       action: SnackBarAction(
            //         label: 'Refresh',
            //         textColor: Colors.white,
            //         onPressed: () => _controller.reload(),
            //       ),
            //     ),
            //   );
            // }
          },
        ),
      )
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36 ExamApp/2.2",
      )
      ..loadRequest(Uri.parse(_examUrl));
  }

  Future<void> _exitApp() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar Ujian?'),
          content: const Text(
            'Pastikan Anda sudah LOGOUT dan mengirim jawaban.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await stopKioskMode();
                await ScreenProtector.preventScreenshotOff();
                SystemNavigator.pop();
              },
              child: const Text(
                'KELUAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isRefreshing = true;
              });
              _controller.reload().then((_) {
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted && _isRefreshing) {
                    setState(() => _isRefreshing = false);
                  }
                });
              });
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SMKS Airlangga",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.isBypassMode
                    ? "MODE DARURAT v2.2.1"
                    : "CBT Online v2.2.1",
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isBypassMode
                      ? Colors.yellowAccent
                      : Colors.white70,
                  fontWeight: widget.isBypassMode
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: _isViolationLocked
              ? [const ExamStatusBar()]
              : [
                  const ExamStatusBar(),
                  IconButton(
                    icon: const Icon(
                      Icons.power_settings_new,
                      color: Colors.redAccent,
                    ),
                    onPressed: _exitApp,
                  ),
                ],
        ),
        body: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
              gestureRecognizers: Set()
                ..add(
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                )
                ..add(
                  Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                ),
            ),

            if (_isLoading) const LinearProgressIndicator(),

            if (_isViolationLocked)
              Container(
                color: Colors.red.shade900, // Merah Gelap Menakutkan
                width: double.infinity,
                height: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gpp_bad, size: 100, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        "PELANGGARAN TERDETEKSI!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Anda terdeteksi membuka aplikasi lain / Floating App / Keluar dari ujian.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Aplikasi TERKUNCI secara sistem.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        icon: const Icon(Icons.lock_open),
                        label: const Text("PANGGIL PENGAWAS (BUKA KUNCI)"),
                        onPressed: _unlockViolation, // Panggil Dialog Password
                      ),
                    ],
                  ),
                ),
              ),

            // if (_isObscured)
            //   Container(
            //     color: Color.fromARGB(228, 0, 0, 0),
            //     width: double.infinity,
            //     height: double.infinity,
            //     child: Padding(
            //       padding: const EdgeInsets.all(30.0),
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           const Icon(
            //             Icons.block,
            //             size: 80,
            //             color: Colors.redAccent,
            //           ),
            //           const SizedBox(height: 20),
            //           const Text(
            //             "AKTIVITAS DILARANG TERDETEKSI",
            //             textAlign: TextAlign.center,
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 22,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //           const SizedBox(height: 15),
            //           const Text(
            //             "Aplikasi mendeteksi gangguan (Floating App, Notifikasi, atau Anda keluar aplikasi).",
            //             textAlign: TextAlign.center,
            //             style: TextStyle(color: Colors.white70, fontSize: 14),
            //           ),
            //           const SizedBox(height: 30),
            //           Container(
            //             padding: const EdgeInsets.all(15),
            //             decoration: BoxDecoration(
            //               color: Colors.white10,
            //               borderRadius: BorderRadius.circular(10),
            //               border: Border.all(color: Colors.redAccent),
            //             ),
            //             child: const Column(
            //               children: [
            //                 Text(
            //                   "CARA MELANJUTKAN:",
            //                   style: TextStyle(
            //                     color: Colors.redAccent,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "1. Tutup aplikasi lain/floating app.\n2. Kembali sepenuhnya ke aplikasi ujian.\n3. Ketuk layar ini.",
            //                   textAlign: TextAlign.center,
            //                   style: TextStyle(color: Colors.white),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

class ExamStatusBar extends StatefulWidget {
  const ExamStatusBar({super.key});
  @override
  State<ExamStatusBar> createState() => _ExamStatusBarState();
}

class _ExamStatusBarState extends State<ExamStatusBar> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  String _timeString = "";
  bool _isConnected = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initBattery();
    _checkConnectivity();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _getTime(),
    );
  }

  void _initBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    if (mounted)
      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final l = await _battery.batteryLevel;
      if (mounted)
        setState(() {
          _batteryState = state;
          _batteryLevel = l;
        });
    });
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    if (mounted)
      setState(
        () => _timeString =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      );
  }

  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      bool hasInternet =
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
      if (mounted) setState(() => _isConnected = hasInternet);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getBatteryColor() {
    if (_batteryState == BatteryState.charging) return Colors.greenAccent;
    if (_batteryLevel <= 20) return Colors.redAccent;
    return Colors.white;
  }

  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging)
      return Icons.battery_charging_full;
    if (_batteryLevel <= 20) return Icons.battery_alert;
    return Icons.battery_full;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(_timeString, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Icon(
          _isConnected ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: _isConnected ? Colors.white : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          "$_batteryLevel%",
          style: TextStyle(
            fontSize: 12,
            color: _getBatteryColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Icon(_getBatteryIcon(), size: 18, color: _getBatteryColor()),
        const SizedBox(width: 5),
      ],
    );
  }
}
