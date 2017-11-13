//
//  TrainingViewController.swift
//  EmoT
//
//  Created by Akira Matsuda on 2017/11/13.
//  Copyright © 2017 Akira Matsuda. All rights reserved.
//

import UIKit
import MEMELib
import GRTiOS

class TrainingViewController: UIViewController, MEMELibDelegate {

	var pipeline: GestureRecognitionPipeline?
	@IBOutlet weak var trainButton: UIButton!
	@IBOutlet weak var gestureSelector: UISegmentedControl!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.trainButton.addTarget(self, action:#selector(trainBtnPressed(_:)), for: .touchDown);
		self.trainButton.addTarget(self, action:#selector(trainBtnReleased(_:)), for: .touchUpInside);
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if MEMELib.sharedInstance().isConnected {
			MEMELib.sharedInstance().delegate = self
			MEMELib.sharedInstance().startDataReport()
		}
		let appDelegate = UIApplication.shared.delegate as! AppDelegate

		self.pipeline = appDelegate.pipeline!
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@objc func trainBtnPressed(_ sender: Any) {
		self.trainButton.isSelected = true
	}
	
	@objc func trainBtnReleased(_ sender: Any) {
		self.trainButton.isSelected = false
	}
	
	@IBAction func save(_ sender: Any) {
		// Set URL for saving the pipeline to
		let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let pipelineURL = documentsUrl.appendingPathComponent("train.grt")
		
		// Remove the pipeline if it already exists
		let _ = try? FileManager.default.removeItem(at: pipelineURL)
		
		let pipelineSaveResult = self.pipeline?.save(pipelineURL)
		if !pipelineSaveResult! {
			let userAlert = UIAlertController(title: "Error", message: "Failed to save pipeline", preferredStyle: .alert)
			self.present(userAlert, animated: true, completion: nil)
			let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
			userAlert.addAction(cancel)
		}
		
		// Save the training data as a CSV file
		let classificiationDataURL = documentsUrl.appendingPathComponent("trainingData.csv")
		
		let _ = try? FileManager.default.removeItem(at: classificiationDataURL)
		
		let classificationSaveResult = self.pipeline?.saveClassificationData(classificiationDataURL)
		
		if !classificationSaveResult! {
			let userAlert = UIAlertController(title: "Error", message: "Failed to save classification data", preferredStyle: .alert)
			self.present(userAlert, animated: true, completion: nil)
			let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
			userAlert.addAction(cancel)
		}
	}
	
	func memeRealTimeModeDataReceived(_ data: MEMERealTimeData!) {
		//傾き
		let yaw = Double(data.yaw) * .pi / 180.0
		let pitch = Double(data.pitch) * .pi / 180.0
		let roll = Double(data.roll) * .pi / 180.0
		print("yaw:\(yaw), pitch:\(pitch), roll:\(roll)")
		
		let gestureClass = self.gestureSelector.selectedSegmentIndex
		
		//Add the accellerometer data to a vector, which is how we'll store the classification data
		let vector = VectorFloat()
		vector.clear()
		vector.pushBack(yaw)
		vector.pushBack(pitch)
		vector.pushBack(roll)
		vector.pushBack(Double(data.accX))
		vector.pushBack(Double(data.accY))
		vector.pushBack(Double(data.accZ))
		print("Gesture class is %@", gestureClass);
		
		if (self.trainButton.isSelected == true) {
			self.pipeline!.addSamplesToClassificationData(forGesture: UInt(gestureClass), vector)
		}
	}
}
