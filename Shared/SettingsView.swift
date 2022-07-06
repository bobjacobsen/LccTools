//
//  SettingsView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/18/22.
//

import SwiftUI

// Using @AppStorage to persist the IP_ADDRESS, see https://medium.com/swlh/introducing-appstorage-in-swiftui-470a56f5ba9e
struct SettingsView: View {
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = "localhost"
    @AppStorage("THIS_NODE_ID") private var this_node_ID: String = "05.01.01.01.03.FF"
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter your hub's IP address:")
            TextField("", text: $ip_address)
            Divider()
            Text("Enter a node ID for this program:")
            TextField("", text: $this_node_ID)
            Divider()
        }.frame(width: 450, height: 250)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
