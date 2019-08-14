//
//  Store.swift
//  Recombine
//
//  Created by Charlotte Tortorella on 2019-07-13.
//  Copyright © 2019 Charlotte Tortorella. All rights reserved.
//

import Combine
import Foundation

public class Store<State, Action>: ObservableObject, Subscriber {
    @Published public private(set) var state: State
    public let actions = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()

    // TODO: Change this to an init generic over reducer when the @Published crashing issue with protocols is fixed.
    public required init(state: State, reducer: MutatingReducer<State, Action>, middleware: Middleware<State, Action> = .init()) {
        self.state = state
        actions.scan(state) { state, action in
            reducer.reduce(
                state: state,
                actions: middleware.transform(state, action)
            )
        }
        .receive(on: RunLoop.main)
        .sink { [unowned self] state in
            self.state = state
        }
        .store(in: &cancellables)
    }

    open func dispatch(_ actions: Action...) {
        dispatch(actions)
    }

    open func dispatch<S: Sequence>(_ actions: S) where S.Element == Action {
        actions.forEach(self.actions.send)
    }

    public func receive(subscription: Subscription) {
        subscription.store(in: &cancellables)
        subscription.request(.unlimited)
    }

    public func receive(_ input: Action) -> Subscribers.Demand {
        actions.send(input)
        return .unlimited
    }

    public func receive(completion: Subscribers.Completion<Never>) {}
}
