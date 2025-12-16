import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';
import '../services/sip_manager.dart';
import 'call_page.dart';

class CallMiddleSectionPage extends StatefulWidget {
  final Call call;
  final SIPUAHelper helper;
  final SipManager sipManager;

  const CallMiddleSectionPage({
    super.key,
    required this.call,
    required this.helper,
    required this.sipManager,
  });

  @override
  State<CallMiddleSectionPage> createState() => _CallMiddleSectionPageState();
}

class _CallMiddleSectionPageState extends State<CallMiddleSectionPage> {
  String _callStatus = 'Starting Audio Call...';
  Timer? _durationTimer;
  int _secondsElapsed = 0;
  bool _hasNavigatedAway = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register callback for call state changes
    widget.sipManager.onCallStateChanged = _onCallStateChanged;
  }

  @override
  void dispose() {
    // Unregister callback
    widget.sipManager.onCallStateChanged = null;
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_hasNavigatedAway) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _onCallStateChanged(CallState state, Call call) {
    // Don't process state changes if we've already navigated away
    if (_hasNavigatedAway || !mounted) return;

    if (call.id == widget.call.id) {
      // Handle call accepted - navigate to CallPage
      if (state.state == CallStateEnum.CONFIRMED) {
        _hasNavigatedAway = true;
        widget.sipManager.onCallStateChanged = null;
        _durationTimer?.cancel();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CallPage(
                call: call,
                helper: widget.helper,
                sipManager: widget.sipManager,
              ),
            ),
          );
        }
        return;
      }

      // Update status for other states
      setState(() {
        switch (state.state) {
          case CallStateEnum.STREAM:
            _callStatus = 'Audio Call in Progress';
            break;
          case CallStateEnum.MUTED:
            _callStatus = 'Muted';
            break;
          case CallStateEnum.UNMUTED:
            _callStatus = 'Unmuted';
            break;
          default:
            _callStatus = state.state.toString().split('.').last;
        }
      });

      // Handle call ended or failed
      if (state.state == CallStateEnum.ENDED ||
          state.state == CallStateEnum.FAILED) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remoteIdentity = widget.call.remote_identity ?? 'Unknown';
    // Extract number if possible, or use the whole identity string
    final displayName = remoteIdentity
        .split('@')
        .first
        .replaceFirst('sip:', '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Line Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.call, color: Colors.blue[800], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Line 1',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Right: Controls/Icons
                  Row(
                    children: [
                      Icon(Icons.mic, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.volume_up, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status and Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _callStatus,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(_secondsElapsed),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Center Number
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const Spacer(flex: 1),

            // Divider
            Divider(color: Colors.blue[400], thickness: 1),

            const SizedBox(height: 40),

            // Hangup Button
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  onPressed: () {
                    widget.call.hangup();
                  },
                  backgroundColor: Colors.red,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
