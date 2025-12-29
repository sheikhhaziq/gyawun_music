// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AdaptiveIcons {
  static IconData home = Icons.home;
  static IconData home_filled = Icons.home_filled;
  static IconData back = Icons.arrow_back;
  static IconData chevron_left = Icons.chevron_left;
  static IconData chevron_right = Icons.chevron_right;
  static IconData chevron_down = CupertinoIcons.chevron_down;
  static IconData search = Icons.search;
  static IconData download = Icons.download;
  static IconData downloading = Icons.downloading;
  static IconData sync = Icons.sync;
  static IconData create = Icons.edit;
  static IconData add = Icons.add;
  static IconData import = Icons.import_export_outlined;
  static IconData heart = CupertinoIcons.heart;
  static IconData heart_fill = CupertinoIcons.heart_fill;
  static IconData lyrics = Icons.lyrics;
  static IconData queue = Icons.queue_music;
  static IconData play = Icons.play_arrow;

  static IconData pause = Icons.pause;

  static IconData skip_previous = Icons.skip_previous;
  static IconData skip_next = Icons.skip_next;
  static IconData repeat = Icons.repeat;
  static IconData repeat_one = Icons.repeat_one;
  static IconData repeat_all = Icons.repeat;
  static IconData more_vertical = Icons.more_vert;
  static IconData delete = Icons.delete;
  static IconData volume(double range) {
    if (range == 0) {
      return Icons.volume_off;
    } else if (range < .2) {
      return Icons.volume_down;
    } else if (range < .6) {
      return Icons.volume_down;
    }
    return Icons.volume_up;
  }

  static IconData library_add = Icons.library_add;
  static IconData library_add_check = Icons.library_add_check;
  static IconData playlist_play = Icons.playlist_play;
  static IconData queue_add = Icons.queue;
  static IconData radio = Icons.radar;
  static IconData person = Icons.person;
  static IconData people = Icons.people;
  static IconData album = Icons.album;
  static IconData equalizer = Icons.equalizer;
  static IconData timer = Icons.timer;
  static IconData share = Icons.share;
  static IconData wifi_off_rounded = Icons.wifi_off_rounded;
}
