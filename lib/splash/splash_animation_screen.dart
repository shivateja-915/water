import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animation_constants.dart';
import 'floating_particles.dart';
import 'ripple_painter.dart';
import 'splash_initializer.dart';

final appInitializedProvider = StateProvider<bool>((ref) => false);

class SplashOverlayWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SplashOverlayWrapper({super.key, required this.child});

  @override
  ConsumerState<SplashOverlayWrapper> createState() => _SplashOverlayWrapperState();
}

class _SplashOverlayWrapperState extends ConsumerState<SplashOverlayWrapper>
    with TickerProviderStateMixin {
  bool _isInitDone = false;
  bool _isMinTimeElapsed = false;
  bool _isTransitionComplete = false;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _breatheController;
  late AnimationController _dropletController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _transitionController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _breatheAnimation;
  
  late Animation<double> _dropletLiftAnimation;
  late Animation<double> _dropletFallAnimation;
  late Animation<double> _rippleAnimation;
  
  late Animation<double> _glowAnimation;
  
  late Animation<double> _textFadeAnimation;
  late Animation<double> _letterSpacingAnimation;
  late Animation<double> _subtitleFadeAnimation;

  late Animation<double> _logoScaleTransition;
  late Animation<Offset> _logoMoveTransition;
  late Animation<Offset> _homeSlideTransition;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
    _runInitialization();
  }

  void _setupAnimations() {
    // 1. Fade
    _fadeController = AnimationController(
      vsync: this,
      duration: SplashAnimationConstants.phase1FadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: SplashAnimationConstants.opacityCurve,
    );

    // 2. Breathe
    _breatheController = AnimationController(
      vsync: this,
      duration: SplashAnimationConstants.phase2BreatheDuration,
    );
    _breatheAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.03), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _breatheController,
      curve: SplashAnimationConstants.scaleCurve,
    ));

    // 3. Droplet & Ripple (combined controller for simplicity)
    _dropletController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750), // 150+100+150+350
    );
    
    _dropletLiftAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _dropletController, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );
    _dropletFallAnimation = Tween<double>(begin: -8, end: 0).animate(
      CurvedAnimation(parent: _dropletController, curve: const Interval(0.33, 0.53, curve: Curves.easeIn)),
    );
    _rippleAnimation = CurvedAnimation(
      parent: _dropletController,
      curve: const Interval(0.53, 1.0, curve: SplashAnimationConstants.rippleCurve),
    );

    // 4. Glow
    _glowController = AnimationController(
      vsync: this,
      duration: SplashAnimationConstants.phase4GlowDuration,
    );
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 18.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 18.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 5. Text
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 450 + 150 delay
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
    );
    _letterSpacingAnimation = Tween<double>(begin: 18.0, end: 2.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.75, curve: Curves.easeOut)),
    );
    _subtitleFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
    );

    // 8. Transition
    _transitionController = AnimationController(
      vsync: this,
      duration: SplashAnimationConstants.phase8TransitionDuration,
    );
    _logoScaleTransition = Tween<double>(begin: 1.0, end: 0.42).animate(
      CurvedAnimation(parent: _transitionController, curve: SplashAnimationConstants.movementCurve),
    );
    _logoMoveTransition = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -2.5)).animate(
      CurvedAnimation(parent: _transitionController, curve: SplashAnimationConstants.movementCurve),
    );
    _homeSlideTransition = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _transitionController, curve: SplashAnimationConstants.movementCurve),
    );

    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isTransitionComplete = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _breatheController.dispose();
    _dropletController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _startSequence() async {
    // 1. Fade in
    await _fadeController.forward();
    
    // 2. Breathe
    await _breatheController.forward();
    
    // 3. Droplet & Ripples
    await _dropletController.forward();
    
    // 4. Glow
    await _glowController.forward();
    
    // 5. Text
    await _textController.forward();

    _isMinTimeElapsed = true;
    _checkTransition();
  }

  void _runInitialization() async {
    await SplashInitializer.initializeApp();
    _isInitDone = true;
    _checkTransition();
  }

  void _checkTransition() {
    if (_isInitDone && _isMinTimeElapsed && !_transitionController.isAnimating && !_isTransitionComplete) {
      // Trigger Riverpod to notify GoRouter that init is done
      ref.read(appInitializedProvider.notifier).state = true;
      
      // Give the router a frame to build the target screen (Home/Login) offstage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transitionController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTransitionComplete) {
      return widget.child;
    }

    return Stack(
      children: [
        // 1. The App (sliding up from bottom)
        SlideTransition(
          position: _homeSlideTransition,
          child: widget.child,
        ),
        
        // 2. The Splash Screen Overlay
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: _transitionController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn))
          ),
          child: Container(
            color: SplashAnimationConstants.backgroundColor,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating particles
                const FloatingParticles(),
                
                // The main logo and effects
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _fadeController,
                    _breatheController,
                    _dropletController,
                    _glowController,
                    _transitionController,
                  ]),
                  builder: (context, child) {
                    final dy = _dropletController.value < 0.33 
                        ? _dropletLiftAnimation.value 
                        : _dropletFallAnimation.value;

                    return SlideTransition(
                      position: _logoMoveTransition,
                      child: Transform.scale(
                        scale: _logoScaleTransition.value * (_breatheController.isAnimating ? _breatheAnimation.value : 1.0),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple Effect
                              CustomPaint(
                                painter: RipplePainter(
                                  animationValue: _rippleAnimation.value,
                                  color: SplashAnimationConstants.rippleColor,
                                ),
                                size: const Size(200, 200),
                              ),
                              
                              // Glow Effect
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (_glowAnimation.value > 0)
                                      BoxShadow(
                                        color: SplashAnimationConstants.glowColor.withValues(alpha: 0.18),
                                        blurRadius: _glowAnimation.value,
                                        spreadRadius: _glowAnimation.value / 2,
                                      )
                                  ],
                                ),
                              ),

                              // Base Logo (without droplet if possible, but assuming it's a single image, 
                              // we might need to just animate the whole image or simulate the droplet.
                              // Wait, the user asked to 'Animate Water Droplet'. If the logo is a single PNG,
                              // we can't detach the droplet. We'll animate the whole logo up and down for the droplet phase
                              // or just use the dy translation.)
                              Transform.translate(
                                offset: Offset(0, dy),
                                child: Image.asset(
                                  'assets/images/siply.logo.png',
                                  width: 140,
                                  height: 140,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // The Text (Fades out earlier during transition)
                FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(parent: _transitionController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 240), // Position below logo
                      child: AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: _textFadeAnimation.value,
                                child: Text(
                                  'SIPLY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: SplashAnimationConstants.textColor,
                                    letterSpacing: _letterSpacingAnimation.value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Opacity(
                                opacity: _subtitleFadeAnimation.value,
                                child: Text(
                                  'Every Sip Counts',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: SplashAnimationConstants.subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

