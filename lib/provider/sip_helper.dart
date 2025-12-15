import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:uuid/uuid.dart';
import '../services/callkit_service.dart';

typedef OnRegisterCallback = void Function(RegistrationState state);
typedef OnCallStateCallback = void Function(CallState state, Call call);

class SipManager extends ChangeNotifier implements SipUaHelperListener {
  final SIPUAHelper _uaHelper = SIPUAHelper();
  final CallKitService _callKitService = CallKitService();
  final Map<String, String> _sipCallIdToUuid = {};

  RegistrationState? _currentRegistrationState;
  Call? _currentCall;
  CallState? _currentCallState;

  RegistrationState? get currentRegistrationState => _currentRegistrationState;
  Call? get currentCall => _currentCall;
  CallState? get currentCallState => _currentCallState;

  SipManager() {
    _uaHelper.addSipUaHelperListener(this);
    _initCallKit();
  }

  void _initCallKit() {
    _callKitService.init();
    _callKitService.onCallAccepted = (uuid) {
      final sipCallId = _sipCallIdToUuid.entries
          .firstWhere(
            (element) => element.value == uuid,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (sipCallId.isNotEmpty &&
          _currentCall != null &&
          _currentCall!.id == sipCallId) {
        _currentCall!.answer(_uaHelper.buildCallOptions());
      }
    };
    _callKitService.onCallEnded = (uuid) {
      final sipCallId = _sipCallIdToUuid.entries
          .firstWhere(
            (element) => element.value == uuid,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (sipCallId.isNotEmpty &&
          _currentCall != null &&
          _currentCall!.id == sipCallId) {
        _currentCall!.hangup();
      }
    };
  }

  SIPUAHelper get uaHelper => _uaHelper;

  void registerToSip({
    required String wsUrl,
    required String uri,
    required String user,
    required String password,
    String? displayName,
  }) {
    developer.log('=== SIP Registration Starting ===', name: 'SipManager');
    developer.log('WebSocket URL: $wsUrl', name: 'SipManager');
    developer.log('SIP URI: $uri', name: 'SipManager');
    developer.log('User: $user', name: 'SipManager');
    developer.log('Display Name: ${displayName ?? user}', name: 'SipManager');
    developer.log(
      'Password: ${password.isNotEmpty ? "***" : "empty"}',
      name: 'SipManager',
    );

    final UaSettings settings = UaSettings();
    settings.webSocketUrl = wsUrl;
    settings.uri = uri;
    settings.authorizationUser = user;
    settings.password = password;
    settings.displayName = displayName ?? user;

    // User-Agent matching the provided REGISTER message
    settings.userAgent =
        'View360 CX 0.3.27 (SIPJS - 0.20.0) Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36';

    settings.dtmfMode = DtmfMode.RFC2833;

    // Use WS transport type (works with wss:// URLs for secure WebSocket)
    settings.transportType = TransportType.WS;

    // Contact URI expires parameter (300 seconds as shown in REGISTER)
    settings.register_expires = 300;

    developer.log(
      'Transport Type: ${settings.transportType}',
      name: 'SipManager',
    );
    developer.log('DTMF Mode: ${settings.dtmfMode}', name: 'SipManager');
    developer.log(
      'Register Expires: ${settings.register_expires}',
      name: 'SipManager',
    );
    developer.log('User-Agent: ${settings.userAgent}', name: 'SipManager');

    // WebSocket settings with extra headers
    final webSocketSettings = WebSocketSettings();
    webSocketSettings.allowBadCertificate = true;

    // Extra headers as shown in the REGISTER message
    // Allow: ACK,CANCEL,INVITE,MESSAGE,BYE,OPTIONS,INFO,NOTIFY,REFER
    // Supported: outbound, path, gruu
    webSocketSettings.extraHeaders = {
      'Allow': 'ACK,CANCEL,INVITE,MESSAGE,BYE,OPTIONS,INFO,NOTIFY,REFER',
      'Supported': 'outbound, path, gruu',
    };

    settings.webSocketSettings = webSocketSettings;

    developer.log('Allow Bad Certificate: true', name: 'SipManager');
    developer.log(
      'Extra Headers: ${webSocketSettings.extraHeaders}',
      name: 'SipManager',
    );
    developer.log('Starting UA Helper...', name: 'SipManager');

    _uaHelper.start(settings);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    developer.log('=== Registration State Changed ===', name: 'SipManager');
    developer.log('State: ${state.state}', name: 'SipManager');
    developer.log('Cause: ${state.cause}', name: 'SipManager');
    _currentRegistrationState = state;
    notifyListeners();
  }

  @override
  void callStateChanged(Call call, CallState state) {
    developer.log('=== Call State Changed ===', name: 'SipManager');
    developer.log('State: ${state.state}', name: 'SipManager');
    developer.log('Direction: ${call.direction}', name: 'SipManager');
    developer.log(
      'Remote Identity: ${call.remote_identity}',
      name: 'SipManager',
    );
    developer.log(
      'Remote Display Name: ${call.remote_display_name}',
      name: 'SipManager',
    );
    _currentCall = call;
    _currentCallState = state;

    if (state.state == CallStateEnum.CALL_INITIATION &&
        call.direction == 'INCOMING') {
      final uuid = const Uuid().v4();
      if (call.id != null) {
        _sipCallIdToUuid[call.id!] = uuid;
      }
      _callKitService.showIncomingCall(
        uuid: uuid,
        name: call.remote_display_name ?? 'Unknown',
        handle: call.remote_identity ?? 'Unknown',
      );
    } else if (state.state == CallStateEnum.ENDED ||
        state.state == CallStateEnum.FAILED) {
      if (call.id != null && _sipCallIdToUuid.containsKey(call.id)) {
        final uuid = _sipCallIdToUuid[call.id]!;
        _callKitService.endCall(uuid);
        _sipCallIdToUuid.remove(call.id);
      }
    }

    notifyListeners();
  }

  @override
  void transportStateChanged(TransportState state) {
    developer.log('=== Transport State Changed ===', name: 'SipManager');
    developer.log('State: ${state.state}', name: 'SipManager');
    notifyListeners();
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    developer.log('=== New SIP Message ===', name: 'SipManager');
    developer.log('From: ${msg.request.from}', name: 'SipManager');
    developer.log('Body: ${msg.request.body}', name: 'SipManager');
    notifyListeners();
  }

  @override
  void onNewNotify(Notify ntf) {
    developer.log('=== New Notify ===', name: 'SipManager');
    developer.log('Notify: ${ntf.toString()}', name: 'SipManager');
    notifyListeners();
  }

  @override
  void onNewReinvite(ReInvite event) {
    developer.log('=== New Re-Invite ===', name: 'SipManager');
    developer.log('ReInvite: ${event.toString()}', name: 'SipManager');
    notifyListeners();
  }
}
