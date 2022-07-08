//
//  sunvox-cl - Program for managing .sunvox files from command line.
//
//  Author:  Doj
//  License: Public domain or MIT
//
//
//
//  Powered by:
//   * SunVox modular synthesizer
//     Copyright (c) 2008 - 2018, Alexander Zolotov <nightradio@gmail.com>,
//     WarmPlace.ru
//   * Ogg Vorbis 'Tremor' integer playback codec
//     Copyright (c) 2002, Xiph.org Foundation
//
//
//
//  ---------------------------------------------------------------------------
//  This software is available under 2 licenses -- choose whichever you prefer.
//  ---------------------------------------------------------------------------
//  ALTERNATIVE A - MIT License
//
//  Copyright (c) 2022 Viktor Matuzenko aka Doj
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//  ---------------------------------------------------------------------------
//  ALTERNATIVE B - Public Domain (www.unlicense.org)
//
//  This is free and unencumbered software released into the public domain.
//
//  Anyone is free to copy, modify, publish, use, compile, sell, or distribute
//  this software, either in source code form or as a compiled binary, for any
//  purpose, commercial or non-commercial, and by any means.
//
//  In jurisdictions that recognize copyright laws, the author or authors of
//  this software dedicate any and all copyright interest in the software to
//  the public domain. We make this dedication for the benefit of the public at
//  large and to the detriment of our heirs and successors. We intend this
//  dedication to be an overt act of relinquishment in perpetuity of all
//  present and future rights to this software under copyright law.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  For more information, please refer to <http://unlicense.org/>
//  ---------------------------------------------------------------------------

{$MODE FPC}
{$MODESWITCH DEFAULTPARAMETERS}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}

uses
  dterm,
  dsunvox;

const
  SUNVOXCL_VERSION  = 0;
  SUNVOXCL_MAJOR    = 0;
  SUNVOXCL_MINOR    = 0;

var
Args: record
  NoArgs: Boolean;
  Usage: Boolean;
  Help: Boolean;
  Version: Boolean;
  ShortVersion: Boolean;
  SubProgram: AnsiString;
  LibraryPath: AnsiString;
  OutputFilename: AnsiString;
  FreeArgs: array of AnsiString;
  SunvoxSampleRate: TSunvoxInt;
  SunvoxChannelsNum: TSunvoxInt;
  SunvoxFlags: TSunvoxInt;
end;

OutputF: file of Byte;
OutputError: Boolean;

function Error(const Msg: AnsiString): Boolean;
begin
  SetTerminalColor(TERMINAL_COLOR_BRIGHT_RED);
  Writeln(stderr, 'Error: ', Msg);
  SetTerminalColor(TERMINAL_COLOR_DEFAULT);
  Exit(False);
end;

function OpenOutput(const FileName: AnsiString): Boolean;
begin
  Assign(OutputF, FileName);
  {$PUSH}{$I-} ReWrite(OutputF); {$POP}
  OutputError := IOResult <> 0;
  Exit(not OutputError);
end;

procedure CloseOutput;
begin
  {$PUSH}{$I-} Close(OutputF); {$POP}
end;

procedure WriteStr(const S: AnsiString); inline;
begin
  {$PUSH}{$I-} BlockWrite(OutputF, S[1], Length(S)); {$POP}
  OutputError := OutputError or (IOResult <> 0);
end;

procedure WriteU16(const Value: UInt16); inline;
begin
  {$PUSH}{$I-} BlockWrite(OutputF, Value, SizeOf(UInt16)); {$POP}
  OutputError := OutputError or (IOResult <> 0);
end;

procedure WriteU32(const Value: UInt32); inline;
begin
  {$PUSH}{$I-} BlockWrite(OutputF, Value, SizeOf(UInt32)); {$POP}
  OutputError := OutputError or (IOResult <> 0);
end;

function SetSubProgram(const Name: AnsiString): Boolean;
begin
  if (Args.SubProgram <> '') and (Args.SubProgram <> Name) then
    Exit(Error('conflicted subprograms: ' + Args.SubProgram + ' and ' + Name));
  Args.SubProgram := Name;
  Exit(True);
end;

function ParseCommandLines: Boolean;
var
  I: Int32;
