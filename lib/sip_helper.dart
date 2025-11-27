import 'dart:developer' as developer;
import 'package:sip_ua/sip_ua.dart';

typedef OnRegisterCallback = void Function(RegistrationState state);
typedef OnCallStateCallback = void Function(CallState state, Call call);

class SipManager implements SipUaHelperListener {
  final SIPUAHelper _uaHelper = SIPUAHelper();

  OnRegisterCallback? onRegister;
  OnCallStateCallback? onCallState;
  RegistrationState? currentRegistrationState;

  SipManager() {
    _uaHelper.addSipUaHelperListener(this);
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
    currentRegistrationState = state;
    onRegister?.call(state);
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
    onCallState?.call(state, call);
  }

  @override
  void transportStateChanged(TransportState state) {
    developer.log('=== Transport State Changed ===', name: 'SipManager');
    developer.log('State: ${state.state}', name: 'SipManager');
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    developer.log('=== New SIP Message ===', name: 'SipManager');
    developer.log('From: ${msg.request.from}', name: 'SipManager');
    developer.log('Body: ${msg.request.body}', name: 'SipManager');
  }

  @override
  void onNewNotify(Notify ntf) {
    developer.log('=== New Notify ===', name: 'SipManager');
    developer.log('Notify: ${ntf.toString()}', name: 'SipManager');
  }

  @override
  void onNewReinvite(ReInvite event) {
    developer.log('=== New Re-Invite ===', name: 'SipManager');
    developer.log('ReInvite: ${event.toString()}', name: 'SipManager');
  }
}
