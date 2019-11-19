import UIKit

public final class UIStore<Value, Action, Environment> {
    private let reducer: Reducer<Value, Action, Environment>
    private let environment: Environment
    public fileprivate(set) var value: Value {
        didSet { _subscribers.forEach { $0.update() } }
    }

    public init(initialValue: Value,
                reducer: @escaping Reducer<Value, Action, Environment>,
                environment: Environment) {
        self.reducer = reducer
        self.value = initialValue
        self.environment = environment
    }

    public func send(_ action: Action) {
        let effects = self.reducer(&self.value, action)
        effects.forEach { $0.runReader(environment).run(self.send) }
    }

    public func view<LocalValue, LocalAction, LocalEnvironment>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action,
        environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
    ) -> UIStore<LocalValue, LocalAction, LocalEnvironment> {
        let localStore = UIStore<LocalValue, LocalAction, LocalEnvironment>(
            initialValue: toLocalValue(self.value),
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
        }, environment: toLocalEnvironment(self.environment)
        )
        localStore.value = toLocalValue(self.value)
        return localStore
    }

    private var _subscribers: [Subscriber] = []
    public func subscribe(_ subscriber: Subscriber) {
        _subscribers.append(subscriber)
        subscriber.update()
    }
    public func unsubscribe(_ subscriber: Subscriber) {
        _subscribers.removeAll(where: { $0 === subscriber })
    }
}

public protocol Subscriber: class {
    func update()
}

public func get<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
  return { root in root[keyPath: keyPath] }
}

public func id<A>(_ x: A) -> A { x }
