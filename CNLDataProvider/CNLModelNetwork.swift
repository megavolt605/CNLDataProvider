//
//  CNLModelNetwork.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 22/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

public typealias CNLModelNetworkSuccess = (_ api: CNLModelAPI) -> Void
public typealias CNLModelNetworkFail = (_ api: CNLModelAPI) -> Void
public typealias CNLModelNetworkNetworkError = (_ api: CNLModelAPI, _ error: Error?) -> Void

public typealias CNLModelNetworkDownloadFileSuccess = (_ fileName: String, _ fileData: Data?, _ userData: Any?) -> Void
public typealias CNLModelNetworkDownloadFileFail = (_ fileName: String, _ error: Error?, _ userData: Any?) -> Void
public typealias CNLModelNetworkDownloadFileCancel = (_ fileName: String, _ userData: Any?) -> Void

public typealias CNLModelNetworkDownloadImageSuccess = (_ fileName: String, _ image: UIImage, _ imageData: Data, _ userData: Any?) -> Void

public protocol CNLModelNetwork {
    func performRequest(
        api: CNLModelAPI,
        success: @escaping CNLModelNetworkSuccess,
        fail: @escaping CNLModelNetworkFail,
        networkError: @escaping CNLModelNetworkNetworkError
    )
    func performRequest(
        api: CNLModelAPI,
        maxTries: Int,
        retryDelay: TimeInterval,
        success: @escaping CNLModelNetworkSuccess,
        fail: @escaping CNLModelNetworkFail,
        networkError: @escaping CNLModelNetworkNetworkError
    )
    func downloadFileFromURL(
        _ urlString: String,
        priority: Float,
        userData: Any?,
        success: @escaping CNLModelNetworkDownloadFileSuccess,
        fail: @escaping CNLModelNetworkDownloadFileFail
        ) -> CNLModelNetworkDownloadFileCancel?
}

public extension CNLModelNetwork {

    public func performRequest(
        api: CNLModelAPI,
        maxTries: Int,
        retryDelay: TimeInterval = 5.0,
        success: @escaping CNLModelNetworkSuccess,
        fail: @escaping CNLModelNetworkFail,
        networkError: @escaping CNLModelNetworkNetworkError
        ) {
        
        performRequest(api: api, maxTries: maxTries, retryDelay: retryDelay, success: success, fail: fail, networkError: networkError)
    }
}
