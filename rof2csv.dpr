program rof2csv;

uses
  Sysutils;

{$APPTYPE CONSOLE}
{$I-}

const
	MAX_FILE_SIZE = 256 * 1024 * 1024; // 256MB
	MIN_FILE_SIZE = 28 + 8; // header (28 bytes) + one datapoint (2 * 4 bytes)
	MAX_CHANNELS = 8; // max number of data channels
type
	PByte = ^Byte;
	PLongInt = ^LongInt;

procedure DumpHelp;
begin;
Writeln('Usage:');
Writeln('');
Writeln('  rof2csv [-fds|-fdc] [-overwrite] infile [outfile]');
Writeln('');
Writeln('  -fdd        use colon (dot) as float separator');
Writeln('  -fdc        use comma as float separator');
Writeln('              NOTE: defaults to whatever system locale uses');
Writeln('  -overwrite  force overwriting destination file.');
Writeln('  infile      source ROF file');
Writeln('  outfile     destination CSV file, defaults to imfile but with ".csv"');
Writeln('               extension.');
Writeln('');
end;

procedure DumpError(const Msg: string);
begin;
Writeln('** Error: ', Msg);
Writeln('');
DumpHelp;
end;

procedure DumpWarning(const Msg: string);
begin;
Writeln('!! Warning: ', Msg);
Writeln('');
end;

procedure ProcessBuffer(InBuffer: PByte; FSize: Cardinal; const Dst: string);
var
	Buffer: array[0..4095] of char;
	IOErr: integer;
	i: integer;
	OutFile: TextFile;
	InBufPtr, InBufPtrMax: PByte;
	SamplingPeriod, DataPoints, DataPoints2: LongInt;
	Channels, CurrentChan, CurrentTime, RowSize: integer;
	ChanData: array[0..MAX_CHANNELS-1] of array[0..1] of Longint;
	TmpLine: string;
begin;
AssignFile(OutFile, Dst);
Rewrite(Outfile);
IOErr := IOResult;
if IOErr = 0 then
	begin;
	SetTextBuf(OutFile, Buffer, sizeof(Buffer));
	InBufPtr := InBuffer;
	InBufPtrMax := PByte(Longint(InBuffer) + FSize);
	if PLongInt(InBufPtr)^ <> $464F52 then
		DumpError(format('Invalid file header magic: %.8x', [PLongInt(InBufPtr)^]))
	else
		begin;
		// metadata header is 16 bytes
		inc(InBufPtr, 16);

		SamplingPeriod := PLongInt(InBufPtr)^;
		inc(InBufPtr, sizeof(LongInt));

		DataPoints := PLongInt(InBufPtr)^;
		inc(InBufPtr, sizeof(LongInt));

		DataPoints2 := PLongInt(InBufPtr)^;
		inc(InBufPtr, sizeof(LongInt));

		Channels := (FSize - 28) div DataPoints div 8;
		RowSize := Channels * 2 * sizeof(Longint);

		if (SamplingPeriod <= 0) or (SamplingPeriod > 4096) then
			DumpError(format('Nonsensical sampling period: %d', [SamplingPeriod]))
		else
		if (DataPoints <= 0) then
			DumpError(format('Nonsensical data points count: %d', [SamplingPeriod]))
		else
		if (Channels > MAX_CHANNELS) or (Channels < 1) then
			DumpError(format('Inferred channel count (%d) not supported', [SamplingPeriod]))
		else
			begin;
			TmpLIne := 'Time;';
			for i := 1 to Channels do
				TmpLine := TmpLine + format('Ch%d V; Ch%d A;', [i, i]);
			Writeln(OutFile, TmpLine);
			CurrentTime := 0;
			while longint(InBufPtr) < longint(InBufPtrMax) do
				begin;
				TmpLine := format('%.2d:%.2d:%.2d;', [(CurrentTime div 3600), (CurrentTime div 60) mod 60, CurrentTime mod 60]);
				if longint(InBufPtr) + RowSize <= longint(InBufPtrMax) then
					begin;
					move(InBufPtr^, ChanData, RowSize);
					inc(InBufPtr, RowSize);
					for CurrentChan := 0 to Channels-1 DO
						TmpLine := TmpLine + format('%.4f;%.4f;', [ChanData[CurrentChan][0] / 10000, ChanData[CurrentChan][1] / 10000]);
					WriteLn(OutFile, TmpLine);
					inc(CurrentTime, SamplingPeriod);
					dec(DataPoints, Channels);
					end
				else
					break;
				end;
			if DataPoints > 0 then
				DumpWarning(format('Data truncated - expected %d more datapoints', [Datapoints]));
			end;
		end;
	Flush(OutFile);
	CloseFile(OutFile);
	end
else
	DumpError(format('I/O error %d opening %s for writing', [IOErr, Dst]));
end;

procedure ProcessROF(const Src: string; const Dst: string);
var
	InFile: File of byte;
	InBuffer: PByte;
	IOErr: integer;
	FSize: integer;

begin;
AssignFile(InFile, Src);
Reset(InFile);
IOErr := IOResult;
if IOErr = 0 then
	begin;
	FSize := FileSize(InFile);
	if FSize > MAX_FILE_SIZE then
		DumpError(format('File %s is too large (%d, max is %d)', [Src, FSize, MAX_FILE_SIZE]))
	else
	if FSize < MIN_FILE_SIZE then
		DumpError(format('File %s is too small (%d, expected at least %d)', [Src, FSize, MIN_FILE_SIZE]))
	else
		begin;
		try
			GetMem(InBuffer, FSize);
			BlockRead(InFile, InBuffer^, FSize);
			IOErr := IOResult;
			if IOErr = 0 then
				ProcessBuffer(InBuffer, FSize, Dst)
			else
				DumpError(format('I/O error %d reading %s', [IOErr, Src]));
			FreeMem(InBuffer);
		except
		on E: Exception do
			DumpError(format('Exception %s (%s) during data processing', [E.Classname, E.Message]));
			end;
		end;
	CloseFile(InFile);
	end
else
	DumpError(format('I/O error %d opening %s', [IOErr, Src]));
end;

procedure ProcessArgs;
var
	a: integer;
	ForceOverwrite: boolean;
	FloatDelimiter: char;
	Src: string;
	Dst: string;
	arg: string;

begin;
FloatDelimiter := DecimalSeparator;
ForceOverwrite := false;
for a:=1 to ParamCount do
	begin;
	arg := lowercase(ParamStr(a));
	if  arg = '-fdd' then
		FloatDelimiter := '.'
	else
	if arg = '-fdc' then
		FloatDelimiter := ','
	else
	if arg = '-overwrite' then
		ForceOverwrite := true
	else
	if Src = '' then
		Src := trim(ParamStr(a))
	else
		Dst := trim(ParamStr(a));
	end;
DecimalSeparator := FloatDelimiter;
if Dst = '' then
	Dst := ChangeFileExt(Src, '.csv');

if Src = '' then
	DumpError('No source file specified.')
else if Src = Dst then
	DumpError('Destination and source files must be different.')
else
if not FileExists(Src) then
	DumpError('Source file doesn''t exist.')
else
if FileExists(Dst) and not ForceOverwrite then
	DumpError('Destination file exists (override with "-overwrite").')
else
	ProcessROF(Src, Dst);
end;

begin
if (paramcount < 1) then
	DumpHelp
else
	ProcessArgs;
end.

