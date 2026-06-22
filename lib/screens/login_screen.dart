import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isRegisterMode = false;
  String? errorMessage;

  Future<void> submit() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isRegisterMode) {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = credential.user;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'role': 'member',
            'playerId': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = convertErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String convertErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'このメールアドレスはすでに登録されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードは6文字以上にしてください';
      case 'user-not-found':
        return 'このメールアドレスのユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが間違っています';
      default:
        return e.message ?? 'エラーが発生しました';
    }
  }

  void toggleMode() {
    setState(() {
      isRegisterMode = !isRegisterMode;
      errorMessage = null;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isRegisterMode ? '新規登録' : 'ログイン';
    final buttonText = isRegisterMode ? '登録する' : 'ログイン';
    final loadingText = isRegisterMode ? '登録中...' : 'ログイン中...';
    final toggleText = isRegisterMode ? 'ログインはこちら' : '新規登録はこちら';

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "We's Volleyball Manager",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: Text(isLoading ? loadingText : buttonText),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading ? null : toggleMode,
                  child: Text(toggleText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}