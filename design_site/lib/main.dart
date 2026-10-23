import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

import 'catalog_page.dart';

void main() => runApp(const DesignSite());

class DesignSite extends StatefulWidget {
  const DesignSite({super.key});

  @override
  State<DesignSite> createState() => _DesignSiteState();
}

class _DesignSiteState extends State<DesignSite> {
  ThemeMode mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ImHere 디자인 시스템',
    debugShowCheckedModeBanner: false,
    theme: ImHereTheme.light,
    darkTheme: ImHereTheme.dark,
    themeMode: mode,
    home: CatalogPage(
      dark: mode == ThemeMode.dark,
      onThemeChanged: (dark) =>
          setState(() => mode = dark ? ThemeMode.dark : ThemeMode.light),
    ),
  );
}
