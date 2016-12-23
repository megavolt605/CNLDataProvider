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

public protocol CNLModelNetwork {
    func performRequest(api: CNLModelAPI, success: @escaping CNLModelNetworkSuccess, fail: @escaping CNLModelNetworkFail, networkError: @escaping CNLModelNetworkNetworkError)
}
