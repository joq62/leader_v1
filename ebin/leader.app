%% This is the application resource file (.app file) for the 'base'
%% application.
{application, leader,
[{description, "Leader application and cluster" },
{vsn, "1.0.0" },
{modules, 
	  [leader_app,leader,leader_sup,appfile,lib_leader]},
{registered,[leader]},
{applications, [kernel,stdlib]},
{mod, {leader_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/leader.git"},
{constraints,[]}
]}.
