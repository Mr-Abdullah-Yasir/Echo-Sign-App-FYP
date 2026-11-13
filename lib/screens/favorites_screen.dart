import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import 'gloss_screen.dart';

class FavoritesScreen extends StatefulWidget {
  static const String routeName = '/favorites';
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);

  Future<List<Map<String, Object?>>> _load() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return Future.value([]);
    return DatabaseService.instance.getFavoritesForUser(user.id);
  }

  Future<void> _remove(Map<String, Object?> item) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await DatabaseService.instance.toggleFavorite(
      userId: user.id,
      translationId: item['id'] as int,
    );
    if (mounted) setState(() {});
  }

  void _open(Map<String, Object?> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlossScreen(
          englishInput: item['english_text'] as String,
          aslGloss: item['asl_gloss'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Favorites'),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentPurple));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load favorites.', style: TextStyle(color: Colors.white70)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No favorites yet.', style: TextStyle(color: Colors.white70)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => _open(item),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: accentPurple),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['english_text'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 7),
                            Text(item['asl_gloss'] as String, style: const TextStyle(color: accentPurple, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _remove(item),
                        icon: const Icon(Icons.close_rounded, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
