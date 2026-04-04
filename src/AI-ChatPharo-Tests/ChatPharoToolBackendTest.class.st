Class {
	#name : 'ChatPharoToolBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'tool',
		'echoClient',
		'originalRequestTimeoutSeconds',
		'originalCognitiveLoadBudget',
		'originalTokenBudget',
		'originalTimeBudgetMinutes',
		'originalMessageLimit',
		'originalMandate',
		'originalLastRequestDuration'
	],
	#category : 'AI-ChatPharo-Tests-Tools',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
ChatPharoToolBackendTest >> setUp [

	| director |
	super setUp.
	director := ChatPharoSettings default ethicsDirector.
	originalRequestTimeoutSeconds := ChatPharoSettings default requestTimeoutSeconds.
	originalCognitiveLoadBudget := director cognitiveLoadBudget.
	originalTokenBudget := director tokenBudget.
	originalTimeBudgetMinutes := director timeBudgetMinutes.
	originalMessageLimit := director messageLimit.
	originalMandate := director mandate.
	originalLastRequestDuration := director lastRequestDurationSeconds.
	tool := ChatPharoToolTestDouble
		        baseURL: (ZnUrl new
				         scheme: 'http';
				         host: 'localhost';
				         yourself)
		        system: 'system'
		        tools: nil.
	echoClient := ChatPharoClient
		              name: 'echo'
		              description: 'Echoes the provided text.'
		              parameters: Dictionary new
		              block: [ :arguments | arguments ].
	tool tools: { echoClient }
]

