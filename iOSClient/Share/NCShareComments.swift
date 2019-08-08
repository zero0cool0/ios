//
//  NCShareComments.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 28/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class NCShareComments: UIViewController {
    
    var metadata: tableMetadata?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metadata = self.metadata else { return }

        OCNetworking.sharedManager()?.getCommentsWithAccount(appDelegate.activeAccount, fileID: metadata.fileID, completion: { (account, items, message, errorCode) in
            if errorCode == 0 {
                let itemsNCComments = items as! [NCComments]
                NCManageDatabase.sharedInstance.addComments(itemsNCComments, account: metadata.account, fileID: metadata.fileID)
            } else {
                self.appDelegate.messageNotification("_share_", description: message, visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: errorCode)
            }
        })
    }
}
