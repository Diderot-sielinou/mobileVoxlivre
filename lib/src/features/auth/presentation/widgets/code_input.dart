import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';

/// Saisie du code à [length] chiffres (ADR-0005).
///
/// Un **seul** champ texte, invisible, porte la saisie : clavier numérique du
/// système, collage, remplissage automatique (`oneTimeCode`) et lecteurs
/// d'écran fonctionnent comme sur un champ ordinaire. Les cases ne font
/// qu'afficher. Une case qui se remplit rebondit (150 ms) ; un code refusé
/// ([rejections] qui augmente) secoue les cases (300 ms) avec une vibration
/// d'erreur. « Réduire les animations » : ni rebond ni secousse, seule la
/// couleur d'erreur reste, avec le message affiché sous les cases.
class CodeInput extends StatefulWidget {
  const CodeInput({
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.rejections = 0,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;
  final bool hasError;

  /// Nombre de codes refusés : chaque hausse déclenche la secousse.
  final int rejections;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput>
    with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(
    vsync: this,
    duration: VoxMotion.codeShake,
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _focus.addListener(_redraw);
  }

  @override
  void didUpdateWidget(CodeInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    if (widget.rejections > old.rejections) _reject();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _redraw() => setState(() {});

  String _lastText = '';

  void _onText() {
    final text = widget.controller.text;
    if (text == _lastText) return;
    if (text.length > _lastText.length) {
      HapticFeedback.selectionClick();
    }
    _lastText = text;
    setState(() {});
    if (text.length == widget.length) widget.onCompleted(text);
  }

  void _reject() {
    HapticFeedback.heavyImpact();
    widget.controller.clear();
    _focus.requestFocus();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final boxes = Row(
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: VoxSpacing.sm),
          Expanded(
            child: _CodeBox(
              digit: i < text.length ? text[i] : null,
              focused:
                  widget.enabled &&
                  _focus.hasFocus &&
                  i == math.min(text.length, widget.length - 1),
              hasError: widget.hasError,
              animate: !reduceMotion,
            ),
          ),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Secousse amortie : ±6 dp, trois allers-retours.
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Stack(
        children: [
          ExcludeSemantics(child: boxes),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: true,
                showCursor: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: InputDecoration(
                  labelText: 'Code à ${widget.length} chiffres',
                  counterText: '',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.digit,
    required this.focused,
    required this.hasError,
    required this.animate,
  });

  final String? digit;
  final bool focused;
  final bool hasError;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final borderColor = hasError
        ? colors.error
        : focused
        ? colors.accent
        : colors.border;
    final box = AnimatedContainer(
      duration: animate ? VoxMotion.tap : Duration.zero,
      constraints: const BoxConstraints(maxHeight: VoxSizes.codeBox),
      height: VoxSizes.codeBox,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(VoxRadius.chip),
        border: Border.all(
          color: borderColor,
          width: hasError || focused ? 2 : 1,
        ),
        boxShadow: focused && !hasError
            ? [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        digit ?? '',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontFeatures: VoxTypography.tabularFigures,
        ),
      ),
    );
    if (!animate || digit == null) return box;
    // Rebond à l'arrivée d'un chiffre : 1 → 1,08 → 1.
    return TweenAnimationBuilder<double>(
      key: ValueKey(digit),
      tween: Tween(begin: 0, end: 1),
      duration: VoxMotion.codeFill,
      builder: (context, t, child) => Transform.scale(
        scale: 1 + 0.08 * math.sin(t * math.pi),
        child: child,
      ),
      child: box,
    );
  }
}
