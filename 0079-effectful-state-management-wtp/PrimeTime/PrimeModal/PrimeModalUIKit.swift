import UIKit

import ComposableArchitecture

public class IsPrimeModalViewController: UIViewController {
    private let _stackView = UIStackView()
    private let _label = UILabel()
    private let _button = UIButton()
    private var _buttonAction: PrimeModalAction?
    private let _store: UIStore<PrimeModalState, PrimeModalAction, PrimeModalEnvironment>

    private func _layout() {
        _stackView.axis = .vertical
        _stackView.alignment = .center
        _stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_stackView)
        view.leadingAnchor
            .constraint(equalTo: _stackView.leadingAnchor)
            .isActive = true
        view.trailingAnchor
            .constraint(equalTo: _stackView.trailingAnchor)
            .isActive = true
        view.centerYAnchor
            .constraint(equalTo: _stackView.centerYAnchor)
            .isActive = true

        _stackView.addArrangedSubview(_label)
        _stackView.addArrangedSubview(_button)

        _button.addTarget(self, action: #selector(_buttonTapped), for: .touchUpInside)
        _button.setTitleColor(.blue, for: .normal)
    }

    @objc private func _buttonTapped() {
        _buttonAction.map(_store.send)
    }

    public init(store: UIStore<PrimeModalState, PrimeModalAction, PrimeModalEnvironment>) {
        _store = store
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(#function, String(reflecting: self))
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        _layout()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _store.subscribe(self)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _store.unsubscribe(self)
    }
}

extension IsPrimeModalViewController: Subscriber {
    public func update() {
        if isPrime(_store.value.count) {
            _label.text = "\(_store.value.count) is prime 🎉"
            _button.isHidden = false
            if _store.value.favoritePrimes.contains(_store.value.count) {
                _button.setTitle("Remove from favorite primes", for: .normal)
                _buttonAction = .removeFavoritePrimeTapped
            } else {
                _button.setTitle("Save to favorite primes", for: .normal)
                _buttonAction = .saveFavoritePrimeTapped
            }
        } else {
            _label.text = "\(_store.value.count) is not prime :("
            _button.isHidden = true
        }
    }
}