begin
  Args.NoArgs         := ParamCount < 1;
  Args.Usage          := False;
  Args.Help           := False;
  Args.Version        := False;
  Args.ShortVersion   := False;
  Args.SubProgram     := '';
  Args.LibraryPath    := SUNVOX_LIBNAME;
  Args.OutputFilename := '';
  SetLength(Args.FreeArgs, 0);
  Args.SunvoxSampleRate     := 44100;
  Args.SunvoxChannelsNum    := 2;
  Args.SunvoxFlags          := SV_INIT_FLAG_USER_AUDIO_CALLBACK
                            or SV_INIT_FLAG_ONE_THREAD
                            or SV_INIT_FLAG_AUDIO_FLOAT32
                            or SV_INIT_FLAG_NO_DEBUG_OUTPUT;

  I := 1;
  while I <= ParamCount do begin
    if (ParamStr(I) = '-?') or (ParamStr(I) = '-h') or (ParamStr(I) = '--usage') then begin
      Args.Usage := True
    end else if (ParamStr(I) = '--help') or (ParamStr(I) = '--long-help') then begin
      Args.Help := True
    end else if (ParamStr(I) = '-v') or (ParamStr(I) = '--version') then begin
      Args.Version := True;
    end else if (ParamStr(I) = '--short-version') then begin
      Args.ShortVersion := True;
    end else if (ParamStr(I) = 'sunvox2wav') then begin
      if not SetSubProgram(ParamStr(I)) then
        Exit(False);
    end else if (ParamStr(I) = '--library') then begin
      Inc(I);
      if I > ParamCount then
        Exit(Error('missed argument for ' + ParamStr(I)));
      Args.LibraryPath := ParamStr(I);
    end else if (ParamStr(I) = '-o') or (ParamStr(I) = '--output') then begin
      Inc(I);
      if I > ParamCount then
        Exit(Error('missed argument for ' + ParamStr(I)));
      Args.OutputFilename := ParamStr(I);
    end else begin
      if (ParamStr(I) <> '') and (ParamStr(I)[1] = '-') then begin
        Exit(Error('unknown option ' + ParamStr(I)));
      end else begin
        SetLength(Args.FreeArgs, Length(Args.FreeArgs) + 1);
        Args.FreeArgs[High(Args.FreeArgs)] := ParamStr(I);
      end;
    end;
    Inc(I);
  end;

  Exit(True);
end;

procedure PrintVersion;
begin
  Writeln('sunvox-cl ', SUNVOXCL_VERSION, '.', SUNVOXCL_MAJOR, '.', SUNVOXCL_MINOR);
end;

procedure PrintShortVersion;
begin
  Writeln(SUNVOXCL_VERSION, '.', SUNVOXCL_MAJOR, '.', SUNVOXCL_MINOR);
end;

procedure PrintUsage;
begin
  Writeln('Usage:');
  Writeln('  sunvox-cl -?|-h|--help');
  Writeln('  sunvox-cl -v|--version');
  Writeln('  sunvox-cl sunvox2wav file.sunvox [-o file.wav]');
end;

procedure PrintHelp;
begin
  PrintUsage;
end;

function ReplaceExt(const FileName: AnsiString; const NewExt: AnsiString): AnsiString;
var
  I: Int32;
begin
  I := Length(FileName);
  while I > 0 do begin
    if FileName[I] = '.' then
      break;
    Dec(I);
  end;

  if I <= 0 then begin
    Exit(FileName + NewExt);
  end else
    Exit(Copy(FileName, 1, I - 1) + NewExt);
end;

function IntToStr(Value: LongInt): AnsiString;
begin
  Str(Value, Result);
end;

function Sunvox2Wav: Boolean;
label
  LFailed;
const
  BUFFER_FRAMES = 1024;
var
  OutputFileName: AnsiString;
  Slot: TSunvoxInt;
  Frame, FramesRead, FrameSize, SongLengthFrames, SongSize: TSunvoxInt;
  Buffer: Pointer;
  pos, new_pos: TSunvoxInt;
