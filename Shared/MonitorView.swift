//
//  MonitorView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import OpenlcbLibrary

struct MonitorView: View {  // TODO: Is only showing messages from network, not ones we originate (see OpenlcbLibrary comment)
    @ObservedObject var monitorModel:MonitorModel = MonitorModel.sharedInstance
    
    // TODO: Add some nice scrolling control so it stays at the bottom until user wants to stick on something
    var body: some View {
        ScrollView {
            VStack(spacing: 3) {
                ForEach(monitorModel.printingProcessorContentArray, id: \.id) { element in
                    HStack {
                        Text(element.line)
                            .font(.callout)
                        Spacer()
                    }
                    Divider()
                }
            }
            .navigationTitle("Monitor View")
        }
    }
}

struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
}
