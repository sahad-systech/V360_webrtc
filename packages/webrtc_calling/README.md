# WebRTC Calling Package

A reusable Flutter package for WebRTC calling features including SIP registration, call management, dialpad UI, and native CallKit integration for iOS and Android.

## Features

- 🎯 **SIP Registration & Management** - Complete SIP UA implementation with WebSocket support
- 📞 **Native CallKit Integration** - iOS CallKit and Android ConnectionService support  
- 🎨 **Beautiful UI Components** - Pre-built dialpad, call screen, and call controls
- 🔊 **Audio Controls** - Mute, hold, speaker, and DTMF support
- 📱 **Incoming/Outgoing Calls** - Full bidirectional call support
- 🎥 **WebRTC Support** - Built on flutter_webrtc for media handling
- ⚡ **No State Management Dependencies** - Uses callback-based architecture

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  webrtc_calling:
    path: packages/webrtc_calling
```

Then run:

```bash
flutter pub get
```

## Dependencies

This package requires the following dependencies (automatically included):

- `flutter_webrtc: ^1.2.1` - WebRTC implementation
- `sip_ua` - SIP User Agent library
- `flutter_callkit_incoming: ^3.0.0` - Native call UI
- `uuid: ^4.5.2` - UUID generation

**Note:** This package does NOT use Provider or any other state management library. It uses a simple callback-based approach.

## Setup

### 1. Create SipManager Instance

In your app, create and manage a `SipManager` instance:

```dart
import 'package:webrtc_calling/webrtc_calling.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SipManager sipManager;

  @override
  void initState() {
    super.initState();
    sipManager = SipManager();
    
    // Set up callbacks
    sipManager.onRegistrationStateChanged = (state) {
      print('Registration state: ${state.state}');
      // Update UI or handle state change
    };
    
    sipManager.onCallStateChanged = (callState, call) {
      print('Call state: ${callState.state}');
      // Handle call state changes, navigate to call screen, etc.
    };
    
    sipManager.onTransportStateChanged = (state) {
      print('Transport state: ${state.state}');
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(sipManager: sipManager),
    );
  }
}
```

### 2. Register to SIP Server

Use the `SipManager` to register to your SIP server:

```dart
sipManager.registerToSip(
  wsUrl: 'wss://your-sip-server.com:7443',
  uri: 'sip:1000@your-sip-server.com',
  user: '1000',
  password: 'your-password',
  displayName: 'John Doe', // Optional
);
```

### 3. Monitor State Changes

Use the callbacks to monitor state changes:

```dart
// In your widget
sipManager.onRegistrationStateChanged = (state) {
  if (state.state == RegistrationStateEnum.REGISTERED) {
    setState(() {
      // Update UI to show registered status
    });
  }
};

sipManager.onCallStateChanged = (callState, call) {
  if (callState.state == CallStateEnum.CALL_INITIATION) {
    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          call: call,
          helper: sipManager.uaHelper,
          sipManager: sipManager,
        ),
      ),
    );
  }
};
```

## Usage

### Dialpad Widget

Display a dialpad for making calls:

```dart
import 'package:webrtc_calling/webrtc_calling.dart';

class MyDialpadScreen extends StatelessWidget {
  final SipManager sipManager;

  const MyDialpadScreen({required this.sipManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dialpad')),
      body: Center(
        child: DialPad(
          isDarkMode: false,
          sipManager: sipManager,
        ),
      ),
    );
  }
}
```

**Properties:**
- `isDarkMode` (bool, required) - Enable dark mode styling
- `sipManager` (SipManager, required) - The SipManager instance

### Call Page

Navigate to the call page when a call is active:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CallPage(
      call: call,
      helper: sipManager.uaHelper,
      sipManager: sipManager,
    ),
  ),
);
```

**Properties:**
- `call` (Call, required) - The active call object
- `helper` (SIPUAHelper, required) - The SIP UA helper
- `sipManager` (SipManager, required) - The SipManager instance

### Making Outgoing Calls

```dart
// Make a call
sipManager.uaHelper.call('sip:2000@your-sip-server.com');
```

