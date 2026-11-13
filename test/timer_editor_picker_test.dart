import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
import 'package:timecop/screens/timer/TimerEditor.dart';

// Regression test: flutter_datetime_picker_plus 2.x used the legacy
// package:flutter/material.dart localizations, which the app no longer
// provides (it uses material_ui), so the pickers threw "No
// MaterialLocalizations found" and never opened.
void main() {
  testWidgets('Timer editor rows open the date/time pickers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final settings = MockSettingsProvider();
    final data = MockDataProvider(const Locale('en'));
    final notifications = NotificationsProvider(
      FlutterLocalNotificationsPlugin(),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc(settings)),
          BlocProvider<LocaleBloc>(create: (_) => LocaleBloc(settings)),
          BlocProvider<SettingsBloc>(
            create: (_) => SettingsBloc(settings, data),
          ),
          BlocProvider<TimersBloc>(
            create: (_) => TimersBloc(data, settings, notifications),
          ),
          BlocProvider<ProjectsBloc>(create: (_) => ProjectsBloc(data)),
          BlocProvider<NotificationsBloc>(
            create: (_) => NotificationsBloc(notifications),
          ),
        ],
        child: app.TimeCopApp(settings: settings),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final timers = await tester.runAsync(() => data.listTimers());
    final timer = timers!.firstWhere((t) => t.endTime != null);
    Navigator.of(tester.element(find.byType(Scaffold).first))
        .push(MaterialPageRoute(builder: (_) => TimerEditor(timer: timer)));
    await tester.pumpAndSettle();

    for (final label in ['Start Time', 'End Time', 'Duration']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
      expect(
        find.text('Done'),
        findsOneWidget,
        reason: '$label: picker sheet not shown',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
    }
  });
}
