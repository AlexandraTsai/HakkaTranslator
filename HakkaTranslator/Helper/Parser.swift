//
//  Parser.swift
//  HakkaTranslator
//
//  Created by AlexandraTsai on 2021/9/4.
//

import Alamofire
import AVFoundation
import Foundation
import PromiseKit

class Parser {
    static let shared = Parser()

    func translate(_ chinese: String) -> Promise<String> {
        getHakkaWord(chinese)
            .then { hakka in
                return self.getHakkaPinyin(hakka)
            }
    }

    func speak(_ string: String) {
        let headers: HTTPHeaders = [.accept("*/*"),
                                    .userAgent("Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Mobile Safari/537.36"),
                                    .contentType("audio/wav"),
                                    .acceptLanguage("zh-TW,zh;q=0.9"),
                                    .acceptEncoding("identity;q=1, *;q=0"),
        ]
        let parameters = ["查詢腔口": "四縣腔", "查詢語句": string]

        AF.request(speakUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
            .validate()
            .response(completionHandler: { response in
                switch response.result {
                case let .success(data):
                    guard let data = data else {
                        return
                    }
                    do {
                        self.player = try! AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
                        self.player?.prepareToPlay()
                        self.player?.volume = 1
                        self.player?.play()
                    }
                case let .failure(error):
                    print(error)
                }
            })
    }

    private let hakkaWordUrl = "http://gohakka.org/hakkadic/translate.py"
    private let hakkaPinyinurl = "https://hts.ithuan.tw/%E6%A8%99%E6%BC%A2%E5%AD%97%E9%9F%B3%E6%A8%99?%25E6%259F%25A5%25E8%25A9%25A2%25E8%2585%2594%25E5%258F%25A3=%25E5%259B%259B%25E7%25B8%25A3%25E8%2585%2594&%25E6%259F%25A5%25E8%25A9%25A2%25E8%25AA%259E%25E5%258F%25A5=%25E4%25BD%25A0%25E5%25A5%25BD"
    private let speakUrl = "https://hts.ithuan.tw/%E8%AA%9E%E9%9F%B3%E5%90%88%E6%88%90?%E6%9F%A5%E8%A9%A2%E8%85%94%E5%8F%A3=%E5%9B%9B%E7%B8%A3%E8%85%94&%E6%9F%A5%E8%A9%A2%E8%AA%9E%E5%8F%A5=%E9%A3%9F-%E9%A3%BD%EF%BD%9Csiid-bau%CB%8B%20%E5%90%82%EF%BD%9Cmang%CB%87"
    private var player: AVAudioPlayer?
}

private extension Parser {
    func getHakkaWord(_ string: String) -> Promise<String> {
        let headers: HTTPHeaders = [.accept("*/*"),
                                    .acceptLanguage("zh-TW,zh;q=0.9"),
                                    .acceptEncoding("gzip, deflate"),
                                    .contentType("application/x-www-form-urlencoded; charset=UTF-8"),
                                    .userAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.164 Safari/537.36"),
        ]
        return Promise { seal in
            let parameters: Parameters = ["input_lang": "zh-tw", "input_txt": string]
            AF.request(hakkaWordUrl,
                       method: .post,
                       parameters: parameters,
                       encoding: URLEncoding.default,
                       headers: headers)
                .validate()
                .responseDecodable(of: HakkaWord.self) { response in
                    switch response.result {
                    case let .success(translation):
                        seal.fulfill(translation.hakka)
                    case let .failure(error):
                        seal.reject(error)
                    }
                }
        }
    }

    func getHakkaPinyin(_ string: String) -> Promise<String> {
        let headers: HTTPHeaders = [.accept("*/*"),
                                    .userAgent("Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Mobile Safari/537.36"),
                                    .contentType("application/json"),
                                    .init(name: "referer", value: "http://gohakka.org/")]
        let parameters = ["查詢腔口": "四縣腔", "查詢語句": string]
        return Promise { seal in
            AF.request(hakkaPinyinurl, method: .get, parameters: parameters, headers: headers)
                .validate()
                .responseDecodable(of: Translate.self) { response in
                    switch response.result {
                    case let .success(translation):
                        seal.fulfill(translation.complex.first?.participle ?? translation.participle)
                    case let .failure(error):
                        seal.reject(error)
                    }
                }
        }
    }
}
