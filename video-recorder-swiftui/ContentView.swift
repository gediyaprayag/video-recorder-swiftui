//
//  ContentView.swift
//  video-recorder-swiftui
//
//  Created by Prayag Gediya on 10/07/22.
//

import SwiftUI

struct ContentView: View {
    @State private var recording: Bool = false
    var body: some View {
        VStack {
            RecordginView()
            ZStack {
                Button(action: handleAction) {
                    Image(systemName: recording ? "stop.circle" : "record.circle")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.red)
                }.buttonStyle(.plain)
                HStack {
                    Button(action: handleRotation) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            .font(.system(size: 32, weight: .bold))
                    }.buttonStyle(.plain)
                    Spacer()
                    Button(action: handleCapture) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 32, weight: .bold))
                    }.buttonStyle(.plain)
                }.padding(.horizontal)
            }
        }
    }
    
    private func handleRotation() {
        NotificationCenter.default.post(name: NSNotification.CameraSwitchAction, object: nil, userInfo: ["action": "switchcamera"])
    }
    
    private func handleCapture() {
        
    }
    
    private func handleAction() {
        if recording {
            NotificationCenter.default.post(name: NSNotification.RecordAction, object: nil, userInfo: ["action": RecordAction.stop])
        } else {
            NotificationCenter.default.post(name: NSNotification.RecordAction, object: nil, userInfo: ["action": RecordAction.start])
        }
        withAnimation {
            recording.toggle()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
