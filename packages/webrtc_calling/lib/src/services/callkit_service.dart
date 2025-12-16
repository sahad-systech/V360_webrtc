import 'dart:async';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();

  factory CallKitService() {
    return _instance;
  }

  CallKitService._internal();

  Function(String uuid)? onCallAccepted;
  Function(String uuid)? onCallEnded;
  Function(String uuid)? onCallMuted;
  Function(String uuid)? onCallUnMuted;

  void init() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallIncoming:
          // TODO: received an incoming call
          break;
        case Event.actionCallStart:
          // TODO: started an outgoing call
          // TODO: show screen calling in Flutter
          break;
        case Event.actionCallAccept:
          // TODO: accepted an incoming call
          // TODO: show screen calling in Flutter
          onCallAccepted?.call(event.body['id']);
          break;
        case Event.actionCallDecline:
          // TODO: declined an incoming call
          onCallEnded?.call(event.body['id']);
          break;
        case Event.actionCallEnded:
          // TODO: ended an incoming/outgoing call
          onCallEnded?.call(event.body['id']);
          break;
        case Event.actionCallTimeout:
          // TODO: missed an incoming call
          onCallEnded?.call(event.body['id']);
          break;
        case Event.actionCallCallback:
          // TODO: only Android - click action `Call back` from missed call notification
          break;
        case Event.actionCallToggleHold:
          // TODO: toggled hold status
          break;
        case Event.actionCallToggleMute:
          // TODO: toggled mute status.
          break;
        case Event.actionCallToggleDmtf:
          // TODO: toggled Dmtf status
          break;
        case Event.actionCallToggleGroup:
          // TODO: toggled group call status
          break;
        case Event.actionCallToggleAudioSession:
          // TODO: toggled audio session status
          break;

        case Event.actionDidUpdateDevicePushTokenVoip:
          // TODO: only iOS
          break;
        default:
          break;
      }
    });
  }

  Future<void> showIncomingCall({
    required String uuid,
    required String name,
    required String handle,
    bool hasVideo = false,
  }) async {
    final params = CallKitParams(
      id: uuid,
      nameCaller: name,
      appName: 'View360',
      avatar: 'https://i.pravatar.cc/100',
      handle: handle,
      type: 0, // 0 - Audio, 1 - Video
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      duration: 30000,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'https://i.pravatar.cc/500',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endCall(String uuid) async {
    await FlutterCallkitIncoming.endCall(uuid);
  }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
