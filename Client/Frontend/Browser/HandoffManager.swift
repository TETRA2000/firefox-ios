/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class HandoffManager: NSObject {
    static var sharedInstance = HandoffManager()
    
    lazy var userActivity: NSUserActivity? = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    
    func start() {
        guard ((userActivity?.webpageURL) != nil) else {
            return
        }
        userActivity?.becomeCurrent()
    }
    
    func stop() {
         // iOS 8.x is not current target
        if #available(iOS 9.0, *) {
            userActivity?.resignCurrent()
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
