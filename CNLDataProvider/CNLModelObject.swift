//
//  CNLModelObject.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 22/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

/// Common class used for access to resources through class bundle reference, holding singletone for network provider
open class CNLModel {
    /// Callback type for success network request completion
    public typealias Success = (_ model: CNLModelObject, _ status: Error) -> Void
    /// Callback type for failed network request
    public typealias Failed = (_ model: CNLModelObject, _ error: Error?) -> Void

    /// Type alias for CNLModelError
    public typealias Error = CNLModelError
    /// Type alias for CNLModelErrorKind
    public typealias ErrorKind = CNLModelErrorKind
    /// Type alias for CNLModelErrorAlert
    public typealias ErrorAlert = CNLModelErrorAlert
    
    open static var networkProvider: CNLModelNetwork?
}

/// Common model object
public protocol CNLModelObject: class {
    func createAPI() -> CNLModelAPI?
    var okStatus: CNLModel.Error { get }
    init()
}

public extension CNLModelObject {
    
    public func createAPI() -> CNLModelAPI? {
        return nil
    }
    
    public func defaultAPIPerform(_ api: CNLModelAPI, success: @escaping CNLModel.Success, fail: @escaping CNLModel.Failed) {
        CNLModel.networkProvider?.performRequest(
            api: api,
            success: { apiObject in success(self, apiObject.status) },
            fail: { apiObject in fail(self, apiObject.errorStatus) },
            networkError: { apiObject, error in fail(self, apiObject.errorStatus(error)) }
        )
    }
    
}

public protocol CNLModelObjectPrimaryKey: class, CNLModelObject {
    associatedtype KeyType: Hashable, CNLDictionaryValue
    var primaryKey: KeyType { get }
    init?(keyValue: KeyType)
    var encodedPrimaryKey: String? { get }
}

public extension CNLModelObjectPrimaryKey {
    public var encodedPrimaryKey: String? { return "\(primaryKey)" }
}

public protocol CNLModelObjectEditable {
    var editing: Bool { get set }
    func updateList()
}
