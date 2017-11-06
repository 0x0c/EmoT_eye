//
//  EmoT.swift
//  EmoT
//
//  Created by Akira Matsuda on 2017/11/06.
//  Copyright © 2017 Akira Matsuda. All rights reserved.
//

import UIKit
import CoreBluetooth

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
			return "💪"
		case .fire:
			return "🔥"
		}
	}
	
	static let allValues = [heart,
							beer,
							exclamation,
							question,
							pray,
							arm,
							tengu,
							sushi,
							vsign,
							fire]
}

class EmoTManager : NSObject {
	
	static let shared = EmoTManager()
	
	var centralManager: CBCentralManager?
	var peripherals = NSMutableSet()
	var emot = NSMutableSet()
	
	var connectedHandler : ((_ emot : EmoT) -> Void)?
	
	override init() {
		super.init()
		self.centralManager = CBCentralManager(delegate: self as CBCentralManagerDelegate, queue: nil)
	}
	
	func scan(duration : TimeInterval = 3, completion : @escaping (_ peripherals : [CBPeripheral]) -> Void) {
		if let m = self.centralManager {
			m.scanForPeripherals(withServices: nil, options: nil)
			DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
				m.stopScan()
				self.prepareEmoT()
				completion(self.peripherals.allObjects as! [CBPeripheral])
			}
		}
	}
	
	func stopScan() {
		if let m = self.centralManager {
			m.stopScan()
		}
	}
	
	private func prepareEmoT() {
		self.emot = NSMutableSet()
		for p in self.peripherals.allObjects as! [CBPeripheral] {
			self.emot.add(EmoT(peripheral: p, manager: self))
		}
	}
}

extension EmoTManager : CBCentralManagerDelegate {
	func centralManagerDidUpdateState(_ central: CBCentralManager) {}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("did connect : \(peripheral.description)")
		peripheral.delegate = self
		peripheral.discoverServices(nil)
		
		if let c = self.connectedHandler {
			for e in self.emot.allObjects as! [EmoT] {
				if let p = e.peripheral, p == peripheral {
					c(e);
					break
				}
			}
		}
	}
	
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print(peripheral.description)
		if let name = peripheral.name, name.lowercased().contains("emot") {
			print(name)
			self.peripherals.add(peripheral)
		}
	}
	
}

extension EmoTManager : CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("did discover services: \(peripheral.name ?? "none")")
		if let s = peripheral.services {
			for ss in s {
				print("service: \(ss)")
				peripheral.discoverCharacteristics(nil, for: ss)
			}
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {}
}


extension EmoTManager {
	func discover(presentingViewController : UIViewController, completion : @escaping () -> Void) {
		self.scan { (peripherals) in
			let actionSheet = UIAlertController(title: "EmoT", message: "Select a peripheral to connect.", preferredStyle: .actionSheet)
			for p : CBPeripheral in self.peripherals.allObjects as! [CBPeripheral] {
				let action = UIAlertAction(title: p.name, style: .default, handler: { (_) in
					if let m = self.centralManager {
						m.connect(p, options: nil)
					}
				})
				actionSheet.addAction(action)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			actionSheet.addAction(cancel)
			presentingViewController.present(actionSheet, animated: true, completion: nil)
			completion()
		}
	}
}

class EmoT: NSObject {
	var peripheral : CBPeripheral?
	var manager : EmoTManager?
	
	init(peripheral : CBPeripheral, manager : EmoTManager) {
		super.init()
		self.peripheral = peripheral
		self.manager = manager
	}
	
	func change(emoji : Emoticon) {
		if let p = self.peripheral, let s = self.peripheral?.findService(uuid: CBUUID(string: "0x00FF")), let c = s.findCharacteristic(uuid: CBUUID(string: "0xFF01")) {
			let bytes: [UInt8] = [
				UInt8(emoji.rawValue)
			]
			let data = Data(bytes: bytes)
			p.writeValue(data, for: c, type: .withResponse)
		}
	}
	
	func isConnected() -> Bool {
		if let p = self.peripheral {
			return p.state == .connected
		}
		
		return false
	}
	
	func connect() -> Bool{
		if let em = self.manager, let m = em.centralManager, let p = self.peripheral {
			m.connect(p, options: nil)
			return true
		}
		
		return false
	}
	
	func disconnet() -> Bool {
		if let em = self.manager, let m = em.centralManager, let p = self.peripheral {
			m.cancelPeripheralConnection(p)
			return true
		}
		
		return false
	}
}

extension CBUUID {
	func isEqualTo(uuid : CBUUID) -> Bool {
		return self.data == uuid.data
	}
}

extension CBService {
	func findCharacteristic(uuid : CBUUID) -> CBCharacteristic? {
		if let cs = self.characteristics {
			for c in cs {
				if c.uuid.isEqualTo(uuid: c.uuid) {
					return c
				}
			}
		}
		return nil
	}
}

extension CBPeripheral {
	func findService(uuid : CBUUID) -> CBService? {
		if let ss = self.services {
			for s in ss {
				if s.uuid.isEqualTo(uuid: uuid) {
					return s
				}
			}
		}
		return nil
	}
}
