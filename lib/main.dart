import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

const kAccent = Color(0xFFFA243C);

// ───────────────────────── Data ─────────────────────────

class Track {
  final String title, artist, album, art, url;
  const Track(this.title, this.artist, this.album, this.art, this.url);
}

const _names = [
  ['Midnight Drive', 'Luna Park', 'City Lights'],
  ['Golden Hour', 'The Hollows', 'Amber'],
  ['Paper Planes', 'Kira Voss', 'Drift'],
  ['Neon Garden', 'Soft Machines', 'Bloom'],
  ['Slow Tide', 'Atlas Bloom', 'Low Season'],
  ['Velvet Sky', 'Luna Park', 'City Lights'],
  ['Echoes', 'The Hollows', 'Amber'],
  ['Last Train', 'Kira Voss', 'Drift'],
  ['Daylight', 'Soft Machines', 'Bloom'],
  ['Ocean Floor', 'Atlas Bloom', 'Low Season'],
];

// Audio contoh gratis dari SoundHelix. Ganti dengan sumber audiomu sendiri.
final List<Track> kTracks = List.generate(_names.length, (i) {
  return Track(
    _names[i][0],
    _names[i][1],
    _names[i][2],
    'https://picsum.photos/seed/applemusic$i/700',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-${i + 1}.mp3',
  );
});

// ───────────────────────── Player ─────────────────────────

class PlayerController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  List<Track> queue = kTracks;
  int index = -1;
  bool playing = false;

  Track? get current => index >= 0 ? queue[index] : null;

  PlayerController() {
    player.playerStateStream.listen((s) {
      playing = s.playing;
      if (s.processingState == ProcessingState.completed) next();
      notifyListeners();
    });
  }

  Future<void> playAt(int i, [List<Track>? newQueue]) async {
    if (newQueue != null) queue = newQueue;
    index = i;
    notifyListeners();
    try {
      await player.setUrl(current!.url);
      player.play();
    } catch (e) {
      debugPrint('Gagal memutar: $e');
    }
  }

  void toggle() {
    if (current == null) return;
    playing ? player.pause() : player.play();
  }

  void next() {
    if (queue.isEmpty) return;
    playAt((index + 1) % queue.length);
  }

  void prev() {
    if (queue.isEmpty) return;
    if (player.position > const Duration(seconds: 3)) {
      player.seek(Duration.zero);
    } else {
      playAt((index - 1 + queue.length) % queue.length);
    }
  }
}

final ctrl = PlayerController();

String fmt(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

// ───────────────────────── App ─────────────────────────

void main() => runApp(const MusicApp());

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musik',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
        scaffoldBackgroundColor: Colors.white,
        splashFactory: NoSplash.splashFactory,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.black,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barColor = dark ? const Color(0xFF1C1C1E) : const Color(0xFFF7F7F7);
    return Scaffold(
      body: IndexedStack(index: tab, children: const [
        ListenNowPage(),
        BrowsePage(),
        LibraryPage(),
        SearchPage(),
      ]),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        BottomNavigationBar(
          currentIndex: tab,
          onTap: (i) => setState(() => tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: barColor,
          selectedItemColor: kAccent,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_fill), label: 'Dengarkan'),
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded), label: 'Jelajahi'),
            BottomNavigationBarItem(
                icon: Icon(Icons.library_music), label: 'Pustaka'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
          ],
        ),
      ]),
    );
  }
}

// ───────────────────────── Shared widgets ─────────────────────────

class Art extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  const Art(this.url, {super.key, required this.size, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFFA243C), Color(0xFF8E2DE2)]),
            ),
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  const SongTile(this.track, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Art(track.art, size: 52, radius: 6),
      title: Text(track.title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.more_horiz, color: Colors.grey),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(children: [
          Text(text,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      );
}

class LargeTitle extends StatelessWidget {
  final String title;
  const LargeTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => SliverAppBar(
        pinned: true,
        expandedHeight: 96,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface)),
        ),
      );
}

