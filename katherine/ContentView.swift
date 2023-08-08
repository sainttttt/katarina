//
//  ContentView.swift
//  katherine
//
//  Created by Saint on 8/7/23.
//

import AudioKit
import Combine
import AudioKitEX
import AudioKitUI
import AVFoundation
import SwiftUI

struct RecorderData {
    var isRecording = false
    var isPlaying = false
    var fileToPlay: URL?
}

class RecorderConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var silencer: Fader?
    var recorder: NodeRecorder?
    let mixer = Mixer()
    let player = AudioPlayer()

    @Published var data = RecorderData() {
        didSet {
            if data.isRecording {
                do {

                    let filename = UUID().uuidString + ".m4a"
                    let documents = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]
                    let fileUrl = documents.appendingPathComponent(filename)

                    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
                    var settings = audioFormat.settings
                    settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
                    settings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)

                    var fileForWriting = try? AVAudioFile(forWriting: fileUrl, settings: settings)
                    
                    print("Written File URL:",fileForWriting!.url)
                    recorder?.openFile(file: &fileForWriting)

                    try recorder?.record()

                } catch let err {
                    print(err)
                }
            } else {
                recorder?.stop()
                print("STOPPED")
            }

            // if (data.fileToPlay != nil && !self.data.isPlaying) {
            if (data.fileToPlay != nil) {
                 
                self.data.isPlaying = true
                print("trying to play")
                print(data.fileToPlay!.path)
                player.file = try? AVAudioFile(forReading: data.fileToPlay!)
                player.completionHandler = {
                    print("done")
                    self.data.fileToPlay = nil
                    self.data.isPlaying = false
                }
                player.play()
            }

        }
    }

    init() {
        print("starting")

        Settings.bufferLength = .short
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)

        } catch let err {
            print(err)
        }

        guard let input = engine.input else {
            fatalError()
        }

        do {
            recorder = try NodeRecorder(node: input)
        } catch let err {
            fatalError("\(err)")
        }
        let silencer = Fader(input, gain: 0)
        self.silencer = silencer
        mixer.addInput(silencer)
        mixer.addInput(player)
        engine.output = mixer
    }
}

struct ContentView: View {
    @StateObject var conductor = RecorderConductor()


    @State var fileList: [URL]?
    @State var fileSelected: [URL]?


    var body: some View {
        VStack {
            Spacer()
            Text(conductor.data.isRecording ? "STOP RECORDING" : "RECORD")
                .foregroundColor(.blue)
                .onTapGesture {
                conductor.data.isRecording.toggle()

                    let fileManager = FileManager.default
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    do {
                        fileList = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                        // process files
                    } catch {
                        print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
                    }
            }
            Spacer()
            // Text(conductor.data.isPlaying ? "STOP" : "PLAY")
            //     .foregroundColor(.blue)
            //     .onTapGesture {
            //     conductor.data.isPlaying.toggle()
            // }
            Spacer()

            if (fileList != nil) {
                ForEach(fileList!, id: \.self) { filename in
                    Text(filename.path)
                        .onTapGesture {
                            conductor.data.fileToPlay = filename
                        }
                }
            }



        }

        .padding()
        // .cookbookNavBarTitle("Recorder")
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
    }
}


// struct ContentView_Previews: PreviewProvider {
//     static var previews: some View {
//         ContentView()
//     }
// }
