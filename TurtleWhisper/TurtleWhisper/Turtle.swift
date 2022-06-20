//
//  Turtle.swift
//  TurtleWhisper
//
//  Created by mahit on 04/04/2022.
//
import UIKit
import Foundation

class Turtle: UIImageView {
    static var positionY: Float = 0
    
    @IBOutlet weak var turtle: UIImageView!
    
    func move(position: Float) {
        Turtle.positionY = position
    }
}
