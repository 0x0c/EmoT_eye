//
//  Animation.swift
//  EmoT
//
//  Created by Akira Matsuda on 2017/11/16.
//  Copyright © 2017 Akira Matsuda. All rights reserved.
//

import Foundation

enum Animation : Int {
	case blink
	
	func toString() -> String {
		switch self {
		case .blink:
			return "blink"
		}
	}
	
	static let allValues = [
		blink
	]
}
