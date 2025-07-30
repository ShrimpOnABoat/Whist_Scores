//
//  Whist_ScoresApp.swift
//  Whist Scores
//
//  Created by Tony Buffard on 2025-04-03.
//

import SwiftUI
import CloudKit
import Firebase
import FirebaseAppCheck
import FirebaseAuth

@main
struct Whist_ScoresApp: App {
    @StateObject private var gameManager = GameManager()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    
    init() {
        // Configure Firebase
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        FirebaseApp.configure()
        // Ensure there is a signed‑in Firebase user
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ Firebase anonymous sign‑in failed: \(error.localizedDescription)")
                } else if let uid = authResult?.user.uid {
                    print("✅ Signed in anonymously with UID: \(uid)")
                }
            }
        } else if let uid = Auth.auth().currentUser?.uid {
            print("✅ Reusing existing Firebase UID: \(uid)")
        }

        // Listen for auth‑state changes so we can automatically re‑authenticate
        self.authStateListener = Auth.auth().addStateDidChangeListener { _, user in
            guard user == nil else { return }
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ Re‑auth failed: \(error.localizedDescription)")
                } else if let uid = authResult?.user.uid {
                    print("✅ Re‑authenticated anonymously with UID: \(uid)")
                }
            }
        }
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings() // Use disk-backed cache
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
    }
}
