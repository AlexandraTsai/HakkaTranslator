//
//  Translate.swift
//  HakkaTranslator
//
//  Created by AlexandraTsai on 2021/9/4.
//

import Foundation

struct HakkaWord: Decodable {
    let success: Bool
    let message: String
    let hakka: String

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
        case hakka = "zh_ha"
    }
}

struct Translate: Decodable {
    let participle: String
    let complex: [Complex]

    enum CodingKeys: String, CodingKey {
        case participle = "分詞"
        case complex = "綜合標音"
    }
}

struct Complex: Decodable {
    let chinese: String
    let hakka: String
    let participle: String

    enum CodingKeys: String, CodingKey {
        case chinese = "漢字"
        case hakka = "臺灣客話"
        case participle = "分詞"
    }
}
