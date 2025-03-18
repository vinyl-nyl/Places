
//  ContentView.swift
//  Places
//
//  Created by junil on 4/1/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

struct ContentView: View {
    @State private var isActive: Bool = false
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        if logStatus {
            // MARK: Home View
            MainView()
        } else {
            LoginView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
