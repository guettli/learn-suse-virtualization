import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/deck_repository.dart';
import 'settings_screen.dart';
import 'study_screen.dart';

class DeckSelectionScreen extends StatefulWidget {
  const DeckSelectionScreen({super.key});

  @override
  State<DeckSelectionScreen> createState() => _DeckSelectionScreenState();
}

class _DeckSelectionScreenState extends State<DeckSelectionScreen> {
  late Future<Map<String, Deck>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  void _loadDecks() {
    setState(() {
      _decksFuture = DeckRepository.loadDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hands-Free Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Voice & Audio Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Voice Commands Help',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Deck>>(
        future: _decksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading decks: ${snapshot.error}'),
              ),
            );
          }

          final decks = snapshot.data?.values.toList() ?? [];
          if (decks.isEmpty) {
            return const Center(child: Text('No decks found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: decks.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader(theme);
              }
              final deck = decks[index - 1];
              return _buildDeckCard(context, deck);
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.record_voice_over, size: 36, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hands-Free Voice Study',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Put on headphones, lock your phone or put it in your pocket. Speak commands to learn on the go.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck) {
    final theme = Theme.of(context);

    return FutureBuilder<DeckStats>(
      future: DeckRepository.getDeckStats(deck),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _startStudy(context, deck),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.library_books,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deck.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (deck.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                deck.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatChip(
                        label: '${deck.totalCards} cards',
                        color: Colors.blueGrey,
                      ),
                      if (stats != null) ...[
                        _buildStatChip(
                          label: '${stats.due} due',
                          color: stats.due > 0 ? Colors.orange : Colors.grey,
                        ),
                        _buildStatChip(
                          label: '${stats.mastered} mastered',
                          color: Colors.green,
                        ),
                      ],
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Study'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _startStudy(context, deck),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _startStudy(BuildContext context, Deck deck) async {
    final dueCards = await DeckRepository.getDueCards(deck: deck);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyScreen(deck: deck, cards: dueCards),
      ),
    );
    _loadDecks();
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blue),
            SizedBox(width: 8),
            Text('Voice Commands'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How hands-free mode works:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Question is read aloud by TTS.'),
              Text('2. Say "next" or "ok" to reveal the answer.'),
              Text('3. Answer is read aloud.'),
              Text('4. Grade your recall by saying:'),
              Padding(
                padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• "Simple" (or "easy") -> Perfect recall'),
                    Text('• "Medium" (or "good") -> Correct with effort'),
                    Text('• "Hard" (or "difficult") -> Difficult recall'),
                  ],
                ),
              ),
              Divider(height: 24),
              Text('Extra Commands:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• "repeat" / "again" - Read question or answer again'),
              Text('• "repeat question" - Read question again from answer'),
              Text('• "pause" / "stop" - Pause speech and listening'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
