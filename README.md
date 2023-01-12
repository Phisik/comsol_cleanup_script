# COMSOL cleanup script
MATLAB script for clearing solution data in MPH-files

COMSOL projects consume enormous amount of disk space. This space can be drastically reduced by removing solution & mesh data from the MPH-files.

The script clears COMSOL solution data in your MPH files. The script starts COMSOL server, loads models one-by-one from target folder, clears mesh & solution data and saves it back on disk. 

USE AT YOUR OWN RISK.
IN PARTICULAR, DO NOT USE IF YOU DON'T UNDERSTAND WHAT IT DOES. Documentation for all of the items used below is publicly available.

Read through the code before you use it. Some important information is in the inline comments.

Prerequisites:
1) Install COMSOL with LiveLink for MATLAB
2) Install all COMSOL modules required by files your are going to reduce 
3) Modify search_path, maxsize & comsol_server_path
4) Test the script on any test folder before you feed it with the entire disk

Search strings:
* Batch reduction of COMSOL projects file size
* Script for clearing solution data in MPH-files
* Batch processing of COMSOL MPH-files
