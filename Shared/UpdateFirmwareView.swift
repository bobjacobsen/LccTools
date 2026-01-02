//
//  UpdateFirmwareView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 12/28/25.
//

import SwiftUI
import OpenlcbLibrary

/// View to control updating firmware in a selected node
struct UpdateFirmwareView: View {
    @State var selectingFile = false
    @State var fileURL: URL?
    
    let displayNode: Node
    let network: OpenlcbNetwork
    
    @ObservedObject var model : UpdateFirmwareModel
    
    init(displayNode : Node, network: OpenlcbNetwork) {
        self.displayNode = displayNode
        self.network = network
        
        model = UpdateFirmwareModel(firmwareContent: NSData(), mservice : network.mservice, dservice: network.dservice, nodeID : displayNode.id)
    }
    
    var body: some View {
        VStack {
            
            // if !model.transferring {
                StandardClickButton(label: "Start Firmware Update", height: STANDARD_BUTTON_HEIGHT*2, font: STANDARD_BUTTON_FONT) {
                    selectingFile = true
                }
                .fileImporter(
                    isPresented: $selectingFile,
                    allowedContentTypes: [.plainText], // Specify allowed file types
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let url):
                        // Handle the URL of the selected file
                        guard url.first != nil
                        else { return }
                        self.fileURL = url.first
                        handleFileSelection(url: self.fileURL!)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            // }
            
            // if model.transferring {
                StandardClickButton(label: "Cancel Firmware Update", height: STANDARD_BUTTON_HEIGHT*2, font: STANDARD_BUTTON_FONT) {
                    model.cancel()
                }
            // }
            
            Text(model.status)
            // if model.transferring {
                let progress = Double(model.nextWriteAddress)/(Double(model.writeLength)+1.0)
                let percent : Int = Int(progress * 100)
                Text("\(model.nextWriteAddress) bytes (\(percent)%) transferred") // dynamically updates
                ProgressView(value: min(1.0, progress)) // sometimes overruns by a few in last read block, min(..) to avoid error message
            // }
        }
    }
    
    func handleFileSelection(url: URL) {
        // Need to start accessing a security-scoped resource
        // if the file is outside app's sandbox.
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Read the file data as bytes
        let data = NSData(contentsOf: url)
        
        // Start the download process and show the progress bar
        model.provideContent(data: data!)
        model.startUpdate()
        
    }
    
}

/// XCode preview for the UpdateFirmwareView
struct UpdateFirmwareView_Previews: PreviewProvider {
    static var previews: some View {
        let network = OpenlcbNetwork(localNodeID: NodeID(123))
        UpdateFirmwareView(displayNode: Node(NodeID(0)), network: network)
   }
}
