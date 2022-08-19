//
//  StandardButton.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 8/19/22.
//

import SwiftUI

// Button that toggles a state on and off
struct StandardToggleButton: View {
    let label : String
    let height : CGFloat
    @Binding var select : Bool
    let action : () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15.0)
                        .frame(height: height, alignment: .center)
                        .foregroundColor(select ? .blue : .green)
                    
                    Text(label)
                        .font(.title)
                        .foregroundColor(.white)
                }
            } // label
        ) // Button
    }
}

// Button that just goes down and up, calling an action
struct StandardMomentaryButton: View {
    let label : String
    let height : CGFloat
    let action : () -> Void
    
    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15.0)
                        .frame(height: height, alignment: .center)
                        .foregroundColor(.green)
                    
                    Text(label)
                        .font(.title)
                        .foregroundColor(.white)
                }
            } // label
        ) // Button
    }
}

struct StandardButton_Previews: PreviewProvider {
    static var previews: some View {
        StandardMomentaryButton(label: "Foo", height: 50){
          // on pressed
        }
    }
}
