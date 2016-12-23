//
//  CNLModelAPI.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 22/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation


public enum CNLModelAPIMethod {
    case get, put, post, mpost, patch, delete
    public var description: String {
        switch self {
        case .get: return "GET"
        case .put: return "PUT"
        case .post, .mpost: return "POST"
        case .patch: return "PATCH"
        case .delete: return "DELETE"
        }
    }
}

public protocol CNLModelAPI {
    var request: CNLDictionary { get }
    var response: HTTPURLResponse? { get set }
    var status: CNLModelError { get }
    var statusKind: CNLModelErrorKind { get set }
    var errorStatus: CNLModelError { get }
    var answerJSON: CNLDictionary? { get set }
    var success: Bool { get }
    var endpoint: CNLModelAPIEndpoint? { get }
    func errorStatus(_ error: Error?) -> CNLModelError
    func createAlertStruct(_ json: CNLDictionary?, defaultType: CNLModelErrorAlertStyle) -> CNLModelErrorAlertStruct?
    func createAlertStruct(_ defaultType: CNLModelErrorAlertStyle) -> CNLModelErrorAlertStruct?
    init(endpoint: CNLModelAPIEndpoint)
}

public protocol CNLModelAPIEndpoint {

    var logEnabled: Bool { get }
    var requestParams: CNLDictionary? { get }
    var method: CNLModelAPIMethod { get }
    var path: String { get }
    
    var requestIsDictionary: Bool { get }
    var answerIsDictionary: Bool { get }
    
    var isHTTP: Bool { get }
    
    var mockAnswer: Any? { get }
}
