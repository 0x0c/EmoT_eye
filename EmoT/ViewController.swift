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

class ViewController: UIViewController, MEMELibDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
	
	@IBOutlet var memeStatusLabel: UILabel!
	@IBOutlet var emotStatusLabel: UILabel!
	
	@IBOutlet var scanEmoTButton: UIButton!
	@IBOutlet var scanJinsMEMEButton: UIButton!
	
	@IBOutlet var emojiPalette: UICollectionView!
	
	var emot : EmoT?
	var hud : JGProgressHUD?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		MEMELib.sharedInstance().delegate = self
		EmoTManager.shared.connectedHandler = { (e) in
			self.emot = e
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if MEMELib.sharedInstance().isConnected {
			MEMELib.sharedInstance().delegate = self
			MEMELib.sharedInstance().startDataReport()
		}
		self.updateView()
	}
	
	// MARK: JINS MEME delegate
	func memePeripheralDisconnected(_ peripheral: CBPeripheral!) {
		self.updateView()
	}
	
	func memeRealTimeModeDataReceived(_ data: MEMERealTimeData!) {
		//瞬き
		print("blinkStrength:\(data.blinkStrength)")
		if data.blinkStrength > 0 {
			let speed = Double(data.blinkSpeed) / 1000.0 //瞬きのスピード
			print("blink speed:\(speed), strength:\(data.blinkStrength)")
//			eyeImageView.animationDuration = speed
//			eyeImageView.animationRepeatCount = 1
//			eyeImageView.startAnimating()
		}
		
		//傾き
		let yaw = CGFloat(Double(data.yaw) * .pi / 180.0)
		let pitch = CGFloat(Double(data.pitch) * .pi / 180.0)
		let roll = CGFloat(Double(data.roll) * .pi / 180.0)
		print("yaw:\(yaw), pitch:\(pitch), roll:\(roll)")
//		bodyImageView.transform = CGAffineTransform(rotationAngle: -angle)
	}
	
	func memeCommand(_ response: MEMEResponse) {
		switch response.eventCode {
		case 0x02:
			print("start data report : result ", response.commandResult);
			break
		case 0x04:
			print("stop data report : result ", response.commandResult);
			break
		default:
			break;
		}
	}
	
	// MARK -
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return Emoticon.allValues.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! EmojiCell
		cell.textLabel.text = Emoticon.allValues[indexPath.row].toString()
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let e = self.emot {
			e.change(emoji: Emoticon.allValues[indexPath.row])
		}
	}
	
	// MARK -
	@IBAction func scan(_ sender: Any) {
		let hud = JGProgressHUD(style: .dark)
		EmoTManager.shared.discover(presentingViewController: self) { [weak hud] in
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
		}
		
		if let e = self.emot, e.isConnected() {
			self.emotStatusLabel.text = "Connected"
			self.scanEmoTButton.setTitle("Disconnect EmoT", for: .normal)
		}
		else {
			self.emotStatusLabel.text = "Disonnected"
			self.scanEmoTButton.setTitle("Scan EmoT", for: .normal)
		}
	}
	
	func connectToEmoT() {
		if let e = self.emot {
			_ = e.connect()
		}
	}
	
	@IBAction func unwindAction(segue: UIStoryboardSegue) {
		
	}

}

