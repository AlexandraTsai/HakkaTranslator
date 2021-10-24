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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPulsatingLayer()
    }

    private let micButton = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "microphone").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = Constant.buttonColor
        $0.layer.cornerRadius = 40
        $0.imageEdgeInsets = .init(top: 20, left: 20, bottom: 20, right: 20)
    }
    private let pulsatingLayer = CAShapeLayer()
    private let bigPulsatingLayer = CAShapeLayer()
    private let chineseContainer = UIView()
    private let clearBtn = UIButton() --> {
        $0.contentEdgeInsets = .init(top: 2, left: 2, bottom: 2, right: 2)
    }
    private let inputTextView = UITextView() --> {
        $0.font = .boldSystemFont(ofSize: 18)
        $0.textColor = .white
        $0.backgroundColor = .clear
    }
    private let hakkaContainer = UIView()
    private let playButton = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "play-button").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.clipsToBounds = true
        $0.tintColor = Constant.backgroundColor
        $0.layer.cornerRadius = 25
    }
    private let hakkaLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 25)
        $0.textColor = Constant.labelColor
        $0.numberOfLines = 0
    }
    private var viewModel: TranslationViewModelProtocol?
    private let disposeBag = DisposeBag()
}

// MARK: Setup UI
private extension ViewController {
    func setupUI() {
        let bg = UIView()
        bg.backgroundColor = .black.withAlphaComponent(0.8)
        let titleView = UIStackView()
        titleView.axis = .horizontal
        titleView.distribution = .fillEqually
        titleView.spacing = 8
        ["中文", "客家"].forEach {
            let bg = UIView()
            bg.layer.cornerRadius = 18
            bg.backgroundColor = Constant.backgroundColor
            let label = UILabel()
            label.text = $0
            label.textColor = .white
            bg.addSubview(label)
            label.snp.makeConstraints { $0.center.equalToSuperview() }
            titleView.addArrangedSubview(bg)
        }
        [bg, titleView, chineseContainer, hakkaContainer, micButton].forEach { view.addSubview($0) }
        bg.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        titleView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(10)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.height.equalTo(50)
        }
        chineseContainer.snp.makeConstraints {
            $0.height.equalTo(view.snp.height).multipliedBy(1.0 / 4.0)
            $0.top.equalTo(titleView.snp.bottom).offset(20)
            $0.left.right.equalToSuperview().inset(10)
        }
        hakkaContainer.snp.makeConstraints {
            $0.top.equalTo(chineseContainer.snp.bottom).offset(10)
            $0.bottom.lessThanOrEqualTo(micButton.snp.top).offset(-5)
            $0.left.right.equalToSuperview().inset(10)
        }
        micButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            $0.width.height.equalTo(80)
        }
        setupChineseView()
        setupHakkaView()
    }

    func setupPulsatingLayer() {
        let bezier = UIBezierPath(arcCenter: .zero, radius: 40, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        [pulsatingLayer, bigPulsatingLayer].forEach {
            $0.path = bezier.cgPath
            $0.lineCap = .round
            $0.position = micButton.center
            view.layer.addSublayer($0)
        }
        pulsatingLayer.fillColor = Constant.buttonColor.withAlphaComponent(0.8).cgColor
        bigPulsatingLayer.fillColor = Constant.buttonColor.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(bigPulsatingLayer)
        view.bringSubviewToFront(micButton)
    }

    func setupChineseView() {
        chineseContainer.addSubview(clearBtn)
        clearBtn.setImage(#imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate), for: .normal)
        clearBtn.tintColor = Constant.backgroundColor
        clearBtn.snp.makeConstraints {
            $0.top.right.equalToSuperview()
            $0.height.width.equalTo(40)
        }
        chineseContainer.addSubview(inputTextView)
        inputTextView.snp.makeConstraints {
            $0.top.left.bottom.equalToSuperview().inset(5)
            $0.right.equalToSuperview().inset(45)
        }
    }

    func setupHakkaView() {
        let separator = UIView()
        separator.backgroundColor = Constant.backgroundColor
        [separator, playButton, hakkaLabel].forEach { hakkaContainer.addSubview($0) }
        separator.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(0.6)
        }
        playButton.snp.makeConstraints {
            $0.height.width.equalTo(50)
            $0.top.left.equalToSuperview()
        }
        hakkaLabel.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview().inset(5)
            $0.top.equalTo(playButton.snp.bottom).offset(10)
        }
    }

    func binding(viewModel: TranslationViewModelProtocol) {
        self.viewModel = viewModel

        inputTextView.rx.text
            .compactMap { $0 }
            .subscribe(onNext: { [weak viewModel] text in
                viewModel?.translate(text)
            }).disposed(by: disposeBag)

        viewModel.chinese
            .distinctUntilChanged()
            .bind(to: inputTextView.rx.text)
            .disposed(by: disposeBag)

        viewModel.chinese
            .map { $0?.isEmpty ?? true }
            .bind(to: clearBtn.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.hakka
            .bind(to: hakkaLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.hakka
            .map { $0?.isEmpty ?? true }
            .bind(to: hakkaContainer.rx.isHidden)
            .disposed(by: disposeBag)

        gestureBinding()
    }

    func gestureBinding() {
        micButton.rx.anyGesture(.longPress())
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                switch gesture.state {
                case .began:
                    self.viewModel?.startRecording()
                    self.pulsatingLayer.addPulsing(toValue: 1.7, forKey: "smallPulsing")
                    self.bigPulsatingLayer.addPulsing(toValue: 2.1, forKey: "bigPulsing")
                case .ended:
                    self.viewModel?.endRecording()
                    self.pulsatingLayer.removeAllAnimations()
                    self.bigPulsatingLayer.removeAllAnimations()
                default: break
                }
            }).disposed(by: disposeBag)

        clearBtn.rx.tapGesture()
            .subscribe(onNext: { [weak viewModel] _ in
                viewModel?.clearAll()
            }).disposed(by: disposeBag)

        playButton.rx.tapGesture()
            .subscribe(onNext: { [weak viewModel] _ in
                viewModel?.speak()
            }).disposed(by: disposeBag)

        view.rx.tapGesture()
            .subscribe(onNext: { [weak view] _ in
                view?.endEditing(true)
            }).disposed(by: disposeBag)
    }
}

infix operator -->
func --> <T>(object: T, closure: (T) -> Void) -> T {
    closure(object)
    return object
}

enum Constant {
    /// FF7168
    static let buttonColor = UIColor(hex: "FF7168")
    /// 606666
    static let labelColor = UIColor(hex: "DF5656")
    /// 7C5151
    static let backgroundColor = UIColor(hex: "7C5151")
}
