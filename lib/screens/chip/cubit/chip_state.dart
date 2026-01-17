part of 'chip_cubit.dart';

@immutable
sealed class ChipState {
  const ChipState();
}

final class ChipLoading extends ChipState {
  const ChipLoading();
}

final class ChipError extends ChipState {
  final String? message;
  final String? stackTrace;
  const ChipError([this.message, this.stackTrace]);
}

final class ChipSuccess extends ChipState {
  final List sections;
  final bool loadingMore;
  final String? continuation;
  const ChipSuccess({
    required this.sections,
    required this.continuation,
    required this.loadingMore,
  });

  ChipSuccess copyWith({
    List? sections,
    String? continuation,
    bool? loadingMore,
  }) {
    return ChipSuccess(
      sections: sections ?? this.sections,
      continuation: continuation ?? this.continuation,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}
