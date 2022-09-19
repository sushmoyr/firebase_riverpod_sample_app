import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_riverpod_sample_app/controllers/auth_controler.dart';
import 'package:firebase_riverpod_sample_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authControllerState = ref.read(authControllerProvider.notifier);
    final authController = ref.watch(authControllerProvider);

    print(authController != null ? 'Signed in' : 'null signing');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        leading: authController != null ? IconButton(
          icon: Icon(Icons.logout),
          onPressed: (){
            authControllerState.signOut();
          },
        ) : null,
      ),
      body: Center(
        child: Text(authController?.uid.toString() ?? 'No User'),
      ),
    );
  }

}