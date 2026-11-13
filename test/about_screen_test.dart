import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timecop/blocs/locale/locale_bloc.dart';
import 'package:timecop/blocs/notifications/notifications_bloc.dart';
import 'package:timecop/blocs/projects/projects_bloc.dart';
import 'package:timecop/blocs/settings/bloc.dart';
import 'package:timecop/blocs/theme/theme_bloc.dart';
import 'package:timecop/blocs/timers/timers_bloc.dart';
import 'package:timecop/data_providers/data/mock_data_provider.dart';
import 'package:timecop/data_providers/notifications/notifications_provider.dart';
import 'package:timecop/data_providers/settings/mock_settings_provider.dart';
import 'package:timecop/main.dart' as app;
import 'package:timecop/screens/about/AboutScreen.dart';

// Regression test: the `about` package was built on the legacy
// package:flutter/material.dart, which the app no longer provides (it uses
// material_ui), so the About screen threw "No Material widget found" /
// "No MaterialLocalizations found" and rendered nothing.
void main() {
  testWidgets('About screen, README page and licenses page render',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    PackageInfo.setMockInitialValues(
        appName: 'Time Cop',
        packageName: 'io.github.twohardthings.timecop',
        version: '1.8.1',
        buildNumber: '45',
        buildSignature: '');

    final settings = MockSettingsProvider();
    final data = MockDataProvider(const Locale('en'));
    final notifications =
        NotificationsProvider(FlutterLocalNotificationsPlugin());
    await tester.pumpWidget(MultiBlocProvider(providers: [
      BlocProvider<ThemeBloc>(create: (_) => ThemeBloc(settings)),
      BlocProvider<LocaleBloc>(create: (_) => LocaleBloc(settings)),
      BlocProvider<SettingsBloc>(create: (_) => SettingsBloc(settings, data)),
      BlocProvider<TimersBloc>(
          create: (_) => TimersBloc(data, settings, notifications)),
      BlocProvider<ProjectsBloc>(create: (_) => ProjectsBloc(data)),
      BlocProvider<NotificationsBloc>(
          create: (_) => NotificationsBloc(notifications)),
    ], child: app.TimeCopApp(settings: settings)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> settle() async {
      // the asset bundle and PackageInfo load asynchronously
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Navigator.of(tester.element(find.byType(Scaffold).first))
        .push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
    await settle();
    expect(tester.takeException(), isNull);
    expect(find.text('v1.8.1+45'), findsOneWidget);
    expect(find.text('Readme'), findsOneWidget);

    await tester.tap(find.text('Readme'));
    await settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Markdown), findsOneWidget);
    expect(find.textContaining('Time Cop', findRichText: true), findsWidgets);

    await tester.pageBack();
    await settle();
    await tester.tap(find.text('Licenses'));
    await settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LicensePage), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
