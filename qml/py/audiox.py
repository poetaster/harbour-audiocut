#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pyotherside
import time
import os
import shutil
import subprocess
from pathlib import Path


# check if pydub is installed
try:
    import pydub
except ImportError:
    pyotherside.send('warningPydubNotAvailable', )
from pydub import AudioSegment
from pydub import effects
from pydub.utils import mediainfo

# check if LAME is manually installed by user
retval = subprocess.call(["which", "lame"])
if retval != 0:
    pyotherside.send('warningLameNotAvailable', )



# Functions for file operations
# #######################################################################################

def getHomePath ():
    homeDir = str(Path.home())
    pyotherside.send('homePathFolder', homeDir )

def createTmpAndSaveFolder ( tempAudioFolderPath, saveAudioFolderPath ):
    if os.path.exists("/" + "/home" + "/nemo" + "/audioworks_tmp/"): #if folder exists from older versions, remove it
        shutil.rmtree("/" + "/home" + "/nemo" + "/audioworks_tmp/")    
    if not os.path.exists( "/"+tempAudioFolderPath ):
        os.makedirs( "/"+tempAudioFolderPath )
        pyotherside.send('folderExistence', )
    if not os.path.exists( "/"+saveAudioFolderPath ):
        os.makedirs( "/"+saveAudioFolderPath )
        pyotherside.send('folderExistence', )

def deleteAllTMPFunction ( tempAudioFolderPath ):
    for i in os.listdir( "/"+tempAudioFolderPath ) :
        if (i.find(".tmp") != -1):
            os.remove ( "/"+tempAudioFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )

def deleteLastTmpFunction ( lastTmpAudio2delete, lastTmpImage2delete ):
    if ".tmp" in lastTmpAudio2delete :
        os.remove ( lastTmpAudio2delete )
    if ".tmp" in lastTmpImage2delete :
        os.remove ( lastTmpImage2delete )
        pyotherside.send('deleteLastTmp', )

def deleteFile ( inputPathPy ):
    os.remove ( "/" + inputPathPy )
    pyotherside.send('deletedFile', )

def renameOriginal ( inputPathPy, newFilePath, newFileName, newFileType ) :
    os.rename( "/" + inputPathPy, "/" + newFilePath )
    pyotherside.send('finishedSavingRenaming', newFilePath, newFileName, newFileType)

def getFileSizeFunction ( inputPathPy ):
    estimatedSize = os.stat( "/" + inputPathPy ).st_size
    pyotherside.send( 'estimatedFileSize', estimatedSize )

def getAudioTagsFunction ( inputPathPy ):
    allTags = mediainfo( "/"+inputPathPy ).get('TAG',None)
    if "title" in allTags:
        title = allTags["title"]
    else:
        title = ""
    if "artist" in allTags:
        artist = allTags["artist"]
    else:
        artist = ""
    if "album" in allTags:
        album = allTags["album"]
    else:
        album = ""
    if "date" in allTags:
        date = allTags["date"]
    else:
        date = ""
    if "track" in allTags:
        track = allTags["track"]
    else:
        track = ""
    pyotherside.send( 'audioTags', title, artist, album, date, track )


def saveFile ( inputPathPy, savePath, tempAudioFolderPath, tempAudioType, newFileName, newFileType, mp3Bitrate, mp3CompressBitrateType, tagTitle, tagArtist, tagAlbum, tagDate, tagTrack ):
    if "mp3" in newFileType :
        sound = AudioSegment.from_file( inputPathPy )
        outputPathTmp = tempAudioFolderPath + "audioWAV" + ".tmp" + "." + tempAudioType
        sound.export( outputPathTmp, format = tempAudioType )
        subprocess.run([ "lame", mp3CompressBitrateType, "--tt", str(tagTitle), "--ta", str(tagArtist), "--tl", str(tagAlbum), "--ty", str(tagDate), "--tn", str(tagTrack), "/"+outputPathTmp, "/"+savePath ])
    elif "ogg" in newFileType :
        sound = AudioSegment.from_file( inputPathPy )
        sound.export( "/" + savePath, format = newFileType, tags={'title':str(tagTitle), 'artist':str(tagArtist), 'album':str(tagAlbum), 'date':str(tagDate), 'track':str(tagTrack)  } )
    elif "flac" in newFileType :
        sound = AudioSegment.from_file( inputPathPy )
        sound.export( "/" + savePath, format = newFileType, tags={'title':str(tagTitle), 'artist':str(tagArtist), 'album':str(tagAlbum), 'date':str(tagDate), 'track':str(tagTrack)  } )
    else:
        sound = AudioSegment.from_file( inputPathPy )
        sound.export( "/" + savePath, format = newFileType )
    # do not forget to clear tmp files
    for i in os.listdir( "/" + tempAudioFolderPath ) :
        if (i.find(".tmp") != -1):
            os.remove ("/" + tempAudioFolderPath+i)
            pyotherside.send('tempFilesDeleted', i )
    pyotherside.send('fileIsSaved', )
    pyotherside.send('finishedSavingRenaming', savePath, newFileName, newFileType)





