import Foundation
import SwiftUI

struct InstallerPage: View {
    @EnvironmentObject var installer: Installer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Current state: \(installer.state.rawValue)")
                .font(.system(size: 30))
            
            HStack(spacing: 20) {
                Button {
                    installer.install()
                } label: {
                    Text("Install")
                        .padding()
                        .frame(width: 200)
                        .font(.system(size: 25))
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.green)
                
                Button {
                    installer.uninstall()
                } label: {
                    Text("Uninstall")
                        .padding()
                        .frame(width: 200)
                        .font(.system(size: 25))
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.red)
            }
            VStack {
                Text("Debug log:")
                    .padding(.vertical)
                    .font(.system(size: 25))
                
                DebugView(messages: self.$installer.messages)
            }
        }
        .padding(25)
        .onAppear {
            installer.check()
        }
    }
}
