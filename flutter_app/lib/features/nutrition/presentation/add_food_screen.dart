import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:noop/core/data/nutrition/ai_food_client.dart';
import 'package:noop/core/data/nutrition/off_client.dart';
import 'package:noop/features/nutrition/state/nutrition.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

enum _Mode { search, manual, photo }

/// Add-food flow: search Open Food Facts, enter a food manually, or estimate it
/// from a photo with the AI (bring-your-own-key). Everything logs into the local
/// nutrition store under the selected day + meal.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  _Mode _mode = _Mode.search;
  MealType _meal = MealType.breakfast;

  int get _nowMicros => DateTime.now().microsecondsSinceEpoch;
  String get _day => ref.read(selectedIsoDayProvider);

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Add food',
      glow: Palette.effortColor,
      children: [
        NoopSegmented<MealType>(
          expand: true,
          value: _meal,
          onChanged: (m) => setState(() => _meal = m),
          segments: [for (final m in MealType.values) NoopSegment(m, m.label)],
        ),
        const SizedBox(height: Metrics.space12),
        NoopSegmented<_Mode>(
          expand: true,
          value: _mode,
          onChanged: (m) => setState(() => _mode = m),
          segments: const [
            NoopSegment(_Mode.search, 'Search'),
            NoopSegment(_Mode.manual, 'Manual'),
            NoopSegment(_Mode.photo, 'Photo'),
          ],
        ),
        const SizedBox(height: Metrics.space16),
        switch (_mode) {
          _Mode.search => _SearchTab(onPick: _logProduct),
          _Mode.manual => _ManualTab(onSubmit: _logManual),
          _Mode.photo => _PhotoTab(onEstimate: _logEstimate),
        },
      ],
    );
  }

  Future<void> _logProduct(OffProduct p, double grams) async {
    await ref
        .read(nutritionServiceProvider)
        .logProduct(_day, _meal, p, grams, nowMicros: _nowMicros);
    if (mounted) {
      noopToast(context, 'Added ${p.name}', kind: ToastKind.success);
      Navigator.of(context).pop();
    }
  }

  Future<void> _logManual(
      String name, double grams, double kcal, double p, double c, double f) async {
    await ref.read(nutritionServiceProvider).logManual(
          _day,
          _meal,
          name: name,
          grams: grams,
          kcal: kcal,
          protein: p,
          carbs: c,
          fat: f,
          nowMicros: _nowMicros,
        );
    if (mounted) {
      noopToast(context, 'Added $name', kind: ToastKind.success);
      Navigator.of(context).pop();
    }
  }

  Future<void> _logEstimate(AiFoodEstimate est) async {
    await ref
        .read(nutritionServiceProvider)
        .logAiEstimate(_day, _meal, est, nowMicros: _nowMicros);
    if (mounted) {
      noopToast(context, 'Added ${est.items.length} items',
          kind: ToastKind.success);
      Navigator.of(context).pop();
    }
  }
}

// ── Search (Open Food Facts) ─────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  final void Function(OffProduct, double grams) onPick;
  const _SearchTab({required this.onPick});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<OffProduct> _results = const [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await OffClient.searchByName(q);
      if (mounted) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'Search failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          controller: _ctrl,
          hint: 'Search a food (or paste a barcode)',
          onSubmitted: (_) => _run(),
        ),
        const SizedBox(height: Metrics.space10),
        NoopButton('Search', icon: Icons.search_rounded, onPressed: _run),
        const SizedBox(height: Metrics.space16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_error != null)
          Text(_error!, style: NoopType.body.copyWith(color: Palette.statusCritical))
        else
          for (final p in _results)
            _ProductRow(product: p, onTap: () => _askGrams(context, p)),
      ],
    );
  }

  Future<void> _askGrams(BuildContext context, OffProduct p) async {
    final grams = await _gramsSheet(context, p);
    if (grams != null) widget.onPick(p, grams);
  }
}

