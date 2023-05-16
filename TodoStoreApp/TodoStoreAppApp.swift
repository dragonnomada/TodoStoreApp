//
//  TodoStoreAppApp.swift
//  TodoStoreApp
//
//  Created by Alan Badillo Salas on 15/05/23.
//

import SwiftUI
import TodoStore

@main
struct TodoStoreAppApp: App {
    @StateObject var todoStore = TodoStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(todoStore)
        }
    }
}
