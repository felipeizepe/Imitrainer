//
//  ViewController.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {

	
	//MARK: Outles
	@IBOutlet weak var recordListTableView: UITableView!
	
	//MARK: Properties
	
	var recordingList : [Recording]?
	
	
	//MARK: Applicaton Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.isUserInteractionEnabled = false
		// Do any additional setup after loading the view, typically from a nib.
		
		//Sets-up the table view
		recordListTableView.delegate = self
		recordListTableView.dataSource = self
		
		
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		
		//Retrieves the Recording list
		SharedRecordingAPI.shared.getRecordings(completion: { [unowned self] (success, message, recordings) in
			self.recordingList = recordings
			
			//Updates the data and the views
			
			DispatchQueue.main.async {
				self.recordListTableView.reloadData()
				self.view.isUserInteractionEnabled = true
			}
			
		})
		
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "playRecordingSegue" {
			let index = sender as! Int
			
			let playView = segue.destination as! PlayViewController
			playView.recording = self.recordingList![index]
			
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	//MARK: Auxiliar Methods
	
	//MARK: Outlet actions
	
	@IBAction func editClicked(_ sender: Any) {
		
		if(self.recordListTableView.isEditing == true)
		{
			self.recordListTableView.isEditing = false
			self.navigationItem.leftBarButtonItem?.title = "Edit"
		}
		else
		{
			self.recordListTableView.isEditing = true
			self.navigationItem.leftBarButtonItem?.title = "Done"
		}
		
	}
}

//MARK: TableView delegate extension
extension ListViewController : UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == UITableViewCellEditingStyle.delete {

			let recording = self.recordingList![indexPath.row]

			//Retrieves the Recording list
			SharedRecordingAPI.shared.deleteRecording(recording: recording, completion: { [unowned self] (success, message) in

				self.recordingList!.remove(at: indexPath.row)
				self.recordListTableView.deleteRows(at: [indexPath], with: .automatic)

			})
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		if (self.recordListTableView.isEditing) {
			return UITableViewCellEditingStyle.delete
		}
		return UITableViewCellEditingStyle.none
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.backgroundColor = ColorConstants.bgColor
	}
	
}

//MARK: TableView Data Source extension
extension ListViewController : UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return recordingList?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "listViewCell", for: indexPath) as! ListViewCell
	
		let record = recordingList![indexPath.row]
		
		cell.recordNameLabel.text = record.name
		
		return cell
	
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		performSegue(withIdentifier: "playRecordingSegue", sender: indexPath.row)
	}
	
}



