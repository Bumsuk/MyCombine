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
	
	// 기본 Framework에 이미 Combine이 녹여 들어가있다!
	public class func test1() {
		print("📲", #function)
		
		let myNotfi = Notification.Name("내 노티!")
		let publisher = NotificationCenter.default.publisher(for: myNotfi, object: nil)
		
		let subscription = publisher.sink(receiveValue: { notification in
			print("1[구독] \(notification.object)")
		})
		
		let subscription2 = publisher.sink(receiveCompletion: { (complete) in
			print("2[완료] \(complete)")
		}) { noti in
			print("2[구독] \(noti)")
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
	
	
	// 커스텀 Subscriber 만들기
	public class func test_custom_subscriber() {
		print("📲", #function)
		
		let publisher = (1...6).publisher
		
		final class IntSubscriber: Subscriber {
			typealias Input = Int
			typealias Failure = Never
			
			func receive(subscription: Subscription) {
				subscription.request(.max(3))
			}
			
			func receive(_ input: Int) -> Subscribers.Demand {
				print("Received value", input)
				// return .none 			// 수요 조정은 하지않음
				// return .unlimited		// 모든 값 요청
				return .max(1)				// .unlimited 와 같이 모든값을 수신받고 완료 이벤트도 받는데, 그 이유는 값을 받을때마다 하나더 달라는 요청이기 때문!
			}
			
			func receive(completion: Subscribers.Completion<Never>) {
				print("Reveived completion", completion)
			}
		}
		
		let subscriber = IntSubscriber()
		publisher.receive(subscriber: subscriber)
		
	}

	
}

