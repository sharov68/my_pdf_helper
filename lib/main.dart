import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'download_helper.dart' as download_helper;

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
  static final Uri _releasesUri = Uri.parse(
    'https://github.com/sharov68/my_pdf_helper/releases',
  );

  Future<void> _openReleases(BuildContext context) async {
    try {
      final ok = await launchUrl(
        _releasesUri,
        webOnlyWindowName: '_blank',
      );

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть страницу релизов.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при открытии страницы релизов: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

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
                  const PdfSplitTab(),
                  const PdfMergeTab(),
                ],
              ),
            ),
            // Футер той же высоты, пока пустой
            SizedBox(
              height: _headerFooterHeight,
              child: Container(
                color: _footerColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: kIsWeb
                      ? TextButton.icon(
                          onPressed: () => _openReleases(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.brown.shade700,
                          ),
                          icon: const Icon(
                            Icons.open_in_new,
                            size: 16,
                          ),
                          label: const Text('Релизы на GitHub'),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfSplitTab extends StatefulWidget {
  const PdfSplitTab({super.key});

  @override
  State<PdfSplitTab> createState() => _PdfSplitTabState();
}

class _PdfSplitTabState extends State<PdfSplitTab> {
  String? _filePath;
  String? _fileName;
  int? _pageCount;
  bool _isLoadingInfo = false;
  bool _isSplitting = false;

  // Для веба храним байты исходного файла, чтобы можно было разбить его
  // целиком в памяти и отдать пользователю через скачивание.
  Uint8List? _fileBytesWeb;

  final _formKey = GlobalKey<FormState>();
  final List<_PageRange> _ranges = [
    _PageRange(),
  ];

  Future<void> _pickPdf() async {
    try {
      setState(() {
        _isLoadingInfo = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoadingInfo = false;
        });
        return;
      }

      final file = result.files.single;

      // На вебе у FilePicker нет пути к файлу, доступны только байты.
      // См. FAQ плагина: https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ
      if (kIsWeb) {
        final bytes = file.bytes;

        if (bytes == null) {
          setState(() {
            _isLoadingInfo = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Браузер не передал содержимое файла. '
                  'Попробуйте выбрать файл ещё раз или использовать другой браузер.',
                ),
                duration: Duration(minutes: 5),
              ),
            );
          }
          return;
        }

        final document = PdfDocument(inputBytes: bytes);
        final pageCount = document.pages.count;
        document.dispose();

        setState(() {
          // В веб‑версии настоящего пути к файлу нет.
          _filePath = null;
          _fileName = file.name;
          _pageCount = pageCount;
          _fileBytesWeb = bytes;
          _ranges
            ..clear()
            ..add(_PageRange(from: 1, to: pageCount));
        });
      } else {
        final path = file.path;

        if (path == null) {
          setState(() {
            _isLoadingInfo = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось получить путь к выбранному файлу.'),
                duration: Duration(minutes: 5),
              ),
            );
          }
          return;
        }

        final bytes = await File(path).readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        final pageCount = document.pages.count;
        document.dispose();

        setState(() {
          _filePath = path;
          _fileName = p.basename(path);
          _pageCount = pageCount;
          _ranges
            ..clear()
            ..add(_PageRange(from: 1, to: pageCount));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе файла: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInfo = false;
        });
      }
    }
  }

  void _addRange() {
    setState(() {
      _ranges.add(_PageRange());
    });
  }

  Future<void> _splitPdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    final pageCount = _pageCount;

    final validRanges = _ranges
        .where(
          (r) =>
              r.from != null &&
              r.to != null &&
              r.from! >= 1 &&
              r.to! >= r.from! &&
              (pageCount == null || r.to! <= pageCount),
        )
        .toList();

    if (validRanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите хотя бы один корректный диапазон страниц.'),
          duration: Duration(minutes: 5),
        ),
      );
      return;
    }

    if (kIsWeb) {
      // Веб‑режим: всё разбиение выполняем в памяти и выдаём файлы
      // пользователю через скачивание, не трогая локальную файловую систему.
      await _splitPdfWeb(validRanges);
      return;
    }

    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выберите PDF-файл.'),
          duration: Duration(minutes: 5),
        ),
      );
      return;
    }

    await _splitPdfDesktop(validRanges);
  }

  Future<void> _splitPdfWeb(List<_PageRange> validRanges) async {
    if (_fileBytesWeb == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выберите PDF-файл.'),
          duration: Duration(minutes: 5),
        ),
      );
      return;
    }

    setState(() {
      _isSplitting = true;
    });

    // Даём фреймворку отрисовать изменение UI (кнопка, индикатор прогресса)
    // перед началом тяжёлой синхронной работы.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final sourceBytes = _fileBytesWeb!;
      final document = PdfDocument(inputBytes: sourceBytes);
      final totalPages = document.pages.count;

      final baseName = _fileName != null
          ? p.basenameWithoutExtension(_fileName!)
          : 'document';

      var index = 1;
      final results = <_SplitResult>[];

      for (final range in validRanges) {
        final from = range.from!;
        final to = range.to!;

        if (from > totalPages) {
          continue;
        }

        final lastPage = to > totalPages ? totalPages : to;

        final outDoc = PdfDocument();
        outDoc.pageSettings.margins.all = 0;

        for (var pageNum = from; pageNum <= lastPage; pageNum++) {
          final originalPage = document.pages[pageNum - 1];
          final template = originalPage.createTemplate();
          final newPage = outDoc.pages.add();
          final pageSize = newPage.getClientSize();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            Size(pageSize.width, pageSize.height),
          );
        }

        final outBytes = await outDoc.save();
        outDoc.dispose();

        final indexStr = index.toString().padLeft(3, '0');
        final fileName =
            '${baseName}_$indexStr' '_${from}-${lastPage}.pdf'; // e.g. doc_001_1-3.pdf

        results.add(_SplitResult(fileName: fileName, bytes: outBytes));
        index++;
      }

      document.dispose();

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Не удалось создать файлы по указанным диапазонам. Проверьте номера страниц.',
              ),
              duration: Duration(minutes: 5),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Файлы готовы'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Нажмите на файл, чтобы скачать его:'),
                  const SizedBox(height: 12),
                  ...results.map(
                    (result) => TextButton.icon(
                      onPressed: () => download_helper.downloadBytes(
                        result.fileName,
                        result.bytes,
                      ),
                      icon: const Icon(Icons.download),
                      label: Text(result.fileName),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF успешно разбит. Файлов для скачивания: ${results.length}',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при разбиении PDF: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSplitting = false;
        });
      }
    }
  }

  Future<void> _splitPdfDesktop(List<_PageRange> validRanges) async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выберите PDF-файл.'),
          duration: Duration(minutes: 5),
        ),
      );
      return;
    }

    // Определяем папку out рядом с исходным файлом и предупреждаем,
    // что при разбиении её содержимое будет полностью удалено.
    final sourceFile = File(_filePath!);
    final parentDir = sourceFile.parent.path;
    final outDirPath = p.join(parentDir, 'out');
    final outDir = Directory(outDirPath);

    if (await outDir.exists()) {
      final existingEntries =
          outDir.listSync().toList(growable: false);
      if (existingEntries.isNotEmpty) {
        if (!mounted) return;

        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Внимание'),
              content: const Text(
                'Папка \"out\" уже существует и содержит файлы. '
                'Перед разбиением ВСЕ файлы в этой папке будут удалены и заменены новыми. '
                'Продолжить?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Да, продолжить'),
                ),
              ],
            );
          },
        );

        if (shouldContinue != true) {
          return;
        }
      }
    }

    // Создаём папку out (если её нет) и полностью очищаем её содержимое.
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    } else {
      await for (final entity in outDir.list(recursive: false)) {
        await entity.delete(recursive: true);
      }
    }

    setState(() {
      _isSplitting = true;
    });

    // Даём отрисоваться изменениям UI перед началом тяжёлой работы.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final sourceBytes = await sourceFile.readAsBytes();
      final document = PdfDocument(inputBytes: sourceBytes);
      final totalPages = document.pages.count;

      final dirPath = outDirPath;
      final baseName = p.basenameWithoutExtension(sourceFile.path);

      var index = 1;
      final createdFiles = <String>[];

      for (final range in validRanges) {
        final from = range.from!;
        final to = range.to!;

        if (from > totalPages) {
          continue;
        }

        final lastPage = to > totalPages ? totalPages : to;

        final outDoc = PdfDocument();
        outDoc.pageSettings.margins.all = 0;

        for (var pageNum = from; pageNum <= lastPage; pageNum++) {
          final originalPage = document.pages[pageNum - 1];
          final template = originalPage.createTemplate();
          final newPage = outDoc.pages.add();
          final pageSize = newPage.getClientSize();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            Size(pageSize.width, pageSize.height),
          );
        }

        final outBytes = await outDoc.save();
        outDoc.dispose();

        final indexStr = index.toString().padLeft(3, '0');
        final fileName =
            '${baseName}_$indexStr' '_${from}-${lastPage}.pdf'; // e.g. doc_001_1-3.pdf
        final outPath = p.join(dirPath, fileName);

        final outFile = File(outPath);
        await outFile.writeAsBytes(outBytes, flush: true);

        createdFiles.add(outPath);
        index++;
      }

      document.dispose();

      if (createdFiles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Не удалось создать файлы по указанным диапазонам. Проверьте номера страниц.',
              ),
              duration: Duration(minutes: 5),
            ),
          );
        }
        return;
      }

      if (mounted) {
        // Показываем диалог с точным путём и именами файлов
        // чтобы пользователь точно знал, где искать результат.
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Файлы созданы'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Папка:'),
                    const SizedBox(height: 4),
                    Text(
                      dirPath,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    const Text('Файлы:'),
                    const SizedBox(height: 8),
                    ...createdFiles.map(
                      (path) => Text('• ${p.basename(path)}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF успешно разбит. Создано файлов: ${createdFiles.length}',
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при разбиении PDF: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSplitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingInfo || _isSplitting ? null : _pickPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                _isLoadingInfo ? 'Загрузка...' : 'Выбери PDF',
              ),
            ),
          ),
          if (_isLoadingInfo || _isSplitting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  _isLoadingInfo
                      ? 'Читаем файл...'
                      : 'Разбиваем PDF, подождите...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (_fileName != null) ...[
            const SizedBox(height: 12),
            Text(
              'Файл: $_fileName'
              '${_pageCount != null ? ' (страниц: $_pageCount)' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Диапазоны страниц',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ..._buildRangeFields(context),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addRange,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить диапазон'),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _isSplitting || _isLoadingInfo ? null : _splitPdf,
                    child: Text(
                      _isSplitting ? 'Разбиение...' : 'Разбить',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRangeFields(BuildContext context) {
    final pageCount = _pageCount;

    return List.generate(_ranges.length, (index) {
      final range = _ranges[index];
      final isFirst = index == 0;

      return Padding(
        padding: EdgeInsets.only(bottom: isFirst ? 8 : 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'От',
                  helperText:
                      pageCount != null ? '1–$pageCount' : 'Номер страницы',
                ),
                keyboardType: TextInputType.number,
                initialValue: range.from?.toString(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Укажите страницу';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Некорректное число';
                  }
                  if (pageCount != null && parsed > pageCount) {
                    return 'Макс. $pageCount';
                  }
                  return null;
                },
                onSaved: (value) {
                  range.from = int.tryParse(value?.trim() ?? '');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'До',
                ),
                keyboardType: TextInputType.number,
                initialValue: range.to?.toString(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Укажите страницу';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Некорректное число';
                  }
                  if (pageCount != null && parsed > pageCount) {
                    return 'Макс. $pageCount';
                  }
                  if (range.from != null && parsed < range.from!) {
                    return 'Должно быть ≥ ${range.from}';
                  }
                  return null;
                },
                onSaved: (value) {
                  range.to = int.tryParse(value?.trim() ?? '');
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PageRange {
  _PageRange({this.from, this.to});

  int? from;
  int? to;
}

class _SplitResult {
  _SplitResult({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final List<int> bytes;
}

class PdfMergeTab extends StatefulWidget {
  const PdfMergeTab({super.key});

  @override
  State<PdfMergeTab> createState() => _PdfMergeTabState();
}

class _PdfMergeTabState extends State<PdfMergeTab> {
  String? _directoryPath;
  int _lastFoundFilesCount = 0;
  bool _isScanning = false;
  bool _isMerging = false;

  Future<void> _pickFolderAndScan() async {
    // На вебе нет доступа к локальной файловой системе и выбору папки,
    // поэтому вместо этого позволяем выбрать несколько файлов через FilePicker.
    if (kIsWeb) {
      await _pickFilesWebAndMaybeMerge();
      return;
    }

    try {
      setState(() {
        _isScanning = true;
      });

      final dirPath = await FilePicker.platform.getDirectoryPath();

      if (!mounted) return;

      if (dirPath == null) {
        setState(() {
          _isScanning = false;
        });
        return;
      }

      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выбранная папка недоступна.'),
            duration: Duration(minutes: 5),
          ),
        );
        return;
      }

      final entities = directory.listSync().whereType<File>().toList();
      final pdfFiles = entities
          .where(
            (f) => p.extension(f.path).toLowerCase() == '.pdf',
          )
          .toList();

      if (pdfFiles.isEmpty) {
        setState(() {
          _directoryPath = dirPath;
          _lastFoundFilesCount = 0;
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('В выбранной папке нет PDF‑файлов.'),
            duration: Duration(seconds: 10),
          ),
        );
        return;
      }

      pdfFiles.sort(
        (a, b) => p.basename(a.path).toLowerCase().compareTo(
              p.basename(b.path).toLowerCase(),
            ),
      );

      setState(() {
        _directoryPath = dirPath;
        _lastFoundFilesCount = pdfFiles.length;
        _isScanning = false;
      });

      final shouldMerge = await _showFilesDialog(dirPath, pdfFiles);

      if (!mounted || shouldMerge != true) {
        return;
      }

      await _mergeFiles(dirPath, pdfFiles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сканировании папки: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _pickFilesWebAndMaybeMerge() async {
    try {
      setState(() {
        _isScanning = true;
      });

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pdfFiles = result.files
          .where((f) => (f.bytes != null && f.bytes!.isNotEmpty))
          .toList();

      if (pdfFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось получить содержимое выбранных файлов. '
              'Попробуйте ещё раз или используйте другой браузер.',
            ),
            duration: Duration(minutes: 5),
          ),
        );
        return;
      }

      pdfFiles.sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

      final shouldMerge = await _showFilesDialogWeb(pdfFiles);

      if (!mounted || shouldMerge != true) {
        return;
      }

      await _mergeFilesWeb(pdfFiles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе файлов: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<bool?> _showFilesDialog(String dirPath, List<File> pdfFiles) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Найденные PDF‑файлы'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Папка:'),
                const SizedBox(height: 4),
                Text(
                  dirPath,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text('Файлов: ${pdfFiles.length}'),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pdfFiles.length,
                    itemBuilder: (context, index) {
                      final file = pdfFiles[index];
                      return Text('• ${p.basename(file.path)}');
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Слить'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showFilesDialogWeb(List<PlatformFile> pdfFiles) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Найденные PDF‑файлы'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Файлов: ${pdfFiles.length}'),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pdfFiles.length,
                    itemBuilder: (context, index) {
                      final file = pdfFiles[index];
                      return Text('• ${file.name}');
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Слить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mergeFiles(String dirPath, List<File> pdfFiles) async {
    setState(() {
      _isMerging = true;
    });

    try {
      if (pdfFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет файлов для слияния.'),
            duration: Duration(seconds: 10),
          ),
        );
        return;
      }

      // Папка для результата: ../out_merged относительно выбранной папки.
      final outDirPath = p.normalize(p.join(dirPath, '..', 'out_merged'));
      final outDir = Directory(outDirPath);
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }

      final firstFile = pdfFiles.first;
      final outFileName = p.basename(firstFile.path);
      final outPath = p.join(outDirPath, outFileName);

      final mergedDocument = PdfDocument();
      mergedDocument.pageSettings.margins.all = 0;

      for (final file in pdfFiles) {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        final pageCount = document.pages.count;

        for (var i = 0; i < pageCount; i++) {
          final originalPage = document.pages[i];
          final template = originalPage.createTemplate();
          final newPage = mergedDocument.pages.add();
          final pageSize = newPage.getClientSize();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            Size(pageSize.width, pageSize.height),
          );
        }

        document.dispose();
      }

      final outBytes = await mergedDocument.save();
      mergedDocument.dispose();

      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes, flush: true);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Файл создан'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Папка:'),
                const SizedBox(height: 4),
                Text(
                  outDirPath,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                const Text('Файл:'),
                const SizedBox(height: 4),
                Text(
                  p.basename(outPath),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Файлы успешно слиты. Итоговый файл: ${p.basename(outPath)}',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при слиянии файлов: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMerging = false;
        });
      }
    }
  }

  Future<void> _mergeFilesWeb(List<PlatformFile> pdfFiles) async {
    setState(() {
      _isMerging = true;
    });

    // Даём отрисоваться изменению состояния кнопки перед тяжёлой работой.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      if (pdfFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет файлов для слияния.'),
            duration: Duration(seconds: 10),
          ),
        );
        return;
      }

      final mergedDocument = PdfDocument();
      mergedDocument.pageSettings.margins.all = 0;

      for (final file in pdfFiles) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          continue;
        }

        final document = PdfDocument(inputBytes: bytes);
        final pageCount = document.pages.count;

        for (var i = 0; i < pageCount; i++) {
          final originalPage = document.pages[i];
          final template = originalPage.createTemplate();
          final newPage = mergedDocument.pages.add();
          final pageSize = newPage.getClientSize();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            Size(pageSize.width, pageSize.height),
          );
        }

        document.dispose();
      }

      final outBytes = await mergedDocument.save();
      mergedDocument.dispose();

      if (!mounted) return;

      if (outBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось создать объединённый файл.'),
            duration: Duration(minutes: 5),
          ),
        );
        return;
      }

      final firstName = pdfFiles.first.name;
      final baseName = p.basenameWithoutExtension(firstName);
      final outFileName = '${baseName}_merged.pdf';

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Файл готов'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Нажмите, чтобы скачать объединённый файл:'),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => download_helper.downloadBytes(
                    outFileName,
                    outBytes,
                  ),
                  icon: const Icon(Icons.download),
                  label: Text(outFileName),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Файлы успешно слиты. Итоговый файл: $outFileName',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при слиянии файлов: $e'),
            duration: const Duration(minutes: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMerging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning || _isMerging ? null : _pickFolderAndScan,
              icon: const Icon(Icons.folder),
              label: Text(
                _isScanning
                    ? 'Сканирование...'
                    : (kIsWeb ? 'Выбрать файлы' : 'Выбрать папку'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_directoryPath != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Последняя выбранная папка:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _directoryPath!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Найдено PDF‑файлов: $_lastFoundFilesCount',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

