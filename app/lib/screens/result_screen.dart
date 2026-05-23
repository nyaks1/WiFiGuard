import 'package:flutter/material.dart';
import 'package:wifiguard/screens/scan_screen.dart';
import 'package:wifiguard/services/wifiguard_service.dart';

class ResultScreen extends StatelessWidget {
  final WiFiGuardVerdict verdict;

  const ResultScreen({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    // Determine theme colors based on the verdict state
    final Color primaryColor;
    final Color backgroundGradStart;
    final Color backgroundGradEnd;
    final IconData statusIcon;
    final String title;

    switch (verdict.state) {
      case WiFiGuardVerdictState.safe:
        primaryColor = const Color(0xFF10B981); // Emerald Green
        backgroundGradStart = const Color(0xFF064E3B);
        backgroundGradEnd = const Color(0xFF022C22);
        statusIcon = Icons.verified_user_rounded;
        title = 'Network Secured';
        break;
      case WiFiGuardVerdictState.suspect:
        primaryColor = const Color(0xFFF59E0B); // Amber Orange
        backgroundGradStart = const Color(0xFF78350F);
        backgroundGradEnd = const Color(0xFF451A03);
        statusIcon = Icons.warning_amber_rounded;
        title = 'Security Advisory';
        break;
      case WiFiGuardVerdictState.blocked:
        primaryColor = const Color(0xFFEF4444); // Crimson Red
        backgroundGradStart = const Color(0xFF7F1D1D);
        backgroundGradEnd = const Color(0xFF450A0A);
        statusIcon = Icons.gpp_bad_rounded;
        title = 'Connection Blocked';
        break;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundGradStart, backgroundGradEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Animated Status Shield/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      statusIcon,
                      size: 56,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Verdict Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      verdict.reason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Mock South African Banking App Shell
                  _buildBankingMockApp(context, primaryColor),
                  const SizedBox(height: 40),
                  // Navigation Actions
                  _buildActions(context, primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankingMockApp(BuildContext context, Color primaryColor) {
    final bool isDisabled = verdict.state == WiFiGuardVerdictState.blocked;
    final bool hasWarning = verdict.state == WiFiGuardVerdictState.suspect;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Internal Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Opacity(
                opacity: isDisabled ? 0.3 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Bank Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'THEMIS BANK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Cheque *5902',
                            style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    // Warning Banner (Suspect Mode)
                    if (hasWarning) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.bottom,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF78350F).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Color(0xFFF59E0B), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Caution: Minor network anomalies detected. Proceed with care.',
                                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Amount Field
                    const Text(
                      'TRANSFER TO',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Z. Zuma (Savings account)',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AMOUNT',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'R 2,450.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Button inside App
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: isDisabled
                            ? null
                            : () {
                                _showTransactionSuccess(context);
                              },
                        child: const Text(
                          'Authorize Transaction',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Blocked Overlay Screen
            if (isDisabled)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Color(0xFFEF4444), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'TRANSACTIONS SUSPENDED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'WiFiGuard has blocked outgoing traffic to prevent credential theft. Change to a secure network or cellular data to resume.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color primaryColor) {
    if (verdict.state == WiFiGuardVerdictState.blocked) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.styleFrom(
              elevation: 4,
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).primaryButton(
              onPressed: () {
                _simulateMobileDataSwitch(context);
              },
              label: 'Switch to Mobile Data',
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _goToScan(context),
            child: const Text(
              'Scan Again (Rotates mock state)',
              style: TextStyle(color: Colors.white60, decoration: TextDecoration.underline),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.08),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _goToScan(context),
        child: const Text(
          'Run New Scan (Rotates mock state)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _goToScan(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
  }

  void _showTransactionSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Success', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'The R 2,450.00 transfer has been successfully processed under network protection.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _simulateMobileDataSwitch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.settings_cell_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Mobile Data Switch', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Simulating network system command to disable WiFi. Banking transactions will now proceed over secure cellular infrastructure.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToScan(context);
            },
            child: const Text('Re-Scan Cell Network', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }
}

// Extension to clean up code syntax for the primary button
extension on ButtonStyle {
  Widget primaryButton({required VoidCallback onPressed, required String label}) {
    return ElevatedButton(
      style: this,
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
