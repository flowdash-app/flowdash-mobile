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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.dashboard,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'FlowDash',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_packageInfo != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
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
                            title: const Text('Package Name'),
                            subtitle: Text(_packageInfo!.packageName),
                          ),
                          const Divider(),
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
                ],
              ),
            ),
    );
  }
}

