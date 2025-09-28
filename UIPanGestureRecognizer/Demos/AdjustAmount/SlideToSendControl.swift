//
//  SlideToSendControl.swift
//  UIPanGestureRecognizer
//
//  Created by Taylor Cottrell on 9/28/25.
//


import UIKit

/// Minimal slide-to-confirm control driven by UIPanGestureRecognizer.
/// Sends `.primaryActionTriggered` when the thumb crosses the threshold.
final class SlideToSendControl: UIControl {

  // Config
  var threshold: CGFloat = 0.85 // 0..1

  // Subviews
  private let track = UIView()
  private let fill = UIView()
  private let titleLabel = UILabel()
  private let thumb = UIView()
  private let spinner = UIActivityIndicatorView(style: .medium)

  // State
  private lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
  private var leftX: CGFloat = 0
  private var rightX: CGFloat = 0

  // Init
  override init(frame: CGRect) {
    super.init(frame: frame)

    // Track
    track.backgroundColor = .secondarySystemFill
    track.layer.cornerRadius = 28
    track.layer.cornerCurve = .continuous
    track.layer.borderColor = UIColor.separator.cgColor
    track.layer.borderWidth = 1 / UIScreen.main.scale
    addSubview(track)

    // Fill
    fill.backgroundColor = tintColor.withAlphaComponent(0.25)
    fill.layer.cornerRadius = 28
    fill.layer.cornerCurve = .continuous
    addSubview(fill)

    // Title
    titleLabel.text = "Slide to Send"
    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textAlignment = .center
    addSubview(titleLabel)

    // Thumb
    thumb.backgroundColor = tintColor
    thumb.layer.cornerRadius = 24
    thumb.layer.cornerCurve = .continuous
    thumb.layer.shadowColor = UIColor.black.cgColor
    thumb.layer.shadowOpacity = 0.18
    thumb.layer.shadowRadius = 6
    thumb.layer.shadowOffset = CGSize(width: 0, height: 2)
    thumb.addGestureRecognizer(pan)
    addSubview(thumb)

    // Spinner
    spinner.hidesWhenStopped = true
    thumb.addSubview(spinner)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()

    track.frame = bounds
    let h = bounds.height
    track.layer.cornerRadius = h/2

    // Thumb sizing/placement
    let inset: CGFloat = 4
    let side = h - inset*2
    if thumb.frame == .zero {
      thumb.frame = CGRect(x: bounds.minX + inset, y: bounds.minY + inset, width: side, height: side)
    } else {
      thumb.bounds.size = CGSize(width: side, height: side)
      thumb.center.y = bounds.midY
    }
    thumb.layer.cornerRadius = side/2

    // Pan limits
    leftX  = bounds.minX + inset + thumb.bounds.width/2
    rightX = bounds.maxX - inset - thumb.bounds.width/2

    // Title & fill
    titleLabel.frame = bounds.insetBy(dx: h, dy: 0)
    spinner.center = CGPoint(x: thumb.bounds.midX, y: thumb.bounds.midY)
    fill.frame = CGRect(x: bounds.minX, y: bounds.minY, width: max(thumb.frame.maxX, h/2), height: bounds.height)
    fill.layer.cornerRadius = h/2
  }

  override func tintColorDidChange() {
    super.tintColorDidChange()
    fill.backgroundColor = tintColor.withAlphaComponent(0.25)
    thumb.backgroundColor = tintColor
  }

  // MARK: - Pan
  @objc private func onPan(_ g: UIPanGestureRecognizer) {
    guard isUserInteractionEnabled else { return }
    let t = g.translation(in: self)

    switch g.state {
    case .changed:
      var x = thumb.center.x + t.x
      x = min(max(x, leftX), rightX)
      thumb.center.x = x
      g.setTranslation(.zero, in: self)

      let p = progress
      titleLabel.alpha = 1 - min(1, p * 1.1)
      fill.frame.size.width = max(thumb.frame.maxX, bounds.height/2)

    case .ended, .cancelled:
      if progress >= threshold {
        commit()
      } else {
        reset()
      }

    default: break
    }
  }

  private var progress: CGFloat {
    guard rightX > leftX else { return 0 }
    return (thumb.center.x - leftX) / (rightX - leftX)
  }

  private func commit() {
    isUserInteractionEnabled = false
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

    UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
      self.thumb.center.x = self.rightX
      self.fill.frame.size.width = self.bounds.width
      self.titleLabel.alpha = 0
    } completion: { _ in
      self.spinner.startAnimating()
      self.sendActions(for: .primaryActionTriggered)
    }
  }

  // MARK: - Public API
  func startLoading() { isUserInteractionEnabled = false; spinner.startAnimating() }

  func reset() {
    spinner.stopAnimating()
    isUserInteractionEnabled = true
    UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
      self.thumb.center.x = self.leftX
      self.titleLabel.alpha = 1
      self.fill.frame.size.width = max(self.bounds.height/2, self.thumb.frame.maxX)
    }
  }
}
