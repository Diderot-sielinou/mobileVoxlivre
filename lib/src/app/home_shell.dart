import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coquille des 4 onglets : la barre du bas reste, chaque onglet garde sa pile
/// de navigation et son défilement quand on en change.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // Un second appui sur l'onglet courant revient à sa racine.
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Bibliothèque',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Importer',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Statistiques',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Page d'attente d'un onglet, remplacée par l'écran de sa fonctionnalité.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('À venir', style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
