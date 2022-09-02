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
                    Text("Produces").font(.title).font(.title).frame(alignment: .leading)
                    ForEach(produced, id:\.eventID) { (event) in
                        EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                            .padding(.vertical, 0)
                    }.listRowSeparator(.hidden)
                }
                List {
                    Text("Consumes").font(.title).font(.title).frame(alignment: .leading)
                    ForEach(consumed, id:\.eventID) { (event) in
                        EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                            .padding(.vertical, 0)
                    }.listRowSeparator(.hidden)
                }
            }
        }.navigationTitle("Events")
    }
}

struct EventViewOneEvent : View {
    @EnvironmentObject var openlcblib : OpenlcbLibrary
    
    let eventID : EventID
    
    var body: some View {
        StandardMomentaryButton(label: "\(eventID.description)", height: 35, font: .headline) {
            // TODO: Encapsulate this and set Message, sendMessage back to internal
            let msg = Message(mti: .Producer_Consumer_Event_Report, source: openlcblib.linkLevel.localNodeID, data: eventID.toArray())
            openlcblib.linkLevel.sendMessage(msg)
            // button action
        }.font(.subheadline)
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
