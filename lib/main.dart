import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My PDF Helper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _headerFooterHeight = kTextTabBarHeight;
  static const Color _footerColor = Color(0xFFFFF3E0);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            // Хедер: только табы, высота как у TabBar
            SizedBox(
              height: _headerFooterHeight,
              child: Material(
                color: Theme.of(context).appBarTheme.backgroundColor,
                child: const TabBar(
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: 'Разбиение PDF'),
                    Tab(text: 'Слияние PDF'),
                  ],
                ),
              ),
            ),
            // Основная область контента
            Expanded(
              child: TabBarView(
                children: [
                  Center(
                    child: Text(
                      'Демо‑контент для первого таба',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Демо‑контент для второго таба',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            // Футер той же высоты, пока пустой
            SizedBox(
              height: _headerFooterHeight,
              child: Container(
                color: _footerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

