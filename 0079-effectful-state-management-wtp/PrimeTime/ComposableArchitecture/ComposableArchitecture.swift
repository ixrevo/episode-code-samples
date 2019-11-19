import Combine
import SwiftUI


struct Parallel<A> {
  let run: (@escaping (A) -> Void) -> Void
}

public struct Effect<A> {
  public let run: (@escaping (A) -> Void) -> Void

  public init(run: @escaping (@escaping (A) -> Void) -> Void) {
    self.run = run
  }

  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
    return Effect<B> { callback in self.run { a in callback(f(a)) } }
  }
}

public typealias Reducer<Value, Action, Environment> = (inout Value, Action) -> [Reader<Environment, Effect<Action>>]

public final class Store<Value, Action, Environment>: ObservableObject {
  private let reducer: Reducer<Value, Action, Environment>
  @Published public private(set) var value: Value
  private var cancellable: Cancellable?
  private let _environment: Environment

  public init(initialValue: Value,
              reducer: @escaping Reducer<Value, Action, Environment>,
              environment: Environment) {
    self.reducer = reducer
    self.value = initialValue
    _environment = environment
  }

  public func send(_ action: Action) {
    let effects = self.reducer(&self.value, action)
    effects.forEach { effect in
      effect.runReader(_environment).run(self.send)
    }
  }

  public func view<LocalValue, LocalAction, LocalEnvironment>(
    value toLocalValue: @escaping (Value) -> LocalValue,
    action toGlobalAction: @escaping (LocalAction) -> Action,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Store<LocalValue, LocalAction, LocalEnvironment> {
    let localStore = Store<LocalValue, LocalAction, LocalEnvironment>(
      initialValue: toLocalValue(self.value),
      reducer: { localValue, localAction in
        self.send(toGlobalAction(localAction))
        localValue = toLocalValue(self.value)
        return []
    }, environment: toLocalEnvironment(self._environment)
    )
    localStore.cancellable = self.$value.sink { [weak localStore] newValue in
      localStore?.value = toLocalValue(newValue)
    }
    return localStore
  }
}

public func combine<Value, Action, Environment>(
  _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
  return { value, action in reducers.flatMap { $0(&value, action) } }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
  _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>,
  environment toLocalEnvironment: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
  return { globalValue, globalAction in
    guard let localAction = globalAction[keyPath: action] else { return [] }
    let localEffects = reducer(&globalValue[keyPath: value], localAction)

    return localEffects.map { localEffect in
      return Reader { globalEnvironment in
        Effect { callback in
          localEffect.runReader(toLocalEnvironment(globalEnvironment))
            .run { localAction in
              var globalAction = globalAction
              globalAction[keyPath: action] = localAction
              callback(globalAction)
          }
        }
      }
    }
  }
}

public func logging<Value, Action, Environment>(
  _ reducer: @escaping Reducer<Value, Action, Environment>
) -> Reducer<Value, Action, Environment> {
  return { value, action in
    let effects = reducer(&value, action)
    let newValue = value
    return [pure(Effect { _ in
      print("Action: \(action)")
      print("Value:")
      dump(newValue)
      print("---")
    })] + effects
  }
}


public struct Reader<R, A> {
  let runReader: (R) -> A

  public init(_ runReader: @escaping (R) -> A) {
    self.runReader = runReader
  }
}

// MARK: - Functor
extension Reader {
  public func map<B>(_ f: @escaping (A) -> B) -> Reader<R, B> {
    return Reader<R, B>.init { f(self.runReader($0)) }
  }
}

public func pure<R, A>(_ a: A) -> Reader<R, A> {
  return Reader { _ in a }
}