### Handling Incoming Calls

Incoming calls are automatically handled by the `CallKitService`. Set up your callback to navigate to the call screen:

```dart
sipManager.onCallStateChanged = (callState, call) {
  if (callState.state == CallStateEnum.CALL_INITIATION &&
      call.direction == Direction.incoming) {
    // Show incoming call UI or navigate to call screen
  }
};
```

### Call Controls

The package provides built-in call controls:

- **Mute/Unmute** - Toggle microphone
- **Hold/Resume** - Put call on hold
- **Speaker** - Toggle speakerphone
- **Hangup** - End the call
- **DTMF** - Send DTMF tones during call

### Monitoring Call State

```dart
sipManager.onCallStateChanged = (callState, call) {
  switch (callState.state) {
    case CallStateEnum.STREAM:
      print('Call Connected');
      break;
    case CallStateEnum.PROGRESS:
      print('Ringing...');
      break;
    case CallStateEnum.ENDED:
      print('Call Ended');
      break;
    default:
      break;
  }
};
```

## Advanced Usage

### Callback Functions

The `SipManager` provides three callback functions:

```dart
// Called when SIP registration state changes
sipManager.onRegistrationStateChanged = (RegistrationState state) {
  // Handle registration state
};

// Called when call state changes
sipManager.onCallStateChanged = (CallState callState, Call call) {
  // Handle call state
};

// Called when transport state changes
sipManager.onTransportStateChanged = (TransportState state) {
  // Handle transport state
};
```

### SIP Configuration Options

The `registerToSip` method supports various configuration options:

```dart
sipManager.registerToSip(
  wsUrl: 'wss://your-sip-server.com:7443',
  uri: 'sip:1000@your-sip-server.com',
  user: '1000',
  password: 'your-password',
  displayName: 'John Doe',
);
```

**Default Settings:**
- Transport: WebSocket (WS/WSS)
- DTMF Mode: RFC2833
- Registration Expires: 300 seconds
- User-Agent: Custom View360 user agent string
- Extra Headers: Allow, Supported
- Bad Certificate: Allowed (for development)

### Accessing the SIP Helper

For advanced SIP operations, access the underlying `SIPUAHelper`:

```dart
final uaHelper = sipManager.uaHelper;

// Make a call with custom options
uaHelper.call(
  'sip:2000@your-sip-server.com',
  uaHelper.buildCallOptions(),
);

// Send DTMF
final call = sipManager.currentCall;
call?.sendDTMF('1');

// Answer incoming call
call?.answer(uaHelper.buildCallOptions());

// Hangup
call?.hangup();

// Hold/Unhold
call?.hold();
call?.unhold();

// Mute/Unmute
call?.mute(true);  // Mute
call?.mute(false); // Unmute
```

## UI Components

### DialPad

A fully functional dialpad with:
- Number input display
- 0-9, *, # buttons
- Call button with gradient styling
- Backspace button (long press to clear)
- Light/Dark mode support

### CallPage

A complete call screen with:
- Remote video renderer
- Local video renderer (picture-in-picture)
- Call timer
- Caller information display
- Call control buttons (mute, hold, speaker, hangup)
- Call state indicators

### CallMiddleSectionPage

An intermediate call screen shown during call setup:
- Call state display (Calling, Ringing, etc.)
- Caller information
- Accept/Decline buttons for incoming calls
- Hangup button for outgoing calls
- Call timer

## Call States

The package handles the following call states:

- `NONE` - No active call
- `CALL_INITIATION` - Call is being initiated
- `PROGRESS` - Call is ringing
- `STREAM` - Call is connected and streaming
- `MUTED` - Call is muted
- `UNMUTED` - Call is unmuted
- `HOLD` - Call is on hold
- `UNHOLD` - Call is resumed
- `ENDED` - Call has ended
- `FAILED` - Call failed
- `REFER` - Call is being transferred

## Registration States

Monitor SIP registration with these states:

