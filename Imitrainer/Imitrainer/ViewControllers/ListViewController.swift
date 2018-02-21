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
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	@IBOutlet weak var searchBar: UISearchBar!
	//MARK: Properties
	
	var recordingList: [Recording]?
	var searchResults: [Recording]!
	var searchIsActive = false
	
	
	//MARK: Applicaton Lifecycle
	override func viewDidLoad() {
		navigationController?.navigationBar.prefersLargeTitles = false
		
		searchResults = [Recording]()
		
		//Setup for the activity indicator
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		super.viewDidLoad()
		self.view.isUserInteractionEnabled = false
		
		//Sets-up the table view
		recordListTableView.delegate = self
		recordListTableView.dataSource = self
		
		//Setup sarch bar
		navigationItem.hidesSearchBarWhenScrolling = false
		
		
		navigationController?.navigationBar.isTranslucent = false
		navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
		navigationController?.navigationBar.shadowImage = UIImage()
		
		searchBar.barStyle = .default
		searchBar.isTranslucent = false
		searchBar.backgroundImage = UIImage()
		searchBar.delegate = self
		searchBar.showsCancelButton = false
		
		let tap = UITapGestureRecognizer(target: self, action: (#selector(ListViewController.dismissKeyboard)))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
		
		
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		
		//Retrieves the Recording list
		SharedRecordingAPI.shared.getRecordings(completion: { [unowned self] (success, message, recordings) in
			//Sorts the recordings by name
			self.recordingList = recordings?.sorted {
				return $0.name < $1.name
			}
			
			//Updates the data and the views
			
			DispatchQueue.main.async {
				self.recordListTableView.reloadData()
				self.view.isUserInteractionEnabled = true
				
				//Stops the activity indicator
				self.activityIndicator.stopAnimating()
				self.activityIndicator.isHidden = true
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
	/// Object that dismisses the keyboard
	@objc func dismissKeyboard(){
		self.view.endEditing(true)
	}
	
	
	func search(recordingName: String){
		//Setup for the activity indicator
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		
		self.searchIsActive = true
		self.searchBar.showsCancelButton = true
		
		searchResults.removeAll()
		
		if recordingList == nil {
			return
		}
		
		for recording in recordingList! {
			if recording.name.contains(recordingName) {
				searchResults.append(recording)
			}
		}
		
		DispatchQueue.main.async {
			self.recordListTableView.reloadData()
			self.view.isUserInteractionEnabled = true
			
			//Stops the activity indicator
			self.activityIndicator.stopAnimating()
			self.activityIndicator.isHidden = true
		}
		
	}
	
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
		
		return activeList?.count ?? 0
		
		/*
		if !searchIsActive {
			return recordingList?.count ?? 0
		}
			return searchResults.count */
	}
	
	var activeList: [Recording]? {
		get {
			return  !searchIsActive  ? recordingList : searchResults
		}
	}
	
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "listViewCell", for: indexPath) as! ListViewCell
	
		let record: Recording
		
		record = activeList![indexPath.row]
		
		/*
		if !searchIsActive {
			record = recordingList![indexPath.row]
		}else{
			record = searchResults[indexPath.row]
		}*/
		
		cell.recordNameLabel.text = record.name
		cell.ratingView.settings.updateOnTouch = false
		
		if let rating = record.lastRatign {
			cell.ratingView.rating = rating
		
		}
		
		//MARK: Setup cell soundwave image
		cell.waveformView.audioURL = record.infoData.audioFile.url
		
		return cell
	
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//Performs the segue to the play recording view based on the clicked cell
		performSegue(withIdentifier: "playRecordingSegue", sender: indexPath.row)
	}
	
}

//MARK: SearBar extensions

extension ListViewController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		searchIsActive = true
	}
	
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		searchIsActive = false
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchIsActive = false
		
		searchBar.text = nil
		searchBar.resignFirstResponder()
		recordListTableView.resignFirstResponder()
		self.searchBar.showsCancelButton = false
		recordListTableView.reloadData()
		
	}
	
	func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
		return true
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		
		self.searchIsActive = true;
		self.searchBar.showsCancelButton = true
		
		self.search(recordingName: searchText)
	}

	
}



