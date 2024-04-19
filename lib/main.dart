import 'package:flutter/material.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

const _defaultScript = """
import core.widgets;
import core.material;

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
    return const MaterialApp(
      home: Scaffold(
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
  final _runtime = Runtime();
  final _data = DynamicContent();
  var _script = _defaultScript;
  var _showBackground = false;

  static const _name = LibraryName(["demo"]);

  void _update() {
    _runtime.update(_name, parseLibraryFile(_script));
  }

  @override
  void initState() {
    super.initState();
    _runtime.update(
      const LibraryName(['core', 'widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(['core', 'material']),
      createMaterialWidgets(),
    );
    _update();
  }

  void _showSettingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, rebuild) {
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
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12.0,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Update'),
                        onPressed: _update,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                        onPressed: _showSettingDialog,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: _script,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints.expand(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      onChanged: (value) {
                        _script = value.replaceAll('\r', '');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _showBackground
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.surface,
                child: RemoteWidget(
                  runtime: _runtime,
                  data: _data,
                  widget: const FullyQualifiedWidgetName(_name, 'main'),
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
