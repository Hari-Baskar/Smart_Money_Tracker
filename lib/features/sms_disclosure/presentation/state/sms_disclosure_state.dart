class SmsDisclosureState {
  final bool isCheckboxChecked;
  final bool hasConsented;
  final bool isLoading;

  const SmsDisclosureState({
    this.isCheckboxChecked = false,
    this.hasConsented = false,
    this.isLoading = false,
  });

  SmsDisclosureState copyWith({
    bool? isCheckboxChecked,
    bool? hasConsented,
    bool? isLoading,
  }) {
    return SmsDisclosureState(
      isCheckboxChecked: isCheckboxChecked ?? this.isCheckboxChecked,
      hasConsented: hasConsented ?? this.hasConsented,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
