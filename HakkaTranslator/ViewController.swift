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

    private let titleLabel = UILabel() --> {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = UIColor.lightGray
        $0.text = "Listening..."
    }
    private let micButton = UIButton() --> {
        $0.setImage(#imageLiteral(resourceName: "microphone").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .purple
        $0.layer.cornerRadius = 30
        $0.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
    }
    let chineseContainer = UIView()
    let hakkaContainer = UIView()
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
            $0.bottom.equalToSuperview().inset(50)
            $0.width.equalTo(60)
            $0.height.equalTo(60)
        }
        setupChineseView()
        setupHakkaView()
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
            .subscribe(onNext: { [weak viewModel, weak titleLabel] gesture in
                switch gesture.state {
                case .began:
                    titleLabel?.isHidden = false
                    viewModel?.startRecording()
                case .ended:
                    titleLabel?.isHidden = true
                    viewModel?.endRecording()
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
