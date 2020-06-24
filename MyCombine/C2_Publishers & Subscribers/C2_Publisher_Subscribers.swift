//
//  C2_Publisher_Subscribers.swift
//  MyCombine
//
//  Created by brown on 2020/06/03.
//  Copyright © 2020 brown. All rights reserved.
//

import Foundation
import Combine

public class C2_Publisher_Subscribers {
	// DisposeBag 과 비슷!
	static var subscriptions = Set<AnyCancellable>()
	
	// 기본 Framework에 이미 Combine이 녹여 들어가있다!
	public class func test1() {
		print("📲", #function)
		
		let myNotfi = Notification.Name("내 노티!")
		let publisher = NotificationCenter.default.publisher(for: myNotfi, object: nil)
		
		let subscription = publisher.sink(receiveValue: { notification in
			print("[구독1] \(notification.object)")
		})
		
		let subscription2 = publisher.sink(receiveCompletion: { (complete) in
			print("[완료2] \(complete)")
		}) { noti in
			print("[구독2] \(noti)")
		}
		
		let center = NotificationCenter.default
		center.post(name: myNotfi, object: "object 값이야!")
		
		subscription.cancel() // 취소해야지!
		subscription2.cancel()
	}
	
	// 이 just가 RxSwift의 just와 같네.
	public class func test_just() {
		print("📲", #function)
		
		let just = Just("칼퇴근이야!").delay(for: .seconds(5), scheduler: DispatchQueue.main)
		let subscription = just.sink(receiveCompletion: { (complete) in
			print("[완료] \(complete)")
		}) { str in
			print("[구독] \(str)")
		}
		
		subscription.cancel()
	}
	
	// 이 asign == bind, 특히나 Combine은 기본자료형을 확장해 쉽게 사용할수 있다. 게다가 KVO 속성에 값을 assign 도 가능하다!
	public class func test_assign() {
		print("📲", #function)
		
		class SomeObject {
			var value: String = "" {
				didSet {
					print("[didSet] \(value)")
				}
			}
		}
		
		let object = SomeObject()
		let pub = ["Hello", "world!"].publisher
		
		// assign(bind) 사용
		_ = pub.assign(to: \SomeObject.value, on: object)
		// pub.assign(to: \.value, on: object)
		
		// 일반적인 구독(sink(subscribe))
		_ = pub.sink { str in
			print("[sink] \(str)")
		}
	}
	
	
	// 커스텀 Subscriber 만들기 (커스텀 구.독.자 / 커스텀 Publisher(=Observable)는 아래 예제에서..
	public class func test_custom_subscriber() {
		print("📲", #function)
		
		let publisher = (1...6).publisher
		
		final class IntSubscriber: Subscriber {
			// typealias를 안쓸수도 있지않나? 그냥 메서드들의 자료형을 맞춰줘도 되지만...
			typealias Input = Int
			typealias Failure = Never
			
			func receive(subscription: Subscription) {
				subscription.request(.max(3))
			}
			
			func receive(_ input: Int) -> Subscribers.Demand {
				print("Received value", input)
				return .none 				// 수요 조정은 하지않음
				// return .unlimited		// 모든 값 요청
				// return .max(1)			// .unlimited 와 같이 모든값을 수신받고 완료 이벤트도 받는데, 그 이유는 값을 받을때마다 하나더 달라는 요청이기 때문!
			}
			
			func receive(completion: Subscribers.Completion<Never>) {
				print("Reveived completion", completion)
			}
		}
		
		let subscriber = IntSubscriber()
		publisher.receive(subscriber: subscriber)
	}
	
	// future publisher 테스트
	// future 는 단일값 출력 = Single 과 같다. 그리고 share 기능도 있다.
	// They're only similar in the sense of single emission, but Future shares resources and executes immediately (very strange behavior)
	public class func test_future() {
		print("📲", #function)

		let delay = 3.0
		let intValue = 10
		
		//Future<Int, Never>(<#T##attemptToFulfill: (@escaping Future<Int, Never>.Promise) -> Void##(@escaping Future<Int, Never>.Promise) -> Void#>)
		let future = Future<Int, Never> { promise in
			DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
				print("🤡future 작업 클로저 실행!") // promise는 재실행되지 않는다. 2개의 구독에 1번 실행!
				promise(.success(intValue + 1))
			}
		}
		
		// future는 share 효과도 있다.
		future
			.sink(receiveCompletion: {
				print("[완료1] \($0)")
				}, receiveValue: {
					print("[수신1] \($0)")
				}
			)
			.store(in: &subscriptions)
		
		// share 기능이 있으니, future 클로저는 한번만 호출됨.
		future
			.sink(receiveCompletion: {
				print("[완료2] \($0)")
			}) {
				print("[수신2] \($0)")
			}
			.store(in: &subscriptions)
		
		print("check!")
	}
	
	/*
	📲 test_future()
	🤡future 작업 클로저 실행!
	[수신1] 11
	[완료1] finished
	[수신2] 11
	[완료2] finished
	*/
	
	
	// Subject 테스트(=Subject), PassthroughSubject(=PublishSubject)
	public class func test_subject_PassthroughSubject() {
		print("📲", #function)
		enum MyError: Error {
			case errorCommon(String)
		}
		
		final class StringSubScriber: Subscriber {
			typealias Input = String
			typealias Failure = MyError
			
			func receive(subscription: Subscription) {
				subscription.request(.max(2))
			}
			
			func receive(_ input: String) -> Subscribers.Demand {
				print("수신(StringSubScriber) : \(input)")
				return input == "World" ? .max(1) : .none
			}
			
			func receive(completion: Subscribers.Completion<MyError>) {
				print("완료(StringSubScriber) : \(completion)")
			}
		}
		
		let subscriber = StringSubScriber()
		let subject = PassthroughSubject<String, MyError>()
		
		// 구독 #1
		subject.subscribe(subscriber)
		
		// 구독 #2
		let subscription = subject.sink(receiveCompletion: { completion in
			print("완료(sink) : \(completion)")
		}) { strValue in
			print("수신(sink) : \(strValue)")
		}
		
		// subject 타입 사용!
		subject.send("Hello")
		subject.send("World")

		// subject.send(completion: .failure(.errorCommon("임의로 에러 발생시킴!")))
		
		subscription.cancel() // 구독 #2 취소
		subject.send("Still there??") // 위에서 cancle 했으니 구독 #2는 값을 수신받지 않음.
		
		subject.send(completion: .finished)
		subject.send("How about another one?")
		
		// subject.send(completion: .finished)
	}
	
	// Subject 테스트(=Subject), CurrentValueSubject(=BehaviorSubject, 현재 BehaviorRelay는 존재하지 않음)
	public class func test_subject_CurrentValueSubject() {
		print("📲", #function)
		
		// var subscriptions = Set<AnyCancellable>() // 이건 예제에 포함되지만, ViewController의 static subscriptions를 사용한다.
		let subject = CurrentValueSubject<Int, Never>(0) // 초기값 0
		
		subject
			.sink(초
				receiveCompletion: { print("완료 : \($0)") },
				receiveValue: { intValue in print("수신 : \(intValue)") }
			)
			.store(in: &subscriptions) // =disposed(by)
				
		subject.send(1)
		subject.send(2)
		subject.send(3)

		// subject.send(completion: .failure(_))
		subject.send(completion: .finished)

	}
}

