import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/styles/github.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

const _defaultScript = """
import widgets;
import material;

widget text = Text(
  text: 'Some text here', 
  textAlign: "center"
);

widget node = Container(
  height: 100.0,
  width: 200.0,
  color: 0xFF80ACEF,
  child: Center(
    child: text()
  )
);

widget main = Center(
  child: node()
);

""";

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const Scaffold(
        body: Demo(),
      ),
    );
  }
}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => DemoState();
}

class DemoState extends State<Demo> {
  final _selectWidgetKey = GlobalKey();
  final _runtime = Runtime();
  final _data = DynamicContent();
  final _codeController = CodeLineEditingController();
  var _showBackground = false;
  var _error = "";
  var _main = 'main';

  static const _library = LibraryName(["demo"]);

  void _update({bool rebuild = true}) {
    try {
      _runtime.update(_library, parseLibraryFile(_codeController.text));
      _error = "";
    } catch (e) {
      _error = '$e';
    }
    if (rebuild) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _codeController.text = _defaultScript;
    _runtime.update(
      const LibraryName(['widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(['material']),
      createMaterialWidgets(),
    );
    _update(rebuild: false);
  }

  void _showSettingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, rebuild) {
            return AlertDialog(
              title: const Text('Settings'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 360.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Show background'),
                      value: _showBackground,
                      onChanged: (value) {
                        setState(() {
                          _showBackground = value;
                          rebuild(() {});
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4.0,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Update'),
                        onPressed: _update,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                        onPressed: _showSettingDialog,
                      ),
                      TextButton.icon(
                        key: _selectWidgetKey,
                        icon: const Icon(Icons.dashboard),
                        onPressed: () async {
                          // dropdown menu
                          final library = _runtime.libraries[_library];
                          final widgets = <String>[];
                          if (library is RemoteWidgetLibrary) {
                            for (var widget in library.widgets) {
                              widgets.add(widget.name);
                            }
                          }

                          final box = _selectWidgetKey.currentContext
                              ?.findRenderObject() as RenderBox?;
                          final position =
                              box?.localToGlobal(Offset.zero) ?? Offset.zero;
                          final size = box?.size ?? Size.zero;

                          final value = await showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              position.dx,
                              position.dy + size.height,
                              double.infinity,
                              double.infinity,
                            ),
                            initialValue: _main,
                            items: widgets
                                .map((w) => PopupMenuItem<String>(
                                      value: w,
                                      child: Text(w),
                                    ))
                                .toList(),
                          );

                          if (value != null) {
                            setState(() {
                              _main = value;
                            });
                          }
                        },
                        label: Text('Widget: $_main'),
                      ),
                      if (_error.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                          icon: const Icon(Icons.error_outline),
                          label: const Text('Errors'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Errors'),
                                  content: Text(_error),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: colors.primary,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: CodeEditor(
                        controller: _codeController,
                        wordWrap: true,
                        autofocus: true,
                        style: CodeEditorStyle(
                          fontSize: 14,
                          fontFamily: 'RobotoMono',
                          codeTheme: CodeHighlightTheme(
                            languages: {
                              'rfwtxt': CodeHighlightThemeMode(
                                mode: langDart,
                              ),
                            },
                            theme: githubTheme,
                          ),
                        ),
                        indicatorBuilder: (context, editingController,
                            chunkController, notifier) {
                          return Row(
                            children: [
                              DefaultCodeLineNumber(
                                controller: editingController,
                                notifier: notifier,
                              ),
                              const SizedBox(width: 8),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _showBackground
                    ? colors.secondaryContainer
                    : colors.surface,
                child: RemoteWidget(
                  runtime: _runtime,
                  data: _data,
                  widget: FullyQualifiedWidgetName(_library, _main),
                  onEvent: (String name, DynamicMap arguments) {
                    debugPrint(
                        'user triggered event "$name" with data: $arguments');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
