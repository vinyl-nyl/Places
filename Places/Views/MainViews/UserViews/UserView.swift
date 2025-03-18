//
//  UserView.swift
//  Places
//
//  Created by junil on 4/21/24.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct UserView: View {
    // MARK: My Profile Data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: View Properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack{
                if let myProfile {
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // MARK: Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // MARK: Two Action's
                        // 1. Logout
                        // 2. Delete Account
                        Button("로그아웃", action: logOutUser)
                        
                        Button("계정삭제", role: .destructive, action: deleteAccount)
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.gray)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
        }
        .task {
            // This Modifer is like onAppear
            // So Fetching for the First Time Only
            if myProfile != nil{return}
            // MARK: Initial Fetch
            await fetchUserData()
        }
    }
    
    // MARK: Fetching User Data
    func fetchUserData() async {
        guard let userUID = Auth.auth().currentUser?.uid else {return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    // MARK: Logging User Out
    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount() {
        isLoading = true
        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else {return}
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Setting Error
    func setError(_ error: Error) async {
        isLoading = false
        // MARK: UI Must be run on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView()
    }
}
