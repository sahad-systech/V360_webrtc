import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_helper.dart';
import 'call_page.dart';
import 'sip_config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter SIP Demo', home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SipManager sip = SipManager();

  String registerStatus = "Not registered";
  Call? currentCall;

  @override
  void initState() {
    super.initState();

    developer.log('=== HomeScreen Initialized ===', name: 'HomeScreen');

    sip.onRegister = (state) {
      developer.log('=== Registration Callback ===', name: 'HomeScreen');
      developer.log('Registration State: ${state.state}', name: 'HomeScreen');
      developer.log('Registration Cause: ${state.cause}', name: 'HomeScreen');

      setState(() {
        registerStatus = state.state.toString();
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

  void _makeCall() {
    final callTarget = "sip:1002@${SipConfig.sipDomain}";
    developer.log('=== Making Call ===', name: 'HomeScreen');
    developer.log('Call Target: $callTarget', name: 'HomeScreen');
    sip.uaHelper.call(callTarget);
  }

  void _register() {
    developer.log('=== Register Button Pressed ===', name: 'HomeScreen');
    developer.log('Using SipConfig values:', name: 'HomeScreen');
    developer.log(
      'WebSocket URL: ${SipConfig.websocketUrl}',
      name: 'HomeScreen',
    );
    developer.log('SIP URI: ${SipConfig.sipUri}', name: 'HomeScreen');
    developer.log(
      'Auth Username: ${SipConfig.sipAuthUsername}',
      name: 'HomeScreen',
    );
    developer.log('Display Name: ${SipConfig.sipUsername}', name: 'HomeScreen');

    sip.registerToSip(
      wsUrl: SipConfig.websocketUrl,
      uri: SipConfig.sipUri,
      user: SipConfig.sipAuthUsername,
      password: SipConfig.sipPassword,
      displayName: SipConfig.sipUsername,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter SIP Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("SIP Status: $registerStatus"),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _register,
                child: Text("Register to SIP"),
              ),
              SizedBox(height: 24),
              ElevatedButton(onPressed: _makeCall, child: Text("Call 1002")),
            ],
          ),
        ),
      ),
    );
  }
}
