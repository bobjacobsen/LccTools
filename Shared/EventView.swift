//
//  EventView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct EventView: View {
    
    @ObservedObject var displayNode : Node
    
    @EnvironmentObject var openlcblib : OpenlcbLibrary
    
    var body: some View {
        var produced = Array(displayNode.events.eventsProduced)
        produced.sort()
        var consumed = Array(displayNode.events.eventsConsumed)
        consumed.sort()
        return VStack {
            Divider() // Needed to align tops of columns
            HStack {
                // TODO: Work on left/right margins to make a bit more space in portrait
                List {
                    Text("Produces").font(.title).frame(alignment: .leading)
                    ForEach(produced, id:\.eventID) { (event) in
                        EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                            .padding(.vertical, 0)
                    }
                    #if os(iOS)
                        .listRowSeparator(.hidden)  // first supported in macOS 13
                    #endif
                }.padding(.horizontal, -15.0)
                List {
                    Text("Consumes").font(.title).font(.title).frame(alignment: .leading)
                    ForEach(consumed, id:\.eventID) { (event) in
                        EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                            .padding(.vertical, 0)
                    }
                    #if os(iOS)
                        .listRowSeparator(.hidden) // first supported in macOS 13
                    #endif
                }.padding(.horizontal, -15.0)
            }
        }.navigationTitle("\(displayNode.name) Events")
    }
}

struct EventViewOneEvent : View {
    @EnvironmentObject var openlcblib : OpenlcbLibrary
    
#if os(iOS) // to check for iPhone v iPad & orientation
    @Environment(\.horizontalSizeClass) var horizontalSizeClass : UserInterfaceSizeClass?
#endif

    let eventID : EventID
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fontsize = Font.system(size: width / 12.5) // empirically derived
            
            StandardMomentaryButton(label: "\(eventID.description)", height: 35, font: fontsize) {
                // TODO: Encapsulate this and set Message, sendMessage back to internal
                let msg = Message(mti: .Producer_Consumer_Event_Report, source: openlcblib.linkLevel.localNodeID, data: eventID.toArray())
                openlcblib.linkLevel.sendMessage(msg)
                // button action
            }.padding(.horizontal, -5.0)
        }
    }
}

struct EventView_Previews: PreviewProvider {
    static let displayNode = Node(NodeID(12))
    static var previews: some View {
        displayNode.events.eventsConsumed.insert(EventID("1.2.3.4.5.6.7.8"))
        
        displayNode.events.eventsProduced.insert(EventID("1.2.3.4.5.6.7.8"))
        displayNode.events.eventsProduced.insert(EventID("1.2.3.4.5.6.7.9"))
        displayNode.events.eventsProduced.insert(EventID("1.2.3.4.5.6.7.7"))
        
        return EventView(displayNode : displayNode)
        //.previewInterfaceOrientation(.landscapeLeft)
    }
}