- `NONE` - Not registered
- `REGISTRATION_FAILED` - Registration failed
- `REGISTERED` - Successfully registered
- `UNREGISTERED` - Unregistered

## Platform-Specific Setup

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone for calls</string>
<key>NSCameraUsageDescription</key>
<string>This app needs access to the camera for video calls</string>
```

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## Example

Here's a complete example of a simple calling app:

```dart
import 'package:flutter/material.dart';
import 'package:webrtc_calling/webrtc_calling.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SipManager sipManager;

  @override
  void initState() {
    super.initState();
    sipManager = SipManager();
    
    // Set up callbacks
    sipManager.onRegistrationStateChanged = (state) {
      setState(() {
        // Update UI based on registration state
      });
    };
    
    sipManager.onCallStateChanged = (callState, call) {
      // Handle call state changes
      if (callState.state == CallStateEnum.CALL_INITIATION) {
        // Navigate to call screen
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC Calling Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(sipManager: sipManager),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final SipManager sipManager;

  const HomeScreen({required this.sipManager});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerSip();
    
    // Listen to registration state
    widget.sipManager.onRegistrationStateChanged = (state) {
      setState(() {
        isRegistered = state.state == RegistrationStateEnum.REGISTERED;
      });
    };
  }

  void _registerSip() {
    widget.sipManager.registerToSip(
      wsUrl: 'wss://your-sip-server.com:7443',
      uri: 'sip:1000@your-sip-server.com',
      user: '1000',
      password: 'your-password',
      displayName: 'John Doe',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebRTC Calling'),
        actions: [
          Icon(
            isRegistered ? Icons.check_circle : Icons.error,
            color: isRegistered ? Colors.green : Colors.red,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: DialPad(
          isDarkMode: false,
          sipManager: widget.sipManager,
        ),
      ),
    );
  }
}
```

## Troubleshooting

### Registration Issues

1. **Check WebSocket URL** - Ensure your WebSocket URL is correct and accessible
2. **Verify Credentials** - Double-check SIP username and password
3. **Network Connectivity** - Ensure device has internet connection
4. **Firewall/NAT** - Check if your network allows WebSocket connections

### Call Issues

1. **No Audio** - Check microphone permissions
2. **One-Way Audio** - Verify NAT/firewall settings and STUN/TURN servers
3. **Call Drops** - Check network stability and WebSocket connection

### Debug Logging

The package includes comprehensive logging. Check your console for detailed logs:

```
=== SIP Registration Starting ===
=== Registration State Changed ===
=== Call State Changed ===
=== Transport State Changed ===
```

## API Reference

### SipManager

Main class for managing SIP operations.

**Properties:**
- `currentRegistrationState` - Current SIP registration state
- `currentCall` - Active call object
- `currentCallState` - Current call state
- `uaHelper` - Access to underlying SIPUAHelper

**Callbacks:**
- `onRegistrationStateChanged` - Called when registration state changes
- `onCallStateChanged` - Called when call state changes
- `onTransportStateChanged` - Called when transport state changes

**Methods:**
- `registerToSip()` - Register to SIP server

### CallKitService

Manages native call UI integration.

**Methods:**
- `init()` - Initialize CallKit service
- `showIncomingCall()` - Display incoming call UI
- `endCall()` - End a specific call
- `endAllCalls()` - End all active calls

**Callbacks:**
- `onCallAccepted` - Called when user accepts a call
- `onCallEnded` - Called when user ends a call

## Migration from Provider

If you're migrating from a version that used Provider:

1. **Remove Provider dependency** from your app's `pubspec.yaml`
2. **Create SipManager instance** in your app state instead of using Provider
3. **Pass SipManager** to widgets that need it as a parameter
4. **Use callbacks** instead of `Consumer` or `Provider.of` to listen to state changes

## Contributing

This is a local package. To contribute:

1. Make changes in `packages/webrtc_calling`
2. Test thoroughly in the main app
3. Update this README if adding new features

## License

This package is part of the View360 project and is for internal use only.

## Support

For issues or questions, please contact the development team.

---

**Version:** 0.0.1  
**Last Updated:** December 2025
