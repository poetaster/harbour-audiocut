import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // File-Loader
import QtMultimedia 5.0 // Audio Support
import io.thp.pyotherside 1.4

Item {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Theme.paddingLarge
    anchors.rightMargin: Theme.paddingLarge

     property var speed: 0.5 // 0.1 - 10 Hz
     property var depth: 2 // 0 - 10
     property var phase: 25 // 0 - 100
     property var delay: 10 // 0 - 30
     property var regen: 5 // -95 - 95

    Slider {
        id: idFlangerSpeed
        enabled: true // ( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        value: 0.9
        smooth: true
        stepSize: .1
        minimumValue: 0.1
        maximumValue: 10.0
        Label {
            text: parent.value + qsTr(" flanger speed")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { speed = value }
    }

    Slider {
        id: idFlangerDelay
        enabled: true //( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idFlangerSpeed.bottom
        value: 5
        smooth: true
        stepSize: 1
        minimumValue: 0
        maximumValue: 30
        Label {
            text: parent.value + qsTr(" flanger delay")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { delay = value }
    }
    Slider {
        id: idFlangerPhase
        enabled: true //( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idFlangerDelay.bottom
        value: 25
        smooth: true
        stepSize: 1
        minimumValue: 0
        maximumValue: 100
        Label {
            text: parent.value + qsTr(" flanger phase")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { phase = value }
    }
    Slider {
        id: idFlangerDepth
        enabled: true //( finishedLoading === true && showTools === true )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idFlangerPhase.bottom
        value: 2
        smooth: true
        stepSize: 1
        minimumValue: 0
        maximumValue: 10
        Label {
            text: parent.value + qsTr(" flanger depth")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { depth = value }
    }
}
