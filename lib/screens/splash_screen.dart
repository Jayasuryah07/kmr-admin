import 'package:flutter/material.dart';
import 'package:krm_admin/screens/home_screen.dart';
import 'package:krm_admin/screens/login_screen.dart';
import 'package:krm_admin/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late List<Bubble> _bubbles;
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _checkLoginStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize bubbles here instead of initState
    _initializeBubbles();
  }

  void _initializeBubbles() {
    _screenSize = MediaQuery.of(context).size;
    _bubbles = List.generate(20, (index) {
      return Bubble(
        id: index,
        size: 20 + (index % 5) * 10,
        xPosition: (index * 50) % _screenSize!.width,
        yPosition: (index * 30) % _screenSize!.height,
        speed: 1 + (index % 3) * 0.5,
        opacity: 0.3 + (index % 5) * 0.1,
      );
    });
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    
    bool isLoggedIn = await _authService.isLoggedIn();
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn 
            ? const HomeScreen() 
            : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Animated Bubbles
            if (_bubbles != null)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BubblePainter(
                      bubbles: _bubbles,
                      animationValue: _animationController.value,
                      screenSize: MediaQuery.of(context).size,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            // Center Logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                   
                    child: Image.asset(
                      'assets/applogo.png',
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Loading Animation
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple.shade300,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bubble Model
class Bubble {
  final int id;
  final double size;
  double xPosition;
  double yPosition;
  final double speed;
  final double opacity;

  Bubble({
    required this.id,
    required this.size,
    required this.xPosition,
    required this.yPosition,
    required this.speed,
    required this.opacity,
  });
}

// Custom Painter for Bubbles
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;
  final Size screenSize;

  BubblePainter({
    required this.bubbles,
    required this.animationValue,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Update bubble positions and draw them
    for (var bubble in bubbles) {
      // Move bubbles upwards
      bubble.yPosition -= bubble.speed * 0.5;
      
      // Reset bubble position when it goes off screen
      if (bubble.yPosition < -bubble.size) {
        bubble.yPosition = screenSize.height + bubble.size;
        bubble.xPosition = (bubble.id * 50) % screenSize.width;
      }

      // Slight horizontal movement
      bubble.xPosition += (bubble.id % 2 == 0) ? 0.3 : -0.3;
      
      // Keep within bounds
      if (bubble.xPosition < 0) {
        bubble.xPosition = screenSize.width;
      } else if (bubble.xPosition > screenSize.width) {
        bubble.xPosition = 0;
      }

      // Draw the bubble
      paint.color = Colors.deepPurple.shade100.withOpacity(bubble.opacity * 0.3);
      canvas.drawCircle(
        Offset(bubble.xPosition, bubble.yPosition),
        bubble.size / 2,
        paint,
      );

      // Draw inner glow
      paint.color = Colors.deepPurple.shade50.withOpacity(bubble.opacity * 0.1);
      canvas.drawCircle(
        Offset(bubble.xPosition - bubble.size * 0.2, bubble.yPosition - bubble.size * 0.2),
        bubble.size / 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return true;
  }
}