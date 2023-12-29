//
//  licenseGenerator
//

import Foundation

public extension String {
    
    var nsString: NSString {
        (self as NSString)
    }

    var pathExtension: String {
        return nsString.pathExtension
    }

    var lastPathComponent: String {
        return nsString.lastPathComponent
    }

    var deletingLastPathComponent: String {
        return nsString.deletingLastPathComponent
    }

    var stringByDeletingPathExtension: String {
        return nsString.deletingPathExtension
    }

    var expandingTildeInPath: String {
        return nsString.expandingTildeInPath
    }
    
    func appendingPathComponent(_ component: String) -> String {
        return nsString.appendingPathComponent(component)
    }
}
