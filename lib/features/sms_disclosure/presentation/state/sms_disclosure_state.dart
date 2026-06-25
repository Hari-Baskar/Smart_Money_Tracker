class SmsDisclosureState {
  final bool isCheckboxChecked;
  final bool hasConsented;
  final bool isLoading;
  final bool isRejecting;

  const SmsDisclosureState({
    this.isCheckboxChecked = false,
    this.hasConsented = false,
    this.isLoading = false,
    this.isRejecting = false,
  });

  SmsDisclosureState copyWith({
    bool? isCheckboxChecked,
    bool? hasConsented,
    bool? isLoading,
    bool? isRejecting,
  }) {
    return SmsDisclosureState(
      isCheckboxChecked: isCheckboxChecked ?? this.isCheckboxChecked,
      hasConsented: hasConsented ?? this.hasConsented,
      isLoading: isLoading ?? this.isLoading,
      isRejecting: isRejecting ?? this.isRejecting,
    );
  }
}
