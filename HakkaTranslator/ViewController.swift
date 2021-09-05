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

    private let titleLabel = UILabel() --> {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = UIColor.lightGray
        $0.text = "Listening..."
        $0.isHidden = true
    }
    private let micButton = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "microphone").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .purple
        $0.layer.cornerRadius = 40
        $0.imageEdgeInsets = .init(top: 20, left: 20, bottom: 20, right: 20)
    }
    private let pulsatingLayer = CAShapeLayer()
    private let bigPulsatingLayer = CAShapeLayer()
    private let chineseContainer = UIView()
    private let hakkaContainer = UIView()
    private let chineseLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 22)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    private let hakkaLabel = UILabel() --> {
        $0.font = .boldSystemFont(ofSize: 22)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    private var viewModel: TranslationViewModelProtocol?
    private let disposeBag = DisposeBag()
}

// MARK: Setup UI
private extension ViewController {
    func setupUI() {
        [titleLabel, chineseContainer, hakkaContainer, micButton].forEach { view.addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        chineseContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.bottom.equalTo(view.snp.centerY)
            $0.left.right.equalToSuperview()
        }
        hakkaContainer.snp.makeConstraints {
            $0.bottom.left.right.equalToSuperview()
            $0.top.equalTo(view.snp.centerY)
        }
        micButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            $0.width.equalTo(80)
            $0.height.equalTo(80)
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
        pulsatingLayer.fillColor = UIColor.purple.withAlphaComponent(0.8).cgColor
        bigPulsatingLayer.fillColor = UIColor.purple.withAlphaComponent(0.6).cgColor
        view.layer.addSublayer(bigPulsatingLayer)
        view.bringSubviewToFront(micButton)
    }

    func setupChineseView() {
        let image = UIImageView(image: #imageLiteral(resourceName: "chinese_icon").withRenderingMode(.alwaysTemplate))
        image.tintColor = .blue
        image.layer.cornerRadius = 25
        image.clipsToBounds = true
        chineseContainer.addSubview(image)
        chineseContainer.addSubview(chineseLabel)
        image.snp.makeConstraints {
            $0.top.greaterThanOrEqualToSuperview().offset(30)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(50)
        }
        chineseLabel.snp.makeConstraints {
            $0.top.equalTo(image.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview().inset(30)
            $0.bottom.equalToSuperview().inset(50)
        }
    }

    func setupHakkaView() {
        let image = UIImageView(image: #imageLiteral(resourceName: "hakka_symbol"))
        image.layer.cornerRadius = 25
        image.clipsToBounds = true
        hakkaContainer.addSubview(image)
        hakkaContainer.addSubview(hakkaLabel)
        image.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(50)
        }
        hakkaLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(image.snp.bottom).offset(20)
            $0.left.right.equalToSuperview().inset(30)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    func binding(viewModel: TranslationViewModelProtocol) {
        self.viewModel = viewModel

        viewModel.chinese
            .distinctUntilChanged()
            .bind(to: chineseLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.chinese
            .map { $0 == nil }
            .bind(to: chineseContainer.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.hakka
            .bind(to: hakkaLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.hakka
            .map { $0 == nil }
            .bind(to: hakkaContainer.rx.isHidden)
            .disposed(by: disposeBag)

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
    }


}

infix operator -->
func --> <T>(object: T, closure: (T) -> Void) -> T {
    closure(object)
    return object
}

extension CAShapeLayer {
    func addPulsing(toValue: Any, forKey: String) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = toValue
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.timingFunction = .init(name: .easeInEaseOut)
        animation.autoreverses = true
        add(animation, forKey: forKey)
    }
}
