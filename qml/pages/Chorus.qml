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

     property var speed: 0.4 // 0.1 - 10 Hz
     property var depth: 1 // 0 - 10
     property var decay: 0.2 // 0 - 100
     property var delay: 50 // 0 - 30

    Slider {
        id: idChorusSpeed
        enabled: true // ( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        value: 0.4
        stepSize: .1
        minimumValue: 0.1
        maximumValue: 1.0
        Label {
            text: parent.value + qsTr("chorus speed")
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
        id: idChorusDelay
        enabled: true //( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idChorusSpeed.bottom
        value: 50
        stepSize: 10
        minimumValue: 20
        maximumValue: 150
        Label {
            text: parent.value + qsTr(" chorus delay")
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
        id: idChorusDecay
        enabled: true //( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idChorusDelay.bottom
        value: 0.3
        stepSize: 0.1
        minimumValue: 0.1
        maximumValue: 1.0
        Label {
            text: parent.value + qsTr(" chorus decay")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { decay = value }
    }
    Slider {
        id: idChorusDepth
        enabled: true //( finishedLoading === true && showTools === true )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idChorusDecay.bottom
        value: 1
        stepSize: 0.1
        minimumValue: .3
        maximumValue: 2.5
        Label {
            text: parent.value + qsTr(" chorus depth")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { depth = value }
    }
    Text{
        text: "Warning! Chorus has artifacts."
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingSmall
            horizontalCenter: parent.horizontalCenter
        }
    }
}
