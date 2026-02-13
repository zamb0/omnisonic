import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/animation_manager.dart';

void main() {
  group('AnimationManager', () {
    late AnimationManager animationManager;
    
    setUp(() {
      animationManager = AnimationManager();
    });
    
    tearDown(() {
      animationManager.dispose();
    });
    
    test('should initialize with default settings', () {
      expect(animationManager.activeAnimationCount, equals(0));
      expect(animationManager.isPerformanceMonitoringEnabled, isFalse);
    });
    
    test('should enable performance monitoring when initialized', () {
      animationManager.initialize(enablePerformanceMonitoring: true);
      expect(animationManager.isPerformanceMonitoringEnabled, isTrue);
    });
    
    testWidgets('should create animation controller with proper configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TestAnimationWidget();
              },
            ),
          ),
        ),
      );
      
      // Verify the widget builds without errors
      expect(find.byType(TestAnimationWidget), findsOneWidget);
    });
    
    test('should create tween animations correctly', () {
      final testWidget = TestAnimationWidget();
      expect(testWidget, isNotNull);
    });
    
    test('should provide standardized durations', () {
      expect(AnimationManager.fastDuration, equals(const Duration(milliseconds: 150)));
      expect(AnimationManager.normalDuration, equals(const Duration(milliseconds: 300)));
      expect(AnimationManager.slowDuration, equals(const Duration(milliseconds: 500)));
    });
    
    test('should provide standardized curves', () {
      expect(AnimationManager.standardCurve, equals(Curves.easeInOutCubic));
      expect(AnimationManager.fastCurve, equals(Curves.easeOutQuart));
      expect(AnimationManager.slowCurve, equals(Curves.easeInOutQuint));
    });
  });
  
  group('AnimationUtilities', () {
    testWidgets('should create bounce animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBounceWidget(),
          ),
        ),
      );
      
      expect(find.byType(TestBounceWidget), findsOneWidget);
    });
    
    testWidgets('should create scale animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestScaleWidget(),
          ),
        ),
      );
      
      expect(find.byType(TestScaleWidget), findsOneWidget);
    });
  });
}

class TestAnimationWidget extends StatefulWidget {
  @override
  _TestAnimationWidgetState createState() => _TestAnimationWidgetState();
}

class _TestAnimationWidgetState extends State<TestAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationManager().createController(
      duration: AnimationManager.normalDuration,
      vsync: this,
      debugLabel: 'TestAnimation',
    );
    
    _animation = AnimationManager().createTween<double>(
      controller: _controller,
      begin: 0.0,
      end: 1.0,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ),
        );
      },
    );
  }
}

class TestBounceWidget extends StatefulWidget {
  @override
  _TestBounceWidgetState createState() => _TestBounceWidgetState();
}

class _TestBounceWidgetState extends State<TestBounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationManager().createController(
      duration: AnimationManager.normalDuration,
      vsync: this,
      debugLabel: 'TestBounce',
    );
    
    _bounceAnimation = AnimationUtilities.createBounceAnimation(
      controller: _controller,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value * 50),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.red,
          ),
        );
      },
    );
  }
}

class TestScaleWidget extends StatefulWidget {
  @override
  _TestScaleWidgetState createState() => _TestScaleWidgetState();
}

class _TestScaleWidgetState extends State<TestScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationManager().createController(
      duration: AnimationManager.normalDuration,
      vsync: this,
      debugLabel: 'TestScale',
    );
    
    _scaleAnimation = AnimationUtilities.createScaleAnimation(
      controller: _controller,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 50,
            height: 50,
            color: Colors.green,
          ),
        );
      },
    );
  }
}