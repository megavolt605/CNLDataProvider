//
//  LogMessages.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 28/08/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

extension CNLLogger.Message {
    
    static let ModelNewItems = CNLLogger.Message(code: "CN-001", message: "Model new items: %@")
    static let ModelChangedItems = CNLLogger.Message(code: "CN-002", message: "Model changed items: %@")
    static let ModelRemovedItems = CNLLogger.Message(code: "CN-003", message: "Model removed items: %@")
    static let ModelCount = CNLLogger.Message(code: "CN-004", message: "Model count: %@")

    static let ModelInsertSections = CNLLogger.Message(code: "CN-005", message: "Insert Section:\n %@")
    static let ModelDeleteSections = CNLLogger.Message(code: "CN-006", message: "Delete Section:\n %@")
    static let ModelInsertRows = CNLLogger.Message(code: "CN-007", message: "Insert Rows:\n %@")
    static let ModelDeleteRows = CNLLogger.Message(code: "CN-008", message: "Delete Rows:\n %@")

    static let ImageDownloadedSuccess = CNLLogger.Message(
        code: "CN-100",
        message: "%@ loaded, network time: %@, total time: %@ size: %@ x %@ %@"
    )
    
    static let ImageDownloadingError = CNLLogger.Message(code: "CN-101", message: "%@ loading error")

}
