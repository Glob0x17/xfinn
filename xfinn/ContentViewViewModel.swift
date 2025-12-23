//
//  ContentViewViewModel.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation
import Combine

class ContentViewViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var showLoginView = false
    @Published var showServerSelection = false
    
    func clearJellyfinData() {
        UserDefaults.standard.clearJellyfinData()
    }
}
