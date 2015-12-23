/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client

class LoginManagerTests: KIFTestCase {

    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        generateLogins()
    }

    override func tearDown() {
        super.tearDown()
        clearLogins()
    }

    private func openLoginManager() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")
    }

    private func closeLoginManager() {
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    private func generateLogins() {
        let profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!

        let prefixes = "abcdefghijk"
        let numRange = (0..<20)

        let passwords = generateStringListWithFormat("password%@%d", numRange: numRange, prefixes: prefixes)
        let hostnames = generateStringListWithFormat("http://%@%d.com", numRange: numRange, prefixes: prefixes)
        let usernames = generateStringListWithFormat("%@%d@email.com", numRange: numRange, prefixes: prefixes)

        (0..<(numRange.count * prefixes.characters.count)).forEach { index in
            let login = Login(guid: "\(index)", hostname: hostnames[index], username: usernames[index], password: passwords[index])
            profile.logins.addLogin(login).value
        }
    }

    private func generateStringListWithFormat(format: String, numRange: Range<Int>, prefixes: String) -> [String] {
        return prefixes.characters.map { char in
            return numRange.map { num in
                return String(format: format, "\(char)", num)
            }
        } .flatMap { $0 }
    }

    private func clearLogins() {
        let profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
        profile.logins.removeAll().value
    }

    func testListFiltering() {
        openLoginManager()

        // Filter by username
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("k10@email.com")
        tester().waitForViewWithAccessibilityLabel("k10@email.com")

        var list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(list.numberOfRowsInSection(0), 1)

        tester().tapViewWithAccessibilityLabel("Clear Search")

        // Filter by hostname
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("http://k10.com")
        tester().waitForViewWithAccessibilityLabel("k10@email.com")

        list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(list.numberOfRowsInSection(0), 1)

        tester().tapViewWithAccessibilityLabel("Clear Search")

        // Filter by password
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("passwordd9")
        tester().waitForViewWithAccessibilityLabel("d9@email.com")

        list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(list.numberOfRowsInSection(0), 1)

        tester().tapViewWithAccessibilityLabel("Clear Search")

        // Filter by something that doesn't match anything
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("thisdoesntmatch")

        // TODO: Check for empty view

        closeLoginManager()
    }

    func testListIndexView() {
        openLoginManager()

        // Swipe the index view to navigate to bottom section
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().swipeViewWithAccessibilityLabel("table index", inDirection: KIFSwipeDirection.Down)
        tester().waitForViewWithAccessibilityLabel("k0@email.com, http://k0.com")
        closeLoginManager()
    }

    func testListSelection() {
        openLoginManager()

        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        // Select one entry
        let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        tester().waitForViewWithAccessibilityLabel("Delete")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        let firstCell = list.cellForRowAtIndexPath(firstIndexPath)!
        XCTAssertTrue(firstCell.selected)

        // Deselect first row
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        XCTAssertFalse(firstCell.selected)

        // Cancel
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        // Select multiple logins
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        let pathsToSelect = (0..<5).map { NSIndexPath(forRow: $0, inSection: 0) }
        pathsToSelect.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }
        tester().waitForViewWithAccessibilityLabel("Delete")

        pathsToSelect.forEach { path in
            XCTAssertTrue(list.cellForRowAtIndexPath(firstIndexPath)!.selected)
        }

        // Deselect only first row
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        XCTAssertFalse(firstCell.selected)

        // Make sure delete is still showing
        tester().waitForViewWithAccessibilityLabel("Delete")

        // Deselect the rest
        let pathsWithoutFirst = pathsToSelect[1..<pathsToSelect.count]
        pathsWithoutFirst.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        // Cancel
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        tester().tapViewWithAccessibilityLabel("Edit")

        // Select all using select all button
        tester().tapViewWithAccessibilityLabel("Select All")
        list.visibleCells.forEach { cell in
            XCTAssertTrue(cell.selected)
        }
        tester().waitForViewWithAccessibilityLabel("Delete")

        // Deselect all using button
        tester().tapViewWithAccessibilityLabel("Deselect All")
        list.visibleCells.forEach { cell in
            XCTAssertFalse(cell.selected)
        }
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        // Finally, test selections get persisted after cells recycle
        tester().tapViewWithAccessibilityLabel("Edit")
        let firstInEachSection = (0..<3).map { NSIndexPath(forRow: 0, inSection: $0) }
        firstInEachSection.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        // Go up, down and back up to for some recyling
        tester().scrollViewWithAccessibilityIdentifier("Login List", byFractionOfSizeHorizontal: 0, vertical: 1)
        tester().scrollViewWithAccessibilityIdentifier("Login List", byFractionOfSizeHorizontal: 0, vertical: -1)
        tester().scrollViewWithAccessibilityIdentifier("Login List", byFractionOfSizeHorizontal: 0, vertical: 1)

        XCTAssertTrue(list.cellForRowAtIndexPath(firstInEachSection[0])!.selected)

        firstInEachSection.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        closeLoginManager()
    }

    func testListSelectAndDelete() {
        openLoginManager()

        let list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        let oldLoginCount = countOfRowsInTableView(list)

        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        // Select and delete one entry
        let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        tester().waitForViewWithAccessibilityLabel("Delete")

        let firstCell = list.cellForRowAtIndexPath(firstIndexPath)!
        XCTAssertTrue(firstCell.selected)

        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Are you sure?")
        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Edit")

        var newLoginCount = countOfRowsInTableView(list)
        XCTAssertEqual(oldLoginCount - 1, newLoginCount)

        // Select and delete multiple entries
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        let multiplePaths = (0..<3).map { NSIndexPath(forRow: $0, inSection: 0) }

        multiplePaths.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Are you sure?")
        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Edit")

        newLoginCount = countOfRowsInTableView(list)
        XCTAssertEqual(oldLoginCount - 4, newLoginCount)
        closeLoginManager()
    }

    private func countOfRowsInTableView(tableView: UITableView) -> Int {
        var count = 0
        (0..<tableView.numberOfSections).forEach { section in
            count += tableView.numberOfRowsInSection(section)
        }
        return count
    }

}