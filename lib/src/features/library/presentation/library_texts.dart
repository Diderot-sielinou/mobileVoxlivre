import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Présentation d'un statut : icône **et** libellé (jamais la couleur seule).
typedef StatusLook = ({IconData icon, String label, Color color});

StatusLook statusLook(LibraryStatus status, VoxColors colors) =>
    switch (status) {
      LibraryStatus.processing => (
        icon: Icons.hourglass_top,
        label: 'En préparation',
        color: colors.accent,
      ),
      LibraryStatus.failed => (
        icon: Icons.error_outline,
        label: 'Échec',
        color: colors.error,
      ),
      LibraryStatus.notConverted => (
        icon: Icons.description_outlined,
        label: 'Texte prêt',
        color: colors.textSecondary,
      ),
      LibraryStatus.ready => (
        icon: Icons.headphones,
        label: 'Prêt',
        color: colors.success,
      ),
      LibraryStatus.inProgress => (
        icon: Icons.play_circle_outline,
        label: 'À reprendre',
        color: colors.accent,
      ),
      LibraryStatus.finished => (
        icon: Icons.check_circle_outline,
        label: 'Terminé',
        color: colors.success,
      ),
      LibraryStatus.unknown => (
        icon: Icons.help_outline,
        label: 'Indisponible',
        color: colors.textSecondary,
      ),
    };

/// Seconde ligne d'une carte, selon le statut (ADR-0006, tableau L9).
String statusDetail(LibraryItem item) {
  final conversion = item.conversion;
  return switch (item.status) {
    LibraryStatus.ready when conversion != null =>
      '${VoxFormat.listening(conversion.playable)} d’écoute',
    LibraryStatus.inProgress when item.remaining != null =>
      'Reste ${VoxFormat.listening(item.remaining!)}',
    LibraryStatus.processing when conversion != null =>
      'Conversion · ${conversion.partsReady}/${conversion.partCount ?? '…'} '
          'parties',
    LibraryStatus.processing => 'Analyse du texte…',
    LibraryStatus.notConverted => switch (item.pageCount) {
      final pages? => '$pages pages · à convertir',
      null => 'À convertir',
    },
    LibraryStatus.failed => failureText(
      extraction: item.extractionError,
      conversion: conversion?.failureReason,
    ),
    LibraryStatus.finished when conversion != null =>
      '${VoxFormat.listening(conversion.playable)} écoutées',
    _ => '',
  };
}

/// Raison d'un échec, par code stable du backend.
String failureText({String? extraction, String? conversion}) =>
    switch (extraction ?? conversion) {
      'unreadable' => 'PDF illisible ou protégé par un mot de passe',
      'empty' => 'Le PDF ne contient aucune page',
      'scanned' || 'ocr_no_text' => 'Aucun texte reconnu dans le scan',
      'ocr_too_many_pages' => 'Scan trop long (300 pages au plus)',
      'ocr_quota_exceeded' => 'Limite mensuelle de scans atteinte',
      'source_missing' => 'Fichier introuvable, importez-le à nouveau',
      'text_changed' => 'Texte modifié pendant la conversion, relancez-la',
      'empty_text' => 'Aucun mot à lire',
      'tts_rejected' => 'La voix a refusé ce texte',
      'source_unavailable' => 'Document supprimé ou indisponible',
      _ => 'Échec technique, réessayez plus tard',
    };
