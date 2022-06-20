//
//  SettingsView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/18/22.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings World!")
            Text("Another line")
            Text("Last line")
            // TextField("IP Address: Localhost")
        }.frame(width: 450, height: 250)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
