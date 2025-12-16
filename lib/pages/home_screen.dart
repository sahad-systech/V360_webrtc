import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:webrtc_calling/webrtc_calling.dart';

import '../core/sip_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  SipManager? _sipManager;
  RegistrationStateEnum registerState = RegistrationStateEnum.NONE;
  Call? currentCall;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  CallStateEnum? _lastCallState;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    developer.log('=== HomeScreen Initialized ===', name: 'HomeScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sipManager == null) {
      _sipManager = Provider.of<SipManager>(context, listen: false);
      _sipManager!.onRegistrationStateChanged = (state) {
        if (mounted) _onSipStateChanged();
      };
      _sipManager!.onCallStateChanged = (state, call) {
        if (mounted) _onSipStateChanged();
      };
      _onSipStateChanged(); // Initialize state
    }
  }

  void _onSipStateChanged() {
    if (!mounted) return;
    final sip = _sipManager!;

    // Update registration state
    if (sip.currentRegistrationState != null) {
      final newState =
          sip.currentRegistrationState!.state ?? RegistrationStateEnum.NONE;
      if (registerState != newState) {
        setState(() {
          registerState = newState;
        });
        developer.log('Registration State: $registerState', name: 'HomeScreen');
      }
    }

    // Handle call state
    final call = sip.currentCall;
    final callState = sip.currentCallState?.state;

    if (call != null && callState != null) {
      // Only react if state changed
      if (_lastCallState != callState) {
        developer.log('=== Call State Changed ===', name: 'HomeScreen');
        developer.log('Call State: $callState', name: 'HomeScreen');
        developer.log('Call Direction: ${call.direction}', name: 'HomeScreen');

        // Only navigate for incoming calls - outgoing calls are handled by the call button
        // Also handle if call is already accepted (e.g. via CallKit)
        if ((callState == CallStateEnum.CALL_INITIATION ||
                callState == CallStateEnum.CONFIRMED ||
                callState == CallStateEnum.STREAM) &&
            call.direction == Direction.incoming) {
          if (currentCall?.id == call.id) {
            return;
          }

          developer.log(
            'Incoming call detected, navigating to CallMiddleSectionPage',
            name: 'HomeScreen',
          );
          currentCall = call;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallMiddleSectionPage(
                call: call,
                helper: sip.uaHelper,
                sipManager: sip,
              ),
            ),
          ).then((_) {
            currentCall = null;
          });
        } else if (callState == CallStateEnum.PROGRESS) {
          developer.log('Call in progress', name: 'HomeScreen');
          // currentCall = call; // Already handled above
        }

        _lastCallState = callState;
      }
    }
  }

  @override
  void dispose() {
    if (_sipManager != null) {
      _sipManager!.onRegistrationStateChanged = null;
      _sipManager!.onCallStateChanged = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFf8f9fa),
                    const Color(0xFFe9ecef),
                    const Color(0xFFdee2e6),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(isDarkMode),

              // Main Content
              Expanded(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Dialpad
                        DialPad(
                          isDarkMode: isDarkMode,
                          sipManager: _sipManager!,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SipConfig.profileName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: registerState == RegistrationStateEnum.REGISTERED
                          ? Colors.green
                          : Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color:
                              registerState == RegistrationStateEnum.REGISTERED
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.orange.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    registerState == RegistrationStateEnum.REGISTERED
                        ? 'Online'
                        : 'Offline',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                // Handle profile tap
              },
            ),
          ),
        ],
      ),
    );
  }
}
