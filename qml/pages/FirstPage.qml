import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // File-Loader
import QtMultimedia 5.0 // Audio Support
import io.thp.pyotherside 1.4

Page {
    id: page
    allowedOrientations: Orientation.Portrait //All
    property bool debug : false
    // file variables

    property string inputPathPy : decodeURIComponent( "/" + idAudioPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
    property string saveAudioFolderPath
    property string symbolSourceFolder : "/usr" + "/share" + "/harbour-audiocut" + "/qml" + "/symbols/"
    property string lastTmpAudio2delete
    property string lastTmpImage2delete
    property string origAudioFilePath
    property string origAudioFileName
    property string origAudioFolderPath
    property string origAudioName
    property string origAudioType
    property string homeDirectory
    property string tempAudioFolderPath: StandardPaths.home + '/.cache/de.poetaster/harbour-audiocut'
    property string tempAudioType : "wav"
    property string outputPathPy

    // UI variables
    property bool warningNoPydub : false
    property bool warningNoLAME : false
    property int undoNr : 0
    property bool finishedLoading : true
    property bool showTools : false
    property var handleSize : Theme.paddingLarge
    property var zoomAreaFactor : 5
    property bool audioPlaying : false
    property var minIntervallSpeedSystem : 50 //ms, timerintervall depending on system
    property var minIntervallPxFaktor //factor, by which the marker will jump if millisecondsPerPixelPython < minIntervallSpeedSystem
    property var clipboardAvailable : false
    property var hideMarkersPaste : (buttonCopyPaste.down && idComboBoxToolsCopyPaste.currentIndex != 0 ) ? true : false
    property var markersDiffExists : ( (toPosMillisecond - fromPosMillisecond) > 0 ) ? true : false

    // audio variables
    // careful: QML multimedia calculates audio duration different than Python and changes during playback -> correction factor for playback
    property var millisecondsPerPixelPython : 0
    property var millisecondsPerPixelQML : idAudioPlayer.duration / (idWaveformOverview.width * zoomAreaFactor)
    property var correctionFactorMsPx : millisecondsPerPixelPython / millisecondsPerPixelQML

    property var audioLengthSecondsPython : 0
    property var manualPixelstamp : Math.round( Math.abs(idImageWaveformZoom.x) + idMarkerAB.x + handleSize/2 )
    property var manualNowStamp : manualPixelstamp * millisecondsPerPixelPython
    property var fromPosPixel : 0
    property var toPosPixel : 0
    property var fromPosMillisecond : Math.round(fromPosPixel * millisecondsPerPixelPython)
    property var toPosMillisecond : Math.round(toPosPixel * millisecondsPerPixelPython)

    Component.onCompleted: {
        if(debug) console.debug(tempAudioFolderPath)
        py.getHomePath()
    }
    Timer {
        id: idTimerPlay
        running: false
        repeat: true
        //interval: ?? defined by audio file length and screen pixel, (not possible for intervalls < 20ms !!!)
        onTriggered:

            // case A = move only slider in zoom window (idMarkerAB)
            if ( ( (idMarkerAB.x + handleSize/2) < idWaveformZoom.width/2) || ((idMarkerRegion.x + idMarkerRegion.width) >= idWaveformOverview.width ) ) {
                //console.log("case A")
                if ( ((idMarkerAB.x + handleSize/2)+ ( 1 * minIntervallPxFaktor )) <= idWaveformZoom.width ) {
                    idMarkerAB.x = idMarkerAB.x + ( 1 * minIntervallPxFaktor )
                }
                if ( (idMarkerAB.x + handleSize/2 > (idWaveformOverview.width/2 + Theme.paddingLarge * 1.5 ) ) ) {
                    idMarkerPosText.reanchorToRight()
                }
            }
            // case B = move both at the same time
            else {
                //console.log("case B")
                if ( (idMarkerRegion.x + ( 1 / zoomAreaFactor * minIntervallPxFaktor )) <= idWaveformOverview.width ) {
                    idMarkerRegion.x = idMarkerRegion.x + ( 1 / zoomAreaFactor * minIntervallPxFaktor )
                }
                idImageWaveformZoom.x = idImageWaveformZoom.x - ( 1 * minIntervallPxFaktor )
            }
    }

    Timer {
        id: idTimerPreloadAudioOnce
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            idAudioPlayer.stop()
            idAudioPlayer.volume = 1.0
        }
    }

    Component {
       id: filePickerPage
       FilePickerPage {
           title: qsTr("Select audio file")
           nameFilters: [ '*.wav', '*.mp3', '*.flac', '*.ogg', '*.aac', '*.mp4' ]
           onSelectedContentPropertiesChanged: {
               origAudioFilePath = selectedContentProperties.filePath.toString()
               origAudioFileName = selectedContentProperties.fileName
               origAudioFolderPath = origAudioFilePath.replace(selectedContentProperties.fileName, "")
               var origAudioFileNameArray = origAudioFileName.split(".")
               origAudioName = (origAudioFileNameArray.slice(0, origAudioFileNameArray.length-1)).join(".")
               origAudioType = origAudioFileNameArray[origAudioFileNameArray.length - 1]
               autostart_getAudiolengthQML( origAudioFilePath )
               py.deleteAllTMPFunction()
               py.createWaveformImage()
               undoNr = 0
               stopPlayingResetWaveform()
               clearMarkerPos()
           }
       }
    }

    Audio {
        id: idAudioPlayer
        onStopped: {
            idTimerPlay.running = false
            audioPlaying = false
        }
    }

    RemorsePopup {
        id: remorse
    }


    // global python

    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../py'));
            importModule('audiox', function () {});

            // Handlers do something to QML whith received Infos from Pythonfile (=pyotherside.send)
            setHandler('homePathFolder', function( homeDir ) {
                tempAudioFolderPath = homeDir + "/.cache/de.poetaster/harbour-audiocut/"
                saveAudioFolderPath = homeDir + "/Music/"
                homeDirectory = homeDir
                //py.createTmpAndSaveFolder(tempAudioFolderPath, saveAudioFolderPath )
                py.createTmpAndSaveFolder( )
                py.deleteAllTMPFunction(tempAudioFolderPath)
            });
            setHandler('warningPydubNotAvailable', function() {
                warningNoPydub = true
            });
            setHandler('warningLameNotAvailable', function() {
                warningNoLAME = true
            });
            setHandler('loadImageWaveform', function(outputWaveformImagePath, audioLengthMillisecondsPython) {
                idImageWaveform.source = outputWaveformImagePath
                idImageWaveformZoom.source = outputWaveformImagePath
                audioLengthSecondsPython = audioLengthMillisecondsPython / 1000
                millisecondsPerPixelPython = (audioLengthMillisecondsPython / (idWaveformOverview.width * zoomAreaFactor) )
                finishedLoading = true
                showTools = true
                calculatePlayerPixelSpeed()
                stopPlayingResetWaveform()
            });
            setHandler('loadTempAudio', function( newFilePath ) {
                idAudioPlayer.source = newFilePath
                fromPosPixel = 0
                toPosPixel = 0
                autostart_getAudiolengthQML( newFilePath )
                py.createWaveformImage()
            });
            setHandler('finishedSavingRenaming', function( newFilePath, newFileName, newFileType ) {
                idAudioPlayer.source = newFilePath
                origAudioFilePath = newFilePath
                origAudioFileName = newFileName + "." + newFileType
                origAudioFolderPath = origAudioFilePath.replace(origAudioFileName, "")
                var origAudioFileNameArray = origAudioFileName.split(".")
                origAudioName = (origAudioFileNameArray.slice(0, origAudioFileNameArray.length-1)).join(".")
                origAudioType = origAudioFileNameArray[origAudioFileNameArray.length - 1]
                undoNr = 0
                py.createWaveformImage()
            });
            setHandler('deletedFile', function() {
                origAudioFilePath = ""
                origAudioFileName = ""
                origAudioFolderPath = ""
                origAudioType = ""
                origAudioName = ""
                idAudioPlayer.source = ""
                idImageWaveform.source = ""
                idImageWaveformZoom.source = ""
                audioLengthSecondsPython = 0
                millisecondsPerPixelPython = 0
                showTools = false
            });
            setHandler('deleteLastTmp', function() {
                finishedLoading = true
                showTools = true
            });
            setHandler('getAudioLenghtPy', function(audioLengthMillisecondsPython) {
                audioLengthSecondsPython = audioLengthMillisecondsPython / 1000
                millisecondsPerPixelPython = (audioLengthMillisecondsPython / (idWaveformOverview.width * zoomAreaFactor) )
                autostart_getAudiolengthQML( decodeURIComponent( "/" + idAudioPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") ) )
            });
            setHandler('copiedToClipboard', function() {
                clipboardAvailable = true
            });
        }

        // file operations
        function getHomePath() {
            call("audiox.getHomePath", [])
        }

        function createTmpAndSaveFolder() {
            call("audiox.createTmpAndSaveFolder", [ tempAudioFolderPath, saveAudioFolderPath ])
        }
        function deleteAllTMPFunction() {
            undoNr = 0
            call("audiox.deleteAllTMPFunction", [ tempAudioFolderPath ])
        }
        function deleteLastTMPFunction() {
            console.log(lastTmpAudio2delete)
            console.log(lastTmpImage2delete)
            call("audiox.deleteLastTmpFunction", [ lastTmpAudio2delete, lastTmpImage2delete ])
        }
        function deleteFile() {
            stopPlayingResetWaveform()
            py.deleteAllTMPFunction()
            call("audiox.deleteFile", [ origAudioFilePath ])
        }
        function renameOriginal() {
            stopPlayingResetWaveform()
            py.deleteAllTMPFunction()
            var newFilePath = origAudioFolderPath + idFilenameRenameText.text + "." + origAudioType
            var newFileName = idFilenameRenameText.text
            var newFileType = origAudioType
            call("audiox.renameOriginal", [ origAudioFilePath, newFilePath, newFileName, newFileType ])
        }
        function createWaveformImage() {
            finishedLoading = false
            idImageWaveform.source = ""
            idImageWaveformZoom.source = ""
            var outputWaveformImagePath =  tempAudioFolderPath + "waveform" + ".tmp" + undoNr + ".png"
            if (debug == true) console.debug(inputPathPy)
            if (debug == true) console.debug(outputWaveformImagePath)
            var waveformColor = "yellow"
            var stretch = "" //"compand,"
            var waveformPixelLength = idWaveformOverview.width * zoomAreaFactor
            var waveFormpixelHeight = idWaveformZoom.height //120
            call("audiox.createWaveformImage", [inputPathPy, outputWaveformImagePath, waveformColor, waveformPixelLength, waveFormpixelHeight, stretch])
        }
        function getAudioLengthPy() {
            var tempAudioFilePath = decodeURIComponent( "/" + idAudioPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
            call("audiox.getAudioLength", [ tempAudioFilePath ])
        }
        function copyToClipboard() {
            outputPathPy = tempAudioFolderPath + "audio" + ".tmp" + undoNr + "." + tempAudioType
            call("audiox.copyToClipboard", [ inputPathPy, fromPosMillisecond, toPosMillisecond ])
        }
        function pasteFromClipboard(pasteType) {
            var pasteHere = manualNowStamp
            preparePathAndUndo()
            call("audiox.pasteFromClipboard", [ inputPathPy, outputPathPy, tempAudioType, pasteHere, pasteType ])
        }



        // audio manipulations
        function cutRemove() {
            preparePathAndUndo()
            call("audiox.cutRemove", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
        }
        function cutExtract() {
            preparePathAndUndo()
            call("audiox.cutExtract", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
        }
        function paddingSilence(){
            var padHere = manualNowStamp
            var durationSilence = idSliderPaddingDuration.value * 1000
            if (idComboPadding.currentIndex === 0) {
                var positionSilence = "beginning"
            }
            if (idComboPadding.currentIndex === 1) {
                positionSilence = "end"
            }
            if (idComboPadding.currentIndex === 2) {
                positionSilence = "cursor"
            }
            preparePathAndUndo()
            call("audiox.paddingSilence", [ inputPathPy, outputPathPy, tempAudioType, padHere, positionSilence, durationSilence ])
        }

        function volumeChange() {
            preparePathAndUndo()
            var changeDB = idVolumeSlider.value
            call("audiox.volumeChange", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, changeDB ])
        }
        function volumeFadeIn() {
            preparePathAndUndo()
            call("audiox.volumeFadeIn", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
        }
        function volumeFadeOut() {
            preparePathAndUndo()
            call("audiox.volumeFadeOut", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
        }
        function volumeSilence() {
            preparePathAndUndo()
            var changeDB = -120
            call("audiox.volumeChange", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, changeDB ])
        }
        function speedChange() {
            preparePathAndUndo()
            var factorSpeed = idSpeedSlider.value
            if (idComboBoxSpeedPitch.currentIndex === 0) {
                var keepPitch = "false"
                call("audiox.speedChange", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, factorSpeed, keepPitch ])
            }
            else {
                keepPitch = "true"
                call("audiox.slowDown", [ inputPathPy, outputPathPy, tempAudioType, factorSpeed ])
            }
            //console.log(keepPitch)
            //console.log(factorSpeed)
            //call("audiox.speedChange", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, factorSpeed, keepPitch ])
        }
        function reverseAudio() {
            preparePathAndUndo()
            call("audiox.reverseAudio", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
        }
        function denoiseAudio() {
            preparePathAndUndo()
            if (idComboDenoiseType === 0) {
                var filterType = "afftdn"
            }
            if (idComboDenoiseType === 1) {
                filterType = "anlmdn"
            }
            call("audiox.denoiseAudio", [ inputPathPy, outputPathPy, tempAudioType, filterType ])
        }
        function trimSilence() {
            preparePathAndUndo()
            var breakMS = idSliderSilenceDuration.value * 1000 // 1000 ms
            var breakDB = idSliderSilenceDB.value // -16...-25 dB
            var breakPadding = 100 //ms
            call("audiox.trimSilence", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, breakMS, breakDB, breakPadding ])
            //call("audiox.trimSilence", [ inputPathPy, outputPathPy, tempAudioType, breakMS, breakDB ])
        }
        function echoEffect() {
            preparePathAndUndo()
            if (idSliderEchoType.currentIndex === 0) { // double instruments
                var in_gain = 0.8
                var out_gain = 0.88
                var delays = 60
                var decays = 0.4
            }
            else if (idSliderEchoType.currentIndex === 1) { // mountain concert
                in_gain = 0.8
                out_gain = 0.9
                delays = 1000
                decays = 0.3
            }
            else { // robot style
                in_gain = 0.8
                out_gain = 0.88
                delays = 6
                decays = 0.4
            }
            call("audiox.echoEffect", [ inputPathPy, outputPathPy, tempAudioType, in_gain, out_gain, delays, decays ])
        }
        function lowPassFilter() {
            preparePathAndUndo()
            var filterFrequency = idFilterFrequencyText.text
            var filterOrder = 1 // ...4
            call("audiox.lowPassFilter", [ inputPathPy, outputPathPy, tempAudioType, filterFrequency, filterOrder ])
        }
        function highPassFilter() {
            preparePathAndUndo()
            var filterFrequency = idFilterFrequencyText.text
            var filterOrder = 1 // ...4
            call("audiox.highPassFilter", [ inputPathPy, outputPathPy, tempAudioType, filterFrequency, filterOrder ])
        }

        // https://ffmpeg.org/ffmpeg-filters.html#flanger
        function flangerEffect() {
            preparePathAndUndo()
            var speed = flanger.speed // 0.1 - 10 Hz
            var delay = flanger.delay // 0-30
            var depth = flanger.depth // 0 - 10
            var phase = flanger.phase // 0 - 100
            var regen = 5 // -95 - 95
            //shape // sinusoidal / triangular
            // width // 0-100 71 default
            call("audiox.flangerEffect", [ inputPathPy, outputPathPy, tempAudioType, speed, depth, phase, delay, regen ])
        }

        // https://ffmpeg.org/ffmpeg-filters.html#aphaser
        function phaserEffect() {
            preparePathAndUndo()
            var in_gain = 0.5
            var out_gain = 0.75
            var speed = phaser.speed // 0.1 - 10 Hz
            var delay = phaser.delay // 0-30
            var decay = phaser.decay // 0 - 10
            //shape // sinusoidal / triangular
            // width // 0-100 71 default
            call("audiox.phaserEffect", [ inputPathPy, outputPathPy, tempAudioType, in_gain, out_gain, delay, decay, speed ])
        }
        // https://ffmpeg.org/ffmpeg-filters.html#achorus
        function chorusEffect() {
            preparePathAndUndo()
            var in_gain = 0.5
            var out_gain = 0.90
            var speed = chorus.speed // 0.1 - 10 Hz
            var delay = chorus.delay // 0-30
            var decay = chorus.decay // 0 - 10
            var depth = chorus.depth // 0 - 10
            //shape // sinusoidal / triangular
            // width // 0-100 71 default
            call("audiox.chorusEffect", [ inputPathPy, outputPathPy, tempAudioType, delay, decay, speed, depth ])
        }

        onError: {
            // when an exception is raised, this error handler will be called
            console.log('python error: ' + traceback);
        }
        onReceived: {
            // asychronous messages from Python arrive here via pyotherside.send()
            console.log('got message from python: ' + data);
        }
    } // end python

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                enabled: ( warningNoPydub === false )
                text: qsTr("Info")
                onClicked: {
                    idAudioPlayer.stop()
                    pageStack.push(Qt.resolvedUrl("About.qml"), {} )
                }
            }
            MenuItem {
                enabled: ( warningNoPydub === false )
                text: qsTr("Files")
                onClicked: {
                    idAudioPlayer.stop()
                    pageStack.push(filePickerPage)
                }
            }
            MenuItem {
                enabled: (warningNoPydub === false && showTools === true)
                text: qsTr("Save")
                onClicked: {
                    idAudioPlayer.stop()
                    pageStack.push(Qt.resolvedUrl("SavePage.qml"), {
                        homeDirectory : homeDirectory,
                        origAudioFilePath : origAudioFilePath,
                        origAudioFileName : origAudioFileName,
                        origAudioFolderPath : origAudioFolderPath,
                        origAudioName : origAudioName,
                        origAudioType : origAudioType,
                        tempAudioFolderPath : tempAudioFolderPath,
                        tempAudioType : tempAudioType,
                        warningNoLAME : warningNoLAME,
                        inputPathPy : idAudioPlayer.source.toString()
                    } )
                }
            }
        }

        Column {
            id: column
            width: page.width



            SectionHeader {
                id: idSectionHeader
                height: idSectionHeaderColumn.height
                Column {
                    id: idSectionHeaderColumn
                    width: parent.width / 5 * 4
                    height: idLabelProgramName.height + idLabelFilePath.height
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    anchors.right: parent.right
                    Label {
                        id: idLabelProgramName
                        width: parent.width
                        anchors.right: parent.right
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.primaryColor
                        text: qsTr("Audioworks")
                    }
                    Label {
                        id: idLabelFilePath
                        width: parent.width
                        anchors.right: parent.right
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.primaryColor
                        truncationMode: TruncationMode.Elide
                        text: (warningNoPydub === true) ? qsTr("python3-pydub is not installed") : origAudioFilePath
                    }
                }
                IconButton {
                    id: idIconUndoButton
                    width: (parent.width - 2*Theme.paddingLarge) / 5
                    height: idLabelProgramName.height + idLabelFilePath.height
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    anchors.left: parent.left
                    enabled: ( undoNr >= 1 && finishedLoading === true ) ? true : false
                    visible: ( enabled === true ) ? true : false
                    Image {
                        id: idUndoAudio
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: Theme.paddingSmall/2
                        fillMode: Image.PreserveAspectFit
                        source: "../symbols/icon-m-undo.svg"
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        scale: 1.5
                    }
                    Label {
                        anchors.horizontalCenter: idUndoAudio.horizontalCenter
                        anchors.verticalCenter: idUndoAudio.verticalCenter
                        font.pixelSize: Theme.fontSizeTiny
                        text: undoNr
                    }
                    onClicked: {
                        undoBackwards()
                    }
                }
                BusyIndicator {
                    anchors.left: parent.left
                    anchors.verticalCenter: idIconUndoButton.verticalCenter
                    anchors.verticalCenterOffset: Theme.paddingSmall/2
                    running: (finishedLoading === true) ? false : true
                    size: BusyIndicatorSize.Medium
                }
            }
            Rectangle {
                width: parent.width
                height: 2 * Theme.paddingLarge
                color: "transparent"
            }



            Row {
                id: idTimeInfoRow
                visible: ( showTools === true )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                Label {
                    width: parent.width / 5
                    anchors.baseline: idCurrentPosition.baseline
                    horizontalAlignment: Text.AlignLeft
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeTiny
                    text: "00:00:00"
                        //+ "\n" + millisecondsPerPixelPython + " ms/pxPy"
                        //+ "\n" + millisecondsPerPixelQML + " ms/pxQt"
                        //+ "\n" + idTimerPlay.interval + " ms/pxPlayer"
                }
                Label {
                    id: idCurrentPosition
                    width: parent.width / 5 * 3
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.secondaryHighlightColor
                    text: (showTools === true ) ? ( "< " + new Date(idAudioPlayer.position * correctionFactorMsPx).toISOString().substr(11,8) + " >" )  : "none"
                        // + "\n" + (idAudioPlayer.position / 1000.0) + " sec"
                        // + "\n" + manualPixelstamp + " px"
                }
                Label {
                    id: idAudioDurationLabel
                    width: parent.width / 5
                    anchors.baseline: idCurrentPosition.baseline
                    horizontalAlignment: Text.AlignRight
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeTiny
                    text: new Date(audioLengthSecondsPython*1000).toISOString().substr(11,8) //take only digits 11...23 from iso string, which is the time without date infos
                        //+ "\n" + audioLengthSecondsPython + " secPy"
                        //+ "\n" + idAudioPlayer.duration / 1000 + " secQt"
                }
            }



            Item {
                id: idWaveformOverview
                visible: ( showTools === true )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                height: Theme.itemSizeLarge

                Image {
                    id: idImageWaveform
                    height: parent.height
                    width: parent.width
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    Rectangle {
                        id: idFromTillRegionOverview
                        visible: (buttonEffects.down === false && buttonFile.down === false && hideMarkersPaste === false )
                        x: fromPosPixel / zoomAreaFactor
                        width: (toPosPixel - fromPosPixel) / zoomAreaFactor
                        height: parent.height / 8
                        z: -5
                        color: Theme.errorColor
                        opacity: 0.5
                    }
                }

                Rectangle {
                    id: idMarkerRegion
                    x: 0
                    y: 0
                    z: -1
                    width: parent.width / zoomAreaFactor
                    height: parent.height
                    color: Theme.highlightColor
                    opacity: 0.25
                    MouseArea {
                        id: dragMarkerRegion
                        preventStealing: true
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: idWaveformOverview.width - parent.width
                        onMouseXChanged: idImageWaveformZoom.x = - (parent.x * zoomAreaFactor)
                        onEntered: {
                            idAudioPlayer.pause()
                            idTimerPlay.running = false
                        }
                        onReleased: {
                            if (audioPlaying === true) {
                                var playFromMillisecond = Math.round(manualNowStamp / correctionFactorMsPx) //correctionFactorMsPx
                                idAudioPlayer.seek(playFromMillisecond)
                                idAudioPlayer.play()
                                idTimerPlay.running = true
                            }
                        }
                    }
                }


            } // end idWaveformOverview

            Item {
                id: idWaveformZoom
                visible: ( showTools === true )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                height: Theme.itemSizeLarge

                Rectangle {
                    id: idBackgroundFillerZoom
                    anchors.fill: parent
                    color: Theme.highlightColor
                    opacity: 0.25
                    z: -1
                }

                Item {
                    width: parent.width
                    height: Theme.itemSizeLarge
                    clip: true
                    Image {
                        id: idImageWaveformZoom
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        Rectangle {
                            id: idFromTillRegionZoom
                            visible: (buttonEffects.down === false && buttonFile.down === false && hideMarkersPaste === false )
                            x: fromPosPixel
                            width: (toPosPixel - fromPosPixel)
                            height: parent.height
                            z: -5
                            color: Theme.errorColor
                            opacity: 0.5
                        }
                    }
                 }

                Rectangle {
                    id: idMarkerAB
                    x: -handleSize/2
                    width: handleSize
                    height: parent.height
                    color: "transparent"

                    Rectangle {
                        width: 1
                        height: idBackgroundFillerZoom.height
                        anchors.centerIn: parent
                        color: Theme.primaryColor
                    }
                    Rectangle {
                        width: handleSize
                        height: handleSize
                        color: Theme.primaryColor
                        radius: handleSize
                        anchors.verticalCenter: parent.top
                    }
                    Rectangle {
                        width: handleSize
                        height: handleSize
                        color: Theme.primaryColor
                        radius: handleSize
                        anchors.verticalCenter: parent.bottom
                    }
                    MouseArea {
                        preventStealing: true
                        anchors.fill: parent
                        anchors.leftMargin: -5*Theme.paddingLarge
                        anchors.rightMargin: -5*Theme.paddingLarge
                        anchors.topMargin: -Theme.paddingLarge
                        anchors.bottomMargin: -Theme.paddingLarge
                        drag.target: parent
                        drag.axis: Drag.XAxis
                        drag.minimumX: -parent.width/2
                        drag.maximumX: idWaveformZoom.width - parent.width/2
                        onEntered: {
                            idAudioPlayer.pause()
                            idTimerPlay.running = false
                        }
                        onReleased: {
                            if (audioPlaying === true) {
                                var playFromMillisecond = Math.round(manualNowStamp / correctionFactorMsPx) //correctionFactorMsPx
                                idAudioPlayer.seek(playFromMillisecond)
                                idAudioPlayer.play()
                                idTimerPlay.running = true
                            }
                        }
                        onMouseXChanged: {
                            if ( (idMarkerAB.x + handleSize/2 > (idWaveformOverview.width/2 + Theme.paddingLarge * 1.5 ) ) ) {
                                idMarkerPosText.reanchorToRight()
                            }
                            else if ( (idMarkerAB.x + handleSize/2 < (idWaveformOverview.width/2 - Theme.paddingLarge * 1.5) ) ) {
                                idMarkerPosText.reanchorToLeft()
                            }
                        }
                    }
                    Label {
                        id: idMarkerPosText
                        anchors.top: parent.bottom
                        anchors.topMargin: Theme.paddingMedium
                        anchors.left : parent.left
                        anchors.leftMargin : Theme.paddingSmall
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeTiny
                        function reanchorToRight() {
                            anchors.left = undefined
                            anchors.leftMargin = undefined
                            anchors.right = parent.right
                            anchors.rightMargin = Theme.paddingSmall
                        }
                        function reanchorToLeft() {
                            anchors.rightMargin = undefined
                            anchors.leftMargin = Theme.paddingSmall
                            anchors.right = undefined
                            anchors.left = parent.left
                        }
                        text: new Date(manualNowStamp).toISOString().substr(11,12)
                    }
                }
            } // end idWaveformZoom
            Rectangle {
                visible: ( showTools === true )
                width: parent.width
                height: 3 * Theme.paddingLarge
                color: "transparent"
            }



            Row {
                id: idPlayPauseMarkerRow
                visible: ( showTools === true )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                height: Theme.itemSizeLarge

                IconButton {
                    height: parent.height
                    width: parent.width / 5
                    icon.source : (buttonEffects.down !== true && buttonFile.down !== true && hideMarkersPaste !== true) ? "../symbols/icon-m-marker.svg" : ""
                    icon.height: Theme.iconSizeMedium * 1.1
                    icon.width: Theme.iconSizeMedium * 1.1
                    onClicked: {
                        if ( fromPosPixel === 0 && toPosPixel === 0) {
                            fromPosPixel = manualPixelstamp
                            toPosPixel = manualPixelstamp
                        }
                        else {
                            var oldToPosPixel = toPosPixel
                            var oldFromPosPixel = fromPosPixel
                            fromPosPixel = manualPixelstamp
                            if (fromPosPixel > toPosPixel) {
                                fromPosPixel = oldToPosPixel
                                toPosPixel = manualPixelstamp
                            }
                        }
                    }
                    onPressAndHold: {
                        fromPosPixel = 0
                    }
                }
                Label {
                    width: parent.width/5
                    height: parent.height
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.errorColor
                    text: (buttonEffects.down === true || buttonFile.down === true || hideMarkersPaste === true ) ? "" : new Date(fromPosMillisecond).toISOString().substr(11,12)
                }
                IconButton {
                    height: parent.height
                    width: parent.width / 5
                    icon.source: (audioPlaying === false) ? "image://theme/icon-m-play?" : "image://theme/icon-m-pause?"
                    icon.width: Theme.iconSizeLarge
                    icon.height: Theme.iconSizeLarge
                    onClicked: {
                        if (audioPlaying === false) {
                            var playFromMillisecond = Math.round(manualNowStamp / correctionFactorMsPx) //correctionFactorMsPx
                            idAudioPlayer.seek(playFromMillisecond)
                            idAudioPlayer.play()
                            audioPlaying = true
                            idTimerPlay.running = true
                        }
                        else {
                            idAudioPlayer.pause()
                            audioPlaying = false
                            idTimerPlay.running = false
                        }
                    }
                    onPressAndHold: {
                        stopPlayingResetWaveform()
                        idTimerPlay.running = false
                    }
                }
                Label {
                    width: parent.width/5
                    height: parent.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.errorColor
                    text: (buttonEffects.down === true || buttonFile.down === true || hideMarkersPaste === true ) ? "" : new Date(toPosMillisecond).toISOString().substr(11,12)
                }
                IconButton {
                    height: parent.height
                    width: parent.width / 5
                    icon.source : (buttonEffects.down !== true && buttonFile.down !== true && hideMarkersPaste !== true) ? "../symbols/icon-m-marker.svg" : ""
                    icon.height: Theme.iconSizeMedium * 1.1
                    icon.width: Theme.iconSizeMedium * 1.1
                    onClicked: {
                        var oldToPosPixel = toPosPixel
                        var oldFromPosPixel = fromPosPixel
                        toPosPixel = manualPixelstamp
                        if (toPosPixel < fromPosPixel) {
                            toPosPixel = oldFromPosPixel
                            fromPosPixel = manualPixelstamp
                        }
                    }
                    onPressAndHold: {
                        toPosPixel = idImageWaveformZoom.sourceSize.width
                    }
                }

            } // end idPlayPauseMarkerRow
            Rectangle {
                width: parent.width
                height: 2 * Theme.paddingLarge
                color: "transparent"
            }

            Row {
                id: idToolsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                IconButton {
                    id: buttonCut
                    icon.opacity: 1
                    down: true
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "../symbols/icon-m-cut.svg"
                    icon.width: Theme.iconSizeMedium * 1.1
                    icon.height: Theme.iconSizeMedium * 1.1
                    onClicked: {
                        buttonCut.down = true
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = false
                    }
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }
                IconButton {
                    id: buttonVolume
                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "image://theme/icon-m-speaker?"
                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = true
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = false
                    }
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }
                IconButton {
                    id: buttonSpeed
                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "../symbols/icon-m-speed.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = true
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = false
                    }
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }
                IconButton {
                    id: buttonCopyPaste
                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "image://theme/icon-m-clipboard?" // "../symbols/icon-m-effects.svg"
                    icon.width: Theme.iconSizeMedium * 1.35
                    icon.height: Theme.iconSizeMedium * 1.35
                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = true
                        buttonEffects.down = false
                        buttonFile.down = false
                    }
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                    Rectangle {
                        visible: (clipboardAvailable === true)
                        anchors.centerIn: parent
                        height: parent.height / 10
                        width: parent.width / 10
                        color: Theme.errorColor // primaryColor
                    }
                }
                IconButton {
                    id: buttonEffects
                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "../symbols/icon-m-effects.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = true
                        buttonFile.down = false
                    }
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }
                IconButton {
                    id: buttonFile
                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-file-document-light?"
                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = true
                    }
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }
            } // end ToolsRow
            Rectangle {
                width: parent.width
                height: 2 * Theme.paddingLarge
                color: "transparent"
            }



            Row {
                id: idSubmenuCut
                visible: buttonCut.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxToolsCut
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("remove (trim marked)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("extract (trim unmarked)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("add silence")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsCut.currentIndex === 0) {
                            py.cutRemove()
                        }
                        if (idComboBoxToolsCut.currentIndex === 1) {
                            py.cutExtract()
                        }
                        if (idComboBoxToolsCut.currentIndex === 2) {
                            py.paddingSilence()
                        }
                    }
                }
            }
            ComboBox {
                id: idComboPadding
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonCut.down && idComboBoxToolsCut.currentIndex === 2 )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("at beginning")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("at end")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("at cursor")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }
            Slider {
                id: idSliderPaddingDuration
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonCut.down && idComboBoxToolsCut.currentIndex === 2 )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 5
                smooth: true
                stepSize: 0.5
                minimumValue: 0.5
                maximumValue: 60
                Label {
                    text: parent.value + qsTr(" sec duration")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }


            Row {
                id: idSubmenuVolume
                visible: buttonVolume.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxToolsVolume
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("volume -/+")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("fade in")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("fade out")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("silence")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsVolume.currentIndex === 0) {
                            py.volumeChange()
                        }
                        if (idComboBoxToolsVolume.currentIndex === 1) {
                            py.volumeFadeIn()
                        }
                        if (idComboBoxToolsVolume.currentIndex === 2) {
                            py.volumeFadeOut()
                        }
                        if (idComboBoxToolsVolume.currentIndex === 3) {
                            py.volumeSilence()
                        }
                    }
                }
            }
            Slider {
                id: idVolumeSlider
                enabled: ( finishedLoading === true && showTools === true )
                visible: (buttonVolume.down && idComboBoxToolsVolume.currentIndex === 0)
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 0
                smooth: true
                stepSize: 0.5
                minimumValue: -15
                maximumValue: +15
                Label {
                    text: (parent.value > 0) ? ("+" + parent.value + " " + qsTr(" dB")) : (parent.value + " " + qsTr(" dB"))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }


            Row {
                id: idSubmenuSpeed
                visible: buttonSpeed.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxSpeedPitch
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("speed - ignore pitch")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("speed - keep pitch")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("reverse (backwards)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxSpeedPitch.currentIndex === 0) {
                            py.speedChange()
                        }
                        if (idComboBoxSpeedPitch.currentIndex === 1) {
                            py.speedChange()
                        }
                        if (idComboBoxSpeedPitch.currentIndex === 2) {
                            py.reverseAudio()
                        }

                    }
                }
            }
            Slider {
                id: idSpeedSlider
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonSpeed.down && ( idComboBoxSpeedPitch.currentIndex === 0 || idComboBoxSpeedPitch.currentIndex === 1) )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 1
                smooth: true
                stepSize: 0.05
                minimumValue: 0.5 //(idComboBoxSpeedPitch.currentIndex === 0) ? 0.5 : 1 // pydub can not keep pitch when slower than usual
                maximumValue: 2
                Label {
                    text: qsTr("x ") + parent.value
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }


            Row {
                id: idSubmenuCopyPaste
                visible: buttonCopyPaste.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxToolsCopyPaste
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("copy")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: (clipboardAvailable === true)
                            text: qsTr("paste (insert)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: (clipboardAvailable === true)
                            text: qsTr("paste (replace)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: (clipboardAvailable === true)
                            text: qsTr("paste (overlay)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsCopyPaste.currentIndex === 0) {
                            py.copyToClipboard()
                        }
                        if (idComboBoxToolsCopyPaste.currentIndex === 1) {
                           py.pasteFromClipboard("add")
                        }
                        if (idComboBoxToolsCopyPaste.currentIndex === 2) {
                           py.pasteFromClipboard("replace")
                        }
                        if (idComboBoxToolsCopyPaste.currentIndex === 3) {
                           py.pasteFromClipboard("overlay")
                        }
                    }
                }
            }


            Row {
                id: idSubmenuEffects
                visible: buttonEffects.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxToolsEffects
                    width: parent.width / 5 * 4 // 6?
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("denoise")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("trim silence")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("echo effect")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("low-pass filter")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("high-pass filter")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("flanger")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("phaser")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("chorus")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true && idFilterFrequencyText.text !== "" )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsEffects.currentIndex === 0) {
                            py.denoiseAudio()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 1) {
                            py.trimSilence()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 2) {
                            py.echoEffect()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 3) {
                            py.lowPassFilter()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 4) {
                            py.highPassFilter()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 5) {
                            py.flangerEffect()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 6) {
                            py.phaserEffect()
                        }
                        if (idComboBoxToolsEffects.currentIndex === 7) {
                            py.chorusEffect()
                        }
                    }
                }
            }
            ComboBox {
                id: idComboDenoiseType
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 0 )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("type 1")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("type 2")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }
            ComboBox {
                id: idSliderEchoType
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 2 )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("double instruments")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("mountain concert")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("robot style")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }
            Slider {
                id: idSliderSilenceDB
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: -16
                smooth: true
                stepSize: 1
                minimumValue: -50
                maximumValue: 0
                Label {
                    text: parent.value + qsTr(" dB threshold")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            Slider {
                id: idSliderSilenceDuration
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 5
                smooth: true
                stepSize: 0.5
                minimumValue: 0.5
                maximumValue: 60
                Label {
                    text: parent.value + qsTr(" sec duration")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            TextField {
                id: idFilterFrequencyText
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && (idComboBoxToolsEffects.currentIndex === 3 || idComboBoxToolsEffects.currentIndex === 4 ) )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                inputMethodHints: Qt.ImhDigitsOnly
                text: "1000"
                label: qsTr("cutoff frequency (Hz)")
                EnterKey.onClicked: idFilterFrequencyText.focus = false
                validator: IntValidator {
                    bottom: 0
                    top: 20000
                }
            }
            Flanger{
                id: flanger
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 5  )
                anchors.top: idSubmenuEffects.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            }
            Phaser{
                id: phaser
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 6  )
                anchors.top: idSubmenuEffects.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            }
            Chorus{
                id: chorus
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 7  )
                anchors.top: idSubmenuEffects.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            }


            Row {
                id: idSubmenuFile
                visible: buttonFile.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxToolsFile
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("rename")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("delete")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsFile.currentIndex === 0) {
                            py.renameOriginal()
                        }
                        if (idComboBoxToolsFile.currentIndex === 1) {
                            remorse.execute( qsTr("Delete file?"),  py.deleteFile )
                        }
                    }
                }
            }
            TextField {
                id: idFilenameRenameText
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonFile.down && idComboBoxToolsFile.currentIndex === 0 )
                width: parent.width
                //height: Theme.itemSizeLarge * 1.15
                inputMethodHints: Qt.ImhNoPredictiveText
                text: origAudioName
                horizontalAlignment: TextEdit.AlignHCenter
                EnterKey.onClicked: idFilenameRenameText.focus = false
                validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
            }






        } // end column

    } // end flickable





    function preparePathAndUndo() {
        showTools = false
        idAudioPlayer.stop()
        finishedLoading = false
        idImageWaveform.source = ""
        idImageWaveformZoom.source = ""
        undoNr = undoNr + 1
        outputPathPy = tempAudioFolderPath + "audio" + ".tmp" + undoNr + "." + tempAudioType
        stopPlayingResetWaveform()
    }


    function autostart_getAudiolengthQML( pathTo ) {
        idAudioPlayer.volume = 0
        idAudioPlayer.source = pathTo //origAudioFilePath
        idAudioPlayer.play()
        idTimerPreloadAudioOnce.running = true
    }


    function calculatePlayerPixelSpeed() {
        if (millisecondsPerPixelPython < minIntervallSpeedSystem) {
            idTimerPlay.interval = minIntervallSpeedSystem
            minIntervallPxFaktor = minIntervallSpeedSystem / millisecondsPerPixelPython
        }
        else {
            idTimerPlay.interval = millisecondsPerPixelPython
            minIntervallPxFaktor = 1
        }
    }


    function stopPlayingResetWaveform() {
        idAudioPlayer.stop()
        audioPlaying = false
        idMarkerRegion.x = 0
        idMarkerAB.x = -handleSize/2
        idImageWaveformZoom.x = 0
        idMarkerPosText.reanchorToLeft()
    }


    function clearMarkerPos() {
        console.log("ToDo")
    }


    function undoBackwards() {
        idAudioPlayer.stop()
        finishedLoading = false
        showTools = false
        undoNr = undoNr - 1
        lastTmpAudio2delete = decodeURIComponent( "/" + idAudioPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
        lastTmpImage2delete = decodeURIComponent( "/" + idImageWaveform.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
        if (undoNr <= 0) {
            undoNr = 0
            idAudioPlayer.source = encodeURI(origAudioFilePath)
        }
        else {
            idAudioPlayer.source = idAudioPlayer.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))
        }
        idImageWaveform.source = idImageWaveform.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))
        idImageWaveformZoom.source = idImageWaveformZoom.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))
        py.getAudioLengthPy()
        py.deleteLastTMPFunction()
        stopPlayingResetWaveform()
    }


}
