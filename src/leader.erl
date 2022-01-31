%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(leader).

-behaviour(gen_server). 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("log.hrl").
%% --------------------------------------------------------------------
-define(WAIT_FOR_ELECTION_RESPONSE_TIMEOUT,2*1000).

-define(SERVER,leader).

%% External exports
-export([
	 status/0,
	 election_message/1,
	 election_response/0,
	 election_timeout/1,
	 coordinator_message/1,
	 start_election/0,
	 who_is_leader/0,
	 am_i_leader/1,
	 ping/0
	]).

-export([start/0,
	 stop/0]).


%% gen_server callbacks



-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {nodes, coordinator_node, messageLoopTimeout,pid_timeout}).

%% ====================================================================
%% External functions
%% ====================================================================
start()-> gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).

status()->
    gen_server:call(?SERVER,{status},infinity).

who_is_leader()->
    gen_server:call(?SERVER,{who_is_leader},infinity).
am_i_leader(CallingNode)->
    gen_server:call(?SERVER,{am_i_leader,CallingNode},infinity).
   
election_message(CoordinatorNode)->
     gen_server:cast(?SERVER,{election_message,CoordinatorNode}).
election_response()->
     gen_server:cast(?SERVER,{election_response}).
election_timeout(PidTimeout)->
    gen_server:cast(?SERVER,{election_timeout,PidTimeout}).
coordinator_message(CoordinatorNode)->
     gen_server:cast(?SERVER,{coordinator_message,CoordinatorNode}).

start_election()->
    gen_server:cast(?SERVER,{start_election}).

ping()-> gen_server:call(?SERVER, {ping},infinity).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
%    io:format("leader 1 ~p~n",[{?MODULE,?LINE}]),
    leader:start_election(),
    timer:sleep(?WAIT_FOR_ELECTION_RESPONSE_TIMEOUT),
 %   rpc:cast(node(),log,log,[?Log_info("server started",[])]),
    {ok, #state{nodes = [],
		coordinator_node = node(), 
		pid_timeout=no_pid}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call({who_is_leader},_From, State) ->
    Reply = State#state.coordinator_node,
    {reply, Reply, State};
handle_call({am_i_leader,CallingNode},_From, State) ->
    Reply =State#state.coordinator_node=:=CallingNode,
    {reply, Reply, State};
handle_call({status},_From, State) ->
    Reply = State,
    {reply, Reply, State};

handle_call({ping},_From, State) ->
    Reply = pong,
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({election_message,CoordinatorNode}, State) ->
    rpc:cast(node(),log,log,[?Log_debug("Election_message received",[CoordinatorNode])]),
%    io:format("CoordinatorNode ,node() , > ~p~n",[{CoordinatorNode,node(),CoordinatorNode > node(),
%						   ?FUNCTION_NAME,?MODULE,?LINE}]),
%    {CoordinatorNodeName,_}=misc_node:vmid_hostid(CoordinatorNode),
 %   {NodeName,_}=misc_node:vmid_hostid(node()),
    CoordinatorId=misc_node:vmid_hostid(CoordinatorNode),
    NodeId=misc_node:vmid_hostid(node()),
    case CoordinatorId > NodeId of
	false->% lost election
	    NewState=State;
	true->
	    rpc:cast(CoordinatorNode,leader,election_response,[]),
	    NewState=start_election(State)	   
    end,
    {noreply, NewState};

