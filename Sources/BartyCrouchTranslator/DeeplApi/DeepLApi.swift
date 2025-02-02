import Foundation
import Microya

// Documentation can be found here: https://www.deepl.com/ja/docs-api/

enum DeepLApi {
    case translate(texts: [String], from: Language, to: Language, apiKey: String, glossaryIdList: [String: String]?)

    static let maximumTextsPerRequest: Int = 25
    static let maximumTextsLengthPerRequest: Int = 5_000

    static func textBatches(forTexts texts: [String]) -> [[String]] {
        var batches: [[String]] = []
        var currentBatch: [String] = []
        var currentBatchTotalLength: Int = 0

        for text in texts {
            if currentBatch.count < maximumTextsPerRequest
                && text.count + currentBatchTotalLength < maximumTextsLengthPerRequest
            {
            currentBatch.append(text)
            currentBatchTotalLength += text.count
            }
            else {
                batches.append(currentBatch)

                currentBatch = [text]
                currentBatchTotalLength = text.count
            }
        }

        return batches
    }
}

let formalityLanguages: [String] = [
    "DE",
    "FR",
    "IT",
    "ES",
    "NL",
    "PL",
    "PT-PT",
    "PT-BR",
    "RU",
]

extension DeepLApi: Endpoint {
    typealias ClientErrorType = DeepLTranslateErrorResponse

    enum ApiType {
        case free
        case pro
    }

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    var encoder: JSONEncoder {
        JSONEncoder()
    }

    var subpath: String {
        switch self {
        case .translate:
            return "/v2/translate"
        }
    }

    var method: HttpMethod {
        switch self {
        case .translate:
            return .post(
                body: "".data(using: .utf8)!
            )
        }
    }

    var queryParameters: [String: QueryParameterValue] {
        var urlParameters: [String: QueryParameterValue] = [:]

        switch self {
        case let .translate(texts, sourceLanguage, targetLanguage, apiKey, glossaryIdList):
            urlParameters["text"] = .array(texts)
            urlParameters["source_lang"] = sourceLanguage.deepLParameterValue
            urlParameters["target_lang"] = targetLanguage.deepLParameterValue
            urlParameters["auth_key"] = .string(apiKey)

            if formalityLanguages.contains(targetLanguage.rawValue.uppercased()) {
                urlParameters["formality"] = .string("less")
            }

            if let glossaryIdList = glossaryIdList, let value = glossaryIdList[targetLanguage.rawValue] {
                urlParameters["glossary_id"] = .string(value)
            }
        }

        return urlParameters
    }

    var headers: [String: String] {
        ["Content-Type": "application/x-www-form-urlencoded"]
    }

    static func baseUrl(for apiType: ApiType) -> URL {
        switch apiType {
        case .free:
            return URL(string: "https://api-free.deepl.com")!

        case .pro:
            return URL(string: "https://api.deepl.com")!
        }
    }
}

private extension Language {
    var deepLParameterValue: QueryParameterValue {
        switch self {
        case .chineseSimplified:
            return .string("ZH")

        default:
            return .string(rawValue.uppercased())
        }
    }
}
