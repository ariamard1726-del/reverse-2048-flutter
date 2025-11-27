import 'package:flutter/material.dart';

class GameEngine {
  late List<List<int>> board;
  int score = 0;

  GameEngine() {
    newGame();
  }

  void newGame() {
    board = List.generate(4, (_) => List.filled(4, 0));
    score = 0;
    _addRandomTile();
    _addRandomTile();
  }

  void _addRandomTile() {
    final empty = <List<int>>[];
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 4; c++)
        if (board[r][c] == 0) empty.add([r, c]);
    if (empty.isNotEmpty) {
      final cell = empty[DateTime.now().millisecondsSinceEpoch % empty.length];
      board[cell[0]][cell[1]] = 2;
    }
  }

  bool slideLeft() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      final row = board[r].where((v) => v != 0).toList();
      final merged = <int>[];
      for (int i = 0; i < row.length; i++) {
        if (i + 1 < row.length && row[i] == row[i + 1]) {
          merged.add(row[i] * 2);
          score += row[i] * 2;
          i++;
        } else {
          merged.add(row[i]);
        }
      }
      while (merged.length < 4) merged.add(0);
      if (board[r] != merged) {
        board[r] = merged;
        moved = true;
      }
    }
    if (moved) _addRandomTile();
    return moved;
  }

  bool slideRight() {
    _reverseEachRow();
    bool moved = slideLeft();
    _reverseEachRow();
    return moved;
  }

  bool slideUp() {
    _transpose();
    bool moved = slideLeft();
    _transpose();
    return moved;
  }

  bool slideDown() {
    _transpose();
    _reverseEachRow();
    bool moved = slideLeft();
    _reverseEachRow();
    _transpose();
    return moved;
  }

  void _reverseEachRow() {
    for (int r = 0; r < 4; r++) {
      board[r] = List.from(board[r].reversed);
    }
  }

  void _transpose() {
    final newBoard = List.generate(4, (_) => List.filled(4, 0));
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        newBoard[c][r] = board[r][c];
      }
    }
    board = newBoard;
  }

  bool canMove() {
    for (var r in board) if (r.contains(0)) return true;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        int v = board[r][c];
        if ((r < 3 && board[r + 1][c] == v) || (c < 3 && board[r][c + 1] == v))
          return true;
      }
    }
    return false;
  }
}

void main() => runApp(const Reverse2048App());

class Reverse2048App extends StatelessWidget {
  const Reverse2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reverse 2048',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine engine;

  @override
  void initState() {
    super.initState();
    engine = GameEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reverse 2048')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('امتیاز: ${engine.score}', style: const TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              children: List.generate(16, (index) {
                int row = index ~/ 4;
                int col = index % 4;
                int value = engine.board[row][col];
                return _Tile(value: value);
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      engine.slideUp();
                      if (!engine.canMove()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('بازی تمام شد!')),
                        );
                      }
                    });
                  },
                  child: const Text('بالا'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          engine.slideLeft();
                          if (!engine.canMove()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('بازی تمام شد!')),
                            );
                          }
                        });
                      },
                      child: const Text('چپ'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          engine.slideRight();
                          if (!engine.canMove()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('بازی تمام شد!')),
                            );
                          }
                        });
                      },
                      child: const Text('راست'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      engine.slideDown();
                      if (!engine.canMove()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('بازی تمام شد!')),
                        );
                      }
                    });
                  },
                  child: const Text('پایین'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      engine.newGame();
                    });
                  },
                  child: const Text('بازی جدید'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final int value;
  const _Tile({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value == 0
        ? Colors.grey[200]
        : value <= 4
            ? Colors.orange[200]
            : value <= 8
                ? Colors.orange
                : value <= 16
                    ? Colors.deepOrange
                    : value <= 32
                        ? Colors.red
                        : Colors.purple;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: value == 0
          ? null
          : Center(
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