# Function for waveform creation
# #######################################################################################


def createWaveformImage ( inputPathPy, outputWaveformPath, waveformColor, waveformPixelLength, waveformPixelHeight, stretch ):
    waveformPixelLength = str(int(waveformPixelLength))
    waveformPixelHeight = str(int(waveformPixelHeight))
    subprocess.run([ "ffmpeg", "-y", "-i", "/"+inputPathPy, "-filter_complex", stretch+"showwavespic=s="+waveformPixelLength+"x"+waveformPixelHeight+":colors="+waveformColor, "-frames:v", "1", "/"+outputWaveformPath, "-hide_banner" ])
    sound = AudioSegment.from_file(inputPathPy)
    audioLengthMilliseconds = len(sound)
    pyotherside.send('loadImageWaveform', outputWaveformPath, audioLengthMilliseconds )

def getAudioLength ( inputPathPy ):
    sound = AudioSegment.from_file(inputPathPy)
    audioLengthMilliseconds = len(sound)
    pyotherside.send('getAudioLenghtPy', audioLengthMilliseconds )





# Functions for audio manipulation, depending on markers
# #######################################################################################


def copyToClipboard ( inputPathPy, fromPosMillisecond, toPosMillisecond ):
    global globClipboard
    sound = AudioSegment.from_file( inputPathPy )
    globClipboard = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    pyotherside.send('copiedToClipboard', )

