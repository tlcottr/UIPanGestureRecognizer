//
//  PayViewController.swift
//  UIPanGestureRecognizer
//
//  Created by Taylor Cottrell on 9/28/25.
//

import UIKit

final class PayViewController: UIViewController, UITextFieldDelegate {

  // MARK: - UI
  private let amountField = UITextField()
  private let hintLabel = UILabel()
  private let slide = SlideToSendControl()

  // MARK: - Amount State / Haptics
  private var amountCents: Int = 0                    // source of truth
  private var panStartCents: Int = 0
  private let stepPoints: CGFloat = 12                // vertical pts per $1
  private let selectionHaptic = UISelectionFeedbackGenerator()

  // MARK: - Formatting
  private let formatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = .current
    f.maximumFractionDigits = 2
    f.minimumFractionDigits = 2
    return f
  }()

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pay"
    view.backgroundColor = .systemBackground
    configureUI()
    configureGestures()
    syncAmountLabel()
  }

  // MARK: - Setup
  private func configureUI() {
    // Amount field
    amountField.keyboardType = .decimalPad
    amountField.font = .systemFont(ofSize: 40, weight: .bold)
    amountField.textAlignment = .center
    amountField.placeholder = formatter.string(from: NSNumber(value: 0)) ?? "$0.00"
    amountField.addTarget(self, action: #selector(onAmountChanged), for: .editingChanged)
    amountField.translatesAutoresizingMaskIntoConstraints = false

    // Hint
    hintLabel.text = "Drag amount ↑↓ to adjust, or type. Then slide to send →"
    hintLabel.font = .systemFont(ofSize: 14, weight: .medium)
    hintLabel.textAlignment = .center
    hintLabel.textColor = .secondaryLabel
    hintLabel.numberOfLines = 0
    hintLabel.translatesAutoresizingMaskIntoConstraints = false

    // Slide control
    slide.translatesAutoresizingMaskIntoConstraints = false
    slide.addTarget(self, action: #selector(onSlideTriggered), for: .primaryActionTriggered)

    // Layout
    [amountField, hintLabel, slide].forEach { view.addSubview($0) }

    NSLayoutConstraint.activate([
      amountField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
      amountField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      amountField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

      hintLabel.topAnchor.constraint(equalTo: amountField.bottomAnchor, constant: 12),
      hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

      slide.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 24),
      slide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      slide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      slide.heightAnchor.constraint(equalToConstant: 56)
    ])

    // Done toolbar
    let tb = UIToolbar(); tb.sizeToFit()
    let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(endEditingNow))
    tb.items = [flex, done]
    amountField.inputAccessoryView = tb

    // Start disabled until amount > 0
    slide.isUserInteractionEnabled = false
    slide.alpha = 0.5
  }

  private func configureGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(onAmountPan(_:)))
    pan.cancelsTouchesInView = false // still allows tapping to edit
    amountField.isUserInteractionEnabled = true
    amountField.addGestureRecognizer(pan)
  }

  // MARK: - Actions
  @objc private func endEditingNow() { view.endEditing(true) }

  @objc private func onAmountChanged() {
    // Treat digits as cents for robust currency-as-you-type
    let digits = amountField.text?.filter { "0123456789".contains($0) } ?? ""
    amountCents = Int(digits) ?? 0
    syncAmountLabel()
  }

  @objc private func onSlideTriggered() {
    guard amountCents > 0 else { slide.reset(); return }

    // Simulate a send; SlideToSendControl already started its spinner.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
      let amountString = self.formatter.string(from: NSNumber(value: Double(self.amountCents)/100)) ?? "$0.00"
      let ac = UIAlertController(title: "Sent ✅",
                                 message: "Transferred \(amountString) to Checking ••1234.",
                                 preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "Done", style: .default))
      self.present(ac, animated: true)

      // Reset
      self.amountCents = 0
      self.syncAmountLabel()
      self.slide.reset()
      self.slide.isUserInteractionEnabled = false
      self.slide.alpha = 0.5
    }
  }

  // MARK: - Pan-to-tune handler
  @objc private func onAmountPan(_ g: UIPanGestureRecognizer) {
    switch g.state {
    case .began:
      selectionHaptic.prepare()
      panStartCents = amountCents

    case .changed:
      let dy = -g.translation(in: view).y          // up = positive
      let dollars = Int(dy / stepPoints)           // $1 per 12pt drag
      let newCents = max(0, panStartCents + dollars * 100)

      if newCents != amountCents {
        amountCents = newCents
        selectionHaptic.selectionChanged()
        syncAmountLabel()
      }

    case .ended, .cancelled:
      // Snap to nearest $5 for tidy values
      let rem = amountCents % 500
      if rem != 0 {
        let target = rem >= 250 ? amountCents + (500 - rem) : amountCents - rem
        UIView.animate(withDuration: 0.15) {
          self.amountCents = max(0, target)
          self.syncAmountLabel()
        }
      }

    default: break
    }
  }

  // MARK: - Helpers
  private func syncAmountLabel() {
    amountField.text = formatter.string(from: NSNumber(value: Double(amountCents) / 100)) ?? "$0.00"

    let enabled = amountCents > 0
    slide.isUserInteractionEnabled = enabled
    UIView.animate(withDuration: 0.15) { self.slide.alpha = enabled ? 1.0 : 0.5 }
  }
}
