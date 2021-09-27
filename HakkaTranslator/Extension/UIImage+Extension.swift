//
//  UIImage+Extension.swift
//  HakkaTranslator
//
//  Created by 蔡佳宣 on 2021/9/12.
//

import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        let radio = size.width / size.height
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: .init(x: 0, y: 0, width: size.width * radio, height: size.height))
        let new = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return new ?? self
    }
}
