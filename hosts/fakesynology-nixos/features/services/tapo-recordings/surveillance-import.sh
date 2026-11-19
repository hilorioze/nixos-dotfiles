#!/bin/bash
# the dsm runs it as root on boot: a triggered task scheduler script with this file's content
set -u

# a pass runs in a subshell, so that a failed request ends only that pass
import_recordings() (
  set -e

  cameras=$(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=List version=9 2>/dev/null)

  # the mac address each camera's address ends with, which only the camera's details have
  addresses=$(for id in $(jq .data.cameras[].id <<<$cameras); do
    echo $id $(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=GetInfo version=8 cameraIds=\"$id\" 2>/dev/null | jq --raw-output .data.cameras[0].camPath | base64 --decode | xargs basename)
  done)

  # fakesynology-nixos creates a camera's folder, named by its mac address, on its first detection; dsm adds its own `@eaDir` folders
  for import in /volume1/surveillance-import/[!@]*/; do
    mac=$(basename $import)
    id=$(awk -v mac=$mac '$2 == mac { print $1 }' <<<$addresses)

    # add a user-defined camera on its go2rtc stream, under the camera's alias unless another camera has it
    if [[ -z $id ]]; then
      camera=$(<$import.alias)
      if jq --exit-status --arg camera "$camera" '.data.cameras | any(.newName == $camera)' <<<$cameras >/dev/null; then
        camera="$camera ${mac: -4}"
      fi

      id=$(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=Save version=9 id=0 dsId=0 actFromHost=false newName="$(jq --null-input --arg camera "$camera" '$camera')" vendor='"User"' model='"Define"' firmware='""' videoMode='""' tvStandard=0 channel='"1"' videoCodec=3 audioCodec=6 mountType=0 userName='""' password='""' ip='"fakesynology-nixos.hilorioze.com"' port=8554 streamingType=1 userDefinePath=\"rtsp://fakesynology-nixos.hilorioze.com:8554/$mac\" stream1='{"resolution":"1920x1080"}' recordSchedule=\"$(head --bytes=336 /dev/zero | tr '\0' 0)\" 2>/dev/null | jq .data.id)

      # the imported recordings are the detections; surveillance station's own recording and motion detection would only see the placeholder go2rtc streams while nobody watches
      /usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera.Event method=MDParamSave version=1 camId=$id source=-1 >/dev/null 2>&1

      cameras=$(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=List version=9 2>/dev/null)
    fi

    # surveillance station names the camera's folder after the camera
    camera=$(jq --raw-output --argjson id $id '.data.cameras[] | select(.id == $id) | .newName' <<<$cameras)

    # hidden paths are the alias and the recordings that fakesynology-nixos is still putting together
    if [[ -n $(find $import -name '*.mp4' -not -path '*/.*') ]]; then
      rsync --recursive --remove-source-files --exclude='.*' --owner --group --chown=SurveillanceStation:SurveillanceStation --chmod=D755,F644 $import "/volume1/surveillance/$camera/"
      find $import -mindepth 1 -type d -empty -not -path '*/.*' -delete

      /usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Recording.Reindex method=Start version=1 camIdList=$id >/dev/null 2>&1
    fi

    # the camera records only on its detections; reindex adds the recordings without an event type
    sqlite3 -cmd '.timeout 10000' /volume1/@surveillance/recording.db "update event set trigger_label = 256 where camera_id = $id and trigger_label = 0"
  done
)

# reindex adds a recording's event in the background, and a later pass labels it
while true; do
  import_recordings
  sleep 5
done
