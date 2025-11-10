import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'about',
        screenClass: 'AboutPage',
      );
    });
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLicenses(BuildContext context) {
    final analytics = ref.read(analyticsServiceProvider);
    final version = _packageInfo?.version ?? '1.0.0';
    
    analytics.logEvent(
      name: 'about_action',
      parameters: {'action_type': 'view_licenses'},
    );
    
    showLicensePage(
      context: context,
      applicationName: 'FlowDash',
      applicationVersion: version,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('About'),
                  floating: true,
                  snap: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // App Icon
                  Center(
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.dashboard,
                          size: 120,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  const Center(
                    child: Text(
                      'FlowDash',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Version
                  if (_packageInfo != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FlowDash is a mobile application for managing and automating your workflows and instances with ease.',
                    style: TextStyle(fontSize: 16),
                  ),
                  // App Information
                  if (_packageInfo != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Version'),
                            subtitle: Text(_packageInfo!.version),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Build Number'),
                            subtitle: Text(_packageInfo!.buildNumber),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Legal Information
                  const SizedBox(height: 24),
                  const Text(
                    'Legal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.copyright),
                          title: const Text('Copyright'),
                          subtitle: Text(
                            '© ${DateTime.now().year} FlowDash. All rights reserved.',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.code),
                          title: const Text('Open Source Licenses'),
                          subtitle: const Text(
                            'View licenses for open source software used in this app',
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showLicenses(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                      ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