def pasteFromClipboard ( inputPathPy, outputPathPy, tempAudioType, pasteHere, pasteType ):
    global globClipboard
    sound = AudioSegment.from_file( inputPathPy )
    if ("overlay") in pasteType :
        extract1 = sound[ :int(pasteHere) ]
        extract2 = sound[ int(pasteHere): ]
        mixed = extract2.overlay(globClipboard)
        extract = extract1 + mixed
    if ("replace") in pasteType :
        extract1 = sound[ :int(pasteHere) ]
        extract2 = sound[ int(pasteHere): ]
        extract3 = extract2[len(globClipboard):]
        extract = extract1 + globClipboard + extract3
    if ("add") in pasteType :
        extract1 = sound[ :int(pasteHere) ]
        extract2 = sound[ int(pasteHere): ]
        extract = extract1 + globClipboard + extract2
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def cutRemove ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ):
    sound = AudioSegment.from_file( inputPathPy )
    extract1 = sound[ :int(fromPosMillisecond) ]
    extract2 = sound[ int(toPosMillisecond): ]
    extract = extract1 + extract2
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def cutExtract ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ):
    sound = AudioSegment.from_file( inputPathPy )
    extract = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def paddingSilence ( inputPathPy, outputPathPy, tempAudioType, padHere, positionSilence, durationSilence ) :
    sound = AudioSegment.from_file( inputPathPy )
    silence = AudioSegment.silent(duration=int(durationSilence))
    if ("beginning") in positionSilence :
        extract = silence + sound
    if ("end") in positionSilence :
        extract = sound + silence
    if ("cursor") in positionSilence :
        extract1 = sound[ :int(padHere) ]
        extract2 = sound[ int(padHere): ]
        extract = extract1 + silence + extract2
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def volumeChange ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, changeDB ):
    sound = AudioSegment.from_file( inputPathPy )
    extract1 = sound[ :int(fromPosMillisecond) ]
    extract3 = sound[ int(toPosMillisecond): ]
    extract2 = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    if len(extract2) > 0:
        middle = extract2.apply_gain( changeDB )
        extract = extract1 + middle + extract3
    else:
        extract = extract1 + extract3
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def volumeFadeIn ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ):
    sound = AudioSegment.from_file( inputPathPy )
    extract1 = sound[ :int(fromPosMillisecond) ]
    extract3 = sound[ int(toPosMillisecond): ]
    extract2 = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    if len(extract2) > 0:
        middle = extract2.fade( from_gain=-120.0, start = 0, duration = len(extract2) )
        extract = extract1 + middle + extract3
    else:
        extract = extract1 + extract3
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def volumeFadeOut ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ):
    sound = AudioSegment.from_file( inputPathPy )
    extract1 = sound[ :int(fromPosMillisecond) ]
    extract3 = sound[ int(toPosMillisecond): ]
    extract2 = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    if len(extract2) > 0:
        middle = extract2.fade( to_gain=-120.0, start = 0, duration = len(extract2) )
        extract = extract1 + middle + extract3
    else:
        extract = extract1 + extract3
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def speedChange ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, factorSpeed, keepPitch ):
    def speed_change_and_pitch(sound, speed):
        sound_with_altered_frame_rate = sound._spawn( sound.raw_data, overrides={ "frame_rate": int(sound.frame_rate * speed) } )
        return sound_with_altered_frame_rate.set_frame_rate(sound.frame_rate)
    sound = AudioSegment.from_file( inputPathPy )
    extract1 = sound[ :int(fromPosMillisecond) ]
    extract3 = sound[ int(toPosMillisecond): ]
    extract2 = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    if len(extract2) > 0:
        if ("true") in keepPitch :
            middle = extract2.speedup( float(factorSpeed) )
        else:
            middle = speed_change_and_pitch(extract2, factorSpeed)
        extract = extract1 + middle + extract3
    else:
        extract = extract1 + extract3
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def reverseAudio ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ):
    sound = AudioSegment.from_file( inputPathPy )
    extract1 = sound[ :int(fromPosMillisecond) ]
    extract3 = sound[ int(toPosMillisecond): ]
    extract2 = sound[ int(fromPosMillisecond) : int(toPosMillisecond) ]
    if len(extract2) > 0:
        middle = extract2.reverse()
        extract = extract1 + middle + extract3
    else:
        extract = extract1 + extract3
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def lowPassFilter ( inputPathPy, outputPathPy, tempAudioType, filterFrequency, filterOrder ):
    sound = AudioSegment.from_file( inputPathPy )
    extract = sound.low_pass_filter( int(filterFrequency) )
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def highPassFilter ( inputPathPy, outputPathPy, tempAudioType, filterFrequency, filterOrder ):
    sound = AudioSegment.from_file( inputPathPy )
    extract = sound.high_pass_filter( int(filterFrequency) )
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )




# Functions for audio manipulation, disregarding markers
# #######################################################################################

def denoiseAudio ( inputPathPy, outputPathPy, tempAudioType, filterType ):
    subprocess.run([ "ffmpeg", "-y", "-i", "/"+inputPathPy, "-af", filterType, "/"+outputPathPy, "-hide_banner" ])
    pyotherside.send('loadTempAudio', outputPathPy )

def trimSilence ( inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, breakMS, breakDB, breakPadding ):
    sound = AudioSegment.from_file( inputPathPy )
    extract = sound.strip_silence( int(breakMS), int(breakDB), int(breakPadding) )
    extract.export( outputPathPy, format = tempAudioType )
    pyotherside.send('loadTempAudio', outputPathPy )

def echoEffect ( inputPathPy, outputPathPy, tempAudioType, in_gain, out_gain, delays, decays ):
    subprocess.run([ "ffmpeg", "-y", "-i", "/"+inputPathPy, "-af", "aecho=" + str(in_gain) + ":" + str(out_gain) + ":" + str(delays) + ":" + str(decays), "/"+outputPathPy, "-hide_banner" ])
    pyotherside.send('loadTempAudio', outputPathPy )





#pyotherside.send('debugPythonLogs', i)
