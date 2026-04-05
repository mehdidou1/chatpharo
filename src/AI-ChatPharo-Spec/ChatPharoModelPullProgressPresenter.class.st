"
Progress dialog for pulling/downloading Ollama models.
* Shows a progress bar while downloading model
* Displays current status (pulling, downloading, verifying)
* Cannot be closed until download is complete
* **Why** - provides visual feedback during model download process
```smalltalk
ChatPharoModelPullProgressPresenter pullModel: 'llama3.2:3b'.
"
Class {
	#name : 'ChatPharoModelPullProgressPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'progressBar',
		'statusLabel',
		'detailsLabel',
		'isComplete',
		'modelName',
		'onComplete',
		'onError'
	],
	#category : 'AI-ChatPharo-Spec-Agent',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Agent'
}

{ #category : 'api' }
ChatPharoModelPullProgressPresenter class >> pullModel: aModelName [
	"Open the progress dialog and pull the specified model."

	^ self new
		modelName: aModelName;
		openModal;
		yourself
]

{ #category : 'api' }
ChatPharoModelPullProgressPresenter class >> pullModel: aModelName onComplete: completeBlock onError: errorBlock [
	"Open the progress dialog, pull the model, then execute completion or error block."

	| presenter |
	presenter := self new.
	presenter modelName: aModelName.
	presenter onComplete: completeBlock.
	presenter onError: errorBlock.
	presenter openModal.
	^ presenter
]

{ #category : 'TOREMOVE' }
ChatPharoModelPullProgressPresenter >> askOkToClose [
	"Prevent closing while download is in progress."

	isComplete ifFalse: [
		self inform: 'Please wait for model download to complete.'.
		^ false ].
	^ true
]

{ #category : 'layout' }
ChatPharoModelPullProgressPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		spacing: 12;
		borderWidth: 20;
		add: titleLabel expand: false;
		add: progressBar expand: false;
		add: statusLabel expand: false;
		add: detailsLabel expand: false;
		yourself
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> formatBytes: bytes [
	"Format byte count as human-readable string (KB, MB, GB)."

	| kb mb gb |
	kb := 1024.
	mb := kb * 1024.
	gb := mb * 1024.

	bytes >= gb ifTrue: [ ^ (bytes / gb) asFloat printShowingDecimalPlaces: 2 , ' GB' ].
	bytes >= mb ifTrue: [ ^ (bytes / mb) asFloat printShowingDecimalPlaces: 2 , ' MB' ].
	bytes >= kb ifTrue: [ ^ (bytes / kb) asFloat printShowingDecimalPlaces: 2 , ' KB' ].
	^ bytes asString , ' bytes'
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> initialize [

	super initialize.
	isComplete := false.
	modelName := ''
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> initializePresenters [

	super initializePresenters.

	titleLabel := self newLabel
		label: 'Pulling Model';
		yourself.

	progressBar := self newProgressBar
		progress: 0;
		yourself.

	statusLabel := self newLabel
		label: 'Preparing to download...';
		yourself.

	detailsLabel := self newLabel
		label: '';
		yourself
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'Downloading Model';
		initialExtent: 450@180;
		centered
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> modelName [

	^ modelName
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> modelName: aString [

	modelName := aString ifNil: [ '' ] ifNotNil: [ aString trimBoth ]
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> onComplete: aBlock [
	"Set the block to execute when download is complete."

	onComplete := aBlock
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> onError: aBlock [
	"Set the block to execute when download fails."

	onError := aBlock
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> openModal [
	"Open as modal dialog and start pulling the model."

	| window |
	window := self open.
	self pullModel.
	^ window
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> parseProgressLine: line [
	"Parse a single JSON progress line from Ollama's streaming response.
	Returns a dictionary with status, completed, total, etc."

	| json |
	[ json := STONJSON fromString: line ]
		on: Error
		do: [ :ex | ^ nil ].
	^ json
]

{ #category : 'initialization' }
ChatPharoModelPullProgressPresenter >> pullModel [

  [
        | url client response progressStream
          currentProgress lastProgress
          totalBytes completedBytes isDone successSeen |

        isDone := false.
        successSeen := false.
        lastProgress := -1.
        client := nil.

        self defer: [
            titleLabel label: 'Pulling Model: ', modelName.
            statusLabel label: 'Connecting to Ollama server...'.
            progressBar progress: 0.0
        ].
        modelName ifEmpty: [
            self defer: [
                isComplete := true.
                statusLabel label: 'Error: missing model name.'.
                detailsLabel label: 'Please enter a model name and try again.'.
                progressBar progress: 0.
                1 second wait.
                self window close.
                onError ifNotNil: [ onError value: Error new ].
            ].
            ^ self
        ].
        url := 'http://', ChatPharoOllamaAgent defaultHost, ':',
               ChatPharoOllamaAgent defaultPort, '/api/pull'.
        client := ZnClient new
            url: url;
            entity: (ZnEntity with:
                (STONJSON toString: { (#name -> modelName) } asDictionary));
            contentType: 'application/json';
            streaming: true;
            "Generous timeout: large model pulls can have long silent
             phases (verify digest, slow CDN), which otherwise trip the
             default 60s socket timeout and cut the download."
            timeout: 3600;
            yourself.

        [
            [
                response := client post.
                progressStream := (response respondsTo: #readStream)
                    ifTrue: [ response readStream ]
                    ifFalse: [ response ].

                totalBytes := nil.
                completedBytes := 0.

                [ isDone or: [ progressStream atEnd ] ] whileFalse: [
                    | line progressData status errorMessage |

                    line := progressStream upTo: Character lf.

                    line ifNotEmpty: [
                        progressData := self parseProgressLine: line.

                        progressData ifNotNil: [
                            "Ollama reports per-line errors via an 'error' key."
                            errorMessage := progressData
                                at: 'error'
                                ifAbsent: [ nil ].
                            errorMessage ifNotNil: [
                                isDone := true.
                                (Error new messageText: errorMessage) signal ].

                            status := progressData
                                at: 'status'
                                ifAbsent: [ '' ].

                            "Handle success first"
                            (status = 'success') ifTrue: [
                                isDone := true.
                                successSeen := true.
                                self defer: [
                                    progressBar progress: 1.0.
                                    statusLabel label: 'Download complete!'.
                                    detailsLabel label:
                                        'Model ', modelName, ' is ready to use.'
                                ].
                            ].

                            "Handle byte progress"
                            (progressData includesKey: 'completed')
                                ifTrue: [
                                    completedBytes :=
                                        progressData at: 'completed'.
                                    totalBytes :=
                                        progressData at: 'total'
                                        ifAbsent: [ totalBytes ].

                                    totalBytes ifNotNil: [
                                        currentProgress :=
                                            (completedBytes / totalBytes) asFloat.

                                        "Only update if changed enough"
                                        ((currentProgress - lastProgress) abs > 0.01)
                                            ifTrue: [
                                                lastProgress := currentProgress.

                                                self defer: [
                                                    progressBar progress:
                                                        currentProgress.
                                                    statusLabel label:
                                                        status capitalized.
                                                    detailsLabel label:
                                                        (self formatBytes:
                                                            completedBytes),
                                                        ' / ',
                                                        (self formatBytes:
                                                            totalBytes),
                                                        ' (',
                                                        (currentProgress * 100)
                                                            rounded asString,
                                                        '%)'
                                                ].
                                            ].
                                    ].
                                ].
                        ].
                    ].
                ].

                "Stream ended. Only treat as success if Ollama actually
                 sent a 'success' status line; otherwise the download was
                 truncated and we must surface an error."
                successSeen
                    ifTrue: [
                        self defer: [
                            isComplete := true.
                            200 milliSeconds wait.
                            self window close.
                            onComplete ifNotNil: [ onComplete value ] ] ]
                    ifFalse: [
                        | truncationError |
                        truncationError := Error new
                            messageText:
                                'Download was interrupted before completion.';
                            yourself.
                        self defer: [
                            isComplete := true.
                            statusLabel label:
                                'Error: download interrupted.'.
                            detailsLabel label:
                                'The connection to Ollama closed before the model finished downloading. Please try again.'.
                            progressBar progress: 0.
                            1 second wait.
                            self window close.
                            onError ifNotNil: [ onError value: truncationError ] ] ]

            ] on: Error do: [ :ex |
                self defer: [
                    isComplete := true.
                    statusLabel label: 'Error: ', ex messageText.
                    detailsLabel label:
                        'Please verify the model name and your network, then try again.'.
                    progressBar progress: 0.
                    1 second wait.
                    self window close.
                    onError ifNotNil: [ onError value: ex ].
                ].
            ].
        ] ensure: [
            client ifNotNil: [ [ client close ] on: Error do: [ :e | ] ] ].
    ] fork
]
