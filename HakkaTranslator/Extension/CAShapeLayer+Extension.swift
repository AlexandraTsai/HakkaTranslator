//
//  CAShapeLayer+Extension.swift
//  HakkaTranslator
//
//  Created by 蔡佳宣 on 2021/9/5.
//

import UIKit

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
