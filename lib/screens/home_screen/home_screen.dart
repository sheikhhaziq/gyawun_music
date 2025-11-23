import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/utils/internet_guard.dart';

import '../../generated/l10n.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../ytmusic/ytmusic.dart';
import 'section_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YTMusic ytMusic = GetIt.I<YTMusic>();
  late ScrollController _scrollController;
  late List chips = [];
  late List sections = [];
  int page = 0;
  String? continuation;
  bool initialLoading = true;
  bool nextLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    fetchHome();
  }

  Future<void> _scrollListener() async {
    if (initialLoading || nextLoading || continuation == null) {
      return;
    }

    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await fetchNext();
    }
  }

  Future<void> fetchHome() async {
    setState(() {
      initialLoading = true;
      nextLoading = false;
    });
    Map<String, dynamic> home = await ytMusic.browse();
    if (mounted) {
      setState(() {
        initialLoading = false;
        nextLoading = false;
        chips = home['chips'];
        sections = home['sections'];
        continuation = home['continuation'];
      });
    }
  }

  Future<void> refresh() async {
    if (initialLoading) return;
    Map<String, dynamic> home = await ytMusic.browse();
    if (mounted) {
      setState(() {
        initialLoading = false;
        nextLoading = false;
        chips = home['chips'];
        sections = home['sections'];
        continuation = home['continuation'];
      });
    }
  }

  Future<void> fetchNext() async {
    if (continuation == null) return;
    setState(() {
      nextLoading = true;
    });
    Map<String, dynamic> home =
        await ytMusic.browseContinuation(additionalParams: continuation!);
    List<Map<String, dynamic>> secs =
        home['sections'].cast<Map<String, dynamic>>();
    if (mounted) {
      setState(() {
        sections.addAll(secs);
        continuation = home['continuation'];
        nextLoading = false;
      });
    }
  }

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
        body: initialLoading
            ? const Center(child: AdaptiveProgressRing())
            : RefreshIndicator(
                onRefresh: () => refresh(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  controller: _scrollController,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _horizontalChipsRow(chips),
                        Column(
                          children: [
                            ...sections.map((section) {
                              return SectionItem(section: section);
                            }),
                            if (!nextLoading && continuation != null)
                              const SizedBox(height: 50),
                            if (nextLoading)
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: AdaptiveProgressRing()),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
