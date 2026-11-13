import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import 'gloss_screen.dart';

class HistoryScreen extends StatefulWidget {
  static const String routeName = '/history';
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);

  Future<List<Map<String, Object?>>> _load() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return Future.value([]);
    return DatabaseService.instance.getTranslationsForUser(user.id);
  }

  Future<void> _toggleFavorite(Map<String, Object?> item) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await DatabaseService.instance.toggleFavorite(
      userId: user.id,
      translationId: item['id'] as int,
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(Map<String, Object?> item) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete translation?'),
        content: const Text('This will also remove it from Favorites.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseService.instance.deleteTranslation(
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
        title: const Text('Translation History'),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentPurple));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load translation history.', style: TextStyle(color: Colors.white70)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No translations yet.', style: TextStyle(color: Colors.white70)));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isFavorite = (item['is_favorite'] as int? ?? 0) == 1;
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['english_text'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(item['asl_gloss'] as String, style: const TextStyle(color: accentPurple, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_formatDate(item['created_at'] as String), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () => _toggleFavorite(item),
                              icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? accentPurple : Colors.white38),
                            ),
                            IconButton(
                              onPressed: () => _delete(item),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }
}
