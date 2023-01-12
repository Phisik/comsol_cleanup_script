% Copyright 2023 Ilya Lomaev
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%      http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% The script is based on the original Evgeni Nikitich Sergeev Java scripts
% https://web.archive.org/web/20200218163239/http://evgeni.org/oldfish/Script_for_clearing_Comsol_solution_data_in_all_your_MPH_files

%
% Search strings:
% > Batch reduction of COMSOL projects file size
% > Script for clearing solution data in MPH-files
% > Batch processing of COMSOL MPH-files
%

% COMSOL projects consume enormous amount of disk space. This space can be
% drastically reduced by removing solution & mesh data from the MPH-files.
% 
% The script clears COMSOL solution data in your MPH files. The script       
% starts COMSOL server, loads models one-by-one from target folder, clears
% mesh & solution data and saves it back on disk. 
%
% USE AT YOUR OWN RISK.
%
% IN PARTICULAR, DO NOT USE IF YOU DON'T UNDERSTAND WHAT IT DOES. Documentation
% for all of the items used below is publicly available.
%
% Read through the code before you use it. Some important information is in
% the inline comments.
%
% Prerequisites:
% 1) Install COMSOL with LiveLink for MATLAB
% 2) Install all COMSOL modules required by files your are going to reduce 
% 3) Modify search_path, maxsize & comsol_server_path
% 4) Test the script on any test folder before you feed it with the entire disk
%

% import reqired modules
import com.comsol.model.*;
import com.comsol.model.util.*;

%
% The path the script will look for MPH-files. 
%
error('NB! YOU MUST UPDATE THE SEARCH PATH!!!');
search_path = 'd:\';  % NB! REPLACE THIS!!!

%
% Usually there is no need to process files smaller than 5Mb
%
Mb = 1e6;
maxsize = 5*Mb; % 5Mb

%
% This script was used and tested in Windows 10 environment. You have to 
% adjust it your way to run in Linux environment
%

comsol_path = 'c:\Program Files\COMSOL\COMSOL56\Multiphysics\';
comsol_server = fullfile(comsol_path, 'bin', 'win64', 'comsolmphserver.exe');
reclaimed_total = 0;

% help MATLAB to find livelink interface functions
addpath(fullfile(comsol_path, 'mli'));

% Get a list of %.mph files larger than maxsize
filelist = dir(fullfile(search_path, '**\*.mph'));  
filelist = filelist([filelist.bytes]>maxsize);
fprintf("Found %d mph files larger than %dMb\n", length(filelist), maxsize/Mb);

if length(filelist) < 1
    fprintf('No files found to be processed. Terminating...\n');
    return
end

% Connect to comsol mph server or start it if failed
while(1)
    try
        fprintf('Connecting to COMSOL server... ');
        % using evalc supresses mphstart output
        evalc('mphstart');
        % if there was no exception it means we are got connected
        break;
    catch e
        if(contains(e.message, 'Failed to connect to server', 'IgnoreCase', true))
            fprintf('Failed.\n');
            fprintf('Starting new COMSOL server... ');
            
            % use Java ProcessBuilder to start mphserver
            % but you can always start it manually 
            % check COMSOL docs for Livelink For MATLAB
            % https://doc.comsol.com/5.4/doc/com.comsol.help.llmatlab/LiveLinkForMATLABUsersGuide.pdf
            processBuilder = java.lang.ProcessBuilder(comsol_server);
            % processBuilder.redirectOutput(Redirect.DISCARD);
            % processBuilder.redirectError(Redirect.DISCARD);
            mphserver = processBuilder.start();
            fprintf('Done.\n');
        elseif contains(e.message, 'Already connected to a server', 'IgnoreCase', true)
            break;
        else
            fprintf('Failed.\n');
            fprintf(1,'Error message: \n%s\n', e.message);
            pause(5);
        end
    end
end % while(1)
fprintf('Done.\n');

% loop over 
for nfile = 1:length(filelist)
    try     
        fprintf("Processing file %d of %d: \'%s\'...\n", ...
            nfile, length(filelist), filelist(nfile).name);
        filename = fullfile(filelist(nfile).folder, filelist(nfile).name);
        initial_size = filelist(nfile).bytes/Mb;

        model = ModelUtil.load("Model", filename);
        disp("   File was loaded successfully");

        solution_tags = model.sol().tags();
        for ntag = 1:length(solution_tags)
            tag = solution_tags(ntag);
            fprintf("   Clearing solution %s\n", tag);
            model.sol(tag).clearSolutionData();
        end
        disp("   Cleared all solutions");

        model.mesh().clearMeshes();
        disp("   Cleared all meshes");

        model.save;
        disp("   File was saved successfully");
       

        file_data = dir(filename);
        new_size = file_data.bytes/Mb;
        
        reclaimed_total = reclaimed_total + initial_size - new_size;

        fprintf("   Sizes: old %0.1fMb new %0.1fMb reclaimed %0.1f Mb. %0.1fMb total.\n", ...
                    initial_size, ...
                    new_size, ...
                    (initial_size - new_size), reclaimed_total);
                
    catch e % MException struct
        if contains(e.message, 'Product is not installed')
            fprintf('Warning: file %s was skipped. Please install missing modules.', filelist(nfile).name);
            continue
        else
            fprintf('The identifier was: %s\n',e.identifier);
            fprintf('There was an error! The message was:\n%s\n', e.message);
            % more error handling...
            break
        end
    end
end

ModelUtil.disconnect();
if(exist('mphserver', 'var'))
    %mphserver.destroy();
    mphserver.waitFor();
end

fprintf("Totally reclaimed %0.1f Mbytes\n", reclaimed_total);
