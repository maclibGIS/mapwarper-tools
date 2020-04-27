function [results] = mapwarper_uploader(main_dir,series,upload_list_url, starting_item)

if nargin<4
    starting_item = 1;
end

%%% All the rest (stays the same)
cd(main_dir)
strrep(main_dir,'\','/');
if strcmp(main_dir(end),'/')==1
    main_dir = main_dir(1:end-1);
end

%%% Load the secrets file (with password information)
load([main_dir '/secrets.mat']);

%%% Download GSheet; save as tsv
ind_gid = strfind(upload_list_url,'/edit#gid');
gid_no = upload_list_url(ind_gid+6:end);
dl_url = [upload_list_url(1:ind_gid) 'export?format=tsv&' gid_no ];
websave([series '.tsv'],dl_url);

%%% Read the tsv into a Cell array
[H, C] = read_mapwarper_list([series '.tsv'],'\t',2);

%%% These are webwrite options that are not currently working
options_post = weboptions('Timeout',100,'Username',secrets.username, ...
    'Password',secrets.password,'RequestMethod','post',...
    'MediaType','auto','HeaderFields',{'ContentType' 'application/json'}); 
api_path = 'http://mapwarper.lib.mcmaster.ca/api/v1/maps';

results = struct;
%%% Loop through all sheets, upload using curl (included in repository)
for i = starting_item:1:size(C,1) %first 7 already ingested during tests.
    data = C{i,18};
    data = strrep(data,'"','\"');
    % Build the string:
    to_execute = ['curl-7.69.1-win64-mingw\bin\curl -H "Content-Type: application/json" -H "Accept: application/json" '...
        '-X POST -u ' secrets.username ':' secrets.password ' -d "' data '" http://mapwarper.lib.mcmaster.ca/api/v1/maps -b cookie'];
    results(i).execute = to_execute;
    % Run the command:
    [results(i).status,results(i).cmdout] = dos(to_execute);
    pause(5);
    %%% Perform a POST
    % response = webwrite(api_path,data,options_post);
end
