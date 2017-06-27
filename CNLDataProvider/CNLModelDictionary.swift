//
//  CNLModelDictionary.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public protocol CNLModelDictionary {
    init()
    init?(dictionary: CNLDictionary?)
    func loadFromDictionary(_ dictionary: CNLDictionary)
    func storeToDictionary() -> CNLDictionary
    func updateDictionary()
    func updateDictionary(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed)
}

public extension CNLModelDictionary where Self: CNLModelObject {
    
    public init?(dictionary: CNLDictionary?) {
        self.init()
        if let data = dictionary {
            loadFromDictionary(data)
        } else {
            return nil
        }
    }
    
    public func loadFromDictionary(_ dictionary: CNLDictionary) {
        // dummy
    }
    
    public func storeToDictionary() -> CNLDictionary {
        return [:] // dummy
    }
    
    public func updateDictionary() {
        updateDictionary(success: { _, _ in }, failed: { _, _ in })
    }
    
    public func updateDictionary(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed) {
        if let localAPI = createAPI() {
            CNLModel.networkProvider?.performRequest(
                api: localAPI,
                success: { apiObject in
                    if let json = apiObject.answerJSON {
                        self.loadFromDictionary(json)
                    }
                    success(self, apiObject.status)
            },
                fail: { (apiObject) in
                    failed(self, apiObject.errorStatus)
            },
                networkError: { apiObject, error in
                    failed(self, apiObject.errorStatus(error))
            }
            )
        }
    }
    
}

public protocol CNLModelDictionaryKeyStored: CNLModelDictionary, CNLModelObjectPrimaryKey {
    
}
