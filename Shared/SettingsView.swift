//
//  SettingsView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/18/22.
//

import SwiftUI

// Using @AppStorage to persist the IP_ADDRESS, see https://medium.com/swlh/introducing-appstorage-in-swiftui-470a56f5ba9e

/// View for setting and storing user preferences for e.g. hub IP address and this node's ID
///
/// Stores results in @AppStorage. See `OlcbToolsApp` for example of retrieval
///
struct SettingsView: View {
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = "localhost"
    @AppStorage("HUB_IP_PORT") private var ip_port: String = "12021"
    @AppStorage("THIS_NODE_ID") private var this_node_ID: String = "05.01.01.01.03.FF"
    
    var body: some View {
        VStack() { //
            Text("Enter your hub's IP address:")
            TextField("", text: $ip_address)
                .multilineTextAlignment(.center)
            Divider()
            Text("Enter your hub's port:")
            TextField("", text: $ip_port)
                .multilineTextAlignment(.center)
            Divider()
            Text("Enter a node ID for this program:")
            TextField("", text: $this_node_ID)
                .multilineTextAlignment(.center)
            Divider()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
