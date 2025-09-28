//
//  DraggableCardViewController.swift
//  PanPlayground
//
//  Created by Taylor Cottrell on 9/27/25.
//

import UIKit

final class DraggableCardViewController: UIViewController {
  private let card = UIView()
  private var originalCenter = CGPoint.zero

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    // Visible header to prove we rendered
    let titleLabel = UILabel()
    titleLabel.text = "Draggable Card"
    titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
    ])

    // Card setup
    card.backgroundColor = .secondarySystemBackground
    card.layer.cornerRadius = 20
    card.layer.cornerCurve = .continuous
    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.12
    card.layer.shadowRadius = 12
    card.layer.shadowOffset = .init(width: 0, height: 6)
    view.addSubview(card)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if card.frame == .zero {
      let size = min(view.bounds.width - 40, 360)
      card.frame = CGRect(x: (view.bounds.width - size)/2,
                          y: view.bounds.midY - size*0.35,
                          width: size,
                          height: size*0.6)
      originalCenter = card.center
      addLabels()
      addPan()
    }
  }

  private func addLabels() {
    func makeLabel(_ text: String, color: UIColor, angle: CGFloat, tag: Int) -> UILabel {
      let l = UILabel()
      l.text = text
      l.textColor = color
      l.font = .systemFont(ofSize: 22, weight: .black)
      l.transform = CGAffineTransform(rotationAngle: angle)
      l.alpha = 0
      l.tag = tag
      return l
    }

    let left  = makeLabel("NOPE", color: .systemRed,  angle: -.pi/18, tag: 101)
    let right = makeLabel("LIKE", color: .systemGreen, angle:  .pi/18, tag: 102)
    [left, right].forEach { card.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }

    NSLayoutConstraint.activate([
      left.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      left.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      right.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      right.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
    ])
  }

  private func addPan() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    card.addGestureRecognizer(pan)
  }

  @objc private func handlePan(_ g: UIPanGestureRecognizer) {
    let translation = g.translation(in: view)

    switch g.state {
    case .changed:
      // Move card (reduced Y sensitivity feels nicer)
      card.center = CGPoint(x: originalCenter.x + translation.x,
                            y: originalCenter.y + translation.y * 0.2)

      // Rotate based on horizontal travel
      let percent = min(1, max(-1, translation.x / (view.bounds.width * 0.5)))
      card.transform = CGAffineTransform(rotationAngle: percent * (.pi/18))

      // Affordance fades
      card.viewWithTag(101)?.alpha = max(0, -percent) // NOPE
      card.viewWithTag(102)?.alpha = max(0,  percent) // LIKE

    case .ended, .cancelled:
      let shouldDismiss = abs(card.center.x - originalCenter.x) > view.bounds.width * 0.25
      let velocity = g.velocity(in: view)

      if shouldDismiss {
        let direction: CGFloat = (card.center.x < originalCenter.x) ? -1 : 1
        let targetX = originalCenter.x + direction * (view.bounds.width * 1.2)
        let finalCenter = CGPoint(x: targetX, y: card.center.y + velocity.y * 0.1)

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
          self.card.center = finalCenter
          self.card.alpha = 0.4
        } completion: { _ in
          self.resetCard()
        }
      } else {
        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0.9,
                       options: [.allowUserInteraction]) {
          self.card.center = self.originalCenter
          self.card.transform = .identity
          self.card.viewWithTag(101)?.alpha = 0
          self.card.viewWithTag(102)?.alpha = 0
        }
      }

    default:
      break
    }
  }

  private func resetCard() {
    // Re-center and restore
    card.alpha = 1
    card.center = originalCenter
    card.transform = .identity
    card.viewWithTag(101)?.alpha = 0
    card.viewWithTag(102)?.alpha = 0
  }
}