handle_cast({election_response}, State) ->
    if 
	erlang:is_pid(State#state.pid_timeout)=:=true->
	    State#state.pid_timeout!kill;
	true->
	    ok
    end,
    NewState=State#state{pid_timeout=no_pid},
    {noreply, NewState};

handle_cast({election_timeout,_PidTimeout}, State) ->
    NewState=win_election(State),
    {noreply, NewState};

handle_cast({coordinator_message,CoordinatorNode}, State) ->
    io:format("Coordinator_message received ~p~n", [{CoordinatorNode,?FUNCTION_NAME,?MODULE,?LINE}]),
%    rpc:cast(node(),log,log,[?Log_debug("Coordinator_message received",[CoordinatorNode])]),
    NewState=set_coordinator(State, CoordinatorNode),
    {noreply, NewState};

handle_cast({start_election}, State) ->
    io:format("Start Election message received ~p~n", [{?FUNCTION_NAME,?MODULE,?LINE}]),
 %   rpc:cast(node(),log,log,[?Log_debug("Start Election message received",[])]),
    NewState=start_election(State),
    {noreply, NewState};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{Msg,?FUNCTION_NAME,?MODULE,?LINE}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info({nodedown, CoordinatorNode},State) -> 
    io:format("nodedown Node ~p~n",[{CoordinatorNode,State#state.coordinator_node,?FUNCTION_NAME,?MODULE,?LINE}]),
    NewState=case State#state.coordinator_node=:=CoordinatorNode of
		 true->
		     start_election(State);
		 false->
		     State
	     end,
    {noreply, NewState};

handle_info(Info, State) ->
    io:format("unmatched match Info ~p~n",[{Info,?FUNCTION_NAME,?MODULE,?LINE}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Exported functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%%---------------------------------------------------------------
%% Function:load_appl(App)
%% @doc: loads latest version of App to vm Vm      
%% @param: Application and erlang vm to load 
%% @returns:ok|{error,Reason}
%%
%%---------------------------------------------------------------
%-spec load_appl(atom(),node())-> atom()|{atom(),term()}.
%load_appl(Appl,Vm)->
%    gen_server:call(?SERVER, {load_appl,Appl,Vm},infinity).


start_election(State) ->
%    rpc:cast(node(),log,log,[?Log_debug("Election started by node ",[])]),
    io:format("Election started by node ~p~n", [{node(),?FUNCTION_NAME,?MODULE,?LINE}]),
    Nodes=lib_leader:get_nodes(),
%    NodesHigherId=nodes_with_higher_ids(Nodes),
%    [rpc:cast(Node,leader,election_message,[node()])||Node<-NodesHigherId],
    NodesLowerId=nodes_with_lower_ids(Nodes),
%    io:format("NodesLowerId ~p~n",[{NodesLowerId,node(),
%				 ?MODULE,?FUNCTION_NAME,?LINE}]),
%    [rpc:cast(Node,leader,coordinator_message,[node()])||Node<-NodesLowerId],
    [rpc:cast(Node,leader,election_message,[node()])||Node<-NodesLowerId],
    PidTimeout=spawn(fun()->election_timeout() end),
    State#state{pid_timeout=PidTimeout}.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
%%---------------------------------------------------------------
%% Function:load_appl(App)
%% @doc: loads latest version of App to vm Vm      
%% @param: Application and erlang vm to load 
%% @returns:ok|{error,Reason}
%%
%%---------------------------------------------------------------
-spec load_appl(atom(),node())-> atom()|{atom(),term()}.
load_appl(Appl,Vm)->
    gen_server:call(?SERVER, {load_appl,Appl,Vm},infinity).

win_election( State) ->
  %  rpc:cast(node(),log,log,[?Log_debug("Node  won the election ",[node()])]),
    io:format("Node  won the election ~p~n", [{node(),?FUNCTION_NAME,?MODULE,?LINE}]),
 %   rpc:cast(node(),db_logger,create,["log","election winner",atom_to_list(node()),{?MODULE,?FUNCTION_NAME,?LINE}]),
%    {ok,Nodes}=application:get_env(leader,nodes),
    Nodes=lib_leader:get_nodes(), 
%   NodesLowerId=nodes_with_lower_ids(Nodes),
%    [rpc:cast(Node,leader,coordinator_message,[node()])||Node<-NodesLowerId],
    NodesHigherId=nodes_with_higher_ids(Nodes),
 %   io:format("NodesHigherId ~p~n",[{NodesHigherId,node(),
%				 ?MODULE,?FUNCTION_NAME,?LINE}]),
%    [rpc:cast(Node,leader,election_message,[node()])||Node<-NodesHigherId],
    [rpc:cast(Node,leader,coordinator_message,[node()])||Node<-NodesHigherId],
    set_coordinator(State, node()).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
set_coordinator(State, CoordinatorNode) ->
    monitor_node(State#state.coordinator_node, false),
    monitor_node(CoordinatorNode, true),
    if 
	erlang:is_pid(State#state.pid_timeout)=:=true->
	    State#state.pid_timeout!kill;
	true->
	    ok
    end,
    State#state{coordinator_node = CoordinatorNode, pid_timeout = no_pid}.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
election_timeout()->
    receive
	kill->
%	    io:format("kill ~p~n",[{?FUNCTION_NAME,?MODULE,?LINE}]),
	    ok
    after ?WAIT_FOR_ELECTION_RESPONSE_TIMEOUT->
	    Pid=self(),
%	    io:format("timeout ~p~n",[{?FUNCTION_NAME,?MODULE,?LINE}]),
	    rpc:cast(node(),leader,election_timeout,[Pid])
    end.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
nodes_with_higher_ids(ChallangeNodes) ->
    NodeId=misc_node:vmid_hostid(node()),
    [Node || Node<- ChallangeNodes,
	     misc_node:vmid_hostid(Node) > NodeId].

nodes_with_lower_ids(ChallangeNodes) ->
    NodeId=misc_node:vmid_hostid(node()),
    [Node || Node<- ChallangeNodes,
	     misc_node:vmid_hostid(Node) < NodeId].

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
get_nodes()->
    {ok,ApplNodes}=application:get_env(application),
    case sd:get(ApplNodes) of
	[]->
	 %   rpc:cast(node(),log,log,[?Log_info("no kubelet nodes ",[])]),
	    [];
	Nodes ->
	 %   rpc:cast(node(),log,log,[?Log_info("Nodes ",[Nodes])]),
	    lists:delete(node(),Nodes)
    end.

%nodes_with_higher_ids(Nodes) ->
 %   {NodeName,_}=misc_node:vmid_hostid(node()),
 %   NodeNodeNameHostIds=[{Node,misc_node:vmid_hostid(Node)}||Node<-Nodes],
 %   [Node || {Node, {XNodeName,_HostId}}<- NodeNodeNameHostIds,
%	     XNodeName > NodeName].

%nodes_with_lower_ids(Nodes) ->
% {NodeName,_}=misc_node:vmid_hostid(node()),
%    NodeNodeNameHostIds=[{Node,misc_node:vmid_hostid(Node)}||Node<-Nodes],
 %   [Node || {Node, {XNodeName,_HostId}}<- NodeNodeNameHostIds,
%	     XNodeName < NodeName].
   % [Node || Node <- Nodes, Node < NodeName ].

