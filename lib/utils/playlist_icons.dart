import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:gyawun/utils/playlist_icon.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlaylistIcons {
  PlaylistIcons._();

  static final musicNoteList = MaterialPlaylistIcon(
    'musicNoteList',
    CupertinoIcons.music_note_list,
  );
  static final compactDisc = MaterialPlaylistIcon(
    'compactDisc',
    FontAwesomeIcons.compactDisc,
  );
  static final radio = MaterialPlaylistIcon('radio', FontAwesomeIcons.radio);
  static final podcast = MaterialPlaylistIcon(
    'podcast',
    FontAwesomeIcons.podcast,
  );
  static final guitar = MaterialPlaylistIcon('guitar', FontAwesomeIcons.guitar);
  static final drum = MaterialPlaylistIcon('drum', FontAwesomeIcons.drum);
  static final dumbbell = MaterialPlaylistIcon(
    'dumbbell',
    FontAwesomeIcons.dumbbell,
  );
  static final personRunning = MaterialPlaylistIcon(
    'person_running',
    FontAwesomeIcons.personRunning,
  );
  static final atom = MaterialPlaylistIcon('atom', FontAwesomeIcons.atom);
  static final circleRadiation = MaterialPlaylistIcon(
    'circleRadiation',
    FontAwesomeIcons.circleRadiation,
  );
  static final spa = MaterialPlaylistIcon('spa', FontAwesomeIcons.spa);
  static final bed = MaterialPlaylistIcon('bed', FontAwesomeIcons.bed);
  static final sun = MaterialPlaylistIcon('sun', FontAwesomeIcons.sun);
  static final water = MaterialPlaylistIcon('water', FontAwesomeIcons.water);
  static final fire = MaterialPlaylistIcon('fire', FontAwesomeIcons.fire);
  static final wind = MaterialPlaylistIcon('wind', FontAwesomeIcons.wind);
  static final car = MaterialPlaylistIcon('car', FontAwesomeIcons.car);
  static final motorcycle = MaterialPlaylistIcon(
    'motorcycle',
    FontAwesomeIcons.motorcycle,
  );
  static final fly = MaterialPlaylistIcon('fly', FontAwesomeIcons.fly);
  static final dna = MaterialPlaylistIcon('dna', FontAwesomeIcons.dna);
  static final skull = MaterialPlaylistIcon('skull', FontAwesomeIcons.skull);
  static final virus = MaterialPlaylistIcon('virus', FontAwesomeIcons.virus);
  static final flask = MaterialPlaylistIcon('flask', FontAwesomeIcons.flask);
  static final faceLaugh = MaterialPlaylistIcon(
    'faceLaugh',
    FontAwesomeIcons.faceLaugh,
  );
  static final faceSadCry = MaterialPlaylistIcon(
    'faceSadCry',
    FontAwesomeIcons.faceSadCry,
  );
  static final brain = MaterialPlaylistIcon('brain', FontAwesomeIcons.brain);
  static final earthAmericas = MaterialPlaylistIcon(
    'earthAmericas',
    FontAwesomeIcons.earthAmericas,
  );
  static final heartCrack = MaterialPlaylistIcon(
    'heartCrack',
    FontAwesomeIcons.heartCrack,
  );
  static final spotify = MaterialPlaylistIcon(
    'spotify',
    FontAwesomeIcons.spotify,
  );
  static final pizzaSlice = MaterialPlaylistIcon(
    'pizzaSlice',
    FontAwesomeIcons.pizzaSlice,
  );
  static final pill = PolygonPlaylistIcon('pill', MaterialShapes.pill);
  static final arrow = PolygonPlaylistIcon('arrow', MaterialShapes.arrow);
  static final boom = PolygonPlaylistIcon('boom', MaterialShapes.boom);
  static final circle = PolygonPlaylistIcon('circle', MaterialShapes.circle);
  static final clover4Leaf = PolygonPlaylistIcon(
    'clover4Leaf',
    MaterialShapes.clover4Leaf,
  );

  static List<PlaylistIcon> values = [
    musicNoteList,
    compactDisc,
    radio,
    podcast,
    guitar,
    drum,
    dumbbell,
    personRunning,
    atom,
    circleRadiation,
    spa,
    bed,
    sun,
    water,
    fire,
    wind,
    car,
    motorcycle,
    fly,
    dna,
    skull,
    virus,
    flask,
    faceLaugh,
    faceSadCry,
    brain,
    earthAmericas,
    heartCrack,
    spotify,
    pizzaSlice,
    pill,
    arrow,
    boom,
    circle,
    clover4Leaf,
  ];

  static PlaylistIcon byId(String id) =>
      values.firstWhereOrNull((icon) => icon.toId() == id) ?? values.first;
}
