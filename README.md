[![CI sunvox-cl](https://github.com/visualdoj/sunvox-cl/actions/workflows/github-actions.yml/badge.svg)](https://github.com/visualdoj/sunvox-cl/actions/workflows/github-actions.yml)

# sunvox-cl

Unofficial command line tool for working with `.sunvox` files.

## Dependency

Put SunVox dynamic library to the same directory with binary or provide path to
it with `--library` option, e.g. `--library sunvox.dll`.

## Build

```sh
make
```

## Usage

```sh
sunvox-cl sunvox2wav input.sunvox -o output.wav

    Converts .sunvox file to WAV
```

## License

Sources of `sunvox-cl` are dedicated to public domain. `Sunvox` library has its
own license.

```
Powered by:
 * SunVox modular synthesizer
   Copyright (c) 2008 - 2018, Alexander Zolotov <nightradio@gmail.com>, WarmPlace.ru
 * Ogg Vorbis 'Tremor' integer playback codec
   Copyright (c) 2002, Xiph.org Foundation
```
