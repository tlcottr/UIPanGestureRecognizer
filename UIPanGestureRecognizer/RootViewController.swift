//
//  RootViewController.swift
//  PanPlayground
//
//  Created by Taylor Cottrell on 9/27/25.
//

import UIKit

final class RootViewController: UITableViewController {
  private let demos: [(title: String, makeVC: () -> UIViewController)] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIPanGestureRecognizer"
    view.backgroundColor = .systemBackground
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { demos.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = demos[indexPath.row].title
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    navigationController?.pushViewController(demos[indexPath.row].makeVC(), animated: true)
  }
}
