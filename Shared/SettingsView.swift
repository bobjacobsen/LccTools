//
//  SettingsView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/18/22.
//

import SwiftUI

// Using @AppStorage to persist the IP_ADDRESS, see https://medium.com/swlh/introducing-appstorage-in-swiftui-470a56f5ba9e

// TODO: needs to work with a model to display mDNS results
// TODO: needs to default to mDNS if that's available
// TODO: should display at start if there's no configuration
// TODO: needs an indicator of whether it's connected OK or not

/// View for setting and storing user preferences for e.g. hub IP address and this node's ID
///
/// Stores results in @AppStorage. See `OlcbToolsApp` for example of retrieval
///
struct SettingsView: View {
    @Binding var commStatus: String
    
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
            Text(commStatus)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var commStatus = "status goes here"
    static var previews: some View {
        SettingsView(commStatus: $commStatus)
    }
}
