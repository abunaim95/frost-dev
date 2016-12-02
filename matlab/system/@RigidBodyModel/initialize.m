function obj = initialize(obj, reload)
    % This function load and initialize the rigid body model in the
    % symbolic Wolfram Mathematica Kernel.
    %
    % Parameters:
    %  reload: if 'true', re-initialize the model regardless. @type logical
    %
    % @note This function must be ran before using any functions
    % regarding symbolic calculation of robot model in Mathematica
    % Kernal.
    
    if nargin == 1
        reload = false;
    end
    
    try
        if reload
            eval_math('Get["RobotModel`"];');
        else
            eval_math('Needs["RobotModel`"];');
        end
    catch
        disp('Unable to find the Mathematica package!');
        disp('Trying run the mathematica_setup() function to initialize the Path environment.');
        mathematica_setup();
        eval_math('Get["RobotModel`"];');
    end
    
    flag = '$ModelInitialized';
    
    if checkFlag(obj, flag)
        disp('The model has been initialized in Mathematica.');
        disp('Skipping this operation ...');
        return;
    end
    % Load RobotModel Package
    
    
    %     if ~strcmpi(status,'Null')
    %         warning('Load Mathematica package "RobotModel`" failed.');
    %         obj.status.initialized = false;
    %         return;
    %     end
    
    
    eval_math(['InitializeModel[',str2math(obj.config_file),',',cell2tensor(obj.base_dof_axes),'];']);
    
   
end
