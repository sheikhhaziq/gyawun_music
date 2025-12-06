import 'package:flutter/material.dart';
import 'package:gyawun_music/core/widgets/section_grid.dart';
import 'package:gyawun_music/core/widgets/section_multi_column.dart';
import 'package:gyawun_music/core/widgets/section_multi_row_column.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'section_header.dart';
import 'section_row.dart';
import 'section_single_column.dart';

class SectionsWidget extends StatelessWidget {
  const SectionsWidget({super.key, required this.sections});
  final List<Section> sections;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        for (final section in sections) ...[
          if ((section.title != null && section.title!.isNotEmpty) || section.trailing != null)
            SectionHeader(section: section),

          if (section.type == SectionType.singleColumn) SectionSingleColumn(items: section.items),

          if (section.type == SectionType.row) SectionRow(items: section.items),
          if (section.type == SectionType.grid) SectionGrid(items: section.items),
          if (section.type == SectionType.multiColumnRow)
            SectionMultiColumnRow(items: section.items),
          if (section.type == SectionType.multiColumn)
            SectionMultiColumn(items: section.items, maxItem: section.itemsPerColumn),
        ],
      ],
    );
  }
}
