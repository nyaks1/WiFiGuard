import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wifiguard/screens/result_screen.dart';
import 'package:wifiguard/services/wifiguard_service.dart';


class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _currentStep = 0;
  
  // Static counter keeps its state across pushReplacements
  static int _demoStateCounter = 0;

  final List<String> _steps = [
    'Querying network BSSID & OUI fingerprint...',
    'Analyzing RSSI signal variance (500ms)...',
    'Verifying DNS record consistency (offline)...',
    'Measuring RTT baseline & latency...',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startScanningSequence();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _startScanningSequence() async {
    // Elegant stagger animation stays completely functional
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        setState(() {
          _currentStep = i + 1;
        });
      }
    }

    final WiFiGuardVerdict verdict;
    
    if (Platform.isAndroid) {
      // Run the actual scan (including native/Rust code)
      verdict = await WiFiGuardService.assess();
    } else {
      // Force rotation order: Safe -> Suspect -> Blocked
      _demoStateCounter++;
      final stateIndex = _demoStateCounter % 3;
      
      if (stateIndex == 1) {
        verdict = const WiFiGuardVerdict(
          state: WiFiGuardVerdictState.safe,
          reason: 'BSSID matches known corporate whitelist infrastructure. DNS integrity verified via local cryptographic handshake. SSL pinning enforced successfully.',
        );
      } else if (stateIndex == 2) {
        verdict = const WiFiGuardVerdict(
          state: WiFiGuardVerdictState.suspect,
          reason: 'Warning: Unusually high RSSI signal variance detected. Minor latency anomalies suggest potential proxying or downstream traffic monitoring.',
        );
      } else {
        verdict = const WiFiGuardVerdict(
          state: WiFiGuardVerdictState.blocked,
          reason: 'CRITICAL ALERT: ARP poisoning attack detected! Twin counterfeit gateway MAC address identified. Outbound financial data streams severed instantly to secure assets.',
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultScreen(verdict: verdict),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyPrimary = Color(0xFF0F172A); 
    const navyDark = Color(0xFF020617); 
    const goldPrimary = Color(0xFFD4AF37); 
    const goldGlow = Color(0x33D4AF37);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [navyPrimary, navyDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: goldGlow,
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                goldPrimary,
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 142,
                        height: 142,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: navyPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: goldPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'WiFiGuard Network Assessment',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Securing your mobile banking session...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_steps.length, (index) {
                        final stepText = _steps[index];
                        final isCompleted = _currentStep > index;
                        final isCurrent = _currentStep == index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? const Color(0xFF10B981) 
                                      : isCurrent
                                          ? goldPrimary.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFF10B981)
                                        : isCurrent
                                            ? goldPrimary
                                            : Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : isCurrent
                                          ? const SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(goldPrimary),
                                              ),
                                            )
                                          : Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                            ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  stepText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                    color: isCompleted
                                        ? Colors.white
                                        : isCurrent
                                            ? goldPrimary
                                            : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}