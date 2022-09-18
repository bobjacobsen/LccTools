//
//  SettingsView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/18/22.
//

import SwiftUI
import TelnetListenerLib

// Using @AppStorage to persist the IP_ADDRESS, see https://medium.com/swlh/introducing-appstorage-in-swiftui-470a56f5ba9e

// TODO: needs to work with a model to display mDNS results
// TODO: needs to default to mDNS if that's available

/// View for setting and storing user preferences for e.g. hub IP address and this node's ID
///
/// Stores results in @AppStorage. See `OlcbToolsApp` for example of retrieval
///
struct SettingsView: View {
    @ObservedObject var commModel: TcpConnectionModel
    
    @AppStorage("HUB_IP_ADDRESS") private var ip_address:   String = ""
    @AppStorage("HUB_IP_PORT")    private var ip_port:      String = "12021"
    @AppStorage("THIS_NODE_ID")   private var this_node_ID: String = "05.01.01.01.03.FF"
    
    var body: some View {
        VStack() {
            VStack() {
                Text("Enter your hub's IP address:")
                TextField("", text: $ip_address)
                    .multilineTextAlignment(.center)
                Text("Enter your hub's port:")
                TextField("", text: $ip_port)
                    .multilineTextAlignment(.center)
            }

            Divider()

            VStack {
                Text("Enter a node ID for this program:")
                TextField("", text: $this_node_ID)
                    .multilineTextAlignment(.center)
            }
            
            Divider()

            Text(commModel.statusString)
            StandardMomentaryButton(label: commModel.started ? "Restart Connection" : "Start Connection", height: STANDARD_BUTTON_HEIGHT, font: STANDARD_BUTTON_FONT) {
                commModel.retarget(hostName: ip_address, portNumber: UInt16(ip_port) ?? UInt16(12021) )
                commModel.stop()
                commModel.start()
            }.disabled(false) // TODO: add disable on connection valid?

        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var commStatus = "status goes here"
    static var previews: some View {
        @State var commModel = TcpConnectionModel()
        return SettingsView(commModel: commModel)
    }
}
