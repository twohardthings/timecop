// Copyright 2020 Kenton Hamaluik
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timecop/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("aboutPage"),
      appBar: AppBar(title: Text(L10N.of(context).tr.about)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _AboutContent(packageInfo: snapshot.data!);
        },
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  final PackageInfo packageInfo;
  const _AboutContent({required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = L10N.of(context).tr;
    // The app's name as set on MaterialApp.title
    final name =
        context.findAncestorWidgetOfExactType<Title>()?.title ?? tr.appName;
    final version = "v${packageInfo.version}+${packageInfo.buildNumber}";
    Widget icon({double height = 100}) => SvgPicture.asset(
      "icon.no-bg.cyan.svg",
      semanticsLabel: tr.logoSemantics,
      height: height,
    );
    final chevron = Icon(
      Directionality.of(context) == TextDirection.ltr
          ? Icons.chevron_right
          : Icons.chevron_left,
    );

    Widget markdownTile(String filename, String title, FaIconData faIcon) =>
        ListTile(
          leading: FaIcon(faIcon),
          title: Text(title),
          trailing: chevron,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  MarkdownPage(filename: filename, title: Text(title)),
            ),
          ),
        );

    return ListView(
      children: <Widget>[
        const SizedBox(height: 10),
        Center(child: icon()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                name,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                version,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  tr.appLegalese,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(tr.appDescription, textAlign: TextAlign.justify),
              ),
              const Divider(),
            ],
          ),
        ),
        markdownTile('README.md', tr.readme, FontAwesomeIcons.readme),
        markdownTile(
          'CHANGELOG.md',
          tr.changeLog,
          FontAwesomeIcons.boxesStacked,
        ),
        markdownTile(
          'CONTRIBUTORS.md',
          tr.contributors,
          FontAwesomeIcons.userAstronaut,
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.globe),
          title: Text(tr.translate),
          onTap: () => launchUrl(
            Uri.parse("https://hosted.weblate.org/projects/timecop/"),
          ),
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.code),
          title: Text(tr.sourceCode),
          onTap: () =>
              launchUrl(Uri.parse("https://github.com/hamaluik/timecop")),
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.scroll),
          title: Text(MaterialLocalizations.of(context).licensesPageTitle),
          trailing: chevron,
          onTap: () => showLicensePage(
            context: context,
            applicationName: name,
            applicationVersion: version,
            applicationIcon: icon(height: 48),
            applicationLegalese: tr.appLegalese,
          ),
        ),
      ],
    );
  }
}

/// Shows a Markdown asset (e.g. README.md) on its own page, preferring a
/// localized variant such as README-de.md when one is bundled.
class MarkdownPage extends StatefulWidget {
  final String filename;
  final Widget title;
  const MarkdownPage({Key? key, required this.filename, required this.title})
    : super(key: key);

  @override
  State<MarkdownPage> createState() => _MarkdownPageState();
}

class _MarkdownPageState extends State<MarkdownPage> {
  String? _markdown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_markdown == null) _load();
  }

  Future<void> _load() async {
    final locale = Localizations.localeOf(context);
    final bundle = DefaultAssetBundle.of(context);
    final dot = widget.filename.lastIndexOf('.');
    final base = widget.filename.substring(0, dot);
    final ext = widget.filename.substring(dot);
    var markdown = '';
    for (final candidate in <String>[
      '$base-$locale$ext',
      '$base-${locale.languageCode}$ext',
      widget.filename,
    ]) {
      try {
        markdown = await bundle.loadString(candidate);
        break;
      } catch (_) {
        // try the next candidate
      }
    }
    // strip a YAML front matter header, if any
    final header = RegExp(
      r'^---\n(.*?)---\n',
      dotAll: true,
    ).firstMatch(markdown);
    if (header != null) markdown = markdown.substring(header.end);
    if (mounted) setState(() => _markdown = markdown);
  }

  /// flutter_markdown falls back to the legacy Material theme, which the app
  /// no longer provides, so derive every text style from the app's theme.
  MarkdownStyleSheet _styleSheet(ThemeData theme) {
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    final body = text.bodyMedium;
    final boxed = BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(2),
    );
    return MarkdownStyleSheet(
      p: body,
      // colour only, so links inside headings keep the heading's size
      a: TextStyle(
        color: colors.primary,
        decoration: TextDecoration.underline,
      ),
      h1: text.headlineSmall,
      h2: text.titleLarge,
      h3: text.titleMedium,
      h4: text.titleSmall,
      h5: text.bodyLarge,
      h6: text.bodyLarge,
      code: body?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: colors.surfaceContainerHighest,
      ),
      blockquote: body,
      listBullet: body,
      tableHead: body?.copyWith(fontWeight: FontWeight.w700),
      tableBody: body,
      blockquoteDecoration: boxed,
      codeblockDecoration: boxed,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: widget.title),
      body: _markdown == null
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _markdown!,
              styleSheet: _styleSheet(Theme.of(context)),
              onTapLink: (text, href, title) {
                final uri = href == null ? null : Uri.tryParse(href);
                if (uri != null &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
    );
  }
}
