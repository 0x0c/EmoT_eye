//
//  ViewController.swift
//  EmoT
//
//  Created by Akira Matsuda on 2017/10/12.
//  Copyright © 2017 Akira Matsuda. All rights reserved.
//

import UIKit
import CoreBluetooth
import MEMELib
import JGProgressHUD
import GRTiOS

public struct Queue {
    fileprivate var array = [Double]()
    var maxSize = 0
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public var count: Int {
        return array.count
    }
    
    public mutating func enqueue(_ element: Double) {
        if self.maxSize > 0 {
            if self.count + 1 > self.maxSize {
                _ = self.dequeue()
            }
            array.append(element)
        }
        else {
            array.append(element)
        }
    }
    
    public mutating func dequeue() -> Double? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
    
    public var front: Double? {
        return array.first
    }
    
    public var sd : Double {
        let ave = self.array.reduce(0, { $0 + $1 }) / Double(self.count)
        
        let mapMultiply = { $0 - ave }
        
        let sumOfSquare = self.array.map(mapMultiply).reduce(0, { $0 + $1 })
        let variance = sumOfSquare / Double(self.count)
        return sqrt(Double(variance))
    }
}

class ViewController: UIViewController, MEMELibDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
	
	@IBOutlet var memeStatusLabel: UILabel!
    @IBOutlet weak var memeBatteryLabel: UILabel!
    @IBOutlet var emotStatusLabel: UILabel!
	
	@IBOutlet var scanEmoTButton: UIButton!
	@IBOutlet var scanJinsMEMEButton: UIButton!
	
	@IBOutlet var emojiPalette: UICollectionView!
	
	@IBOutlet var blinkImageView: UIImageView!
	@IBOutlet var headMotionImageView: UIImageView!
    @IBOutlet weak var eyeMovementView: UIView!
    @IBOutlet weak var eyeMoveFrequencyXLabel: UILabel!
    @IBOutlet weak var eyeMoveFrequencyYLabel: UILabel!
	var eyeMoveX : Int = 0
	var eyeMoveY : Int = 0
	@IBOutlet weak var eyeMoveXLabel: UILabel!
	@IBOutlet weak var eyeMoveYLabel: UILabel!
	@IBOutlet weak var blinkCountLabel: UILabel!
	
    var yawBuffer = Queue()
    var pitchBuffer = Queue()
    var rollBuffer = Queue()
    
    var start = Date()
    var blinkTimeBuffer = Queue()
    var blinkFrequency : Int = 0
    var eyeMoveFrequencyX : Int = 0
    var eyeMoveFrequencyY : Int = 0
    var timer : Timer!
	var blinkTimer : Timer!
	var emot : EmoT?
	var hud : JGProgressHUD?
	
	@IBOutlet weak var blinkMode: UISwitch!
	@IBOutlet weak var headTrackMode: UISwitch!
	
	var pipeline: GestureRecognitionPipeline?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		var blinkImages: [UIImage] = []
		for i in 0...15 {
			let imageName = "blink_" + String(format: "%05d", i)
			let image = UIImage(named: imageName)
			blinkImages.append(image!)
		}
		self.blinkImageView.animationImages = blinkImages
		
		MEMELib.sharedInstance().delegate = self
		EmoTManager.shared.connectedHandler = { (e) in
			e.holdStateTimeInterval = 3
			self.emot = e
			self.updateView()
		}
		EmoTManager.shared.disconnectedHandler = { (e) in
			self.emot = nil
			self.updateView()
		}
        self.blinkTimeBuffer.maxSize = 5
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		self.pipeline = appDelegate.pipeline!
		
		self.resetBlinkTimer()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if MEMELib.sharedInstance().isConnected {
			MEMELib.sharedInstance().delegate = self
			MEMELib.sharedInstance().startDataReport()
		}
		self.updateView()
		self.emojiPalette.contentInset = UIEdgeInsetsMake(0, 0, 75, 0)
	}
	
	// MARK: JINS MEME delegate
	func memePeripheralDisconnected(_ peripheral: CBPeripheral!) {
		self.updateView()
	}
	
	func memeRealTimeModeDataReceived(_ data: MEMERealTimeData!) {
		self.blinkCountLabel.text = String(self.blinkFrequency)
        var batteryLevel : String = ""
        for _ in 0..<data.powerLeft {
            batteryLevel += "●"
        }
        self.memeBatteryLabel.text = "Battery : \(batteryLevel)"
		
		//傾き
		let yaw = CGFloat(Double(data.yaw) * .pi / 180.0)
		let pitch = CGFloat(Double(data.pitch) * .pi / 180.0)
		let roll = CGFloat(Double(data.roll) * .pi / 180.0)
		var transform = CATransform3DIdentity
		transform.m34 = 1.0 / -UIScreen.main.bounds.size.height
		transform = CATransform3DRotate(transform, -pitch * 0.8, 1, 0, 0)
		transform = CATransform3DRotate(transform, -roll * 0.5, 0, 0, 1)
		self.headMotionImageView.layer.transform = transform
		
//		print("\(yaw), \(pitch), \(roll), \(data.accX), \(data.accY), \(data.accZ)")
		
		self.eyeMoveFrequencyX = self.eyeMoveFrequencyX + (Int(data.eyeMoveRight) > 0 ? 1 : 0) + (Int(data.eyeMoveLeft) > 0 ? 1 : 0)
		self.eyeMoveFrequencyY = self.eyeMoveFrequencyY + (Int(data.eyeMoveUp) > 0 ? 1 : 0) + (Int(data.eyeMoveDown) > 0 ? 1 : 0)
		self.eyeMoveFrequencyXLabel.text = String(self.eyeMoveFrequencyX)
		self.eyeMoveFrequencyYLabel.text = String(self.eyeMoveFrequencyY)
		self.eyeMoveX = self.eyeMoveX + Int(data.eyeMoveUp) - Int(data.eyeMoveDown)
		self.eyeMoveY = self.eyeMoveY + Int(data.eyeMoveRight) - Int(data.eyeMoveLeft)
		self.eyeMoveYLabel.text = String(self.eyeMoveX)
		self.eyeMoveXLabel.text = String(self.eyeMoveY)
		
		guard let emot = self.emot else {
			return
		}
		if self.blinkMode.isOn {
			//瞬き
			if data.blinkStrength > 0 {
				let end = Date().timeIntervalSince(self.start)
				self.blinkTimeBuffer.enqueue(end)
				self.start = Date()
				
				let speed = Double(data.blinkSpeed) / 1000.0 //瞬きのスピード
				self.blinkImageView.animationDuration = speed
				self.blinkImageView.animationRepeatCount = 1
				self.blinkImageView.startAnimating()
				self.blinkFrequency = self.blinkFrequency + 1
				self.resetBlinkTimer()
				// 目の動きについて評価する
				if (self.blinkFrequency > 15) {
					if self.eyeMoveFrequencyX > 8 || self.eyeMoveFrequencyY > 8 {
						// 落ち着きがない
						emot.change(emoji: .rush) // 💦
						return
					}
					else {
						// 高速瞬き
						emot.change(emoji: .doubleExclamation) // ‼️
						return
					}
				}
				else if (self.blinkFrequency > 4 && self.blinkFrequency < 10) {
					// 落ち着いている
					if self.eyeMoveFrequencyX < 6 {
						// 集中している
						emot.change(emoji: .focus) // 👁
						return
					}
				}
				else if (self.eyeMoveFrequencyX > 5 && self.eyeMoveFrequencyY > 5) {
					// 目をそらした
					emot.change(emoji: .avert) // 👀
					return
				}
				else {
					emot.animate(animation: .blink)
					return
				}
			}
		}
		
		if self.headTrackMode.isOn {
			if roll < -0.5 {
				// 左右に傾ける→❓
				emot.change(emoji: .question)
				return
			}
			if roll > 0.6 {
				if pitch > 0.4 {
					if data.accX < -7 {
						// 怒り顔→👺
						emot.change(emoji: .tengu)
						return
					}
				}
			}
			if data.accY > 8.0 {
				if data.accX > 4 {
					// 左右に振る→❌
					emot.change(emoji: .ng)
					return
				}
				else {
					// 前後に振る→👌
					emot.change(emoji: .ok)
					return
				}
			}
			if data.accY < -9 {
				if data.accX < -2 {
					// 左右に振る→❌
					emot.change(emoji: .ng)
					return
				}
			}
		}
		
		// 該当しない場合は消灯
		emot.change(emoji: .clear)
	}
	
	// MARK -
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case 0:
			return Emoticon.allValues.count
		case 1:
			return Animation.allValues.count
		default:
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! EmojiCell
		if indexPath.section == 0 {
			cell.textLabel.text = Emoticon.allValues[indexPath.row].toString()
		}
		else if indexPath.section == 1 {
			cell.textLabel.text = Animation.allValues[indexPath.row].toString()
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let e = self.emot {
			if indexPath.section == 0 {
				e.change(emoji: Emoticon.allValues[indexPath.row])
			}
			else {
				e.animate(animation: Animation.allValues[indexPath.row])
			}
		}
	}
	
	// MARK -
	@IBAction func scan(_ sender: Any) {
		let hud = JGProgressHUD(style: .dark)
		EmoTManager.shared.discover(duration: 2.0, presentingViewController: self) { [weak hud] in
			hud?.dismiss()
		}
		hud.show(in: self.view)
	}
	
	@IBAction func scanJinsMEME(_ sender: Any) {
		if MEMELib.sharedInstance().isConnected {
			MEMELib.sharedInstance().disconnectPeripheral()
		}
		else {
			self.performSegue(withIdentifier: "ScanSegue", sender: self)
		}
	}
	
	func updateView() {
		if MEMELib.sharedInstance().isConnected {
			self.memeStatusLabel.text = "Connected"
			self.scanJinsMEMEButton.setTitle("Disconnect JINS MEME", for: .normal)
		}
		else {
			self.memeStatusLabel.text = "Disconnected"
			self.scanJinsMEMEButton.setTitle("Scan JINS MEME", for: .normal)
            self.memeBatteryLabel.text = "Battery : -----"
		}
		
		if let e = self.emot, e.isConnected() {
            self.emotStatusLabel.text = "Connected"
            if let name = e.peripheral!.name {
                self.emotStatusLabel.text = "Connected : \(name)"
            }
            
			self.scanEmoTButton.setTitle("Disconnect EmoT", for: .normal)
		}
		else {
			self.emotStatusLabel.text = "Disconnected"
			self.scanEmoTButton.setTitle("Scan EmoT", for: .normal)
		}
	}
	
	@IBAction func changeDemoMode(_ sender: UISwitch) {
		if let t = self.timer, t.isValid {
			t.invalidate()
		}
		if sender.isOn {
			self.resetTimer()
		}
	}
	
	var demoIndex = 0
    func resetTimer() {
		if let t = self.timer, t.isValid {
			t.invalidate()
		}
		print("reset")
		self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (_) in
			guard let emot = self.emot else {
				return
			}
			emot.change(emoji: Emoticon.allValues[self.demoIndex])
			self.demoIndex = self.demoIndex + 1
			self.demoIndex = self.demoIndex % Emoticon.allValues.count
		})
	}
	
	func resetBlinkTimer() {
		if let t = self.blinkTimer, t.isValid {
			t.invalidate()
		}
		self.blinkTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (_) in
			self.blinkFrequency = 0
			self.eyeMoveFrequencyX = 0
			self.eyeMoveFrequencyY = 0
			self.eyeMoveX = 0
			self.eyeMoveY = 0
		})
	}
	
	func connectToEmoT() {
		if let e = self.emot {
			e.holdStateTimeInterval = 3.0;
			_ = e.connect()
		}
	}
	
	@IBAction func unwindAction(segue: UIStoryboardSegue) {}

}

