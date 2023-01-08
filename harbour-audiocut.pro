# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-audiocut

CONFIG += sailfishapp_qml

DISTFILES += qml/harbour-audiocut.qml \
    qml/cover/CoverPage.qml \
    qml/pages/About.qml \
    qml/pages/FirstPage.qml \
    qml/pages/Flanger.qml \
    qml/pages/SavePage.qml \
    rpm/harbour-audiocut.changes \
    rpm/harbour-audiocut.changes.run \
    rpm/harbour-audiocut.spec \
    translations/*.ts \
    harbour-audiocut.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-audiocut-de.ts \
                translations/harbour-audiocut-sv.ts \
                translations/harbour-audiocut-zh_CN.ts

HEADERS +=

# include precompiled static library according to architecture (arm, i486_32bit, arm64)
#equals(QT_ARCH, arm): {
#  ffmpeg_static.files = lib/ffmpeg/arm32/*
#  message("!!!architecture armv7hl detected!!!");
#}
#equals(QT_ARCH, arm64): {
#  ffmpeg_static.files = lib/ffmpeg/arm64/*
#  message("!!!architecture arm64 detected!!!");
#}
#equals(QT_ARCH, i386): {
#  ffmpeg_static.files = lib/ffmpeg/x86_32/*
#  message("!!!architecture x86 / 32bit detected!!!");
#}

#ffmpeg_static.path = /usr/share/harbour-audiocut/lib/ffmpeg
#INSTALLS += ffmpeg_static

#DISTFILES += lib/pydub \

python.files = lib/pydub/*
python.path = "/usr/share/harbour-audiocut/lib/pydub"

INSTALLS += python
