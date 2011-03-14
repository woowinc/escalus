-module(escalus_story).

% Public API
-export([story/3]).

-include_lib("test_server/include/test_server.hrl").

%%--------------------------------------------------------------------
%% Public API
%%--------------------------------------------------------------------

story(Config, ResourceCounts, Test) ->
    UserSpecs = escalus_users:get_users(all),
    Clients = [start_clients(Config, UserSpec, ResCount) ||
               {{_, UserSpec}, ResCount} <- zip_shortest(UserSpecs,
                                                         ResourceCounts)],
    ClientList = lists:flatten(Clients),
    prepare_clients(Config, ClientList),
    apply(Test, ClientList).

%%--------------------------------------------------------------------
%% Helpers
%%--------------------------------------------------------------------

start_clients(Config, UserSpec, ResourceCount) ->
    [start_client(Config, UserSpec, ResNo) ||
     ResNo <- lists:seq(1, ResourceCount)].

start_client(Config, UserSpec, ResNo) ->
    RandPart = binary_to_hex_list(crypto:rand_bytes(10)),
    Res = "res" ++ integer_to_list(ResNo) ++ "-" ++ RandPart,
    escalus_client:start_wait(Config, UserSpec, Res).

prepare_clients(Config, ClientList) ->
    case proplists:get_bool(escalus_save_initial_history, Config) of
        true ->
            do_nothing;
        false ->
            lists:foreach(fun escalus_client:drop_history/1, ClientList)
    end.

hex(N) when N < 10 ->
    $0 + N;
hex(N) when N < 16 ->
    $a + N - 10.

binary_to_hex_list(Binary) ->
    HexBinary = << <<(hex(X bsr 4)), (hex(X band 16#0F))>> || <<X>> <= Binary>>,
    binary_to_list(HexBinary).

zip_shortest([H1|T1], [H2|T2]) ->
    [{H1,H2}|zip_shortest(T1, T2)];
zip_shortest(_, _) ->
    [].
