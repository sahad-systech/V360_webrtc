import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';

class CallPage extends StatefulWidget {
  final Call call;
  final SIPUAHelper helper;

  const CallPage({required this.call, required this.helper});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> implements SipUaHelperListener {
  final RTCVideoRenderer _local = RTCVideoRenderer();
  final RTCVideoRenderer _remote = RTCVideoRenderer();

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
    widget.helper.addSipUaHelperListener(this);
  }

  Future<void> initRenderers() async {
    developer.log('Initializing video renderers...', name: 'CallPage');
    await _local.initialize();
    developer.log('Local renderer initialized', name: 'CallPage');
    await _remote.initialize();
    developer.log('Remote renderer initialized', name: 'CallPage');
    setState(() {});
  }

  @override
  void dispose() {
    developer.log('=== CallPage Disposing ===', name: 'CallPage');
    widget.helper.removeSipUaHelperListener(this);
    _local.dispose();
    _remote.dispose();
    super.dispose();
  }

  @override
  void callStateChanged(Call call, CallState state) {
    developer.log('=== CallPage: Call State Changed ===', name: 'CallPage');
    developer.log('Call ID: ${call.id}', name: 'CallPage');
    developer.log('Widget Call ID: ${widget.call.id}', name: 'CallPage');
    developer.log('State: ${state.state}', name: 'CallPage');

    if (call.id == widget.call.id) {
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
        setState(() {});
      }

      if (state.state == CallStateEnum.ENDED ||
          state.state == CallStateEnum.FAILED) {
        developer.log(
          'Call ended or failed, closing CallPage',
          name: 'CallPage',
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {}

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RTCVideoView(_remote),
          Positioned(
            right: 20,
            bottom: 120,
            child: SizedBox(
              height: 150,
              width: 110,
              child: RTCVideoView(_local, mirror: true),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  developer.log('Hangup button pressed', name: 'CallPage');
                  widget.call.hangup();
                },
                child: Icon(Icons.call_end),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
