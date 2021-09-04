//
//  ViewController.swift
//  HakkaTranslator
//
//  Created by AlexandraTsai on 2021/9/4.
//

import UIKit
import RxCocoa
import RxSwift
import RxGesture
import SnapKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        binding(viewModel: TranslationViewModel(delegate: self))
    }

    private let micButton = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "microphone").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .purple
        $0.layer.cornerRadius = 30
        $0.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
    }
    private let chineseLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .white
    }
    private let hakkaLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .white
    }
    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "zh_Hant"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var viewModel: TranslationViewModelProtocol?
    private let disposeBag = DisposeBag()
}

// MARK: Setup UI
private extension ViewController {
    func setupUI() {
        view.addSubview(micButton)
        micButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(50)
            $0.width.equalTo(60)
            $0.height.equalTo(60)
        }
        view.addSubview(chineseLabel)
        chineseLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(100)
            $0.left.right.equalToSuperview().inset(30)
        }
        view.addSubview(hakkaLabel)
        hakkaLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(chineseLabel.snp.bottom).offset(30)
            $0.left.right.equalToSuperview().inset(30)
        }
    }

    func binding(viewModel: TranslationViewModelProtocol) {
        self.viewModel = viewModel

        viewModel.chinese
            .distinctUntilChanged()
            .throttle(.milliseconds(30), scheduler: MainScheduler.instance)
            .compactMap { [weak viewModel] chinese in
                return (chinese != nil) ? chinese : viewModel?.speakingText
            }
            .bind(to: chineseLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.hakka
            .bind(to: hakkaLabel.rx.text)
            .disposed(by: disposeBag)

        micButton.rx.anyGesture(.longPress())
            .subscribe(onNext: { [weak viewModel] gesture in
                switch gesture.state {
                case .began: viewModel?.startRecording()
                    print(" -------- began --------")
                case .ended: viewModel?.endRecording()
                    print(" -------- ended --------")
                default: break
                }
            }).disposed(by: disposeBag)
    }
}

infix operator -->
func --> <T>(object: T, closure: (T) -> Void) -> T {
    closure(object)
    return object
}
