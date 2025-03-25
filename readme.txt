rof2csv - command-line tool to convert Rigol ROF files to CSV
==============================================================

(c) 2025 Piotr Dałek (https://github.com/branch-predictor)

This tool can be used to convert ROF files (produced by Rigol DP800 Series programmable power supplies) into something that's actually human-usable, that is - comma-separated values file, that can be then used with anything else, like Excel.

Automatically infers number of channels in file and denotes each sample with correct timestamp.

Example output file contents:

Time;Ch1 V; Ch1 A;Ch2 V; Ch2 A;Ch3 V; Ch3 A;
00:00:00;4,9949;0,0551;0,0026;0,0003;0,0001;0,0003;
00:00:01;4,9949;0,0565;0,0025;0,0003;0,0002;0,0003;
00:00:02;4,9948;0,0551;0,0026;0,0003;0,0001;0,0003;
00:00:03;4,9948;0,0532;0,0027;0,0003;0,0001;0,0003;
00:00:04;4,9948;0,0566;0,0027;0,0003;0,0002;0,0003;

Usage
=====

  rof2csv [-fds|-fdc] [-overwrite] infile [outfile]

  -fdd        use colon (dot) as float separator
  -fdc        use comma as float separator
              NOTE: defaults to whatever system locale uses
  -overwrite  force overwriting destination file.
  infile      source ROF file
  outfile     destination CSV file, defaults to imfile but with ".csv" extension.

Rebuilding
==========

Go to https://github.com/branch-predictor/rof2csv, clone the repo or download it as .zip file.
Any Delphi or FreePascal version should work, just feed your compiler with "rof2csv.dpr" file.

