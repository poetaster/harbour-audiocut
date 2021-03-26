import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4


Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: listView
        anchors.fill: parent
        contentHeight: columnSaveAs.height  // Tell SilicaFlickable the height of its content.
        VerticalScrollDecorator {}

        Column {
            id: columnSaveAs
            width: parent.width

            PageHeader {
                title: qsTr("Info")
            }


            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "This app needs python3-pydub for audio manipulation which should be installed automatically. "
                    + "If for some reason this did not happen, kindly download from Openrepos.net."
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                text: "https://openrepos.net/content/planetos/python3-pydub" + "\n"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally("https://openrepos.net/content/planetos/python3-pydub")
                    }
                }
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "Encoding MP3-files furthermore requires LAME, a tool you may install manually. "
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                text: "https://openrepos.net/content/lpr/lame" + "\n"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally("https://openrepos.net/content/lpr/lame")
                    }
                }
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "1) Download the latest files suitable for your device" + "\n"
                      //+ "     Smartphones usually ...armv7hl.rpm" + "\n"
                      //+ "     Tablets possibly ...i486.rpm" + "\n"
                      + "2) Allow '3rd party software' in Sailfish settings" + "\n"
                      + "3) Install" + "\n"
            }

            SectionHeader {
                text: "Contact"
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "tobias.planitzer@protonmail.com" + "\n"
            }




        } // end Column
    } // end Silica Flickable
}
