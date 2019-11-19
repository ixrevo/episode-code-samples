import ComposableArchitecture
import PrimeModal
import SwiftUI

public enum CounterAction {
  case decrTapped
  case incrTapped
  case nthPrimeButtonTapped
  case nthPrimeResponse(Int?)
  case alertDismissButtonTapped
}

public typealias CounterState = (
  alertNthPrime: PrimeAlert?,
  count: Int,
  isNthPrimeButtonDisabled: Bool
)

public struct CounterEnvironment {
  let primeModal: PrimeModalEnvironment
  let nthPrime: (Int) -> Effect<Int?>

  public init(primeModal: PrimeModalEnvironment = .init(),
              nthPrime: @escaping (Int) -> Effect<Int?>) {
    self.primeModal = primeModal
    self.nthPrime = nthPrime
  }
}

extension CounterEnvironment {
  public static let prod = CounterEnvironment(nthPrime: nthPrime(_:))
}

public func counterReducer(state: inout CounterState,
                           action: CounterAction) -> [Reader<CounterEnvironment, Effect<CounterAction>>] {
  switch action {
  case .decrTapped:
    state.count -= 1
    return []

  case .incrTapped:
    state.count += 1
    return []

  case .nthPrimeButtonTapped:
    state.isNthPrimeButtonDisabled = true
    let count = state.count
    return [Reader {
      $0.nthPrime(count)
        .map(CounterAction.nthPrimeResponse)
        .receive(on: .main)
      }
    ]

  case let .nthPrimeResponse(prime):
    state.alertNthPrime = prime.map(PrimeAlert.init(prime:))
    state.isNthPrimeButtonDisabled = false
    return []

  case .alertDismissButtonTapped:
    state.alertNthPrime = nil
    return []
  }
}

public let counterViewReducer = combine(
  pullback(counterReducer,
           value: \CounterViewState.counter,
           action: \CounterViewAction.counter,
           environment: id),
  pullback(primeModalReducer,
           value: \.primeModal,
           action: \.primeModal,
           environment: get(\CounterEnvironment.primeModal))
)

public struct PrimeAlert: Identifiable {
  let prime: Int
  public var id: Int { self.prime }
}

public struct CounterViewState {
  public var alertNthPrime: PrimeAlert?
  public var count: Int
  public var favoritePrimes: [Int]
  public var isNthPrimeButtonDisabled: Bool

  public init(
    alertNthPrime: PrimeAlert?,
    count: Int,
    favoritePrimes: [Int],
    isNthPrimeButtonDisabled: Bool
  ) {
    self.alertNthPrime = alertNthPrime
    self.count = count
    self.favoritePrimes = favoritePrimes
    self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
  }

  var counter: CounterState {
    get { (self.alertNthPrime, self.count, self.isNthPrimeButtonDisabled) }
    set { (self.alertNthPrime, self.count, self.isNthPrimeButtonDisabled) = newValue }
  }

  var primeModal: PrimeModalState {
    get { (self.count, self.favoritePrimes) }
    set { (self.count, self.favoritePrimes) = newValue }
  }
}

public enum CounterViewAction {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)

  var counter: CounterAction? {
    get {
      guard case let .counter(value) = self else { return nil }
      return value
    }
    set {
      guard case .counter = self, let newValue = newValue else { return }
      self = .counter(newValue)
    }
  }

  var primeModal: PrimeModalAction? {
    get {
      guard case let .primeModal(value) = self else { return nil }
      return value
    }
    set {
      guard case .primeModal = self, let newValue = newValue else { return }
      self = .primeModal(newValue)
    }
  }

}

public struct CounterView: View {
  @ObservedObject var store: Store<CounterViewState, CounterViewAction, CounterEnvironment>
  @State var isPrimeModalShown = false

  public init(store: Store<CounterViewState, CounterViewAction, CounterEnvironment>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      HStack {
        Button("-") { self.store.send(.counter(.decrTapped)) }
        Text("\(self.store.value.count)")
        Button("+") { self.store.send(.counter(.incrTapped)) }
      }
      Button("Is this prime?") { self.isPrimeModalShown = true }
      Button(
        "What is the \(ordinal(self.store.value.count)) prime?",
        action: { self.store.send(.counter(.nthPrimeButtonTapped)) }
      )
        .disabled(self.store.value.isNthPrimeButtonDisabled)
    }
    .font(.title)
    .navigationBarTitle("Counter demo")
    .sheet(isPresented: self.$isPrimeModalShown) {
      IsPrimeModalView(
        store: self.store
          .view(
            value: { ($0.count, $0.favoritePrimes) },
            action: { .primeModal($0) },
            environment: get(\CounterEnvironment.primeModal)
        )
      )
    }
    .alert(
      item: .constant(self.store.value.alertNthPrime)
    ) { alert in
      Alert(
        title: Text("The \(ordinal(self.store.value.count)) prime is \(alert.prime)"),
        dismissButton: .default(Text("Ok")) {
          self.store.send(.counter(.alertDismissButtonTapped))
        }
      )
    }
  }
}

func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}
