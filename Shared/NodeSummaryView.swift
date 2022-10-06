//
//  NodeSummaryView.swift
//
//  Created by Bob Jacobsen on 6/15/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display of the details of a single node.
/// 
/// Invoked from e.g. NodeListNavigationView
struct NodeSummaryView: View {
    @ObservedObject var displayNode : Node
    let network : OpenlcbNetwork
    
    var body: some View {
        
        VStack( /* alignment: .leading */) {
            List {
                Text(displayNode.name).font(.title)
                Text(displayNode.snip.userProvidedDescription)
                Text(displayNode.id.description) // nodeID
                Text(displayNode.snip.modelName)
                Text(displayNode.snip.manufacturerName)
                Text("Hardware Version: \(displayNode.snip.hardwareVersion)\nSoftware Version: \(displayNode.snip.softwareVersion)")
            }.refreshable {
                refresh()
            }
            HStack{
                
                if displayNode.pipSet.contains(.CONFIGURATION_DESCRIPTION_INFORMATION)
                    && displayNode.pipSet.contains(.MEMORY_CONFIGURATION_PROTOCOL)  {
                    NavigationLink(destination: CdCdiView(displayNode: displayNode, lib: network)) {
                        MoreButtonView(label: "Configure", symbol: "square.and.pencil")
                    }
                }
                
#if os(iOS) // on iOS display two more icons for Events and PIP
                
                if displayNode.pipSet.contains(.EVENT_EXCHANGE_PROTOCOL) {
                    NavigationLink(destination: EventView(displayNode: displayNode)) {
                        MoreButtonView(label: "Events", symbol: "cpu")
                    }
                }
                
                
                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    MoreButtonView(label: "More Info", symbol: "gear.badge.questionmark")
                }
                
#else // macOS seems to require there be only two buttons/NavigationLinks so use a combined View
                
                NavigationLink(destination: MacOSCombinedView(displayNode: displayNode)) {
                        MoreButtonView(label: "More Info", symbol: "gear.badge.questionmark")
                }
#endif
                
            }.frame(minHeight: 75)
            
#if os(macOS)
            Button("Refresh"){
                refresh()
            }.padding(.bottom, 15)
                .padding(.top, -15)
#endif
            
        } .navigationTitle("\(displayNode.name) Summary")
    }
    
#if os(macOS)
    /// macOS-specific view to show PIP and Events in a single View
    struct MacOSCombinedView : View {
        @ObservedObject var displayNode : Node
        
        var body : some View {
            VStack {
                PipView(displayNode: displayNode)
                StandardHDivider()
                EventView(displayNode: displayNode)
            }
        }
    }
#endif
    
    /// iOS and macOS specific handling of the sub-view navigation buttons
    struct MoreButtonView : View {
        let label : String
        let symbol : String
        
        var body : some View {
            VStack {
#if os(iOS)
                Image(systemName:symbol)
                Text(label)
                    .font(.footnote)
#else   // macOS
                Text(label)
#endif
            }
        }
    }
    
    func refresh() {
        network.refreshNode(node: displayNode)
        
        // reloadRoster() here would happen too soon, network update hasn't happened yet
        // so schedule for a short time from now
        let deadlineTime = DispatchTime.now() + .milliseconds(500)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            network.throttleModel0.reloadRoster()
        }
    }
    
}

/// XCode preview for the NodeSummaryView
struct NodeSummaryView_Previews: PreviewProvider {
    static let displayNode  = Node(NodeID(258),
                                   snip: SNIP(
                                            "Manufacturer Name",
                                            "Model Info",
                                            "Hardware Info",
                                            "And Software Info",
                                            "My Node Name",
                                            "And Description"))
    static var previews: some View {
        let olcblibrary = OpenlcbNetwork(defaultNodeID: NodeID(258))
        return NodeSummaryView(displayNode: displayNode, network: olcblibrary)
    }
}
