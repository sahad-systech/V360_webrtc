import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_manager.dart';
import 'call_middle_section.dart';

class DialPad extends StatefulWidget {
  final bool isDarkMode;

  const DialPad({super.key, required this.isDarkMode});

  @override
  State<DialPad> createState() => _DialPadState();
}

class _DialPadState extends State<DialPad> {
  String _dialedNumber = '';
  SipManager? _sipManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sipManager ??= Provider.of<SipManager>(context);
  }

  void _handleCall() {
    if (_dialedNumber.isNotEmpty && _sipManager != null) {
      // Initiate the call
      _sipManager!.uaHelper.call(_dialedNumber);

      // Wait a brief moment for the call to be created, then navigate
      // Note: In a production app you might want to wait for a specific state change
      // or callback from the sip helper instead of a fixed delay.
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final call = _sipManager!.currentCall;
        if (call != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallMiddleSectionPage(
                call: call,
                helper: _sipManager!.uaHelper,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDialpadGrid(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70), // Spacer for alignment
              _buildCallButton(),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialpadGrid() {
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialpadButton(String number, String letters) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
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
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isDarkMode
                        ? Colors.white.withValues(alpha: 0.5)
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
            color: const Color(0xFF11998e).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleCall,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.call_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
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
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            size: 28,
          ),
        ),
      ),
    );
  }
}
