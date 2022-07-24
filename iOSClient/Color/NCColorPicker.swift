//
//  NCColorPicker.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 24/07/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import Foundation
import UIKit

public protocol NCColorPickerDelegate: AnyObject {
    func colorPickerCancel()
    func colorPickerWillChange(color: UIColor)
    func colorPickerDidChange(color: UIColor)
}

// optional func
public extension NCColorPickerDelegate {
    func colorPickerCancel() {}
    func colorPickerWillChange(color: UIColor) { }
    func colorPickerDidChange(color: UIColor) { }
}

class NCColorPicker: UIViewController, NCColorPickerDelegate {

    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var redButton: UIButton!

    @IBOutlet weak var orangeText: UITextField!
    @IBOutlet weak var redText: UITextField!

    weak var delegate: NCColorPickerDelegate?
    var selectedColor: UIColor?
    var defaultColor: UIColor?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        orangeButton.backgroundColor = .orange
        orangeButton.layer.cornerRadius = 5
        orangeButton.layer.masksToBounds = true

        orangeText.text = "Orange"

        redButton.backgroundColor = .red
        redButton.layer.cornerRadius = 5
        redButton.layer.masksToBounds = true

        redText.text = "Red"

    }

}
