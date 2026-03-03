class_name AppResources
extends Resource

const INSTRUCTIONS: String = "\
App may be run from command line using   whatever_you_renamed_it.exe --headless \r\n\
Currently, as the app is in development, quite a bit gets printed to the terminal.\r\n\
\r\n\
Files to be processed are selected by modifying the app_settings.json.\r\n\
The default settings will process and compare the latest pre-release with the\r\n \
previous pre-release. The results are saved with the build-number appended to \r\n\
the filename.\r\n\
\r\n\
--- Instructions for using app_settings.json ---\r\n\
\r\n\
Open it in a text editor of your choosing.\r\n\
\r\n\
Values may be changed in this file to modify load-path, save-path, and filename \r\n\
without a GUI. run_app_headless should be set to true, because the GUI is not \r\n\
ready. \r\n\
\r\n\
  Make 'true' for slot 1     Make 'true' for 2nd processing slot\r\n\
                      |      |\r\n\
   'scrape_assets': [true, false]\r\n\
This array is used to determine if the associated Asset file will be processed \r\n\
and compared. Make array [false, false] if associated Asset in branch is not\r\n\
of interest. Only one file can have 'true' in the first index, and likewise,\r\n\
only one 'true' can be placed in the second index of all the arrays.\r\n\
\r\n\
You can change asset path values to a different location if you wish to analyze \r\n\
a zip saved in a custom location. So, if you wish to analyze an older release of\r\n\
the Assets.zip file, you can modify the pregenerated path. All paths must use\r\n \
forward-slashes: ( / ). All paths must end with a forward-slash. Filenames can\r\n\
be whatever you like. Output files will have identifiers added to end of generic \r\n\
name you provide. You can create different folders to seperate out the different\r\n\
diff files, if you want to declutter. "

const LICENSE: String = '\
MIT License\r\n\
\r\n\
Copyright (c) 2026 Jamie Halford\r\n\
\r\n\
Permission is hereby granted, free of charge, to any person obtaining a copy\r\n\
of this software and associated documentation files (the "Software""), to deal\r\n\
in the Software without restriction, including without limitation the rights\r\n\
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\r\n\
copies of the Software, and to permit persons to whom the Software is\r\n\
furnished to do so, subject to the following conditions:\r\n\
\r\n\
The above copyright notice and this permission notice shall be included in all\r\n\
copies or substantial portions of the Software.\r\n\
\r\n\
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\r\n\
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\r\n\
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\r\n\
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\r\n\
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\r\n\
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\r\n\
SOFTWARE.'
