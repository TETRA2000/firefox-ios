/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

private enum ListSection: Int {
    case Info = 0
    case Delete = 1
}

private enum InfoItem: Int {
    case TitleItem = 0
    case UsernameItem = 1
    case PasswordItem = 2
    case WebsiteItem = 3
}

private struct LoginDetailUX {
    static let InfoRowHeight: CGFloat = 58
    static let DeleteRowHeight: CGFloat = 44
    static let FooterHeight: CGFloat = 44
}

class LoginDetailViewController: UITableViewController {

    private let profile: Profile

    private var login: LoginData {
        didSet {
            tableView.reloadData()
        }
    }

    private var loginUsageData: LoginUsageData? = nil {
        didSet {
            tableView.reloadData()
        }
    }

    private let LoginCellIdentifier = "LoginCell"
    private let DeleteCellIdentifier = "DeleteCell"
    private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

    // References to input fields
    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?
    private weak var websiteField: UITextField?

    init(profile: Profile, login: LoginData) {
        self.login = login
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")

        tableView.registerClass(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: DeleteCellIdentifier)
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        let footer = SettingsTableSectionHeaderFooterView()
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.scrollEnabled = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        profile.logins.getUsageDataForLoginByGUID(login.guid).uponQueue(dispatch_get_main_queue()) { result in
            self.loginUsageData = result.successValue
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = ListSection(rawValue: indexPath.section)!

        switch section {
        case .Info:
            let loginCell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell
            loginCell.selectionStyle = .None

            loginCell.descriptionLabel.userInteractionEnabled = editing
            loginCell.descriptionLabel.delegate = self

            switch InfoItem(rawValue: indexPath.row)! {
            case .TitleItem:
                loginCell.style = .IconAndDescriptionLabel
                loginCell.descriptionLabel.text = login.hostname
            case .UsernameItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("username", tableName: "LoginManager", comment: "Title for username row in Login Detail View")
                loginCell.descriptionLabel.text = login.username
                loginCell.descriptionLabel.keyboardType = .EmailAddress
                usernameField = loginCell.descriptionLabel
            case .PasswordItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("password", tableName: "LoginManager", comment: "Title for password row in Login Detail View")
                loginCell.descriptionLabel.text = login.password.anonymize()
                passwordField = loginCell.descriptionLabel
            case .WebsiteItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("website", tableName: "LoginManager", comment: "Title for website row in Login Detail View")
                loginCell.descriptionLabel.text = login.hostname
                loginCell.descriptionLabel.keyboardType = .URL
                websiteField = loginCell.descriptionLabel
            }
            return loginCell
        case .Delete:
            let deleteCell = tableView.dequeueReusableCellWithIdentifier(DeleteCellIdentifier, forIndexPath: indexPath)
            deleteCell.textLabel?.text = NSLocalizedString("Delete", tableName: "LoginManager", comment: "Button in login detail screen that deletes the current login")
            deleteCell.textLabel?.textAlignment = NSTextAlignment.Center
            deleteCell.textLabel?.textColor = UIConstants.DestructiveRed
            deleteCell.accessibilityTraits = UIAccessibilityTraitButton
            return deleteCell
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ListSection(rawValue: section)! {
        case .Info: return 4
        case .Delete: return 1
        }
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch ListSection(rawValue: section)! {
        case .Info: return 60
        case .Delete: return 1
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch ListSection(rawValue: indexPath.section)! {
        case .Info: return LoginDetailUX.InfoRowHeight
        case .Delete: return LoginDetailUX.DeleteRowHeight
        }
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch ListSection(rawValue: section)! {
        case .Info:
            let footer = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
            footer.titleAlignment = .Top

            if let passwordModifiedTimestamp = loginUsageData?.timePasswordChanged {
                let lastModified = NSLocalizedString("Last modified %@", tableName: "LoginManager", comment: "Footer label describing when the login was last modified with the timestamp as the parameter")
                let formattedLabel = String(format: lastModified, NSDate.fromTimestamp(passwordModifiedTimestamp).toRelativeTimeString())
                footer.titleLabel.text = formattedLabel
            }
            return footer

        default:
            let footer = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
            footer.showBottomBorder = false
            return footer
        }
    }
}

extension LoginDetailViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField?.becomeFirstResponder()
        } else if textField == passwordField {
            websiteField?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return false
    }
}

// MARK: - Table View Editing
extension LoginDetailViewController {

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }

    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}

// MARK: - Selectors
extension LoginDetailViewController {

    func SELedit() {
        editing = true
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
        usernameField?.becomeFirstResponder()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "SELdoneEditing")
    }

    func SELdoneEditing() {
        editing = false

        let username = usernameField?.text ?? ""
        let password = passwordField?.text ?? ""
        let hostname = websiteField?.text ?? ""

        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")

        let newLogin = Login(guid: login.guid, hostname: hostname, username: username, password: password)

        profile.logins.updateLoginByGUID(login.guid, new: newLogin, significant: true) >>> {
            self.profile.logins.getLoginDataForGUID(self.login.guid).uponQueue(dispatch_get_main_queue()) { result in
                if let updatedLogin = result.successValue {
                    self.login = updatedLogin
                }
            }
        }
    }
}