import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:sip_ua/sip_ua.dart';
import '../services/sip_manager.dart';

class CallPage extends StatefulWidget {
  final Call call;
  final SIPUAHelper helper;

  const CallPage({super.key, required this.call, required this.helper});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final RTCVideoRenderer _local = RTCVideoRenderer();
  final RTCVideoRenderer _remote = RTCVideoRenderer();
  SipManager? _sipManager;
  bool _isHeld = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  int _callDuration = 0;

  @override
  void initState() {
    super.initState();
    developer.log('=== CallPage Initialized ===', name: 'CallPage');
    developer.log('Call ID: ${widget.call.id}', name: 'CallPage');
    developer.log('Call Direction: ${widget.call.direction}', name: 'CallPage');
    developer.log(
      'Remote Identity: ${widget.call.remote_identity}',
      name: 'CallPage',
    );
    initRenderers();
    _startCallTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sipManager == null) {
      _sipManager = Provider.of<SipManager>(context);
      _sipManager!.addListener(_onSipStateChanged);
    }
  }

  Future<void> initRenderers() async {
    developer.log('Initializing video renderers...', name: 'CallPage');
    await _local.initialize();
    developer.log('Local renderer initialized', name: 'CallPage');
    await _remote.initialize();
    developer.log('Remote renderer initialized', name: 'CallPage');
    setState(() {});
  }

  void _startCallTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
        _startCallTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    developer.log('=== CallPage Disposing ===', name: 'CallPage');
    _sipManager?.removeListener(_onSipStateChanged);
    _local.dispose();
    _remote.dispose();
    super.dispose();
  }

  void _onSipStateChanged() {
    final sip = _sipManager!;
    final call = sip.currentCall;
    final state = sip.currentCallState;

    if (call != null && state != null && call.id == widget.call.id) {
      developer.log('=== CallPage: Call State Changed ===', name: 'CallPage');
      developer.log('Call ID: ${call.id}', name: 'CallPage');
      developer.log('Widget Call ID: ${widget.call.id}', name: 'CallPage');
      developer.log('State: ${state.state}', name: 'CallPage');

      if (state.state == CallStateEnum.STREAM) {
        developer.log(
          'Stream received, originator: ${state.originator}',
          name: 'CallPage',
        );
        MediaStream? stream = state.stream;
        if (state.originator == Originator.local) {
          developer.log('Setting local stream', name: 'CallPage');
          _local.srcObject = stream;
        } else {
          developer.log('Setting remote stream', name: 'CallPage');
          _remote.srcObject = stream;
        }

        // Force speakerphone on by default
        developer.log(
          'Forcing speakerphone ON for iOS Simulator compatibility',
          name: 'CallPage',
        );
        Helper.setSpeakerphoneOn(false);
        _isSpeakerOn = false;

        setState(() {});
      }

      if (state.state == CallStateEnum.ENDED ||
          state.state == CallStateEnum.FAILED) {
        developer.log(
          'Call ended or failed, closing CallPage',
          name: 'CallPage',
        );
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    widget.call.mute(_isMuted);
  }

  void _toggleHold() {
    setState(() {
      _isHeld = !_isHeld;
    });
    if (_isHeld) {
      widget.call.hold();
    } else {
      widget.call.unhold();
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  String _getDisplayNumber() {
    final remoteIdentity = widget.call.remote_identity ?? 'Unknown';
    return remoteIdentity.split('@').first.replaceFirst('sip:', '');
  }

  @override
  Widget build(BuildContext context) {
    final displayNumber = _getDisplayNumber();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Line info and controls
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Line 1 info
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue[800], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Line 1',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Mute and Speaker icons
                  Row(
                    children: [
                      Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Phone number
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                displayNumber,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Call status and timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isHeld ? 'Call on Hold' : 'Call in Progress!',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(_callDuration),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Large phone number display
            Text(
              displayNumber,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            // Secondary number display
            Text(
              displayNumber,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const Spacer(),

            // Control buttons container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Chevron up icon
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.grey[400],
                    size: 32,
                  ),

                  const SizedBox(height: 24),

                  // First row of controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        onPressed: _toggleMute,
                        isActive: _isMuted,
                      ),
                      _buildControlButton(
                        icon: Icons.pause,
                        onPressed: _toggleHold,
                        isActive: _isHeld,
                      ),
                      _buildControlButton(
                        icon: Icons.forward,
                        onPressed: () {},
                      ),
                      _buildControlButton(icon: Icons.people, onPressed: () {}),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Second row of controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.dialpad,
                        onPressed: () {},
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        onPressed: _toggleSpeaker,
                        isActive: _isSpeakerOn,
                      ),
                      // Hangup button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            developer.log(
                              'Hangup button pressed',
                              name: 'CallPage',
                            );
                            widget.call.hangup();
                          },
                        ),
                      ),
                      const SizedBox(width: 56), // Spacer to balance layout
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[700] : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.blue[700],
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
