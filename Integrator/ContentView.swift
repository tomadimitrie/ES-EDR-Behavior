import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject var installer = Installer()

    var body: some View {
        TabView {
            InstallerPage()
                .tabItem {
                    Text("Installer")
                }
            InfoPage()
                .tabItem {
                    Text("Info")
                }
            ProcessPage()
                .tabItem {
                    Text("Processes")
                }
            TestPage()
                .tabItem {
                    Text("Testing")
                }
        }
        .environmentObject(self.installer)
    }
}
