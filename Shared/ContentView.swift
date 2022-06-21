//
//  ContentView.swift
//  OlcbLibDemo
//
//  Created by Bob Jacobsen on 6/10/22.
//

import SwiftUI
import os
import OpenlcbLibrary

struct ContentView: View {

    // iphone is one selector window
    // macOS and iPad have two
    
    #if os(iOS) // to check for iPhone
    @Environment(\.horizontalSizeClass) var horizontalSizeClass : UserInterfaceSizeClass?
    #endif
    
    var body: some View {
        HStack{
            NodeListNavigationView()

            #if os(iOS)
                if horizontalSizeClass != .compact {
                    // NodeListNavigationView() // 2nd parallel on iPad
                }

            #else // macOS
                // NodeListNavigationView()
            #endif

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
