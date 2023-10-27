//
//  ContentView.swift
//  katherine
//
//  Created by Saint on 8/7/23.
//

import AudioKit
import Combine
//import AudioKitEX
import AudioKitUI
import AVFoundation
import SwiftUI
import GRDB
import GRDBQuery

struct RecorderData {
    var isRecording = false
}

struct PlayerData {
    var fileToPlay: URL?
}

// class Track: NSObject, Codable {
//     var url: URL
//     var playArm: Bool
// }

class RecorderConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var silencer: Fader?
    var recorder: NodeRecorder?
    var mew : MeowFader
    let mixer = Mixer()
    let player = AudioPlayer()
    var isPlaying = false
    var previousFile: URL?


    @Published var playerData = PlayerData() {
        didSet {
            if true {
                if isPlaying && previousFile == nil {
                    print("empty")
                    player.pause()
                    isPlaying = false
                    return
                }
                print("trying to play")
                print(playerData)
                print(playerData.fileToPlay!.path)
                print(playerData.fileToPlay!)
                do {
                    // let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
                    // var settings = audioFormat.settings
                    if true {
                        var newFile = try AVAudioFile(forReading: playerData.fileToPlay!)

                        var options = FormatConverter.Options()
                        options.format = AudioFileFormat(rawValue: "m4a")
                        options.sampleRate = 48000
                        options.bitDepth = 16

                        let filename = "convert.m4a"
                        let documents = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]
                        let newFileUrl = documents.appendingPathComponent(filename)
                        let converter = FormatConverter(inputURL: playerData.fileToPlay!, outputURL: newFileUrl, options: options)

                        // converter.start { error in
                        //     if error == nil {
                        //         print("no problem convert")
                        //     } else {
                        //         print("\(error)")
                        //     }

                        //     // the error will be nil on success
                        // }

                        print("opened file");
                        print(newFile)
                        // settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
                        // settings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)
                        player.file = newFile
                        // mew.setFile(
                    }
                } catch {
                    print("there was an \(error)")
                }
                player.completionHandler = {
                    print("done")
                    // self.playerData.fileToPlay = nil
                    self.isPlaying = false
                }
                player.play()
                isPlaying = true
                // }
            }
        }
    }

    @Published var recorderData = RecorderData() {
        didSet {
            if recorderData.isRecording {

                do {
                    let filename = UUID().uuidString + ".caf"
                    let documents = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]
                    let fileUrl = documents.appendingPathComponent(filename)

                    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
                    var settings = audioFormat.settings
                    // settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
                    // settings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)

                    if true {
                        var fileForWriting = try? AVAudioFile(forWriting: fileUrl, settings: settings)

                    print("Written File URL:",fileForWriting!.url)
                    recorder?.openFile(file: &fileForWriting)

                    try recorder?.record()
                    }
                    //var fileForWriting = try? AVAudioFile(forWriting: fileUrl)

                } catch let err {
                    print(err)
                }
            } else {
                recorder?.stop()
                // recorder?.closeFile(file: &fileForWriting)
                // fileForWriting = nil
                print("STOPPED")
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

        let silencer = Fader(input, gain: 0)
        self.silencer = silencer
        mixer.addInput(silencer)
        mew = MeowFader(player)
        mew.au.meow()
        // cat = mew.avAudioNode.auAudioUnit;

        // dog = cat!.fullStateForDocument
        // print("fefe")
        // print(dog)
        // dog!["woof"] = "meow"

        // cat!.fullStateForDocument = dog;

        // dog2 = cat!.fullStateForDocument!
        // print(dog)

        mixer.addInput(mew)
        engine.output = mixer

        do {
            recorder = try NodeRecorder(node: mixer)
        } catch let err {
            fatalError("\(err)")
        }
    }
}


func getFiles(_ appDatabase: AppDatabase) {
    var fileList = [URL]()
    var fileManager = FileManager.default
    var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    do {
        fileList = try fileManager.contentsOfDirectory(at: documentsURL,
                                                        includingPropertiesForKeys: nil,
                                                        options: .skipsHiddenFiles)
        print("GOT FILES")
        print(fileList)
    } catch {
        print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
    }

    for track in fileList {

        print("erer")
        print(track.deletingPathExtension().pathComponents)
        print(track.deletingPathExtension().pathComponents.suffix(2))
        print("Www")

        let pathComponents = track.deletingPathExtension().pathComponents.suffix(2)
        print(pathComponents)
        print(pathComponents.count)
        print("xx")
        // let filename = (pathComponents.joined(separator: "/"))
        //let filepath = "\(pathComponents[1])\(pathComponents[2])"
        //print(filepath)

        Task {
            // _ = try await appDatabase.loadTrack(pathComponents.joined(separator: "/"))
            _ = try await appDatabase.loadTrack(track)
        }
    }
}

private struct TrackView: View {
    var track: Track
    //var pathComponents: [String]


    init (track: Track) {
        self.track = track
    }
    var body: some View {
        Text(track.filename)
    }
}

struct ContentView: View {
    @StateObject var conductor = RecorderConductor()
    @Environment(\.appDatabase) private var appDatabase

    @State var fileSelected: [URL]?

    @Query(TrackRequest()) private var tracks: [Track]

    var fileManager = FileManager.default
    var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    init () {
        //getFiles(appDatabase)
    }

    var body: some View {
        VStack {
            Spacer()
            Text(conductor.recorderData.isRecording ? "STOP RECORDING" : "RECORD")
                .foregroundColor(.blue)
                .onTapGesture {
                    conductor.recorderData.isRecording.toggle()
                    getFiles(appDatabase)
                }
            Spacer()
            // Text(conductor.data.isPlaying ? "STOP" : "PLAY")
            //     .foregroundColor(.blue)
            //     .onTapGesture {
            //     conductor.data.isPlaying.toggle()
            // }
            Spacer()

            ForEach(tracks) { track in
                TrackView(track: track)
                    .onTapGesture {
                        print("tap \(track.fileURL)")
                        print(URL(fileURLWithPath:track.fileURL))
                        conductor.playerData.fileToPlay = URL(fileURLWithPath:track.fileURL)
                        // conductor.playerData.isPlaying.toggle()
                    }
            }
        }
            .padding()
            // .cookbookNavBarTitle("Recorder")
            .onAppear {
                conductor.start()
                do {
                    getFiles(appDatabase)
                } catch {
                    print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
                }
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
