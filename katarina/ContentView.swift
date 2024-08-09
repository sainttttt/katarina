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
import GRDB
import GRDBQuery

struct RecorderData {
    var isRecording = false
}

struct PlayerData {
    var fileToPlay: URL?
}

public func printWelcomeMessage(_ name: String) {
  print("Welcome \(name)")
}

class RecorderConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var silencer: Fader?
    var recorder: NodeRecorder?
    var mew : MeowFader
    let mixer = Mixer()
    let player = AudioPlayer()
    var isPlaying = false
    var newFile: AVAudioFile?
    var newFile2: AVAudioFile?
    var previousFile: URL?
    var xa:  UnsafeMutablePointer<UnsafeMutablePointer<Float>?>?


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
                        newFile2 = try AVAudioFile(forReading: playerData.fileToPlay!)
                        newFile = try AVAudioFile(forReading: playerData.fileToPlay!)

                        //var floats = newFile.toFloatChannelData()


                        let pcmbuffer = newFile!.toAVAudioPCMBuffer()!
                        guard let pcm = pcmbuffer.floatChannelData else {
                            return
                        }

                        print("woof dd first \(pcm[1][111231])")

                        print("woof Starting")

                        var x0: UnsafeMutablePointer<Float>?
                        var x1: UnsafeMutablePointer<Float>?
                        x0 = UnsafeMutablePointer<Float>.init(mutating:pcm[0])
                        x1 = UnsafeMutablePointer<Float>.init(mutating:pcm[1])

                        var xx = [x0, x1]

                        xa =  UnsafeMutablePointer<UnsafeMutablePointer<Float>?>.allocate(capacity: 2)
                        xa!.initialize(from: &xx, count: 2)

                        print("woof dd \(xx[0]![34])")

                        let frameLength = Int(pcmbuffer.frameLength)
                        mew.au.meow(sound: "baa 2222 wooof", floats: xa!, frameLength: frameLength)


                        let channelCount = 2
                        let stride = pcmbuffer.stride

                        // // Preallocate our Array so we're not constantly thrashing while resizing as we append.
                        // var result = Array(repeating: [Float](zeros: frameLength), count: channelCount)

                        // for channel in 0 ..< channelCount {
                        //     // Make sure we go through all of the frames...
                        //     for sampleIndex in 0 ..< frameLength {
                        //         result[channel][sampleIndex] = pcm[channel][sampleIndex * stride]
                        //     }
                        // }


                        // print("woof \(result[1][2])")


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
                        player.file = newFile2
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

        Settings.bufferLength = .longest
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)

            #if targetEnvironment(simulator)
                try AVAudioSession.sharedInstance().setCategory(.playback,
                                                                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            #else
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            #endif
            try AVAudioSession.sharedInstance().setActive(true)

        } catch let err {
            print(err)
        }

        guard let input = engine.input else {
            fatalError()
        }


        ////This silencer thing is for I think silencing the output for conversion
        // let silencer = Fader(input, gain: 0)
        // self.silencer = silencer
        // mixer.addInput(silencer)

        mew = MeowFader(player)
        //mew.au.meow(sound: "baa wooof")
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
            .onAppear {
                enum Test {}
                var string: String = ""
                debugPrint(Test.self, to: &string)
                print("Module name: \(string.split(separator: ".").first ?? "")")
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
