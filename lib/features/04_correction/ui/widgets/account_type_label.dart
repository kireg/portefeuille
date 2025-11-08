// lib/features/04_correction/ui/widgets/account_type_label.dart

import 'dart:async';
import 'package:flutter/material.dart';

// Le widget AccountTypeLabel a été extrait ici
class AccountTypeLabel extends StatefulWidget {
  final String label;
  final String description;
  final Color? backgroundColor;
  final Color? textColor;

  const AccountTypeLabel({
    super.key,
    required this.label,
    required this.description,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<AccountTypeLabel> createState() => _AccountTypeLabelState();
}

class _AccountTypeLabelState extends State<AccountTypeLabel> {
  OverlayEntry? _overlayEntry;
  final _hoverKey = GlobalKey();
  Timer? _showTimer;
  Timer? _hideTimer;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderObj = _hoverKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context);
    if (renderObj == null) return;

    final renderBox = renderObj as RenderBox;
    final target = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final left = target.dx;
        final top = target.dy - 8 - 72.0; // Essaye au-dessus
        return Positioned(
          left: left,
          top: top < 8 ? target.dy + size.height + 8 : top, // Sinon en dessous
          child: Material(
            color: Colors.transparent,
            child: MouseRegion(
              onEnter: (_) {
                _hideTimer?.cancel();
              },
              onExit: (_) {
                _hideTimer?.cancel();
                _hideTimer =
                    Timer(const Duration(milliseconds: 200), _hideOverlay);
              },
              child: Container(
                width: 260,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.24)),
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(widget.description,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hideTimer?.cancel();
        _showTimer?.cancel();
        _showTimer = Timer(const Duration(milliseconds: 120), () {
          _showOverlay();
        });
      },
      onExit: (_) {
        _showTimer?.cancel();
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(milliseconds: 200), () {
          _hideOverlay();
        });
      },
      child: Container(
        key: _hoverKey,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              Theme.of(context).colorScheme.surfaceVariant,
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
              widget.textColor ?? Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}