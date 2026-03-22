// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Pas de Titres', one: '1 Titre', other: '${count} Titres')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "About": MessageLookupByLibrary.simpleMessage("À propos"),
    "Add_To_Favourites": MessageLookupByLibrary.simpleMessage(
      "Ajouter aux favoris",
    ),
    "Add_To_Library": MessageLookupByLibrary.simpleMessage(
      "Ajouter à la bibliothèque",
    ),
    "Add_To_Playlist": MessageLookupByLibrary.simpleMessage(
      "Ajouter à une playlist",
    ),
    "Add_To_Queue": MessageLookupByLibrary.simpleMessage(
      "Ajouter à la file d\'attente",
    ),
    "Album": MessageLookupByLibrary.simpleMessage("Album"),
    "Albums": MessageLookupByLibrary.simpleMessage("Albums"),
    "App_Folder": MessageLookupByLibrary.simpleMessage("Dossier Application"),
    "Appearence": MessageLookupByLibrary.simpleMessage("Apparence"),
    "Artists": MessageLookupByLibrary.simpleMessage("Artistes"),
    "Audio_And_Playback": MessageLookupByLibrary.simpleMessage(
      "Audio et Lecture",
    ),
    "Autofetch_Songs": MessageLookupByLibrary.simpleMessage(
      "Lecture automatique de titres similaires",
    ),
    "Backup": MessageLookupByLibrary.simpleMessage("Sauvegarde"),
    "Backup_And_Restore": MessageLookupByLibrary.simpleMessage(
      "Sauvegarde et Restauration",
    ),
    "Backup_Failed": MessageLookupByLibrary.simpleMessage(
      "Échec de la sauvegarde des données",
    ),
    "Backup_Success": MessageLookupByLibrary.simpleMessage(
      "Sauvegarde effectuée avec succès à",
    ),
    "Battery_Optimisation_message": MessageLookupByLibrary.simpleMessage(
      "Cliquez ici pour désactiver l\'optimisation de la batterie afin que Gyawun fonctionne correctement.",
    ),
    "Battery_Optimisation_title": MessageLookupByLibrary.simpleMessage(
      "Optimisation de batterie détectée",
    ),
    "Bug_Report": MessageLookupByLibrary.simpleMessage("Rapport de bug"),
    "Buy_Me_A_Coffee": MessageLookupByLibrary.simpleMessage(
      "Offrez-moi un café",
    ),
    "Cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
    "Check_For_Update": MessageLookupByLibrary.simpleMessage(
      "Vérifier les mises à jour",
    ),
    "Confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
    "Confirm_Delete_All_Message": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir les supprimer ?",
    ),
    "Content": MessageLookupByLibrary.simpleMessage("Contenu"),
    "Contributors": MessageLookupByLibrary.simpleMessage("Contributeurs"),
    "Copied_To_Clipboard": MessageLookupByLibrary.simpleMessage(
      "Copié dans le presse-papiers",
    ),
    "Country": MessageLookupByLibrary.simpleMessage("Pays"),
    "Create": MessageLookupByLibrary.simpleMessage("Créer"),
    "Create_Playlist": MessageLookupByLibrary.simpleMessage(
      "Créer une playlist",
    ),
    "DOwnload_Quality": MessageLookupByLibrary.simpleMessage(
      "Qualité du Téléchargement",
    ),
    "Delete_All_Songs": MessageLookupByLibrary.simpleMessage(
      "Supprimer tous les titres",
    ),
    "Delete_Item_Message": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir supprimer cet élément ?",
    ),
    "Delete_Playback_History": MessageLookupByLibrary.simpleMessage(
      "Supprimer l\'historique de lecture",
    ),
    "Delete_Playback_History_Confirm_Message":
        MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir supprimer l\'historique de lecture ?",
        ),
    "Delete_Search_History": MessageLookupByLibrary.simpleMessage(
      "Supprimer l\'historique de recherche",
    ),
    "Delete_Search_History_Confirm_Message":
        MessageLookupByLibrary.simpleMessage(
          "Êtes-vous sûr de vouloir supprimer l\'historique de recherche ?",
        ),
    "Deleting_Songs": MessageLookupByLibrary.simpleMessage(
      "Suppression de titres...",
    ),
    "Developer": MessageLookupByLibrary.simpleMessage("Développeur"),
    "Donate": MessageLookupByLibrary.simpleMessage("Faire un don"),
    "Donate_Message": MessageLookupByLibrary.simpleMessage(
      "Soutenez le développement de Gyawun",
    ),
    "Done": MessageLookupByLibrary.simpleMessage("Terminé"),
    "Download": MessageLookupByLibrary.simpleMessage("Télécharger"),
    "Download_Started": MessageLookupByLibrary.simpleMessage(
      "Téléchargement en cours...",
    ),
    "Downloading": MessageLookupByLibrary.simpleMessage("Téléchargement"),
    "Downloads": MessageLookupByLibrary.simpleMessage("Téléchargements"),
    "Dynamic_Colors": MessageLookupByLibrary.simpleMessage(
      "Couleurs Dynamiques",
    ),
    "Enable_Equalizer": MessageLookupByLibrary.simpleMessage(
      "Activer l\'égaliseur",
    ),
    "Enable_Playback_History": MessageLookupByLibrary.simpleMessage(
      "Activer l\'historique de lecture",
    ),
    "Enable_Search_History": MessageLookupByLibrary.simpleMessage(
      "Activer l\'historique de recherche",
    ),
    "Enter_Visitor_Id": MessageLookupByLibrary.simpleMessage(
      "Saisir l\'identifiant du visiteur",
    ),
    "Equalizer": MessageLookupByLibrary.simpleMessage("Égaliseur"),
    "Favourites": MessageLookupByLibrary.simpleMessage("Favoris"),
    "Feature_Request": MessageLookupByLibrary.simpleMessage(
      "Demande de fonctionnalité",
    ),
    "Go_To_Downloads": MessageLookupByLibrary.simpleMessage(
      "Accéder aux téléchargements",
    ),
    "Google_Account": MessageLookupByLibrary.simpleMessage("Compte Google"),
    "Gyawun": MessageLookupByLibrary.simpleMessage("Gyawun"),
    "High": MessageLookupByLibrary.simpleMessage("Haute"),
    "History": MessageLookupByLibrary.simpleMessage("Historique"),
    "Home": MessageLookupByLibrary.simpleMessage("Accueil"),
    "Import": MessageLookupByLibrary.simpleMessage("Importer"),
    "Import_Playlist": MessageLookupByLibrary.simpleMessage(
      "Importer une playlist",
    ),
    "In_Progress": MessageLookupByLibrary.simpleMessage("En cours"),
    "Jhelum_Corp": MessageLookupByLibrary.simpleMessage("Jhelum Corp"),
    "Language": MessageLookupByLibrary.simpleMessage("Langue"),
    "Loudness_And_Equalizer": MessageLookupByLibrary.simpleMessage(
      "Volume et Égaliseur",
    ),
    "Loudness_Enhancer": MessageLookupByLibrary.simpleMessage(
      "Amplificateur de Volume",
    ),
    "Low": MessageLookupByLibrary.simpleMessage("Basse"),
    "Made_In_Kashmir": MessageLookupByLibrary.simpleMessage(
      "Fabriqué au Cachemire",
    ),
    "Name": MessageLookupByLibrary.simpleMessage("Nom"),
    "Next_Up": MessageLookupByLibrary.simpleMessage("Suivant"),
    "No": MessageLookupByLibrary.simpleMessage("Non"),
    "No_Internet_Connection": MessageLookupByLibrary.simpleMessage(
      "Aucune connexion Internet",
    ),
    "Organisation": MessageLookupByLibrary.simpleMessage("Organisation"),
    "Pay_With_UPI": MessageLookupByLibrary.simpleMessage("Payer avec UPI"),
    "Payment_Methods": MessageLookupByLibrary.simpleMessage(
      "Modes de Paiement",
    ),
    "Personalised_Content": MessageLookupByLibrary.simpleMessage(
      "Contenu Personnalisé",
    ),
    "Play_Next": MessageLookupByLibrary.simpleMessage("Lire ensuite"),
    "Playback_History_Deleted": MessageLookupByLibrary.simpleMessage(
      "Historique de lecture supprimé",
    ),
    "Playlist_Name": MessageLookupByLibrary.simpleMessage("Nom de la playlist"),
    "Playlist_Not_Available": MessageLookupByLibrary.simpleMessage(
      "Playlist indisponible",
    ),
    "Playlists": MessageLookupByLibrary.simpleMessage("Playlists"),
    "Progress": MessageLookupByLibrary.simpleMessage("Progrès"),
    "Queued": MessageLookupByLibrary.simpleMessage("En attente"),
    "Remove": MessageLookupByLibrary.simpleMessage("Supprimer"),
    "Remove_All_History_Message": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir effacer tout l\'historique ?",
    ),
    "Remove_From_Favourites": MessageLookupByLibrary.simpleMessage(
      "Supprimer des favoris",
    ),
    "Remove_From_Library": MessageLookupByLibrary.simpleMessage(
      "Supprimer de la bibliothèque",
    ),
    "Remove_From_YTMusic_Message": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir le supprimer de YouTube Music ?",
    ),
    "Remove_Message": MessageLookupByLibrary.simpleMessage(
      "Êtes-vous sûr de vouloir le supprimer ?",
    ),
    "Rename": MessageLookupByLibrary.simpleMessage("Renommer"),
    "Rename_Playlist": MessageLookupByLibrary.simpleMessage(
      "Renommer la playlist",
    ),
    "Reset_Visitor_Id": MessageLookupByLibrary.simpleMessage(
      "Réinitialiser l\'identifiant du visiteur",
    ),
    "Restore": MessageLookupByLibrary.simpleMessage("Restauration"),
    "Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "Échec de la restauration des données",
    ),
    "Restore_Missing_Songs": MessageLookupByLibrary.simpleMessage(
      "Restaurer les titres manquants",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage(
      "Données restaurées avec succès",
    ),
    "Restoring_Missing_Songs": MessageLookupByLibrary.simpleMessage(
      "Restauration des titres manquants...",
    ),
    "Retry": MessageLookupByLibrary.simpleMessage("Réessayer"),
    "Save": MessageLookupByLibrary.simpleMessage("Enregistrer"),
    "Saved": MessageLookupByLibrary.simpleMessage("Enregistré"),
    "Search_Gyawun": MessageLookupByLibrary.simpleMessage(
      "Rechercher sur Gyawun",
    ),
    "Search_History_Deleted": MessageLookupByLibrary.simpleMessage(
      "Historique de recherche supprimé",
    ),
    "Search_Settings": MessageLookupByLibrary.simpleMessage(
      "Paramètres de recherche",
    ),
    "Select_Backup": MessageLookupByLibrary.simpleMessage(
      "Sélectionnez  la sauvegarde",
    ),
    "Settings": MessageLookupByLibrary.simpleMessage("Paramètres"),
    "Share": MessageLookupByLibrary.simpleMessage("Partager"),
    "Sheikh_Haziq": MessageLookupByLibrary.simpleMessage("Sheikh Haziq"),
    "Show_Less": MessageLookupByLibrary.simpleMessage("Afficher moins"),
    "Show_More": MessageLookupByLibrary.simpleMessage("Afficher plus"),
    "Shuffle": MessageLookupByLibrary.simpleMessage("Aléatoire"),
    "Skip_Silence": MessageLookupByLibrary.simpleMessage("Ignorer le Silence"),
    "Sleep_Timer": MessageLookupByLibrary.simpleMessage("Minuterie de Sommeil"),
    "Songs": MessageLookupByLibrary.simpleMessage("Titres"),
    "Songs_Will_Start_Playing_Soon": MessageLookupByLibrary.simpleMessage(
      "Les titres commenceront bientôt à être diffusés.",
    ),
    "Source_Code": MessageLookupByLibrary.simpleMessage("Code Source"),
    "Start_Radio": MessageLookupByLibrary.simpleMessage("Démarrer la radio"),
    "Streaming_Quality": MessageLookupByLibrary.simpleMessage(
      "Qualité du Streaming",
    ),
    "Subscriptions": MessageLookupByLibrary.simpleMessage("Abonnements"),
    "Support_Me_On_Kofi": MessageLookupByLibrary.simpleMessage(
      "Soutenez-moi sur Ko-fi",
    ),
    "Telegram": MessageLookupByLibrary.simpleMessage("Telegram"),
    "Theme_Mode": MessageLookupByLibrary.simpleMessage("Thème"),
    "Translate_Lyrics": MessageLookupByLibrary.simpleMessage(
      "Traduire les paroles",
    ),
    "Version": MessageLookupByLibrary.simpleMessage("Version"),
    "Visitor_Id": MessageLookupByLibrary.simpleMessage(
      "Identifiant du Visiteur",
    ),
    "Window_Effect": MessageLookupByLibrary.simpleMessage("Effet fenêtre"),
    "YTMusic": MessageLookupByLibrary.simpleMessage("YouTube Music"),
    "Yes": MessageLookupByLibrary.simpleMessage("Oui"),
    "nSongs": m1,
  };
}
