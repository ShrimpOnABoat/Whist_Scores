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

    
    init() {
        // Configure Firebase
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        FirebaseApp.configure()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try Auth.auth().signOut()
                print("✅ Signed out previous anonymous user")
            } catch {
                print("⚠️ Could not sign out anonymous user: \(error.localizedDescription)")
            }
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ Firebase anonymous sign-in failed: \(error.localizedDescription)")
                } else if let uid = authResult?.user.uid {
                    print("✅ Signed in anonymously with UID: \(uid)")
                }
            }
        }
        print("Firebase UID: \(Auth.auth().currentUser?.uid ?? "nil")")
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
