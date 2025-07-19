import 'package:chat/constant.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/userPref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRegister() async {
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final emailRegex = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$");
    final passwordRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    } else if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    } else if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password can only contain letters, numbers, - or _')),
      );
      return;
    } else if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords must be at least 6 characters')),
      );
      return;
    } else if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await auth.signInWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(auth.currentUser?.uid).set({
        'email': email,
        'username': username,
      });
      await auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register success. Please login')),
      );
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register fail. Please try again')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final color = context.watch<ThemeColorProvider>().theme;

    return Scaffold(
      backgroundColor: color.colorShade3,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Register',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color.colorShade1,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: color.colorShade4,
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                controller: usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: color.colorShade4,
                  hintText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: color.colorShade4,
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: color.colorShade4,
                  hintText: 'Confirmed Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: color.colorShade1,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await _handleRegister();
                  },
                  child: const Text(
                    'Create New Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage())
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: color.colorShade1,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
