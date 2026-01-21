import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/chip/cubit/chip_cubit.dart';
import 'package:gyawun/core/widgets/section_item.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';

class ChipPage extends StatelessWidget {
  const ChipPage({super.key, required this.title, required this.endpoint});
  final String title;
  final Map<String, dynamic> endpoint;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChipCubit(sl(), endpoint: endpoint)..fetch(),
      child: _ChipPage(title: title),
    );
  }
}

class _ChipPage extends StatelessWidget {
  const _ChipPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onConnectivityRestored: context.read<ChipCubit>().fetch,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [ExpressiveAppBar(title: title, hasLeading: true)];
          },
          body: BlocBuilder<ChipCubit, ChipState>(
            builder: (context, state) {
              switch (state) {
                case ChipLoading():
                  return Center(child: LoadingIndicatorM3E());
                case ChipError():
                  return Center(child: Text(state.message ?? ''));
                case ChipSuccess():
                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!state.loadingMore &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                        context.read<ChipCubit>().fetchNext();
                      }
                      return false;
                    },
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...state.sections.map((section) {
                              return SectionItem(section: section);
                            }),
                            if (state.loadingMore)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ExpressiveLoadingIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