{ #category : 'running' }
ChatPharoToolBackendTest >> tearDown [

| director |
director := ChatPharoSettings default ethicsDirector.
	ChatPharoSettings default requestTimeoutSeconds: originalRequestTimeoutSeconds.
		director cognitiveLoadBudget: originalCognitiveLoadBudget.
	director tokenBudget: originalTokenBudget.
	director timeBudgetMinutes: originalTimeBudgetMinutes.
	director messageLimit: originalMessageLimit.
	director mandate: originalMandate.
	director lastRequestDurationSeconds: originalLastRequestDuration.
	super tearDown
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testApplyToolFunctionInvokesClientBlock [

    | result |
    result := tool applyToolFunction: 'echo' arguments: (Dictionary with: 'message' -> 'hi').
    self assert: (result at: 'message') equals: 'hi'.
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testApplyToolFunctionRecordsCall [

    tool applyToolFunction: 'echo' arguments: Dictionary new.
    self assert: tool appliedCalls size equals: 1.
    self assert: tool appliedCalls first first equals: 'echo'.
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testApplyToolFunctionReturnsErrorWhenToolMissing [

    tool tools: nil.
    self assert: (((tool applyToolFunction: 'missing' arguments: Dictionary new) at: 'error')
        includesSubstring: 'There is no function named').
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testApplyToolFunctionTriggersOnToolExecutionCallback [

    | triggered |
    triggered := false.
    tool onToolExecution: [ triggered := true ].
    tool applyToolFunction: 'echo' arguments: Dictionary new.
    self assert: triggered.
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testApplyToolFunctionWrapsErrorsAsDictionary [

    tool tools: {
        ChatPharoClient
            name: 'boom'
            description: 'Raises an error.'
            parameters: Dictionary new
            block: [ :arguments | Error signal: 'failure' ] }.
    self assert: ((tool applyToolFunction: 'boom' arguments: Dictionary new) at: 'error') equals: 'failure'.
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testBuildPayloadIncludesEthicsMetadata [

	| director payload ethics |
	director := ChatPharoSettings default ethicsDirector.
	director
		cognitiveLoadBudget: 77;
		tokenBudget: 2048;
		timeBudgetMinutes: 15;
		messageLimit: 12;
		mandate: 'be helpful';
		requestTimeoutSeconds: 45;
		lastRequestDurationSeconds: 3.
	payload := tool buildPayloadFor: #().
	self assert: (payload includesKey: 'chatpharo_ethics').
	ethics := payload at: 'chatpharo_ethics'.
	self assert: (ethics at: 'cognitive_load_budget') equals: 77.
	self assert: (ethics at: 'token_budget') equals: 2048.
	self assert: (ethics at: 'time_budget_minutes') equals: 15.
	self assert: (ethics at: 'message_limit') equals: 12.
	self assert: (ethics at: 'mandate') equals: 'be helpful'.
	self assert: (ethics at: 'request_timeout_seconds') equals: 45.
	self assert: (ethics at: 'last_request_duration_seconds') equals: 3.
	self assert: (ethics at: 'enabled') equals: director enabled
]

{ #category : 'tests' }
ChatPharoToolBackendTest >> testBuildPayloadMapsTokenBudgetToMaxTokens [

	| payload |
	ChatPharoSettings default ethicsDirector tokenBudget: 1234.
	payload := tool buildPayloadFor: #().
	self assert: (payload at: 'max_tokens') equals: 1234
]

{ #category : 'tests' }
ChatPharoToolBackendTest >> testBuildPayloadPreservesExplicitMaxTokens [

	| payload |
	ChatPharoSettings default ethicsDirector tokenBudget: 1234.
	tool requestParameters: (Dictionary with: 'max_tokens' -> 99).
	payload := tool buildPayloadFor: #().
	self assert: (payload at: 'max_tokens') equals: 99
]

{ #category : 'tests' }
ChatPharoToolBackendTest >> testGetResponseRecordsRequestDuration [

	| director history |
	director := ChatPharoSettings default ethicsDirector.
	director lastRequestDurationSeconds: -1.
	history := ChatPharoHistory new.
	tool getResponseForHistory: history.
	self assert: director lastRequestDurationSeconds >= 0
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testRequestTimeoutSecondsUsesEthicsDefaultWhenUnset [

	ChatPharoSettings default requestTimeoutSeconds: nil.
	self assert: tool requestTimeoutSeconds equals: 300
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testRequestTimeoutSecondsUsesEthicsTimeoutSetting [

	ChatPharoSettings default requestTimeoutSeconds: 12.
	self assert: tool requestTimeoutSeconds equals: 12
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testToolCallsFromMessageGeneratesHistorySaverToolCall [

    | message calls |
    tool tools: { echoClient }.
    message := Dictionary
        with: 'tool_calls' -> (Array with: (Dictionary
            with: 'id' -> 'call-1'
            with: 'function' -> (Dictionary
                with: 'name' -> 'echo'
                with: 'arguments' -> '{"value":5}'))).
    calls := tool toolCallsFromMessage: message.
    self assert: calls size equals: 1.
    self assert: calls first id equals: 'call-1'.
    self assert: calls first content equals: '{"value":5}'.
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testToolCallsFromMessageHandlesInvalidArgumentJson [

    | message calls |
    tool tools: { echoClient }.
    message := Dictionary
        with: 'tool_calls' -> (Array with: (Dictionary
            with: 'function' -> (Dictionary
                with: 'name' -> 'echo'
                with: 'arguments' -> '{invalid json}'))).
    calls := tool toolCallsFromMessage: message.
    self assert: calls size equals: 1.
    self assert: (calls first content includesSubstring: 'Invalid arguments').
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testToolCallsFromMessageParsesDictionaryArguments [

    | message calls |
    tool tools: { echoClient }.
    message := Dictionary
        with: 'tool_calls' -> (Array with: (Dictionary
            with: 'id' -> 'generated'
            with: 'function' -> (Dictionary
                with: 'name' -> 'echo'
                with: 'arguments' -> (Dictionary with: 'value' -> 7)))).
    calls := tool toolCallsFromMessage: message.
    self assert: calls size equals: 1.
    self assert: (calls first arguments) equals: '{"value":7}'.

]

{ #category : 'running' }
ChatPharoToolBackendTest >> testToolCallsFromMessageReturnsNilWhenNoToolCallsPresent [

    self assert: (tool toolCallsFromMessage: Dictionary new) isNil.
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testToolCallsFromMessageSuppliesGeneratedIdentifierWhenAbsent [

    | message calls |
    tool tools: { echoClient }.
    message := Dictionary
        with: 'tool_calls' -> (Array with: (Dictionary
            with: 'function' -> (Dictionary
                with: 'name' -> 'echo'
                with: 'arguments' -> '{"value":1}'))).
    calls := tool toolCallsFromMessage: message.
    self assert: (calls first id beginsWith: 'tool-').
]

{ #category : 'running' }
ChatPharoToolBackendTest >> testToolCallsFromMessageTriggersClientExecution [

    | message |
    tool tools: { echoClient }.
    message := Dictionary
        with: 'tool_calls' -> (Array with: (Dictionary
            with: 'id' -> 'call'
            with: 'function' -> (Dictionary
                with: 'name' -> 'echo'
                with: 'arguments' -> '{"value":2}'))).
    tool toolCallsFromMessage: message.
    self assert: tool appliedCalls size equals: 1.
]
