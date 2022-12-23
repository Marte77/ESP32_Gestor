import 'dart:async';
import 'dart:io';
import 'package:esp32_frontend/paginas/esp32.dart';
import 'package:esp32_frontend/paginas/zigbee.dart';
import 'package:esp32_frontend/widgets/other/navdrawer.dart';
import 'package:flutter/material.dart';

StreamController<MaterialColor> colorTheme = StreamController();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MaterialColor>(
      initialData: Colors.pink,
      stream: colorTheme.stream,
      builder: ((context, snapshot) {
        return MaterialApp(
          title: 'Mudar Leds',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              primarySwatch: snapshot.data ?? Colors.pink,
              splashFactory: InkSplash.splashFactory),
          routes: {
            '/': (context) => const MyHomePage(title: "Pagina inicial"),
            '/esp32': (context) => const PaginaEsp32(),
            '/zigbee': (context) => const PaginaZigbee()
          },
          onUnknownRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) => Scaffold(
                  body: ElevatedButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('Not Found'))),
            );
          },
        );
      }),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Inicio"),
        ),
        drawer: const NavDrawer(),
        body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/pizza.jpg'),
                  fit: BoxFit.fill),
            ),
            child: Column(children: const [
              Card(
                child: Text(
                    "todo fazer cards para mostrar as fitas e lampadas disponiveis"),
              )
            ])));
  }
}
