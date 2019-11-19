import UIKit

import ComposableArchitecture
import PrimeModal

public class CounterViewController: UIViewController {
    private let _verticalStack = UIStackView()
    private let _horizontalStack = UIStackView()
    private let _decrementButton = UIButton()
    private let _counterLabel = UILabel()
    private let _incrementButton = UIButton()
    private let _isPrimeButton = UIButton()
    private let _nthPrimeButton = UIButton()

    private func _layout() {
        _verticalStack.axis = .vertical
        _verticalStack.alignment = .center
        _verticalStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_verticalStack)
        _verticalStack.leadingAnchor
            .constraint(equalTo: view.leadingAnchor)
            .isActive = true
        _verticalStack.trailingAnchor
            .constraint(equalTo: view.trailingAnchor)
            .isActive = true
        _verticalStack.centerYAnchor
            .constraint(equalTo: view.centerYAnchor)
            .isActive = true

        _horizontalStack.alignment = .center
        _horizontalStack.axis = .horizontal
        _verticalStack.addArrangedSubview(_horizontalStack)
        _horizontalStack.addArrangedSubview(_decrementButton)
        _horizontalStack.addArrangedSubview(_counterLabel)
        _horizontalStack.addArrangedSubview(_incrementButton)

        _verticalStack.addArrangedSubview(_isPrimeButton)
        _verticalStack.addArrangedSubview(_nthPrimeButton)

        _decrementButton.addTarget(self, action: #selector(_decrementButtonTapped), for: .touchUpInside)
        _decrementButton.setTitleColor(.blue, for: .normal)
        _decrementButton.setTitle("-", for: .normal)
        _incrementButton.addTarget(self, action: #selector(_incrementButtonTapped), for: .touchUpInside)
        _incrementButton.setTitleColor(.blue, for: .normal)
        _incrementButton.setTitle("+", for: .normal)

        _isPrimeButton.addTarget(self, action: #selector(_isPrimeButtonTapped), for: .touchUpInside)
        _isPrimeButton.setTitleColor(.blue, for: .normal)
        _isPrimeButton.setTitle("Is this prime?", for: .normal)

        _nthPrimeButton.addTarget(self, action: #selector(_nthPrimeButtonTapped), for: .touchUpInside)
        _nthPrimeButton.setTitleColor(.blue, for: .normal)
        _nthPrimeButton.setTitleColor(.gray, for: .disabled)
    }

    @objc private func _decrementButtonTapped() {
        _store.send(.counter(.decrTapped))
    }
    @objc private func _incrementButtonTapped() {
        _store.send(.counter(.incrTapped))
    }
    @objc private func _isPrimeButtonTapped() {
        let vc = IsPrimeModalViewController(store: _store
            .view(value: { ($0.count, $0.favoritePrimes) },
                  action: { .primeModal($0) },
                  environment: get(\CounterEnvironment.primeModal))
        )
        present(vc, animated: true, completion: nil)
    }
    @objc private func _nthPrimeButtonTapped() {
        _store.send(.counter(.nthPrimeButtonTapped))
    }

    private func _showAlert(_ title: String) {
        let vc = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default) { (_) in
            self._store.send(.counter(.alertDismissButtonTapped))
        }
        vc.addAction(action)
        present(vc, animated: true, completion: nil)
    }

    private let _store: UIStore<CounterViewState, CounterViewAction, CounterEnvironment>
    public init(store: UIStore<CounterViewState, CounterViewAction, CounterEnvironment>) {
        _store = store
        super.init(nibName: nil, bundle: nil)
        title = "Counter demo"
        view.backgroundColor = .white
        store.subscribe(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        _layout()
    }
}

extension CounterViewController: Subscriber {
    public func update() {
        _counterLabel.text = "\(_store.value.count)"
        _nthPrimeButton.setTitle("What is the \(ordinal(_store.value.count)) prime?", for: .normal)
        if let alertNthPrime = _store.value.alertNthPrime?.prime {
            _showAlert("The \(ordinal(_store.value.count)) prime is \(alertNthPrime)")
        }
        _nthPrimeButton.isEnabled = !_store.value.isNthPrimeButtonDisabled
    }
}