// ───────────────────────── Pages ─────────────────────────

class ListenNowPage extends StatelessWidget {
  const ListenNowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      const LargeTitle('Dengarkan'),
      SliverToBoxAdapter(child: const SectionTitle('Pilihan Teratas')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 330,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final t = kTracks[i];
              return GestureDetector(
                onTap: () => ctrl.playAt(i, kTracks),
                child: SizedBox(
                  width: 280,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dipilih untukmu',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Art(t.art, size: 280, radius: 10),
                        const SizedBox(height: 8),
                        Text(t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15)),
                        Text(t.artist,
                            style: TextStyle(color: Colors.grey.shade600)),
                      ]),
                ),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(child: const SectionTitle('Baru Diputar')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 210,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final idx = (i + 4) % kTracks.length;
              final t = kTracks[idx];
              return GestureDetector(
                onTap: () => ctrl.playAt(idx, kTracks),
                child: SizedBox(
                  width: 150,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Art(t.art, size: 150),
                        const SizedBox(height: 8),
                        Text(t.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(t.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600)),
                      ]),
                ),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(child: const SectionTitle('Lagu untukmu')),
      SliverList.builder(
        itemCount: kTracks.length,
        itemBuilder: (_, i) =>
            SongTile(kTracks[i], onTap: () => ctrl.playAt(i, kTracks)),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ]);
  }
}

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  static const cats = [
    ['Pop', 0xFFFF5F6D, 0xFFFFC371],
    ['Hip-Hop', 0xFF6A11CB, 0xFF2575FC],
    ['Rock', 0xFF434343, 0xFF000000],
    ['Santai', 0xFF11998E, 0xFF38EF7D],
    ['Elektronik', 0xFF8E2DE2, 0xFF4A00E0],
    ['Jazz', 0xFFF7971E, 0xFFFFD200],
    ['Indie', 0xFFEE0979, 0xFFFF6A00],
    ['Akustik', 0xFF36D1DC, 0xFF5B86E5],
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      const LargeTitle('Jelajahi'),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.6),
          itemCount: cats.length,
          itemBuilder: (_, i) {
            final c = cats[i];
            return Container(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.bottomLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(c[1] as int), Color(c[2] as int)]),
              ),
              child: Text(c[0] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            );
          },
        ),
      ),
    ]);
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  static const items = [
    [Icons.queue_music, 'Playlist'],
    [Icons.mic_external_on, 'Artis'],
    [Icons.album, 'Album'],
    [Icons.music_note, 'Lagu'],
    [Icons.download_for_offline, 'Terunduh'],
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      const LargeTitle('Pustaka'),
      SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 56, endIndent: 0),
        itemBuilder: (_, i) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(items[i][0] as IconData, color: kAccent),
          title: Text(items[i][1] as String,
              style: const TextStyle(fontSize: 20)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
      const SliverToBoxAdapter(child: SectionTitle('Baru Ditambahkan')),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82),
          itemCount: 6,
          itemBuilder: (ctx, i) {
            final t = kTracks[i];
            return GestureDetector(
              onTap: () => ctrl.playAt(i, kTracks),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                        aspectRatio: 1,
                        child: LayoutBuilder(
                            builder: (_, c) =>
                                Art(t.art, size: c.maxWidth, radius: 8))),
                    const SizedBox(height: 6),
                    Text(t.album,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(t.artist,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ]),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final results = kTracks
        .where((t) =>
            t.title.toLowerCase().contains(q.toLowerCase()) ||
            t.artist.toLowerCase().contains(q.toLowerCase()))
        .toList();
    return CustomScrollView(slivers: [
      const LargeTitle('Cari'),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Artis, lagu, atau album',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFFEFEFF0),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
      if (results.isEmpty)
        const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Tidak ada hasil. Coba kata kunci lain.')))
      else
        SliverList.builder(
          itemCount: results.length,
          itemBuilder: (_, i) => SongTile(results[i],
              onTap: () => ctrl.playAt(kTracks.indexOf(results[i]), kTracks)),
        ),
    ]);
  }
}

