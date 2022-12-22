import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/"),
            child: const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(
                        "https://cdn.discordapp.com/attachments/976075396149821511/976517163777150996/20220518_171020.jpg"),
                    fit: BoxFit.fill),
              ),
              child: Text("Ola"),
            ),
          ),
          ListTile(
            title: const Text("Esp32"),
            onTap: () {
              Navigator.pushNamed(context, "/esp32");
            },
          ),
          ListTile(
            title: const Text("ZigBee"),
            onTap: () {
              Navigator.pushNamed(context, "/zigbee");
            },
          )
        ],
      ),
    );
  }
}
