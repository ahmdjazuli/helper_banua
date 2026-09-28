import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/img/logo.png', width: 38, height: 38, fit: BoxFit.contain),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'HELPER\n', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, height: 1.0)),
                    TextSpan(text: 'BANUA', style: TextStyle(color: Color(0xFFFFCB05), fontWeight: FontWeight.w900, fontSize: 16, height: 1.0)),
                  ],
                ),
              ),
            ],
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: user != null 
                ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() 
                : const Stream.empty(),
            builder: (context, snapshot) {
              Map<String, dynamic>? userData;
              if (snapshot.hasData && snapshot.data!.exists) {
                userData = snapshot.data!.data() as Map<String, dynamic>?;
              }

              final String displayName = user?.displayName ?? userData?['nama'] ?? userData?['name'] ?? 'Pengguna';
              final String? photoUrl = user?.photoURL ?? userData?['photoUrl'] ?? userData?['foto'];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade400,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                          ? NetworkImage(photoUrl) 
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty) 
                          ? const Icon(Icons.person, size: 16, color: Colors.white) 
                          : null,
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(text: 'Halo, \n', style: TextStyle(color: Colors.black54, fontSize: 10)),
                          TextSpan(
                            text: displayName, 
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}