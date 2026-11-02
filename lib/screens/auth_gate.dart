import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/election_repository.dart';
import '../state/election_state.dart';
import 'login_screen.dart';
import 'vote_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen(); // nobody is logged in
        }
        // Signed in: one brain for this user, given to the vote screen.
        return ChangeNotifierProvider<ElectionState>(
          create: (_) => ElectionState(ElectionRepository(user.uid)),
          child: const VoteScreen(),
        );
      },
    );
  }
}