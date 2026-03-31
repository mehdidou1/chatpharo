Class {
	#name : 'ChatPharoCommandResultTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Core',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
ChatPharoCommandResultTest >> testCommandCreationSetsFlagsAndPayload [

	| result |
	result := ChatPharoCommandResult
		command: 'export'
		args: #('json' 'full')
		handler: [ :chat :args | 'ok' ]
		prefix: '/'.

	self assert: result isCommand.
	self deny: result isUnknown.
	self assert: result commandName equals: 'export'.
	self assert: result args equals: #('json' 'full').
	self assert: result prefix equals: '/'
]

{ #category : 'tests' }
ChatPharoCommandResultTest >> testExecuteDelegatesToHandlerWithChatAndArgs [

	| result chat seenChat seenArgs |
	chat := Object new.
	result := ChatPharoCommandResult
		command: 'export'
		args: #('json' 'full')
		handler: [ :aChat :arguments |
			seenChat := aChat.
			seenArgs := arguments.
			'done' ]
		prefix: '/'.

	self assert: (result execute: chat) equals: 'done'.
	self assert: seenChat identicalTo: chat.
	self assert: seenArgs equals: #('json' 'full')
]

{ #category : 'tests' }
ChatPharoCommandResultTest >> testExecuteNonCommandRaisesError [

	self
		should: [ (ChatPharoCommandResult text: 'hello') execute: Object new ]
		raise: Error
]

{ #category : 'tests' }
ChatPharoCommandResultTest >> testExecuteUnknownCommandReturnsHelpfulMessage [

	| result |
	result := ChatPharoCommandResult unknownCommand: 'missing' prefix: '/'.

	self
		assert: (result execute: Object new)
		equals: 'Unknown command: /missing. Type /help for available commands.'
]

{ #category : 'tests' }
ChatPharoCommandResultTest >> testTextCreationProducesNonCommandResult [

	| result |
	result := ChatPharoCommandResult text: 'hello world'.

	self deny: result isCommand.
	self deny: result isUnknown.
	self assert: result text equals: 'hello world'
]

{ #category : 'tests' }
ChatPharoCommandResultTest >> testUnknownCommandCreationSetsUnknownFlag [

	| result |
	result := ChatPharoCommandResult unknownCommand: 'wat' prefix: '@'.

	self assert: result isCommand.
	self assert: result isUnknown.
	self assert: result commandName equals: 'wat'.
	self assert: result prefix equals: '@'
]
