--!optimize 2
--!strict
local Promise: any = require("./Promise")

export type Status = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type Promise = {
	Status: Status,
	Then: (
		self: Promise,
		successHandler: (...any) -> ...any,
		failureHandler: ((...any) -> ...any)?
	) -> Promise,
	ThenCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> any,
	ThenReturn: (self: Promise, ...any) -> Promise,

	Wait: (self: Promise) -> (boolean, ...any),
	WaitStatus: (self: Promise) -> (Status, ...any),

	Cancel: (self: Promise) -> (),
	Catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	Expect: (self: Promise) -> ...any,

	Finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	FinallyCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	FinallyReturn: (self: Promise, ...any) -> Promise,

	GetStatus: (self: Promise) -> Status,
	Now: (self: Promise, rejectionValue: any?) -> Promise,
	Tap: (self: Promise, onSuccess: (...any) -> ...any, onError: nil | (...any) -> ...any) -> Promise,
	Timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

export type TypedPromise<T...> = {
	Status: Status,
	Then: (self: Promise, successHandler: (T...) -> ...any, failureHandler: ((...any) -> ...any)?) -> Promise,
	ThenCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	ThenReturn: (self: Promise, ...any) -> Promise,

	Wait: (self: Promise) -> (boolean, T...),
	WaitStatus: (self: Promise) -> (Status, T...),

	Cancel: (self: Promise) -> (),
	Catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	Expect: (self: Promise) -> T...,

	Finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	FinallyCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	FinallyReturn: (self: Promise, ...any) -> Promise,

	GetStatus: (self: Promise) -> Status,
	Now: (self: Promise, rejectionValue: any?) -> Promise,
	Tap: (self: Promise, onSuccess: (T...) -> ...any, onError: nil | (...any) -> ...any) -> Promise,
	Timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ...any) -> SignalConnection,
}

type SignalConnection = {
	Disconnect: (self: SignalConnection) -> ...any,
	[any]: any,
}

return Promise :: {
	Error: any,

	All: <T>(promises: {TypedPromise<T>}) -> TypedPromise<{T}>,
	AllSettled: <T>(promise: {TypedPromise<T>}) -> TypedPromise<{Status}>,
	Any: <T>(promise: {TypedPromise<T>}) -> TypedPromise<T>,
	Defer: <TReturn...>(
		executor: (
			resolve: (TReturn...) -> (),
			reject: (...any) -> (),
			onCancel: (abortHandler: (() -> ())?) -> boolean
		) -> ()
	) -> TypedPromise<TReturn...>,
	Delay: (seconds: number) -> TypedPromise<number>,
	Each: <T, TReturn>(
		list: {T | TypedPromise<T>},
		predicate: (value: T, index: number) -> TReturn | TypedPromise<TReturn>
	) -> TypedPromise<{TReturn}>,
	Fold: <T, TReturn>(
		list: {T | TypedPromise<T>},
		reducer: (accumulator: TReturn, value: T, index: number) -> TReturn | TypedPromise<TReturn>
	) -> TypedPromise<TReturn>,
	FromEvent: <TReturn...>(
		event: Signal<TReturn...>,
		predicate: ((TReturn...) -> boolean)?
	) -> TypedPromise<TReturn...>,
	Is: (object: any) -> boolean,
	new: <TReturn...>(
		executor: (
			resolve: (TReturn...) -> (),
			reject: (...any) -> (),
			onCancel: (abortHandler: (() -> ())?) -> boolean
		) -> ()
	) -> TypedPromise<TReturn...>,
	OnUnhandledRejection: (callback: (promise: TypedPromise<any>, ...any) -> ()) -> () -> (),
	Promisify: <TArgs..., TReturn...>(callback: (TArgs...) -> TReturn...) -> (TArgs...) -> TypedPromise<TReturn...>,
	Race: <T>(promises: {TypedPromise<T>}) -> TypedPromise<T>,
	Reject: (...any) -> TypedPromise<...any>,
	Resolve: <TReturn...>(TReturn...) -> TypedPromise<TReturn...>,
	Retry: <TArgs..., TReturn...>(
		callback: (TArgs...) -> TypedPromise<TReturn...>,
		times: number,
		TArgs...
	) -> TypedPromise<TReturn...>,
	RetryWithDelay: <TArgs..., TReturn...>(
		callback: (TArgs...) -> TypedPromise<TReturn...>,
		times: number,
		seconds: number,
		TArgs...
	) -> TypedPromise<TReturn...>,
	Some: <T>(promise: {TypedPromise<T>}, count: number) -> TypedPromise<{T}>,
	Try: <TArgs..., TReturn...>(callback: (TArgs...) -> TReturn..., TArgs...) -> TypedPromise<TReturn...>,
}
