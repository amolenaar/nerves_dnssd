-module(dnssd_dist).

-define(dist_trace, true).

%% Handles the connection setup phase with other Erlang nodes.

-export([listen/1, accept/1, accept_connection/5,
         setup/5, close/1, select/1, is_node_name/1]).

-export([tick/2, getstat/1, setopts/2, getopts/2]).

%% internal exports

-export([do_setup/6]).

-include_lib("kernel/include/dist_util.hrl").
-include_lib("kernel/include/net_address.hrl").

%-define(trace(Fmt,Args), io:format("~p ~p:~s",[erlang:timestamp(),node(),lists:flatten(io_lib:format(Fmt, Args))])).

%% ------------------------------------------------------------
%%  Select this protocol based on node name
%%  select(Node) => Bool
%% ------------------------------------------------------------

select(Node) ->
    % trace("~p~n", [{select, Node}]),
    inet_tcp_dist:gen_select(inet_tcp, Node).

%% ------------------------------------------------------------
%% Create the listen socket, i.e. the port that this erlang
%% node is accessible through.
%% ------------------------------------------------------------

listen(Name) ->
    % trace("~p~n", [{listen, Name}]),
    inet_tcp_dist:gen_listen(inet_tcp, Name).

%% ------------------------------------------------------------
%% Accepts new connection attempts from other Erlang nodes.
%% ------------------------------------------------------------

accept(Listen) ->
    % trace("~p~n", [{accept, Listen}]),
    inet_tcp_dist:gen_accept(inet_tcp, Listen).

%% ------------------------------------------------------------
%% Accepts a new connection attempt from another Erlang node.
%% Performs the handshake with the other side.
%% ------------------------------------------------------------

accept_connection(AcceptPid, Socket, MyNode, Allowed, SetupTime) ->
    % trace("~p~n", [{accept_connection, AcceptPid, Socket, MyNode, Allowed, SetupTime}]),
    inet_tcp_dist:gen_accept_connection(inet_tcp, AcceptPid, Socket, MyNode, Allowed, SetupTime).

%% ------------------------------------------------------------
%% Setup a new connection to another Erlang node.
%% Performs the handshake with the other side.
%% ------------------------------------------------------------

trace(Fmt, Args) ->
    ok.
    % io:format("~p ~p:~s",[erlang:timestamp(),node(),lists:flatten(io_lib:format(Fmt, Args))]).

setup(Node, Type, MyNode, shortnames, SetupTime) ->
    trace("~p~n",[{dnssd_dist,self(),setup,Node,Type, MyNode, SetupTime}]),
    spawn_opt(?MODULE, do_setup,
	      [inet_tcp, self(), Node, Type, MyNode, SetupTime],
	      [link, {priority, max}]).

do_setup(Driver, Kernel, Node, Type, MyNode, SetupTime) ->
    trace("~p~n",[{dnssd_dist,self(),setup,Node}]),
    Timer = dist_util:start_timer(SetupTime),
    AddressFamily = Driver:family(),
    ErlEpmd = net_kernel:epmd_module(),
    case ErlEpmd:port_please(Node) of
    {port, Hostname, Ip, TcpPort, Version} ->  % list, tuple(int), int, int
        trace("port_please(~p) -> version ~p~n",
            [Node,Version]),
        dist_util:reset_timer(Timer),
        case
        Driver:connect(
            Ip, TcpPort,
            [{active, false}, {packet, 2}])
        of
        {ok, Socket} ->
            trace("Socket opened ~p", [{self(), erlang:port_info(Socket)}]),
            HSData = #hs_data{
                kernel_pid = Kernel,
                other_node = Node,
                this_node = MyNode,
                socket = Socket,
                timer = Timer,
                this_flags = 0,
                other_version = Version,
                f_send = fun Driver:send/2,
                f_recv = fun Driver:recv/3,
                f_setopts_pre_nodeup =
                fun(S) ->
                    inet:setopts
                (S,
                    [{active, false},
                    {packet, 4},
                    nodelay()])
                end,
                f_setopts_post_nodeup =
                fun(S) ->
                    inet:setopts
                (S,
                    [{active, true},
                    {deliver, port},
                    {packet, 4},
                    nodelay()])
                end,

                f_getll = fun inet:getll/1,
                f_address = fun(_,_) ->
                    #net_address{
                        address = {Ip,TcpPort},
                        host = Hostname,
                        protocol = tcp,
                        family = AddressFamily}
                end,
                mf_tick = fun(S) -> ?MODULE:tick(Driver, S) end,
                mf_getstat = fun ?MODULE:getstat/1,
                request_type = Type,
                mf_setopts = fun ?MODULE:setopts/2,
                mf_getopts = fun ?MODULE:getopts/2
                },
            trace("HSData ~p~n", [HSData]),
            dist_util:handshake_we_started(HSData),
            trace("survived handshake ~p~n",[{dnssd_dist,self(),Node,MyNode}]);
        _ ->
            %% Other Node may have closed since
            %% port_please !
            trace("other node (~p) "
                "closed since port_please.~n",
                [Node]),
            ?shutdown(Node)
        end;
    _ ->
        trace("port_please (~p) "
            "failed.~n", [Node]),
        ?shutdown(Node)
    end.

nodelay() ->
    case application:get_env(kernel, dist_nodelay) of
	undefined ->
	    {nodelay, true};
	{ok, true} ->
	    {nodelay, true};
	{ok, false} ->
	    {nodelay, false};
	_ ->
	    {nodelay, true}
    end.

%%
%% Close a socket.
%%
close(Socket) ->
    inet_tcp:close(Socket).

is_node_name(Node) when is_atom(Node) ->
    inet_tcp_dist:is_node_name(Node).

tick(Driver, Socket) ->
    inet_tcp_dist:tick(Driver, Socket).

getstat(Socket) ->
    inet_tcp_dist:getstat(Socket).

setopts(S, Opts) ->
    inet_tcp_dist:setopts(S, Opts).

getopts(S, Opts) ->
    inet_tcp_dist:getopts(S, Opts).
