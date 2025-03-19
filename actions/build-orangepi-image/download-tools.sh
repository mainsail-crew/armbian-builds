#!/bin/bash

# Mirrors
webseed() {
  local path=$1
  local text=""
  local MIRRORS=(
    "https://os.mainsail.xyz/_toolchain"
    "https://dl.armbian.com/_toolchain"
  )

  if [[ "${path}" =~ ^/ky ]]; then
    MIRRORS=(
      "https://os.mainsail.xyz/_toolchain"
      "http://www.iplaystore.cn/"
    )
  fi
  
  for mirror in "${MIRRORS[@]}"; do
    text="${text} ${mirror}${path}"
  done

  echo "${text:1}"
}

# Download function with verification
download_and_verify() {
  local file=$1
  local localdir="$PWD"
  local success=false
  
  # Download .asc file using aria2c
  echo "Downloading signature file for $file"
  aria2c --download-result=hide --disable-ipv6=true --summary-interval=0 \
    --console-log-level=error --auto-file-renaming=false \
    --continue=false --allow-overwrite=true --dir="${localdir}" \
    "$(webseed "/${file}.asc")" -o "${file}.asc"
    
  if [ $? -ne 0 ]; then
    echo "Failed to download signature file for $file"
    return 1
  fi
  
  # Download main file using aria2c
  echo "Downloading $file"
  aria2c --download-result=hide --disable-ipv6=true --summary-interval=0 \
    --console-log-level=error --auto-file-renaming=false \
    --continue=true --allow-overwrite=true --dir="${localdir}" \
    "$(webseed "/${file}")" -o "${file}"

  if [ $? -ne 0 ]; then
    echo "Failed to download $file"
    return 1
  fi

  # create .complete file
  touch "${localdir}/${file}.complete"
  
  # Verify signature
  if [ -f "${file}.asc" ]; then
    if grep -q 'BEGIN PGP SIGNATURE' "${file}.asc"; then
      if gpg --homedir .gpg --no-permission-warning --verify \
        --trust-model always -q "${file}.asc" 2>/dev/null; then
        echo "GPG verification successful for $file"
        success=true
      fi
    else
      if md5sum -c --status "${file}.asc" 2>/dev/null; then
        echo "MD5 verification successful for $file"
        success=true
      fi
    fi
  fi
  
  if [ "$success" = true ]; then
    # Extract based on file extension
    if [[ "$file" == *.tar.xz ]]; then
      pv -p -b -r -c -N "[ Extracting ] $file" "$file" | xz -dc | tar xp --xattrs --no-same-owner --overwrite
    fi
    touch "${file//.tar.xz}/.download-complete"
    return 0
  else
    echo "Verification failed for $file"
    return 1
  fi
}