#!/bin/bash

download fdk-aac https://github.com/mstorsjo/fdk-aec/archive/refs/tags/v2.0.2.tar.gz
build fdk-aac -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

download whisper.cpp https://github.com/ggerganov/whisper.cpp/archive/refs/tags/v1.3.0.tar.gz
build whisper.cpp -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

download aribb24 https://github.com/nkoriyama/aribb24/archive/refs/heads/master.tar.gz
build aribb24 --disable-shared --enable-static

download aribcaption https://github.com/nkoriyama/aribcaption/archive/refs/heads/master.tar.gz
build aribcaption -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

download lc3 https://github.com/google/liblc3/archive/refs/tags/v1.0.3.tar.gz
build lc3 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF

EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS \
  --enable-libfdk-aac \
  --enable-libwhisper \
  --enable-libaribb24 \
  --enable-libaribcaption \
  --enable-liblc3 \
  --enable-d3d12va \
  --enable-libshaderc \
  --enable-libplacebo"


if [[ -f /tmp/sdks.zip ]]; then
  unzip -q /tmp/sdks.zip -d /opt/sdks
  EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS \
    --enable-decklink     --extra-cflags=-I/opt/sdks/DecklinkSDK/include --extra-ldflags=-L/opt/sdks/DecklinkSDK/lib \
    --enable-libndi_newtek --extra-cflags=-I/opt/sdks/NDI/SDK/include    --extra-ldflags=-L/opt/sdks/NDI/SDK/lib"
fi
