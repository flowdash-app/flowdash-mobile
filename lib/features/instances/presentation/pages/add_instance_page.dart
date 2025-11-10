import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';

class AddInstancePage extends ConsumerStatefulWidget {
  const AddInstancePage({super.key});

  @override
  ConsumerState<AddInstancePage> createState() => _AddInstancePageState();
}

class _AddInstancePageState extends ConsumerState<AddInstancePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'add_instance',
        screenClass: 'AddInstancePage',
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Instance name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Instance URL is required';
    }
    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }
    try {
      Uri.parse(url);
    } catch (e) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(instanceRepositoryProvider);
      await repository.createInstance(
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
        apiKey: _apiKeyController.text.trim().isEmpty
            ? null
            : _apiKeyController.text.trim(),
      );

      // Optimistic update: invalidate providers to trigger refresh
      // This will reload instances from server (which now includes the new one)
      ref.invalidate(instancesProvider);
      // Also reload workflows since a new instance might be active
      ref.invalidate(workflowsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instance added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add instance: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Add Instance'),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Instance Name',
                  hintText: 'My n8n Instance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateName,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Instance URL',
                  hintText: 'https://n8n.example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: _validateUrl,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key (Optional)',
                  hintText: 'Enter your n8n API key',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                ),
                obscureText: _obscureApiKey,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              const Text(
                'Note: The API key is optional but may be required for some n8n instances. If your instance requires authentication, enter your API key here.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Instance'),
              ),
            ],
          ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

