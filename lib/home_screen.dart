import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_helper.dart';
import 'call_page.dart';
import 'sip_config.dart';

class HomeScreen extends StatefulWidget {
  final SipManager sipManager;

  const HomeScreen({super.key, required this.sipManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late SipManager sip;
  RegistrationStateEnum registerState = RegistrationStateEnum.NONE;
  Call? currentCall;
  String _dialedNumber = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Use the SipManager passed from LoginScreen
    sip = widget.sipManager;
    if (sip.currentRegistrationState != null) {
      registerState =
          sip.currentRegistrationState!.state ?? RegistrationStateEnum.NONE;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    developer.log('=== HomeScreen Initialized ===', name: 'HomeScreen');

    sip.onRegister = (state) {
      developer.log('=== Registration Callback ===', name: 'HomeScreen');
      developer.log('Registration State: ${state.state}', name: 'HomeScreen');
      developer.log('Registration Cause: ${state.cause}', name: 'HomeScreen');

      setState(() {
        registerState = state.state ?? RegistrationStateEnum.NONE;
      });
    };

    sip.onCallState = (state, call) {
      developer.log('=== Call State Callback ===', name: 'HomeScreen');
      developer.log('Call State: ${state.state}', name: 'HomeScreen');
      developer.log('Call Direction: ${call.direction}', name: 'HomeScreen');
      developer.log(
        'Remote Identity: ${call.remote_identity}',
        name: 'HomeScreen',
      );

      if (state.state == CallStateEnum.CALL_INITIATION &&
          call.direction == Direction.incoming) {
        developer.log(
          'Incoming call detected, navigating to CallPage',
          name: 'HomeScreen',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallPage(call: call, helper: sip.uaHelper),
          ),
        );
      }

      if (state.state == CallStateEnum.PROGRESS) {
        developer.log('Call in progress', name: 'HomeScreen');
        currentCall = call;
      }

      if (state.state == CallStateEnum.ACCEPTED) {
        developer.log(
          'Call accepted, navigating to CallPage',
          name: 'HomeScreen',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallPage(call: call, helper: sip.uaHelper),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
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
                        _buildDialpad(isDarkMode),
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
                              ? Colors.green.withOpacity(0.5)
                              : Colors.orange.withOpacity(0.5),
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
                          ? Colors.white.withOpacity(0.7)
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
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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

  Widget _buildDialpad(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dialed Number Display
          Container(
            height: 60,
            alignment: Alignment.center,
            child: Text(
              _dialedNumber,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDialpadGrid(isDarkMode),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70), // Spacer for alignment
              _buildCallButton(),
              _buildBackspaceButton(isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialpadGrid(bool isDarkMode) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    final subLabels = [
      ['', 'ABC', 'DEF'],
      ['GHI', 'JKL', 'MNO'],
      ['PQRS', 'TUV', 'WXYZ'],
      ['', '+', ''],
    ];

    return Column(
      children: List.generate(
        buttons.length,
        (rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              buttons[rowIndex].length,
              (colIndex) => _buildDialpadButton(
                buttons[rowIndex][colIndex],
                subLabels[rowIndex][colIndex],
                isDarkMode,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialpadButton(String number, String letters, bool isDarkMode) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.shade100,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _dialedNumber += number;
            });
          },
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998e).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_dialedNumber.isNotEmpty) {
              sip.uaHelper.call(_dialedNumber);
            }
          },
          customBorder: const CircleBorder(),
          child: const Icon(Icons.call_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(bool isDarkMode) {
    if (_dialedNumber.isEmpty) {
      return const SizedBox(width: 70, height: 70);
    }
    return SizedBox(
      width: 70,
      height: 70,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (_dialedNumber.isNotEmpty) {
                _dialedNumber = _dialedNumber.substring(
                  0,
                  _dialedNumber.length - 1,
                );
              }
            });
          },
          onLongPress: () {
            setState(() {
              _dialedNumber = '';
            });
          },
          customBorder: const CircleBorder(),
          child: Icon(
            Icons.backspace_rounded,
            color: isDarkMode ? Colors.white70 : Colors.black54,
            size: 28,
          ),
        ),
      ),
    );
  }
}
