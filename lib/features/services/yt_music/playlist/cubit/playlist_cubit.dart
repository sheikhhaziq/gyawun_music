import 'package:bloc/bloc.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';
import 'package:meta/meta.dart';
import 'package:ytmusic/yt_music_base.dart';

part 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  PlaylistCubit(this.ytmusic, this.lb, this.body) : super(PlaylistInitial());
  final YTMusic ytmusic;
  final LibraryManager lb;
  final Map<String, dynamic> body;

  Future<void> fetchData() async {
    try {
      emit(PlaylistLoading());
      final data = await ytmusic.getPlaylist(body: body);
      final issaved = lb.playlistExists(body['browseId']);
      emit(PlaylistSuccess(data, isSaved: issaved));
    } catch (e) {
      emit(PlaylistError(e.toString()));
    }
  }

  void toggleSavedPlaylist() {
    final currentState = state;
    if (currentState is! PlaylistSuccess || currentState.data.header == null) return;
    final isSaved = currentState.isSaved;
    final playlistId = body['browseId'];
    if (isSaved) {
      lb.deletePlaylist(playlistId);
    } else {
      final header = currentState.data.header;
      lb.createPlaylist(
        id: playlistId,
        name: header!.title,
        description: header.description,
        origin: PlaylistOrigin.remote,
        extraJson: SectionItem(
          id: body['browseId'],
          title: header.title,
          subtitle: header.subtitle,
          thumbnails: header.thumbnails,
          endpoint: body,
          radioEndpoint: header.radioEndpoint,
          shuffleEndpoint: header.shuffleEndpoint,
          provider: DataProvider.ytmusic,
          type: SectionItemType.playlist,
        ),
      );
    }
    emit(PlaylistSuccess(currentState.data, isSaved: !isSaved));
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! PlaylistSuccess) return;
    if (currentState.loadingMore) return;
    final currentData = currentState.data;

    final lastSection = currentData.sections.isNotEmpty ? currentData.sections.last : null;
    final continuation = lastSection?.continuation ?? currentData.continuation;
    if (continuation == null) return;

    emit(PlaylistSuccess(currentData, loadingMore: true));

    try {
      if (lastSection?.continuation != null && lastSection?.type == SectionType.singleColumn) {
        final nextPage = await ytmusic.getContinuationItems(
          body: body,
          continuation: lastSection!.continuation!,
        );

        final updatedSection = lastSection.copyWith(
          items: [...lastSection.items, ...nextPage.items],
          continuation: nextPage.continuation,
        );

        final updatedSections = [...currentData.sections];
        updatedSections[updatedSections.length - 1] = updatedSection;

        emit(
          PlaylistSuccess(
            Page(
              header: currentData.header,
              sections: updatedSections,
              continuation: currentData.continuation,
              provider: currentData.provider,
            ),
          ),
        );
        return;
      }

      final nextPage = await ytmusic.getPlaylistSectionContinuation(
        body: body,
        continuation: currentData.continuation!,
      );

      final updatedSections = [...currentData.sections, ...nextPage.sections];

      emit(
        PlaylistSuccess(
          Page(
            header: currentData.header,
            sections: updatedSections,
            continuation: nextPage.continuation,
            provider: currentData.provider,
          ),
        ),
      );
    } catch (e) {
      emit(PlaylistError(e.toString()));
    }
  }
}
