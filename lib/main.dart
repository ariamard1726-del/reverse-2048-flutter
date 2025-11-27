import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Pro',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameModel extends ChangeNotifier {
  List<List<int>> _grid = List.generate(4, (_) => List.filled(4, 0));
  int _score = 0;
  int _bestScore = 0;
  bool _gameOver = false;
  final Random _random = Random();

  List<List<int>> get grid => _grid;
  int get score => _score;
  int get bestScore => _bestScore;
  bool get gameOver => _gameOver;

  GameModel() {
    initializeGame();
  }

  void initializeGame() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _gameOver = false;
    _addRandomTile();
    _addRandomTile();
    notifyListeners();
  }

  void _addRandomTile() {
    List<Point> emptyCells = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (_grid[i][j] == 0) {
          emptyCells.add(Point(i, j));
        }
      }
    }
    
    if (emptyCells.isNotEmpty) {
      Point cell = emptyCells[_random.nextInt(emptyCells.length)];
      _grid[cell.x][cell.y] = _random.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void moveLeft() {
    bool changed = false;
    for (int i = 0; i < 4; i++) {
      List<int> row = _grid[i].where((num) => num != 0).toList();
      
      for (int j = 0; j < row.length - 1; j++) {
        if (row[j] == row[j + 1]) {
          row[j] *= 2;
          _score += row[j];
          row.removeAt(j + 1);
        }
      }
      
      while (row.length < 4) {
        row.add(0);
      }
      
      if (!_listEquals(_grid[i], row)) {
        changed = true;
        _grid[i] = row;
      }
    }
    
    if (changed) {
      _addRandomTile();
      _checkGameOver();
      notifyListeners();
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void rotateGrid() {
    List<List<int>> newGrid = List.generate(4, (_) => List.filled(4, 0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        newGrid[j][3 - i] = _grid[i][j];
      }
    }
    _grid = newGrid;
  }

  void move(Direction direction) {
    if (_gameOver) return;
    
    switch (direction) {
      case Direction.left:
        moveLeft();
        break;
      case Direction.right:
        rotateGrid(); rotateGrid();
        moveLeft();
        rotateGrid(); rotateGrid();
        break;
      case Direction.up:
        rotateGrid(); rotateGrid(); rotateGrid();
        moveLeft();
        rotateGrid();
        break;
      case Direction.down:
        rotateGrid();
        moveLeft();
        rotateGrid(); rotateGrid(); rotateGrid();
        break;
    }
  }

  void _checkGameOver() {
    bool hasEmpty = false;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (_grid[i][j] == 0) {
          hasEmpty = true;
          break;
        }
      }
    }
    if (!hasEmpty) {
      _gameOver = true;
    }
  }
}

class Point {
  final int x, y;
  Point(this.x, this.y);
}

enum Direction { up, down, left, right }

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameModel = Provider.of<GameModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048 PRO'),
        backgroundColor: Colors.orange,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: gameModel.initializeGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ScoreCard(
                    title: 'SCORE',
                    value: gameModel.score,
                  ),
                  _ScoreCard(
                    title: 'BEST',
                    value: gameModel.bestScore,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      int row = index ~/ 4;
                      int col = index % 4;
                      int value = gameModel.grid[row][col];
                      
                      return _Tile(value: value);
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              _ControlPad(onSwipe: gameModel.move),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: gameModel.initializeGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text('NEW GAME'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int value;
  
  const _ScoreCard({required this.title, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
  
  Color _getColor() {
    switch (value) {
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFFCDC1B4);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          value == 0 ? '' : value.toString(),
          style: TextStyle(
            fontSize: value < 100 ? 22 : value < 1000 ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: value < 8 ? const Color(0xFF776E65) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ControlPad extends StatelessWidget {
  final Function(Direction) onSwipe;
  
  const _ControlPad({required this.onSwipe});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, size: 40),
          onPressed: () => onSwipe(Direction.up),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[300],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_left, size: 40),
              onPressed: () => onSwipe(Direction.left),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 60),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_right, size: 40),
              onPressed: () => onSwipe(Direction.right),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 40),
          onPressed: () => onSwipe(Direction.down),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}