%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(prototype_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("log.hrl").
%-include("configs.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
  %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start boot()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok= boot(),
%    io:format("~p~n",[{"Stop  boot()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start host_init()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok= host_init(),
    io:format("~p~n",[{"Stop  host_init()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start host_vm()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok= host_vm(),
%    io:format("~p~n",[{"Stop  host_vm()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start appl_mgr()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok= appl_mgr(),
%    io:format("~p~n",[{"Stop  appl_mgr()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start host_appl()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok= host_appl(),
%    io:format("~p~n",[{"Stop  host_appl()",?MODULE,?FUNCTION_NAME,?LINE}]),


%    io:format("~p~n",[{"Start dist_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=dist_1(),
%    io:format("~p~n",[{"Stop  sim_controller_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.
 %  io:format("application:which ~p~n",[{application:which_applications(),?FUNCTION_NAME,?MODULE,?LINE}]),

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
host_init()->
    %% Config files and ebin for host is already loaded and the vm is started
    [H1|_]=test_nodes:get_nodes(),
 

    HostEbin="ebin",
    true=rpc:call(H1,code,add_patha,[HostEbin],5000),
    ok=rpc:call(H1,boot_host,start,[[worker]], 10000),
    [HostVm1]=rpc:call(H1,sd,get,[host],5000),
    pong=rpc:call(HostVm1,host,ping,[],10000),
    
    %start a leader 
    
    ok=rpc:call(HostVm1,application,set_env,[[{leader,[{application,host}]}]],5000),
    ok=rpc:call(HostVm1,host,load_appl,[leader,HostVm1],10000),
    ok=rpc:call(HostVm1,host,start_appl,[leader,HostVm1],10000),

%   ok=rpc:call(HostVm1,application,start,[leader],5000),
    timer:sleep(2000),
    
    gl=rpc:call(HostVm1,leader,who_is_leader,[],5000),
    
    

    ok.

check_ping(_Num,_Vm,_Module,_T,true)->
    ok;
check_ping(0,_Vm,_Module,_T,Acc)->
    Acc;
check_ping(Num,Vm,Module,T,Acc)->
    io:format("Num Vm ~p~n",[{Num,Vm,?FUNCTION_NAME,?MODULE,?LINE}]),
    case rpc:call(Vm,Module,ping,[],5000) of
	{badrpc,_}->
	    NewAcc=false, 
	    NewN=Num-1,
	    timer:sleep(T);
	pang->
	    NewAcc=false, 
	    NewN=Num-1,
	    timer:sleep(T);
	pong ->
	    NewAcc=true,
	    NewN=Num-1
    end,
    check_ping(NewN,Vm,Module,T,NewAcc).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

host_vm()->
  % Test host initiated in host_init
    [H1|_]=test_nodes:get_nodes(),
  %  ok=application:start(host),
    [HostVm]=rpc:call(H1,sd,get,[host],5000),
    {ok,N1}=rpc:call(HostVm,host,create,[],5000),
    pong=net_adm:ping(N1),
    Test1=test_1@c100,
    {ok,Test1}=rpc:call(HostVm,host,create,["test_1"],5000),
    pong=net_adm:ping(Test1),
    
    ok=rpc:call(HostVm,host,delete,[N1],5000),
    pang=net_adm:ping(N1),

    ok=rpc:call(HostVm,host,delete,[Test1]),
    pang=net_adm:ping(Test1),

    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
appl_mgr()->
    % Test host initiated in host_init
    [H1|_]=test_nodes:get_nodes(),
    [HostVm]=rpc:call(H1,sd,get,[host],5000),
    {ok,"dbase/1.0.0"}=rpc:call(HostVm,appl_mgr,get_appl_dir,[dbase,"1.0.0"],5000),
%    ok=rpc:call(H1,appl_mgr,load_specs,[],5000),
%    io:format(" ~p~n",[{appl_mgr:all_app_info(),?FUNCTION_NAME,?MODULE,?LINE}]),
    {ok,"dbase/1.0.0"}=rpc:call(HostVm,appl_mgr,get_appl_dir,[dbase,"1.0.0"],5000),
    {ok,"dbase/1.0.0"}=rpc:call(HostVm,appl_mgr,get_appl_dir,[dbase,latest],5000),
    
   
    {ok,"myadd/1.0.0"}=rpc:call(HostVm,appl_mgr,get_appl_dir,[myadd,"1.0.0"],5000),
    {ok,"myadd/1.0.0"}=rpc:call(HostVm,appl_mgr,get_appl_dir,[myadd,latest],5000),
   
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
host_appl()->
   
    % Test host initiated in host_init
    [H1|_]=test_nodes:get_nodes(),
    % Start a Vm  

    [H1|_]=test_nodes:get_nodes(),
    [HostVm]=rpc:call(H1,sd,get,[host],5000),

    {ok,N1}=rpc:call(HostVm,host,create,[],5000),
    false=lists:keymember(myadd,1,rpc:call(N1,application,loaded_applications,[],1000)),
    false=lists:keymember(myadd,1,rpc:call(N1,application,which_applications,[],1000)), 
    % Load an application  
    ok=rpc:call(HostVm,host,load_appl,[myadd,N1],5000),
    true=lists:keymember(myadd,1,rpc:call(N1,application,loaded_applications,[],1000)),
    false=lists:keymember(myadd,1,rpc:call(N1,application,which_applications,[],1000)),
    % Start an application   
    ok=rpc:call(HostVm,host,start_appl,[myadd,N1],5000),
    true=lists:keymember(myadd,1,rpc:call(N1,application,loaded_applications,[],1000)),
    true=lists:keymember(myadd,1,rpc:call(N1,application,which_applications,[],1000)),
    % Test the application
    42=rpc:call(N1,myadd,add,[20,22],1000),
    {error,{already_started,myadd}}=rpc:call(HostVm,host,start_appl,[myadd,N1],5000),    
    
   % [H1]=rpc:call(H1,sd,get,[host],5000),

    % stop an application 
    ok=rpc:call(HostVm,host,stop_appl,[myadd,N1],5000),
    true=lists:keymember(myadd,1,rpc:call(N1,application,loaded_applications,[],1000)),
    false=lists:keymember(myadd,1,rpc:call(N1,application,which_applications,[],1000)),
    {badrpc,_}=rpc:call(N1,myadd,add,[20,22],1000),
    % Unload an application
    ok=rpc:call(HostVm,host,unload_appl,[myadd,N1],5000),
    false=lists:keymember(myadd,1,rpc:call(N1,application,loaded_applications,[],1000)),
    false=lists:keymember(myadd,1,rpc:call(N1,application,which_applications,[],1000)),
    {badrpc,_}=rpc:call(N1,myadd,add,[20,22],1000),
    
  
    ok.
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
dist_1()->
    [H1,H2,H3]=test_nodes:get_nodes(),
    io:format("sd:all ~p~n",[{rpc:call(H1,sd,all,[],2000),?FUNCTION_NAME,?MODULE,?LINE}]),

    ok=rpc:call(H2,boot_host,start,[[controller]],10000),
    ok=rpc:call(H3,boot_host,start,[[controller]],10000),
   
  %  [H1,H2,H3]=lists:sort(rpc:call(H1,sd,get,[host],2000)),
  %  [H1,H2,H3]=lists:sort(rpc:call(H2,sd,get,[host],2000)),
  %  [H1,H2,H3]=lists:sort(rpc:call(H3,sd,get,[host],2000)),

  %  {state,worker}=rpc:call(H1,host,read_state,[],2000),
  %  {state,worker}=rpc:call(H2,host,read_state,[],2000),
  %  {state,controller}=rpc:call(H3,host,read_state,[],2000),
    
    io:format("sd:get(host) ~p~n",[{rpc:call(H1,sd,get,[host],2000),?FUNCTION_NAME,?MODULE,?LINE}]),
    
    

    ok.
    


    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
   
          
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
   
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
