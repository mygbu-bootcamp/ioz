//
//  MyGBUApp.swift
//  MyGBU
//
//  Created by Yaduraj Singh on 19/06/25.
//

import SwiftUI

@main
struct MyGBUApp: App {
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(authService)
        }
    }
}
