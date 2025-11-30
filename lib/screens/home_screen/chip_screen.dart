import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/utils/internet_guard.dart';

import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../ytmusic/ytmusic.dart';
import 'section_item.dart';

class ChipScreen extends StatefulWidget {
  const ChipScreen({required this.title, required this.endpoint, super.key});

  final String title;
  final Map<String, dynamic> endpoint;

  @override
  State<ChipScreen> createState() => _ChipScreenState();
}

class _ChipScreenState extends State<ChipScreen> {
  final YTMusic ytMusic = GetIt.I<YTMusic>();
  late ScrollController _scrollController;
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

  @override
  dispose() {
    super.dispose();
    _scrollController.dispose();
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
    Map<String, dynamic> home = await ytMusic.browse(body: widget.endpoint);

    if (mounted) {
      setState(() {
        initialLoading = false;
        nextLoading = false;
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
        await ytMusic.browse(additionalParams: continuation!);
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

  @override
  Widget build(BuildContext context) {
    return InternetGuard(
      onInternetRestored: fetchHome,
      child: AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: initialLoading
            ? const Center(child: AdaptiveProgressRing())
            : SingleChildScrollView(
                controller: _scrollController,
                child: SafeArea(
                  child: Column(
                    children: [
                      ...sections.map((section) {
                        return SectionItem(section: section);
                      }),
                      if (nextLoading)
                        const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: AdaptiveProgressRing()),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
