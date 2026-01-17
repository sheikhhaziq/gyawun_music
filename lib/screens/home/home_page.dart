import 'dart:io';

import 'package:expressive_refresh/expressive_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/home/cubit/home_cubit.dart';
import 'package:gyawun/core/widgets/section_item.dart';
import 'package:gyawun/utils/internet_guard.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';

import '../../generated/l10n.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(sl())..fetch(),
      child: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await context.read<HomeCubit>().fetchNext();
    }
  }

  // Future<void> refresh() async {
  //   if (initialLoading) return;
  //   Map<String, dynamic> home = await ytMusic.browse();
  //   if (mounted) {
  //     setState(() {
  //       initialLoading = false;
  //       nextLoading = false;
  //       chips = home['chips'] ?? [];
  //       sections = home['sections'];
  //       continuation = home['continuation'];
  //     });
  //   }
  // }

  Widget _horizontalChipsRow(List data) {
    var list = <Widget>[const SizedBox(width: 16)];
    for (var element in data) {
      list.add(
        AdaptiveInkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go('/chip', extra: element),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10)),
            child: Text(element['title']),
          ),
        ),
      );
      list.add(const SizedBox(
        width: 8,
      ));
    }
    list.add(const SizedBox(
      width: 8,
    ));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onInternetRestored: context.read<HomeCubit>().fetch,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: AppBar().preferredSize,
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Material(
              color: Colors.transparent,
              child: LayoutBuilder(builder: (context, constraints) {
                return Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth > 400
                              ? (400)
                              : constraints.maxWidth),
                      child: AdaptiveTextField(
                        onTap: () => context.go('/search'),
                        readOnly: true,
                        keyboardType: TextInputType.text,
                        maxLines: 1,
                        autofocus: false,
                        textInputAction: TextInputAction.search,
                        fillColor: Platform.isWindows
                            ? null
                            : Colors.grey.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 8),
                        borderRadius: BorderRadius.circular(
                            Platform.isWindows ? 4.0 : 35),
                        hintText: S.of(context).Search_Gyawun,
                        prefix: Icon(AdaptiveIcons.search),
                      ),
                    ),
                  ],
                );
              }),
            ),
            centerTitle: false,
          ),
        ),
        body: ExpressiveRefreshIndicator(
          onRefresh: context.read<HomeCubit>().refresh,
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              switch (state) {
                case HomeLoading():
                  return Center(
                    child: LoadingIndicatorM3E(),
                  );
                case HomeError():
                  return Center(
                    child: Text(state.message ?? ''),
                  );
                case HomeSuccess():
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    controller: _scrollController,
                    child: SafeArea(
                        child: Column(
                      children: [
                        _horizontalChipsRow(state.chips),
                        Column(
                          children: [
                            ...state.sections.map((section) {
                              return SectionItem(section: section);
                            }),
                            if (!state.loadingMore &&
                                state.continuation != null)
                              const SizedBox(height: 50),
                            if (state.loadingMore)
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: ExpressiveLoadingIndicator()),
                          ],
                        ),
                      ],
                    )),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
