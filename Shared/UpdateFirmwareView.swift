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
    let node : Node
    @State var selectingFile = false
    @State var fileURL: URL?
    
    @ObservedObject var model: UpdateFirmwareModel  // observed for transfer states and quantity transferred
        
    var body: some View {
        VStack {
            
            if !model.transferring {
                StandardClickButton(label: "Start Firmware Update", height: STANDARD_BUTTON_HEIGHT*2, font: STANDARD_BUTTON_FONT) {
                    selectingFile = true
                }
                .fileImporter(
                    isPresented: $selectingFile,
                    allowedContentTypes: [.data], // .data is all file types
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
            }
            
            if model.transferring {
                StandardClickButton(label: "Cancel Firmware Update", height: STANDARD_BUTTON_HEIGHT*2, font: STANDARD_BUTTON_FONT) {
                    model.cancel()
                }
                Text("Please stay on this page until update is complete")
                    .font(.headline)
            }
            
            Text(model.status)
                .font(.title)
            
            if model.transferring {
                let progress = Double(model.nextWriteAddress)/(Double(model.writeLength)+1.0)
                let percent: Int = Int(progress * 100)
                ProgressView(value: min(1.0, progress)) // sometimes overruns by a few in last read block, min(..) to avoid error message
                Text("\(model.nextWriteAddress) bytes (\(percent)%) transferred") // dynamically updates
            }
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
        let model = UpdateFirmwareModel(mservice: network.mservice, dservice: network.dservice, node: Node(NodeID(123)))
        UpdateFirmwareView(node: Node(NodeID(123)), model: model)
   }
}
