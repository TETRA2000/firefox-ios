/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class HandoffManager: NSObject {
    private static var _sharedInstance: HandoffManager?
    static var sharedInstance: HandoffManager {
        get {
            if _sharedInstance == nil {
                _sharedInstance = HandoffManager()
            }
            
            return _sharedInstance!
        }
    }
    
    lazy var userActivity: NSUserActivity? = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    
    func start() {
        if let _ = userActivity?.webpageURL {
            userActivity?.becomeCurrent()
        }
    }
    
    func stop() {
        if #available(iOS 9.0, *) {
            userActivity?.resignCurrent()
        } else {
            // iOS 8 is not our target
        }
    }
    
    func clearCurrentURL() {
        userActivity?.webpageURL = nil
    }
    
    func updateCurrentURL(urlStr: String?) {
        guard let urlStr = urlStr,
            let url = NSURL(string: urlStr) else {
                return
        }
        
        userActivity?.webpageURL = url
    }
}
