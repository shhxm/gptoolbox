function [cache_exists,cache_name] = find_cache()
  % FIND_CACHE Called at the beginning of a very expensive caller function,
  % this function writes the input parameters (whatever's currently in scope)
  % to a temporary file and gets that files md5 checksum as a "cachename". If a
  % file with path built from that cache name and caller name exists and is
  % younger than the caller file name or any of its dependencies, then this
  % returns true and the cache name.
  %
  % [cache_exists,cache_name] = find_cache()
  %
  % Outputs:
  %   cache_exists  true if the cache_name file exists
  %   cache_name  path to cache file for this caller function on these inputs.
  %   
  % See also: create_cache

  % Something's not working correctly on linux
  if ~ismac
    cache_exists = false;
    cache_name = '';
  end

  S = dbstack(1);
  caller_name = S.name;
  % get a list of current variables in this scope, this is the input "state"
  variables = evalin('caller','who');
  % get a temporary file's name
  tmpf = [tempname('.') '.mat'];

  variable_names = sprintf('^%s$|',variables{:});
  save_cmd = sprintf('save(''%s'',''-regexp'',''%s'');',tmpf,variable_names);
  % save the "state" of the caller to file, so we can get a md5 checksum
  evalin('caller',save_cmd);

  % get md5 checksum on input "state", we append .cache.mat to the check sum
  % because we'll use the checksum as the cache file name
  [s,cache_name] = system(['tail -c +117 ' tmpf ...
    ' | md5 -r | awk ''{printf ".' caller_name '.cache."$1".mat"}''']);
  % clean up
  delete(tmpf);
  clear s tmpf variables;
  cache_exists = exist(cache_name,'file')~=0;
  % If cache exists, check that it's older than the caller file.
  if cache_exists
    cache_file = dir(cache_name);
    cache_date = datenum(cache_file.date);
    caller_dependencies = depends(caller_name);
    for si = 1:numel(caller_dependencies)
      caller_dep_name = caller_dependencies{si};
      caller_dep_file = dir(which(caller_dep_name));
      caller_dep_date = datenum(caller_dep_file.date);
      if cache_date < caller_dep_date
        cache_exists = false;
      end
    end
  end
end
