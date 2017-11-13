//
//  PredictionViewController.swift
//  EmoT
//
//  Created by Akira Matsuda on 2017/11/13.
//  Copyright © 2017 Akira Matsuda. All rights reserved.
//

import UIKit
import GRTiOS
import MEMELib

class PredictionViewController: UIViewController, MEMELibDelegate {

	@IBOutlet weak var gesture1CountLabel: UILabel!
	@IBOutlet weak var gesture2CountLabel: UILabel!
	@IBOutlet weak var gesture3CountLabel: UILabel!
	
	var gestureOneCount: UInt = 0
	var gestureTwoCount: UInt = 0
	var gestureThreeCount: UInt = 0
	
	let vector = VectorDouble()
	var pipeline: GestureRecognitionPipeline?
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if MEMELib.sharedInstance().isConnected {
			MEMELib.sharedInstance().delegate = self
			MEMELib.sharedInstance().startDataReport()
		}
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		
		self.pipeline = appDelegate.pipeline!
		
		initPipeline()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	func initPipeline(){
		
		//Load the GRT pipeline and the training data files from the documents directory
		let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		
		let pipelineURL = documentsUrl.appendingPathComponent("train.grt")
		let classificiationDataURL = documentsUrl.appendingPathComponent("trainingData.csv")
		
		let pipelineResult:Bool = pipeline!.load(pipelineURL)
		let classificationDataResult:Bool = pipeline!.loadClassificationData(classificiationDataURL)
		
		if pipelineResult == false {
			let userAlert = UIAlertController(title: "Error", message: "Couldn't load pipeline", preferredStyle: .alert)
			let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
			userAlert.addAction(cancel)
			self.present(userAlert, animated: true, completion: nil)
		}
		
		if classificationDataResult == false {
			let userAlert = UIAlertController(title: "Error", message: "Couldn't load classification data", preferredStyle: .alert)
			self.present(userAlert, animated: true, completion: nil)
			let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
			userAlert.addAction(cancel)
		}
			
			//If the files have been loaded successfully, we can train the pipeline, and then start real-time gesture prediction
		else if (classificationDataResult && pipelineResult) {
			pipeline?.train()
		}
	}
	
	func memeRealTimeModeDataReceived(_ data: MEMERealTimeData!) {
		//傾き
		let yaw = Double(data.yaw) * .pi / 180.0
		let pitch = Double(data.pitch) * .pi / 180.0
		let roll = Double(data.roll) * .pi / 180.0
		print("yaw:\(yaw), pitch:\(pitch), roll:\(roll)")
		
		//Add the accellerometer data to a vector, which is how we'll store the classification data
		self.vector.clear()
		self.vector.pushBack(yaw)
		self.vector.pushBack(pitch)
		self.vector.pushBack(roll)
		self.vector.pushBack(Double(data.accX))
		self.vector.pushBack(Double(data.accY))
		self.vector.pushBack(Double(data.accZ))
		//Use the incoming accellerometer data to predict what the performed gesture class is
		self.pipeline?.predict(self.vector)
		
		DispatchQueue.main.async {
			self.updateGestureCountLabels(gesture: (self.pipeline?.predictedClassLabel)!)
			print("PRECITED GESTURE", self.pipeline?.predictedClassLabel ?? 0);
		}
	}
	
	func updateGestureCountLabels(gesture: UInt){
		
		if gesture == 0 {
			//do nothing
		} else if (gesture == 1){
			gestureOneCount = gestureOneCount + 1
			let gestureOneCountVal = String(gestureOneCount)
			gesture1CountLabel.text = ("Gesture 1 count: " + gestureOneCountVal)
		} else if (gesture == 2){
			gestureTwoCount = gestureTwoCount + 1
			let gestureTwoCountVal = String(gestureTwoCount)
			gesture2CountLabel.text = ("Gesture 2 count: " + gestureTwoCountVal)
		} else if (gesture == 3){
			gestureThreeCount = gestureThreeCount + 1
			let gestureThreeCountVal = String(gestureThreeCount)
			gesture3CountLabel.text = ("Gesture 3 count: " + gestureThreeCountVal)
		}
		
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
