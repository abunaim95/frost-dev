%% The main script to run the ATLAS multi-contact walking optimization
% 
%

main_sim

model_bounds = atlas.getLimits();
bounds = struct();
bounds.RightStance = model_bounds;

bounds.RightStance.time.t0.lb = 0;
bounds.RightStance.time.t0.ub = 0;
bounds.RightStance.time.tf.lb = 0.2;
bounds.RightStance.time.tf.ub = 1;
bounds.RightStance.time.duration.lb = 0.2;
bounds.RightStance.time.duration.ub = 1;
bounds.RightStance.inputs.ConstraintWrench.fqfixed.lb = -1000;
bounds.RightStance.inputs.ConstraintWrench.fqfixed.ub = 1000;
bounds.RightStance.inputs.ConstraintWrench.fRightSole.lb = -10000;
bounds.RightStance.inputs.ConstraintWrench.fRightSole.ub = 10000;

bounds.RightStance.params.pqfixed.lb = zeros(3,1);
bounds.RightStance.params.pqfixed.ub = zeros(3,1);
bounds.RightStance.params.pRightSole.lb = zeros(6,1);
bounds.RightStance.params.pRightSole.ub = zeros(6,1);
bounds.RightStance.params.avelocity.lb = 0.2;
bounds.RightStance.params.avelocity.ub = 0.6;
bounds.RightStance.params.pvelocity.lb = [0.05, -0.3];
bounds.RightStance.params.pvelocity.ub = [0.3, -0.1];
bounds.RightStance.params.aposition.lb = -100;
bounds.RightStance.params.aposition.ub = 100;
bounds.RightStance.params.pposition.lb = [0.05, -0.3];
bounds.RightStance.params.pposition.ub = [0.3, -0.1];
bounds.RightStance.velocity.ep = 10;
bounds.RightStance.position.kp = 100;
bounds.RightStance.position.kd = 20;

bounds.LeftStance = model_bounds;

bounds.LeftStance.time.t0.lb = 0.2;
bounds.LeftStance.time.t0.ub = 0.6;
bounds.LeftStance.time.tf.lb = 0.4;
bounds.LeftStance.time.tf.ub = 2;
bounds.LeftStance.time.duration.lb = 0.2;
bounds.LeftStance.time.duration.ub = 1;
bounds.LeftStance.inputs.ConstraintWrench.fqfixed.lb = -1000;
bounds.LeftStance.inputs.ConstraintWrench.fqfixed.ub = 1000;
bounds.LeftStance.inputs.ConstraintWrench.fRightSole.lb = -10000;
bounds.LeftStance.inputs.ConstraintWrench.fRightSole.ub = 10000;

step_length_min = 0.1;
step_length_max = 0.4;
step_width_min = 0.17;
step_width_max = 0.25;
bounds.LeftStance.params.pqfixed.lb = zeros(3,1);
bounds.LeftStance.params.pqfixed.ub = zeros(3,1);
bounds.LeftStance.params.pRightSole.lb = [step_length_min;step_width_min;0;0;0;0];
bounds.LeftStance.params.pRightSole.ub = [step_length_max;step_width_max;0;0;0;0];
bounds.LeftStance.params.avelocity.lb = 0.2;
bounds.LeftStance.params.avelocity.ub = 0.6;
bounds.LeftStance.params.pvelocity.lb = [0.05, -0.3];
bounds.LeftStance.params.pvelocity.ub = [0.3, -0.1];
bounds.LeftStance.params.aposition.lb = -100;
bounds.LeftStance.params.aposition.ub = 100;
bounds.LeftStance.params.pposition.lb = [0.05, -0.3];
bounds.LeftStance.params.pposition.ub = [0.3, -0.1];
bounds.LeftStance.velocity.ep = 10;
bounds.LeftStance.position.kp = 100;
bounds.LeftStance.position.kd = 20;

r_stance.UserNlpConstraint = str2func('right_stance_constraints');
l_stance.UserNlpConstraint = str2func('left_stance_constraints');
r_impact.UserNlpConstraint = str2func('right_impact_constraints');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Create a gait-optimization NLP based on the existing hybrid system
%%%% model. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_grid.RightStance = 10;
num_grid.LeftStance = 10;
nlp = HybridTrajectoryOptimization('AtlasFlat',atlas_flat,num_grid,'EqualityConstraintBoundary',1e-4);
nlp.configure(bounds);

u = r_stance.Inputs.Control.u;
u2r = tovector(norm(u).^2);
u2r_fun = SymFunction(['torque_' r_stance.Name],u2r,{u});
rs_phase = getPhaseIndex(nlp,'RightStance');
addRunningCost(nlp.Phase(rs_phase),u2r_fun,'u');

u = l_stance.Inputs.Control.u;
u2l = tovector(norm(u).^2);
u2l_fun = SymFunction(['torque_' l_stance.Name],u2l,{u});
ls_phase = getPhaseIndex(nlp,'LeftStance');
addRunningCost(nlp.Phase(ls_phase),u2l_fun,'u');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Compile and export optimization functions
%%%% (uncomment the following lines when run it for the first time.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compileConstraint(nlp,[],[],export_path);
% compileObjective(nlp,[],[],export_path);
% constr_list = nlp.Phase(1).ConstrTable.Properties.VariableNames;
% compileConstraint(nlp,1,constr_list(18:23),export_path);
% constr_list = nlp.Phase(3).ConstrTable.Properties.VariableNames;
% compileConstraint(nlp,4,'xDiscreteMapRightImpact',export_path);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Load Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
loadNodeInitialGuess(nlp.Phase(1),r_stance, r_stance_param);
loadNodeInitialGuess(nlp.Phase(3),l_stance, l_stance_param);
loadEdgeInitialGuess(nlp.Phase(2),r_stance,l_stance);
loadEdgeInitialGuess(nlp.Phase(4),l_stance,r_stance);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Run the simulator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% atlas_multiwalk = simulate(atlas_multiwalk);
% atlas_multiwalk_opt = atlas_multiwalk_opt.loadInitialGuess(atlas_multiwalk);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Link the NLP problem to a NLP solver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
solver = IpoptApplication(nlp);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Run the optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[sol, info] = optimize(solver);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Export the optimization result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [calcs,param] = exportSolution(atlas_multiwalk_opt,sol);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Run animation of the optimal trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% export_file = fullfile(cur,'tmp','atlas_multi_contact_walking.avi');
% anim = animator(atlas);
% anim.animate(calcs,export_file)