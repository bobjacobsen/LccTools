//
//  SettingsView.swift
//
//  Created by Bob Jacobsen on 6/18/22.
//

import Network
import SwiftUI
import TelnetListenerLib
import os

// Using @AppStorage to persist the IP_ADDRESS, see https://medium.com/swlh/introducing-appstorage-in-swiftui-470a56f5ba9e

/// View for setting and storing user preferences for e.g. hub IP address and this node's ID
///
/// Stores results in @AppStorage. See `OlcbToolsApp` for example of retrieval
///
struct SettingsView: View {
    @ObservedObject var commModel: TcpConnectionModel

    @AppStorage("HUB_SERVICE")    private var selectedHubAddress = ModelPeerBrowserDelegate.PeerBrowserDelegateNoHubSelected
    @AppStorage("HUB_IP_ADDRESS") private var ipAddress: String = ""
    @AppStorage("HUB_IP_PORT")    private var ipPort: String = "12021"
    @AppStorage("THIS_NODE_ID")   private var thisNodeID: String = ""

    private let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "SettingsView")
    
    let versionNumber: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "<Unknown>"
    let buildNumber: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "<Unknown>"

    var body: some View {
        VStack {
            VStack {
                Text("Select a Hub:")
                Picker("Visible Hubs", selection: $selectedHubAddress) {
                    ForEach(commModel.browserhandler.destinations, id: \.self.name) {
                        Text($0.name)
                    }
                } // .pickerStyle(WheelPickerStyle())  // wheel takes up too much space on iOS
            }
            StandardClickButton(label: "Scan for Hubs", height: STANDARD_BUTTON_HEIGHT, font: STANDARD_BUTTON_FONT) {
                commModel.rescan()
            }
            StandardHDivider()
            
            VStack {
                Text("Or enter your hub's address below:")
                TextField("", text: $ipAddress)
                    .multilineTextAlignment(.center)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif
                Text("Enter your hub's port:")
                TextField("", text: $ipPort)
                    .multilineTextAlignment(.center)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif

            }

            StandardHDivider()

            VStack {
                Text("Enter a node ID for this program:")
                TextField("", text: $thisNodeID)
                    .multilineTextAlignment(.center)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif
            }
            
            StandardHDivider()

            Text(commModel.statusString)
            StandardClickButton(label: commModel.started ? "Restart Connection" : "Start Connection") {
                resetServiceIfNotPresent()
                commModel.retarget(serviceName: selectedHubAddress, hostName: ipAddress, portNumber: UInt16(ipPort) ?? UInt16(12021) )
                commModel.stop()
                commModel.start()
            }.disabled(false)

            Spacer()
            
            Text("Version \(versionNumber) (\(buildNumber))")

        }
    }
    
    // If a service name has been stored that's not available now, reconnecting will continue
    // to fail.  To avoid that, reset the stored hub selection when "Start Connection" is
    // pressed in that case.
    internal func resetServiceIfNotPresent() {
        if selectedHubAddress.isEmpty { return }
        if selectedHubAddress == ModelPeerBrowserDelegate.PeerBrowserDelegateNoHubSelected {
            return
        }
        for element in commModel.browserhandler.destinations where element.name == selectedHubAddress {
            return // found a match, so already shown
        }
        // didn't find matching element, force reset
        logger.info("Resetting definition for missing service")
        selectedHubAddress = ModelPeerBrowserDelegate.PeerBrowserDelegateNoHubSelected
    }

}

/// XCode preview for the SettingsView
struct SettingsView_Previews: PreviewProvider {
    @State static var commStatus = "status goes here"
    static var previews: some View {
        @State var commModel = TcpConnectionModel()
        return SettingsView(commModel: commModel)
    }
}
