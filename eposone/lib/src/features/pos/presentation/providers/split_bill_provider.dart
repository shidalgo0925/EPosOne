import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';

enum SplitMode { none, byItems, equalParts }

class SplitBillState {
  final SplitMode mode;
  final Set<String> selectedItemIds;
  final List<CartItem>? equalSplitSnapshot;
  final int equalTotalParts;
  final int equalCurrentPart;
  final String? groupId;

  const SplitBillState({
    this.mode = SplitMode.none,
    this.selectedItemIds = const {},
    this.equalSplitSnapshot,
    this.equalTotalParts = 0,
    this.equalCurrentPart = 0,
    this.groupId,
  });

  bool get isActive => mode != SplitMode.none;

  bool get isEqualSplit => mode == SplitMode.equalParts && equalTotalParts > 0;

  SplitBillState copyWith({
    SplitMode? mode,
    Set<String>? selectedItemIds,
    List<CartItem>? equalSplitSnapshot,
    bool clearEqualSnapshot = false,
    int? equalTotalParts,
    int? equalCurrentPart,
    String? groupId,
    bool clearGroupId = false,
  }) =>
      SplitBillState(
        mode: mode ?? this.mode,
        selectedItemIds: selectedItemIds ?? this.selectedItemIds,
        equalSplitSnapshot: clearEqualSnapshot ? null : (equalSplitSnapshot ?? this.equalSplitSnapshot),
        equalTotalParts: equalTotalParts ?? this.equalTotalParts,
        equalCurrentPart: equalCurrentPart ?? this.equalCurrentPart,
        groupId: clearGroupId ? null : (groupId ?? this.groupId),
      );
}

class SplitBillNotifier extends StateNotifier<SplitBillState> {
  SplitBillNotifier() : super(const SplitBillState());

  void reset() => state = const SplitBillState();

  void setSelectedItems(Set<String> ids) {
    state = SplitBillState(
      mode: SplitMode.byItems,
      selectedItemIds: ids,
    );
  }

  void startEqualSplit(List<CartItem> items, int parts) {
    state = SplitBillState(
      mode: SplitMode.equalParts,
      equalSplitSnapshot: items.map((i) => i.copyWith()).toList(),
      equalTotalParts: parts,
      equalCurrentPart: 1,
      groupId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  void advanceEqualPart() {
    if (!state.isEqualSplit) return;
    if (state.equalCurrentPart >= state.equalTotalParts) {
      reset();
      return;
    }
    state = state.copyWith(equalCurrentPart: state.equalCurrentPart + 1);
  }

  void finishEqualSplit() => reset();
}

final splitBillProvider = StateNotifierProvider<SplitBillNotifier, SplitBillState>((ref) {
  return SplitBillNotifier();
});

/// Ítems correspondientes a una parte de división igualitaria.
List<CartItem> equalSplitPartItems(List<CartItem> items, int partIndex, int totalParts) {
  return items
      .map((item) {
        final perPart = item.quantity / totalParts;
        final qty = partIndex == totalParts
            ? item.quantity - perPart * (totalParts - 1)
            : perPart;
        return item.copyWith(quantity: double.parse(qty.toStringAsFixed(4)));
      })
      .where((i) => i.quantity > 0.0001)
      .toList();
}