class _ProductRow extends StatelessWidget {
  final OffProduct product;
  final VoidCallback onTap;
  const _ProductRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kcal = product.kcal100;
    return NoopCard(
      padding: const EdgeInsets.all(Metrics.space12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NoopType.body.copyWith(color: Palette.textPrimary)),
                Text(
                    [
                      if (product.brand != null) product.brand!,
                      if (kcal != null) '${kcal.round()} kcal/100g',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        NoopType.caption.copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          Icon(Icons.add_circle_outline_rounded,
              color: Palette.effortColor, size: 22),
        ],
      ),
    );
  }
}

// ── Manual entry ─────────────────────────────────────────────────────────────

class _ManualTab extends StatefulWidget {
  final void Function(String name, double grams, double kcal, double p, double c,
      double f) onSubmit;
  const _ManualTab({required this.onSubmit});

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _name = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _grams, _kcal, _p, _c, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(controller: _name, hint: 'Food name'),
        const SizedBox(height: Metrics.space10),
        Row(children: [
          Expanded(
              child: _Field(
                  controller: _grams, hint: 'Grams', number: true)),
          const SizedBox(width: Metrics.space10),
          Expanded(
              child: _Field(controller: _kcal, hint: 'kcal', number: true)),
        ]),
        const SizedBox(height: Metrics.space10),
        Row(children: [
          Expanded(child: _Field(controller: _p, hint: 'Protein g', number: true)),
          const SizedBox(width: Metrics.space10),
          Expanded(child: _Field(controller: _c, hint: 'Carbs g', number: true)),
          const SizedBox(width: Metrics.space10),
          Expanded(child: _Field(controller: _f, hint: 'Fat g', number: true)),
        ]),
        const SizedBox(height: Metrics.space16),
        NoopButton('Add', icon: Icons.check_rounded, onPressed: () {
          final name = _name.text.trim();
          if (name.isEmpty) return;
          widget.onSubmit(
              name, _d(_grams), _d(_kcal), _d(_p), _d(_c), _d(_f));
        }),
      ],
    );
  }
}

// ── AI photo ─────────────────────────────────────────────────────────────────

class _PhotoTab extends StatefulWidget {
  final void Function(AiFoodEstimate) onEstimate;
  const _PhotoTab({required this.onEstimate});

  @override
  State<_PhotoTab> createState() => _PhotoTabState();
}

class _PhotoTabState extends State<_PhotoTab> {
  bool _loading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 70,
      );
      if (file == null) {
        setState(() => _loading = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final est = await AiFoodClient.estimate(bytes);
      if (mounted) widget.onEstimate(est);
    } on AiFoodException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not read that image.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Snap or pick a photo of your meal — the AI estimates calories and '
          'macros. Uses your own API key (Settings → AI estimator).',
          style: NoopType.body.copyWith(color: Palette.textSecondary),
        ),
        const SizedBox(height: Metrics.space16),
        if (_loading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()))
        else ...[
          NoopButton('Take photo',
              icon: Icons.photo_camera_rounded,
              onPressed: () => _pick(ImageSource.camera)),
          const SizedBox(height: Metrics.space10),
          NoopButton('Choose from library',
              icon: Icons.photo_library_rounded,
              onPressed: () => _pick(ImageSource.gallery)),
        ],
        if (_error != null) ...[
          const SizedBox(height: Metrics.space12),
          Text(_error!,
              style: NoopType.body.copyWith(color: Palette.statusCritical)),
        ],
      ],
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────────────

/// A grams-amount bottom sheet; returns the chosen grams or null on cancel.
Future<double?> _gramsSheet(BuildContext context, OffProduct p) {
  final ctrl = TextEditingController(
      text: (p.servingGrams ?? 100).round().toString());
  return showNoopSheet<double>(
    context,
    title: p.name,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
          Metrics.space20, 0, Metrics.space20, Metrics.space20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(controller: ctrl, hint: 'Grams', number: true),
          const SizedBox(height: Metrics.space16),
          NoopButton('Add', onPressed: () {
            final g = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
            Navigator.of(context).pop(g == null || g <= 0 ? null : g);
          }),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool number;
  final ValueChanged<String>? onSubmitted;
  const _Field({
    required this.controller,
    required this.hint,
    this.number = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: NoopType.body.copyWith(color: Palette.textPrimary),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Palette.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Metrics.cornerCard),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
