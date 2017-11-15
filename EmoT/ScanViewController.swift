//
//  ScanViewController.swift
//  sdk-liveview-ios
//
//  Created by JINS MEME on 2016/11/01.
//  Copyright © 2016 JINS CO.,LTD. All rights reserved.
//

import UIKit
import MEMELib
import JGProgressHUD

class ScanViewController: UITableViewController, MEMELibDelegate {
	
    var peripherals: [CBPeripheral] = []
    var hud : JGProgressHUD?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        MEMELib.sharedInstance().delegate = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		MEMELib.sharedInstance().startScanningPeripherals()
	}

    /*
     // MARK: - UITableViewDataSource
     */
	override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.identifier.uuidString
        return cell
    }
    
    /*
     // MARK: - UITableViewDelegate
     */
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //接続処理
		self.hud = JGProgressHUD(style: .dark)
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		self.hud!.show(in: appDelegate.window!)
        let peripheral = peripherals[indexPath.row]
        MEMELib.sharedInstance().connect(peripheral)
    }
    
    
    /*
     // MARK: - MEMELibDelegate
     */
    func memePeripheralFound(_ peripheral: CBPeripheral!, withDeviceAddress address: String!) {
        if peripherals.contains(peripheral) == false {
            peripherals.append(peripheral)
            tableView.reloadData()
        }
    }
    
    func memePeripheralConnected(_ peripheral: CBPeripheral!) {
        //接続されたら閉じる
		if let hud = self.hud {
			hud.dismiss()
		}
        if MEMELib.sharedInstance().isCalibrated == CALIB_NOT_FINISHED, MEMELib.sharedInstance().isCalibrated == CALIB_BODY_FINISHED, MEMELib.sharedInstance().isCalibrated == CALIB_EYE_FINISHED {
            let alert = UIAlertController.init(title: "キャリブレーションしてください", message: "JINS MEMEアプリを起動してキャリブレーションを行ってください", preferredStyle: .alert)
            self.present(alert, animated: true, completion: {
                self.dismiss(animated: true, completion: nil)
            })
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
	
	// MARK: - Button
    @IBAction func scanButtonPressed(_ sender: Any) {
        //スキャン開始
        MEMELib.sharedInstance().startScanningPeripherals()
    }
	
}
