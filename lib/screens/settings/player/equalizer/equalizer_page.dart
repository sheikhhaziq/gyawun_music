import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/equalizer_cubit.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/equalizer_state.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/loudness_cubit.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/loudness_state.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/screens/settings/widgets/setting_item.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/themes/text_styles.dart';
import 'package:gyawun/utils/adaptive_widgets/slider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key});

  Future<Widget> _build(BuildContext context) async {
    final settings = GetIt.I<SettingsManager>();
    final androidEq = GetIt.I<AndroidEqualizer>();
    final params = await androidEq.parameters;

    final eqCubit = EqualizerCubit(
      enabled: settings.equalizerEnabled,
      minDb: params.minDecibels,
      maxDb: params.maxDecibels,
      bands: params.bands
          .map(
            (b) => EqBand(
              index: b.index,
              centerFrequency: b.centerFrequency,
              gain: b.gain,
            ),
          )
          .toList(),
    );

    final loudnessCubit = LoudnessCubit(
      enabled: settings.loudnessEnabled,
      targetGain: settings.loudnessTargetGain,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: eqCubit),
        BlocProvider.value(value: loudnessCubit),
      ],
      child: const _EqualizerView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _build(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: ExpressiveLoadingIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}

class _EqualizerView extends StatelessWidget {
  const _EqualizerView();

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = GetIt.I<MediaPlayer>();
    final settings = GetIt.I<SettingsManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).Loudness_And_Equalizer,
          style: mediumTextStyle(context, bold: false),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          /// LOUDNESS
          GroupTitle(title: "Loudness"),
          BlocBuilder<LoudnessCubit, LoudnessState>(
            builder: (context, state) {
              return SettingSwitchTile(
                leading: const Icon(Icons.volume_up),
                title: S.of(context).Loudness_Enhancer,
                isFirst: true,
                value: state.enabled,
                onChanged: (val) async {
                  context.read<LoudnessCubit>().toggle(val);
                  await mediaPlayer.setLoudnessEnabled(val);
                },
              );
            },
          ),
          SettingEmptyTile(
            isLast: true,
            child: BlocBuilder<LoudnessCubit, LoudnessState>(
              builder: (context, state) {
                return Slider(
                  min: -1,
                  max: 1,
                  value: state.targetGain,
                  onChanged: state.enabled
                      ? (val) async {
                          context.read<LoudnessCubit>().setTargetGain(val);
                          await mediaPlayer.setLoudnessTargetGain(val);
                        }
                      : null,
                );
              },
            ),
          ),

          /// EQUALIZER
          GroupTitle(title: "Equalizer"),
          BlocBuilder<EqualizerCubit, EqualizerState>(
            builder: (context, state) {
              return SettingSwitchTile(
                leading: const Icon(Icons.equalizer),
                title: S.of(context).Enable_Equalizer,
                isFirst: true,
                value: state.enabled,
                onChanged: (val) async {
                  context.read<EqualizerCubit>().toggle(val);
                  await mediaPlayer.setEqualizerEnabled(val);
                },
              );
            },
          ),
          SettingEmptyTile(
            isLast: true,
            child: BlocBuilder<EqualizerCubit, EqualizerState>(
              builder: (context, state) {
                if (!state.enabled) return const SizedBox();

                return SizedBox(
                  height: 250,
                  child: Row(
                    children: [
                      for (final band in state.bands)
                        Expanded(
                          child: Column(
                            children: [
                              Text(band.gain.toStringAsFixed(1)),
                              Expanded(
                                child: AdaptiveSlider(
                                  vertical: true,
                                  min: state.minDb,
                                  max: state.maxDb,
                                  value: band.gain,
                                  onChanged: (val) async {
                                    context
                                        .read<EqualizerCubit>()
                                        .setBandGain(band.index, val);

                                    await settings.setEqualizerBandsGain(
                                        band.index, val);

                                    final params =
                                        await GetIt.I<AndroidEqualizer>()
                                            .parameters;
                                    await params.bands[band.index].setGain(val);
                                  },
                                ),
                              ),
                              Text('${band.centerFrequency.round()} Hz'),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
