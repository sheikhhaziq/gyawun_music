import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/equalizer_cubit.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/equalizer_state.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/loudness_cubit.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/loudness_state.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/screens/settings/widgets/setting_item.dart';
import 'package:gyawun/themes/text_styles.dart';
import 'package:gyawun/utils/adaptive_widgets/slider.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => EqualizerCubit()),
        BlocProvider(create: (_) => LoudnessCubit()),
      ],
      child: const _EqualizerView(),
    );
  }
}

class _EqualizerView extends StatelessWidget {
  const _EqualizerView();

  @override
  Widget build(BuildContext context) {
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
                value: state is EqualizerLoaded ? state.enabled : false,
                onChanged: (val) async {
                  context.read<EqualizerCubit>().toggle(val);
                },
              );
            },
          ),
          SettingEmptyTile(
            isLast: true,
            child: BlocBuilder<EqualizerCubit, EqualizerState>(
              builder: (context, state) {
                if (state is EqualizerLoaded) {
                  if (!state.enabled) {
                    return const SizedBox();
                  }
                  return SizedBox(
                    height: 250,
                    child: Row(
                      children: [
                        for (final band in state.bands)
                          Expanded(
                            child: Column(
                              children: [
                                Text(band['gain'].toStringAsFixed(1)),
                                Expanded(
                                  child: AdaptiveSlider(
                                    vertical: true,
                                    min: state.minDb,
                                    max: state.maxDb,
                                    value: band['gain'],
                                    onChanged: (val) async {
                                      context
                                          .read<EqualizerCubit>()
                                          .setBandGain(band['index'], val);
                                    },
                                  ),
                                ),
                                Text('${band['centerFrequency'].round()} Hz'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return SizedBox(
                    child: Text(
                      S.of(context).View_Equalizer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
