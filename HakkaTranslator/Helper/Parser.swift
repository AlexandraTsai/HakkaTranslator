//
//  Parser.swift
//  HakkaTranslator
//
//  Created by AlexandraTsai on 2021/9/4.
//

import Alamofire
import Foundation
import PromiseKit

class Parser {
    static func translate(_ string: String) -> Promise<String> {
        let headers: HTTPHeaders = [.accept("*/*"),
                                    .userAgent("Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Mobile Safari/537.36"),
                                    .contentType("application/json"),
                                    .init(name: "referer", value: "http://gohakka.org/")]
        let parameters = ["查詢腔口": "四縣腔", "查詢語句": string]
        return Promise { seal in
            AF.request(url, method: .get, parameters: parameters, headers: headers)
                .validate()
                .responseDecodable(of: Translate.self) { response in
                    switch response.result {
                    case let .success(translation):
                        seal.fulfill(translation.participle)
                    case let .failure(error):
                        seal.reject(error)
                    }
                }
        }
    }

    private static let url = "https://hts.ithuan.tw/%E6%A8%99%E6%BC%A2%E5%AD%97%E9%9F%B3%E6%A8%99?%25E6%259F%25A5%25E8%25A9%25A2%25E8%2585%2594%25E5%258F%25A3=%25E5%259B%259B%25E7%25B8%25A3%25E8%2585%2594&%25E6%259F%25A5%25E8%25A9%25A2%25E8%25AA%259E%25E5%258F%25A5=%25E4%25BD%25A0%25E5%25A5%25BD"
}

extension String {
    var unicodeStr:String {
        let tempStr1 = self.replacingOccurrences(of: "\\u", with: "\\U")
        let tempStr2 = tempStr1.replacingOccurrences(of: "\"", with: "\\\"")
        let tempStr3 = "\"".appending(tempStr2).appending("\"")
        let tempData = tempStr3.data(using: String.Encoding.utf8)
        var returnStr:String = ""
        do {
            returnStr = try PropertyListSerialization.propertyList(from: tempData!, options: [.mutableContainers], format: nil) as! String
        } catch {
            print(error)
        }
        return returnStr.replacingOccurrences(of: "\\r\\n", with: "\n")
    }
}
