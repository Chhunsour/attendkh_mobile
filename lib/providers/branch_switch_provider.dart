import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BranchSwitchState {
  final int? activeBranchId;
  final String? activeBranchName;
  final bool isSwitching;

  const BranchSwitchState({
    this.activeBranchId,
    this.activeBranchName,
    this.isSwitching = false,
  });

  bool get isActive => activeBranchId != null;

  BranchSwitchState copyWith({
    int? activeBranchId,
    String? activeBranchName,
    bool? isSwitching,
    bool clearBranch = false,
  }) {
    return BranchSwitchState(
      activeBranchId: clearBranch ? null : (activeBranchId ?? this.activeBranchId),
      activeBranchName: clearBranch ? null : (activeBranchName ?? this.activeBranchName),
      isSwitching: isSwitching ?? this.isSwitching,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BranchSwitchNotifier extends StateNotifier<BranchSwitchState> {
  BranchSwitchNotifier() : super(const BranchSwitchState());

  /// Switch to a branch view. Shows loading state for at least 1.5 seconds
  /// for a premium transition feel.
  Future<void> switchToBranch(BranchData branch) async {
    state = state.copyWith(isSwitching: true);

    // Enforce minimum 1.5 second loading for premium UX
    await Future.delayed(const Duration(milliseconds: 1500));

    state = BranchSwitchState(
      activeBranchId: branch.id,
      activeBranchName: branch.name,
      isSwitching: false,
    );
  }

  /// Exit branch view and return to owner's company-wide perspective.
  void exitBranchView() {
    state = const BranchSwitchState();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final branchSwitchProvider = StateNotifierProvider<BranchSwitchNotifier, BranchSwitchState>((ref) {
  return BranchSwitchNotifier();
});
