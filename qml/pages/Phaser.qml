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

     property var speed: 0.5 // 0.1 - 2 Hz
     property var decay: 0.5 // 0 - 1
     property var delay: 3 // 0 - 5
    Slider {
        id: idPhaserSpeed
        enabled: true // ( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        value: 0.9
        smooth: true
        stepSize: .1
        minimumValue: 0.1
        maximumValue: 2.0
        Label {
            text: parent.value + qsTr(" phaser speed")
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
        id: idPhaserDelay
        enabled: true //( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idPhaserSpeed.bottom
        value: 3
        smooth: true
        stepSize: 1
        minimumValue: 0
        maximumValue: 5
        Label {
            text: parent.value + qsTr(" phaser delay")
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
        id: idPhaserDecay
        enabled: true //( finishedLoading === true && showTools === true )
        //visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
        width: parent.width
        height: 1.1 * Theme.itemSizeMedium
        anchors.top: idPhaserDelay.bottom
        value: 0.5
        smooth: true
        stepSize: .1
        minimumValue: 0
        maximumValue: 1
        Label {
            text: parent.value + qsTr(" phaser decay")
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
        }
        onReleased: { decay = value }
    }
}
