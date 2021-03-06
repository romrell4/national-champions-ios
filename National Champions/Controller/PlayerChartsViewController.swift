//
//  PlayerChartsViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 6/3/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit
import Charts

class PlayerChartsViewController: UIViewController {
	@IBOutlet private weak var segmentedControl: UISegmentedControl!
	@IBOutlet private weak var chartView: LineChartView!
	
	var player: Player!
	
	private var matches: [Match] {
		let playerMatches = Match.loadAll().filter {
			$0.allPlayers.contains(player)
		}.sorted { (lhs, rhs) -> Bool in
			lhs.matchDate < rhs.matchDate
		}
		if segmentedControl.selectedSegmentIndex == 0 {
			return playerMatches.filter { $0.isSingles }
		} else {
			return playerMatches.filter { $0.isDoubles }
		}
	}
	
	override func viewDidLoad() {
		loadChart()
		
		let axisFont = UIFont.systemFont(ofSize: 16)
		chartView.xAxis.labelFont = axisFont
		chartView.leftAxis.labelFont = axisFont
		chartView.rightAxis.labelFont = axisFont
	}
	
	//MARK: Listeners
	
	@IBAction func segmentedViewTapped(_ sender: Any) {
		loadChart()
	}
	
	//MARK: Private functions
	
	private func loadChart() {
		let lineDataSet = LineChartDataSet(entries: matches.enumerated().compactMap { (index, match) in
			if let rating = match.findRatings(for: player)?.2 {
				return ChartDataEntry(x: Double(index), y: rating)
			} else {
				return nil
			}
		}, label: "Ratings")
		lineDataSet.colors = [UIColor(named: "PrimaryColor")!]
		chartView.data = LineChartData(dataSet: lineDataSet)
	}
}