// ───────────────────────── Mini player ─────────────────────────

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final t = ctrl.current;
        if (t == null) return const SizedBox.shrink();
        final dark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () => openNowPlaying(context),
          child: Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFEDEDEF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Art(t.art, size: 46, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                  iconSize: 32,
                  onPressed: ctrl.toggle,
                  icon: Icon(ctrl.playing ? Icons.pause : Icons.play_arrow)),
              IconButton(
                  iconSize: 32,
                  onPressed: ctrl.next,
                  icon: const Icon(Icons.fast_forward)),
            ]),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Now playing ─────────────────────────

void openNowPlaying(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NowPlaying(),
  );
}

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key});
  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  double? drag;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final t = ctrl.current;
        if (t == null) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(t.art,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF3A1C71))),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),
            DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(children: [
                  const SizedBox(height: 10),
                  Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(3))),
                  const Spacer(),
                  AnimatedScale(
                    scale: ctrl.playing ? 1.0 : 0.82,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: DecoratedBox(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 40,
                            offset: const Offset(0, 20))
                      ]),
                      child: LayoutBuilder(
                        builder: (_, c) => Art(t.art,
                            size: MediaQuery.of(context).size.width - 56,
                            radius: 14),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          Text(t.artist,
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.white70)),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  _ProgressBar(
                    drag: drag,
                    onDrag: (v) => setState(() => drag = v),
                    onEnd: (v) {
                      ctrl.player.seek(Duration(milliseconds: v.round()));
                      setState(() => drag = null);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                            iconSize: 52,
                            color: Colors.white,
                            onPressed: ctrl.prev,
                            icon: const Icon(Icons.fast_rewind)),
                        IconButton(
                            iconSize: 76,
                            color: Colors.white,
                            onPressed: ctrl.toggle,
                            icon: Icon(ctrl.playing
                                ? Icons.pause
                                : Icons.play_arrow)),
                        IconButton(
                            iconSize: 52,
                            color: Colors.white,
                            onPressed: ctrl.next,
                            icon: const Icon(Icons.fast_forward)),
                      ]),
                  const SizedBox(height: 8),
                  StreamBuilder<double>(
                    stream: ctrl.player.volumeStream,
                    builder: (_, snap) => Row(children: [
                      const Icon(Icons.volume_mute,
                          color: Colors.white70, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: SliderComponentShape.noThumb,
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              overlayShape: SliderComponentShape.noOverlay),
                          child: Slider(
                              value: snap.data ?? 1.0,
                              onChanged: ctrl.player.setVolume),
                        ),
                      ),
                      const Icon(Icons.volume_up,
                          color: Colors.white70, size: 20),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double? drag;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onEnd;
  const _ProgressBar(
      {required this.drag, required this.onDrag, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: ctrl.player.durationStream,
      builder: (_, dSnap) {
        final total = dSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: ctrl.player.positionStream,
          builder: (_, pSnap) {
            final pos = pSnap.data ?? Duration.zero;
            final maxMs = total.inMilliseconds.toDouble();
            final value = (drag ?? pos.inMilliseconds.toDouble())
                .clamp(0.0, maxMs > 0 ? maxMs : 1.0);
            return Column(children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24),
                child: Slider(
                  value: value,
                  max: maxMs > 0 ? maxMs : 1.0,
                  onChanged: maxMs > 0 ? onDrag : null,
                  onChangeEnd: onEnd,
                ),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fmt(Duration(milliseconds: value.round())),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                    Text('-${fmt(total - Duration(milliseconds: value.round()))}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ]),
            ]);
          },
        );
      },
    );
  }
}
