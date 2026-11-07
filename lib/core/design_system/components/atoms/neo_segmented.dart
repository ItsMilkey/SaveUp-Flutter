import 'package:flutter/material.dart';

/// Selector segmentado neo-brutalista.
class NeoSegmented<T> extends StatelessWidget {
  const NeoSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: <ButtonSegment<T>>[
        for (int i = 0; i < values.length; i++)
          ButtonSegment<T>(value: values[i], label: Text(labels[i])),
      ],
      selected: <T>{selected},
      onSelectionChanged: (Set<T> selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
    );
  }
}
