//
//  MonitorView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import OpenlcbLibrary

struct MonitorView: View {  // TODO: Add useful stuff from the monitor stream
    @ObservedObject var monitorModel:MonitorModel = MonitorModel.sharedInstance
    
    var body: some View {
        List {
            ForEach(monitorModel.printingProcessorContentArray, id: \.id) { element in
                Text(element.line)
            }
        }
            .navigationTitle("Monitor View")
    }
}

struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
}
