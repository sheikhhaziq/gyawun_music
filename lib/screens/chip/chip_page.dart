import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/chip/cubit/chip_cubit.dart';
import 'package:gyawun/core/widgets/section_item.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';

class ChipPage extends StatelessWidget {
  const ChipPage({
    super.key,
    required this.title,
    required this.endpoint,
  });
  final String title;
  final Map<String, dynamic> endpoint;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChipCubit(sl(), endpoint: endpoint)..fetch(),
      child: _ChipPage(
        title: title,
      ),
    );
  }
}

class _ChipPage extends StatefulWidget {
  const _ChipPage({required this.title});

  final String title;

  @override
  State<_ChipPage> createState() => _ChipPageState();
}

class _ChipPageState extends State<_ChipPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await context.read<ChipCubit>().fetchNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onConnectivityRestored: context.read<ChipCubit>().fetch,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: BlocBuilder<ChipCubit, ChipState>(
          builder: (context, state) {
            switch (state) {
              case ChipLoading():
                return Center(
                  child: LoadingIndicatorM3E(),
                );
              case ChipError():
                return Center(
                  child: Text(state.message ?? ''),
                );
              case ChipSuccess():
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: SafeArea(
                      child: Column(
                    children: [
                      ...state.sections.map((section) {
                        return SectionItem(section: section);
                      }),
                      if (state.loadingMore)
                        const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ExpressiveLoadingIndicator()),
                    ],
                  )),
                );
            }
          },
        ),
      ),
    );
  }
}
