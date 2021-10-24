//
//  TranslationViewModel.swift
//  HakkaTranslator
//
//  Created by AlexandraTsai on 2021/9/4.
//

import Foundation
import RxCocoa
import RxSwift
import Speech
import PromiseKit

protocol TranslationViewModelInput: AnyObject {
    func startRecording()
    func endRecording()
    func translate(_ text: String)
    func speak()
    func clearAll()
}

protocol TranslationViewModelOutput: AnyObject {
    var chinese: BehaviorRelay<String?> { get }
    var hakka: BehaviorRelay<String?> { get }
    var micEnable: BehaviorRelay<Bool> { get }
}

typealias TranslationViewModelProtocol = TranslationViewModelInput & TranslationViewModelOutput

class TranslationViewModel: TranslationViewModelProtocol {
    let chinese = BehaviorRelay<String?>(value: nil)
    let hakka = BehaviorRelay<String?>(value: nil)
    let micEnable = BehaviorRelay<Bool>(value: true)

    func startRecording() {
        guard !audioEngine.isRunning else {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            micEnable.accept(false)
            return
        }

        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        //configAudioSession
        configAudioSession()
        let input = audioEngine.inputNode
        confiMicInput(inputNode: input)
        createSpeechRecognitionRequest(inputNode: input)

        //confiMicInput
        chinese.accept(nil)
    }

    func endRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        micEnable.accept(true)
    }

    func translate(_ text: String) {
        chinese.accept(text)
    }

    func speak() {
        guard let hakka = hakka.value else {
            return
        }
        Parser.shared.speak(hakka)
    }

    func clearAll() {
        chinese.accept(nil)
    }

    init(delegate: SFSpeechRecognizerDelegate) {
        speechRecognizer?.delegate = delegate
        getAuthorization()
        binding()
    }

    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "zh_Hant"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine() //To retrieve microphone input
    private let disposeBag = DisposeBag()
}

private extension TranslationViewModel {
    func binding() {
        chinese
            .distinctUntilChanged()
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                guard let self = self,
                      let text = text,
                      !text.isEmpty else {
                    self?.hakka.accept(nil)
                    return
                }
                Parser.shared.translate(text)
                    .done { translation in
                        self.hakka.accept(translation)
                    }
                    .catch { _ in
                        self.hakka.accept("找不到符合的翻譯")
                    }   
            }).disposed(by: disposeBag)
    }

    func getAuthorization() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied, .restricted, .notDetermined:
                isButtonEnabled = false
                print("Not able to speech since user denied access to speech recognition, speech recognition restricted on this device, or speech recognition not yet authorized")
            default:
                break
            }

            OperationQueue.main.addOperation() {
                self.micEnable.accept(isButtonEnabled)
            }
        }
    }

    /// Configure the audio session for the app.
    func configAudioSession(){
        //When you press the mic button, the app retrieves the shared AVAudioSession object, configures it for recording, and makes it the active session.
        //Activating the session lets the system know that the app needs the microphone resource.
        //If that resource is unavailable—perhaps because the user is talking on the phone—the `setActive(_:options:)` method throws an exception.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
    }

    /// Configure the microphone input.
    func confiMicInput(inputNode: AVAudioInputNode) {
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: recordingFormat) { (buffer, when) in
            //Accumulates the audio samples and delivers them to the speech recognition system.
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }

    func createSpeechRecognitionRequest(inputNode: AVAudioInputNode) {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        //Let the speech recognition system to return intermediate results as they are recognized.
        recognitionRequest.shouldReportPartialResults = true

        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest,resultHandler: { (result, error) in
            var isFinal = false
            if let result = result {
                self.chinese.accept(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.micEnable.accept(true)
            }
        })
    }
}