begin
  Slot := 0;
  Result := True;

  if Length(Args.FreeArgs) = 0 then
    Exit(Error('sunvox file is not specified'));

  if Length(Args.FreeArgs) > 1 then
    Exit(Error('too many input files'));

  sv_open_slot(Slot);

  if sv_load(Slot, PAnsiChar(Args.FreeArgs[0])) <> 0 then begin
    sv_close_slot(Slot);
    Exit(Error('could not load ' + Args.FreeArgs[0]));
  end;

  sv_volume(Slot, 256);

  OutputFilename := Args.OutputFilename;
  if OutputFilename = '' then
    OutputFilename := ReplaceExt(OutputFilename, '.wav');

  if not OpenOutput(OutputFilename) then begin
    sv_close_slot(Slot);
    Exit(Error('could not open ' + OutputFilename));
  end;

  FrameSize := Args.SunvoxChannelsNum * SizeOf(Single); // TODO customizable type

  Buffer := GetMem(BUFFER_FRAMES * FrameSize);
  SongLengthFrames := sv_get_song_length_frames(0);
  SongSize := SongLengthFrames * FrameSize;

  // WAV header
  WriteStr('RIFF');
  WriteU32(4 + 24 + 8 + SongSize);
  WriteStr('WAVE');

  // WAV
  WriteStr('fmt ');
  WriteU32(16);
  // if Float then begin // TODO
    WriteU16(3);
  // end else
  //  WriteU16(1);
  WriteU16(Args.SunvoxChannelsNum);
  WriteU16(Args.SunvoxSampleRate);
  WriteU16(Args.SunvoxSampleRate * FrameSize);
  WriteU16(FrameSize);
  WriteU16(SizeOf(Single) * 8); // TODO channles?

  // WAV data
  WriteStr('data');
  WriteU32(SongSize);

  if OutputError then begin
    Result := Error('could not write to ' + OutputFilename);
    goto LFailed;
  end;

  if IsStdoutTerminal then begin
    SetTerminalColor(TERMINAL_COLOR_BRIGHT_WHITE);
    StartTerminalStatusLine('0% ' + OutputFilename);
  end;

  pos := 0;
  Frame := 0;
  while Frame < SongLengthFrames do begin
    FramesRead := BUFFER_FRAMES;
    if Frame + FramesRead > SongLengthFrames then
      FramesRead := SongLengthFrames - Frame;

    sv_audio_callback(Buffer, FramesRead, 0, sv_get_ticks());
    Inc(Frame, FramesRead);

    {$PUSH}{$I-} BlockWrite(OutputF, Buffer^, FramesRead * FrameSize); {$POP}
    if IOResult <> 0 then begin
      if IsStdoutTerminal then begin
        UpdateTerminalStatusLine('');
        FinishTerminalStatusLine;
        SetTerminalColor(TERMINAL_COLOR_DEFAULT);
      end;

      Result := Error('could not write to ' + OutputFilename);
      goto LFailed;
    end;

    if IsStdoutTerminal then begin
      new_pos := (Frame * 100) div SongLengthFrames;
      if pos <> new_pos then begin
        UpdateTerminalStatusLine(OutputFilename + ' ' + IntToStr(pos) + '%');
        pos := new_pos;
      end;
    end;
  end;

  if IsStdoutTerminal then begin
    SetTerminalColor(TERMINAL_COLOR_BRIGHT_GREEN);
    UpdateTerminalStatusLine(OutputFilename + ' 100%');
    FinishTerminalStatusLine;
    SetTerminalColor(TERMINAL_COLOR_DEFAULT);
  end;

LFailed:
  CloseOutput;
  sv_close_slot(Slot);
  Exit(False);
end;

function RunActualSubProgram: Boolean;
begin
  if Args.SubProgram = 'sunvox2wav' then begin
    Exit(Sunvox2Wav);
  end else begin
    Exit(Error('unsupported subprogram ' + Args.SubProgram));
  end;
end;

function RunMain: Boolean;
var
  ver, major, minor1, minor2: TSunvoxInt;
begin
  if sv_load_dll(PAnsiChar(Args.LibraryPath)) <> 0 then
    Exit(Error(svGetLoaderError));

  ver := sv_init(nil, Args.SunvoxSampleRate, Args.SunvoxChannelsNum, Args.SunvoxFlags);

  if ver >= 0 then begin
    major   := (ver shr 16) and 255;
    minor1  := (ver shr  8) and 255;
    minor2  := ver and 255;
    // Writeln('SunVox ', major, '.', minor1, '.', minor2);

    Result := RunActualSubProgram;

    sv_deinit;
  end else begin
    Result := Error('sv_init failed: '); // TODO +IntToStr(ver)
  end;

  sv_unload_dll;
end;

begin
  Args.NoArgs := True; // make compiler happy

  if not ParseCommandLines then
    Halt(1);

  if Args.NoArgs then begin
    PrintVersion;
    Writeln;
    PrintUsage;
    Halt(0);
  end;

  if Args.Version then begin
    PrintVersion;
    Halt(0);
  end;

  if Args.ShortVersion then begin
    PrintShortVersion;
    Halt(0);
  end;

  if Args.Usage then begin
    PrintUsage;
    Halt(0);
  end;

  if Args.Help then begin
    PrintHelp;
    Halt(0);
  end;

  if not RunMain then
    Halt(1);
end.
