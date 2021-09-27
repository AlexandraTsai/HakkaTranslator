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
        [chineseContainer, hakkaContainer].forEach {
            addCardStyleBackground(for: $0.frame)
            view.bringSubviewToFront($0)
        }
        setupPulsatingLayer()
    }

    private let titleLabel = UILabel() --> {
        $0.font = UIFont.systemFont(ofSize: 20)
        $0.textColor = UIColor(hex: "414D4D")
        $0.text = "Listening..."
        $0.isHidden = true
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
    private let hakkaContainer = UIView()
    private let playButton = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
        $0.clipsToBounds = true
    }
    private let chineseLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 25)
        $0.textColor = Constant.labelColor
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    private let hakkaLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 25)
        $0.textColor = Constant.labelColor
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    private let textInputBtn = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "enter_text").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 25
    }
    private let textInput = UITextField() //Not visible on the UI
    private var viewModel: TranslationViewModelProtocol?
    private let disposeBag = DisposeBag()
}

// MARK: Setup UI
private extension ViewController {
    func setupUI() {
        let bg = UIImageView(image: #imageLiteral(resourceName: "background"))
        bg.contentMode = .scaleAspectFill

        [bg, titleLabel, chineseContainer, hakkaContainer, micButton, textInputBtn].forEach { view.addSubview($0) }
        bg.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        chineseContainer.snp.makeConstraints {
            $0.height.equalTo(view.snp.height).multipliedBy(200.0 / 896.0)
            $0.bottom.equalTo(view.snp.centerY).offset(-50)
            $0.left.right.equalToSuperview().inset(50)
        }
        hakkaContainer.snp.makeConstraints {
            $0.height.equalTo(chineseContainer)
            $0.bottom.equalTo(micButton.snp.top).offset(-50)
            $0.left.right.equalToSuperview().inset(50)
        }
        micButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            $0.width.height.equalTo(80)
        }
        textInputBtn.snp.makeConstraints {
            $0.width.height.equalTo(50)
            $0.bottom.equalTo(micButton)
            $0.right.equalToSuperview().inset(30)
        }
        view.addSubview(textInput)
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
        pulsatingLayer.fillColor = Constant.btnLayer1Color.withAlphaComponent(0.8).cgColor
        bigPulsatingLayer.fillColor = Constant.btnLayer2Color.withAlphaComponent(0.6).cgColor
        view.layer.addSublayer(bigPulsatingLayer)
        view.bringSubviewToFront(micButton)
    }

    func setupChineseView() {
        let chineseIcon = UIImageView(image: #imageLiteral(resourceName: "dumpling").resize(to: .init(width: 30, height: 30)).withRenderingMode(.alwaysTemplate))
        chineseIcon.backgroundColor = UIColor(hex: "#414D4D")
        chineseIcon.layer.cornerRadius = 35
        chineseIcon.clipsToBounds = true
        chineseIcon.tintColor = .white
        chineseIcon.contentMode = .center
        chineseContainer.addSubview(chineseIcon)
        chineseContainer.addSubview(chineseLabel)
        chineseIcon.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-25)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(70)
        }
        chineseLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview().inset(10)
            $0.bottom.lessThanOrEqualToSuperview()
            $0.height.greaterThanOrEqualToSuperview()
        }
    }

    func setupHakkaView() {
        let image = UIImageView(image: #imageLiteral(resourceName: "flowers"))
        image.layer.cornerRadius = 35
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        hakkaContainer.addSubview(image)
        hakkaContainer.addSubview(hakkaLabel)
        hakkaContainer.addSubview(playButton)
        image.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-25)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(70)
        }
        hakkaLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview().inset(10)
            $0.bottom.lessThanOrEqualToSuperview()
            $0.height.greaterThanOrEqualToSuperview()
        }
        playButton.snp.makeConstraints {
            $0.height.width.equalTo(50)
            $0.bottom.right.equalToSuperview().inset(10)
        }
    }

    func binding(viewModel: TranslationViewModelProtocol) {
        self.viewModel = viewModel

        viewModel.chinese
            .distinctUntilChanged()
            .bind(to: chineseLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.chinese
            .map { $0?.isEmpty ?? true }
            .bind(to: chineseLabel.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.hakka
            .bind(to: hakkaLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.hakka
            .map { $0?.isEmpty ?? true }
            .bind(to: hakkaLabel.rx.isHidden)
            .disposed(by: disposeBag)

        textInputBtn.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak textInput] _ in
                textInput?.becomeFirstResponder()
            }).disposed(by: disposeBag)

        textInput.rx.text
            .compactMap { $0 }
            .subscribe(onNext: { [weak viewModel] text in
                viewModel?.translate(text)
            }).disposed(by: disposeBag)

        micButton.rx.anyGesture(.longPress())
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                switch gesture.state {
                case .began:
                    self.titleLabel.isHidden = false
                    self.viewModel?.startRecording()
                    self.pulsatingLayer.addPulsing(toValue: 1.7, forKey: "smallPulsing")
                    self.bigPulsatingLayer.addPulsing(toValue: 2.1, forKey: "bigPulsing")
                case .ended:
                    self.titleLabel.isHidden = true
                    self.viewModel?.endRecording()
                    self.pulsatingLayer.removeAllAnimations()
                    self.bigPulsatingLayer.removeAllAnimations()
                default: break
                }
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

private extension ViewController {
    func addCardStyleBackground(for frame: CGRect) {
        let path = UIBezierPath()
        path.move(to: frame.origin)
        path.addQuadCurve(to: CGPoint(x: frame.maxX, y: frame.minY), controlPoint: CGPoint(x: frame.maxX - 50, y: frame.minY - 30))
        path.addQuadCurve(to: CGPoint(x: frame.maxX - 3, y: frame.maxY), controlPoint: CGPoint(x: frame.maxX - 10, y: frame.maxY - 10))
        path.addQuadCurve(to: CGPoint(x: frame.minX + 5, y: frame.maxY - 10), controlPoint: CGPoint(x: frame.minX + 40, y: frame.maxY + 8))
        path.addQuadCurve(to: CGPoint(x: frame.minX, y: frame.minY), controlPoint: CGPoint(x: frame.minX - 5, y: frame.minY + 30))
        path.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        view.layer.addSublayer(shapeLayer)
    }
}

infix operator -->
func --> <T>(object: T, closure: (T) -> Void) -> T {
    closure(object)
    return object
}

enum Constant {
    static let buttonColor = UIColor(hex: "57FDFD")
    static let btnLayer1Color = UIColor(hex: "4BF4F4")
    static let btnLayer2Color = UIColor(hex: "50E4E4")
    static let labelColor = UIColor(hex: "606666")
}
