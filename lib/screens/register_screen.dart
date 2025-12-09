import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/providers/auth_state.dart';
import 'package:foodbridge/utils/constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  String _selectedRole = rolePersonal;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).register(
            email: _emailController.text,
            password: _passwordController.text,
            username: _usernameController.text,
            role: _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AppAuthState>(authProvider, (previous, current){
      if (current.error != null && !current.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Error: ${current.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Register new Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val!.isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Password should be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (val) =>
                    val!.isEmpty ? 'Username is required' : null,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: rolePersonal,
                    child: Text('Personal (Donor and Recipient)'),
                  ),
                  DropdownMenuItem(
                    value: roleCompany,
                    child: Text('Company/Restaurant'),
                  ),
                  DropdownMenuItem(
                    value: roleInNeed,
                    child: Text('Person in Need'),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),

              authState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                     onPressed: _register,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),),
                     child: const Text('Register', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
}
}