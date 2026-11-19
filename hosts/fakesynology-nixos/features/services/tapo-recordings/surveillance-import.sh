#!/bin/bash
# the dsm runs it as root every minute: a task scheduler script with this file's content
set -eu

cameras=$(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=List version=9 2>/dev/null)

# the mac address each camera's address ends with, which only the camera's details have
addresses=$(for id in $(jq .data.cameras[].id <<<$cameras); do
  echo $id $(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=GetInfo version=8 cameraIds=\"$id\" 2>/dev/null | jq --raw-output .data.cameras[0].camPath | base64 --decode | xargs basename)
done)

# fakesynology-nixos creates a camera's folder, named by its mac address, on its first detection; dsm adds its own `@eaDir` folders
for import in /volume1/surveillance-import/[!@]*/; do
  mac=$(basename $import)
  id=$(awk -v mac=$mac '$2 == mac { print $1 }' <<<$addresses)

  # surveillance station only shows the imported recordings; add a disabled user-defined camera pointing nowhere, under the camera's alias unless another camera has it
  if [[ -z $id ]]; then
    camera=$(<$import.alias)
    if jq --exit-status --arg camera "$camera" '.data.cameras | any(.newName == $camera)' <<<$cameras >/dev/null; then
      camera="$camera ${mac: -4}"
    fi

    id=$(/usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=Save version=9 id=0 dsId=0 actFromHost=false newName="$(jq --null-input --arg camera "$camera" '$camera')" vendor='"User"' model='"Define"' firmware='""' videoMode='""' tvStandard=0 channel='"1"' videoCodec=3 audioCodec=6 mountType=0 userName='""' password='""' ip='"127.0.0.1"' port=1 streamingType=1 userDefinePath=\"rtsp://127.0.0.1:1/$mac\" stream1='{"resolution":"1920x1080"}' 2>/dev/null | jq .data.id)
    /usr/syno/bin/synowebapi --exec api=SYNO.SurveillanceStation.Camera method=Disable version=9 idList=\"$id\" >/dev/null 2>&1

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
