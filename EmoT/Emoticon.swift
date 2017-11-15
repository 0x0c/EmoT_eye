//
//  Emoticon.swift
//  EmoT
//
//  Created by Akira Matsuda on 2017/11/13.
//  Copyright © 2017 Akira Matsuda. All rights reserved.
//

import Foundation

enum Emoticon: Int {
	case heart
	case beer
	case exclamation
	case question
	case pray
	case arm
	case tengu
	case sushi
	case vsign
	case fire
	case avert
	case rush
	case ok
	case ng
	case focus
	case doubleExclamation
	case clear = 255
	
	func toString() -> String {
		switch self {
		case .heart:
			return "❤"
		case .beer:
			return "🍺"
		case .exclamation:
			return "❗"
		case .question:
			return "❓"
		case .pray:
			return "🙏"
		case .arm:
			return "💪"
		case .tengu:
			return "👺"
		case .sushi:
			return "🍣"
		case .vsign:
			return "✌"
		case .fire:
			return "🔥"
		case .avert:
			return "👀"
		case .rush:
			return "💦"
		case .ok:
			return "👌"
		case .ng:
			return "❌"
		case .focus:
			return "👁"
		case .doubleExclamation:
			return "‼️"
		case .clear:
			return "-"
		}
	}
	
	static let allValues = [
		heart,
		beer,
		exclamation,
		question,
		pray,
		arm,
		tengu,
		sushi,
		vsign,
		fire,
		avert,
		rush,
		ok,
		ng,
		focus,
		doubleExclamation,
		clear
	]
}
