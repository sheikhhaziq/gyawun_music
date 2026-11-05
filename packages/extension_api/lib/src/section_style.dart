enum SectionStyle {
  horizontal,
  vertical,
  carousel;

  /// Null or unknown values fall back to [horizontal], so a newer extension
  /// still renders in an older app.
  static SectionStyle parse(String? value) =>
      SectionStyle.values.asNameMap()[value] ?? SectionStyle.horizontal;
}
