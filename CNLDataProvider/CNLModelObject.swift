//
//  CNLModelObject.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 22/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

// used for access to resource through class bundle reference
class CNLModelDummy {
    
}

public typealias CNLDictionary = [String: Any]
public typealias CNLArray = [CNLDictionary]

public typealias CNLModelCompletion = (_ model: CNLModelObject, _ status: CNLModelError) -> Void
public typealias CNLModelFailed = (_ model: CNLModelObject, _ error: CNLModelError?) -> Void

public protocol CNLModelObject: class {
    func createAPI() -> CNLModelAPI?
    var okStatus: CNLModelError { get }
    init()
}

public var CNLModelNetworkProvider: CNLModelNetwork?

public extension CNLModelObject {
    
    public func createAPI() -> CNLModelAPI? {
        return nil
    }
    
    public func defaultAPIPerform(_ api: CNLModelAPI, success: @escaping CNLModelCompletion, fail: @escaping CNLModelFailed) {
        CNLModelNetworkProvider?.performRequest(
            api: api,
            success: { apiObject in success(self, apiObject.status) },
            fail: { apiObject in fail(self, apiObject.errorStatus) },
            networkError: { apiObject, error in fail(self, apiObject.errorStatus(error)) }
        )
    }
    
}

public protocol CNLModelObjectPrimaryKey: class, CNLModelObject {
    associatedtype KeyType: Hashable
    var primaryKey: KeyType { get }
    init?(keyValue: String)
    var encodedPrimaryKey: String? { get }
}

public extension CNLModelObjectPrimaryKey {
    public var encodedPrimaryKey: String? { return "\(primaryKey)" }
}

public protocol CNLModelObjectEditable {
    var editing: Bool { get set }
    func updateList()
}
