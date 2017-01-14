-module(dnssd_definition).

-compile([export_all]).

%% dns-sd.h:kDNSServiceType
service_type() ->
    [
     {  1, <<"A">>},
     {  2, <<"NS">>},
     {  3, <<"MD">>},
     {  4, <<"MF">>},
     {  5, <<"CNAME">>},
     {  6, <<"SOA">>},
     {  7, <<"MB">>},
     {  8, <<"MG">>},
     {  9, <<"MR">>},
     { 10, <<"NULL">>},
     { 11, <<"WKS">>},
     { 12, <<"PTR">>},
     { 13, <<"HINFO">>},
     { 14, <<"MINFO">>},
     { 15, <<"MX">>},
     { 16, <<"TXT">>},
     { 17, <<"RP">>},
     { 18, <<"AFSDB">>},
     { 19, <<"X25">>},
     { 20, <<"ISDN">>},
     { 21, <<"RT">>},
     { 22, <<"NSAP">>},
     { 23, <<"NSAP_PTR">>},
     { 24, <<"SIG">>},
     { 25, <<"KEY">>},
     { 26, <<"PX">>},
     { 27, <<"GPOS">>},
     { 28, <<"AAAA">>},
     { 29, <<"LOC">>},
     { 30, <<"NXT">>},
     { 31, <<"EID">>},
     { 32, <<"NIMLOC">>},
     { 33, <<"SRV">>},
     { 34, <<"ATMA">>},
     { 35, <<"NAPTR">>},
     { 36, <<"KX">>},
     { 37, <<"CERT">>},
     { 38, <<"A6">>},
     { 39, <<"DNAME">>},
     { 40, <<"SINK">>},
     { 41, <<"OPT">>},
     { 42, <<"APL">>},
     { 43, <<"DS">>},
     { 44, <<"SSHFP">>},
     { 45, <<"IPSECKEY">>},
     { 46, <<"RRSIG">>},
     { 47, <<"NSEC">>},
     { 48, <<"DNSKEY">>},
     { 49, <<"DHCID">>},
     { 50, <<"NSEC3">>},
     { 51, <<"NSEC3PARAM">>},
     { 55, <<"HIP">>},
     { 99, <<"SPF">>},
     {100, <<"UINFO">>},
     {101, <<"UID">>},
     {102, <<"GID">>},
     {103, <<"UNSPEC">>},
     {249, <<"TKEY">>},
     {250, <<"TSIG">>},
     {251, <<"IXFR">>},
     {252, <<"AXFR">>},
     {253, <<"MAILB">>},
     {254, <<"MAILA">>},
     {255, <<"ANY">>}
    ].

%% dns-sd.h:kDNSServiceClass
service_class() ->
    [
     {1, <<"IN">>}
    ].

integer_to_name(Kind, I) when is_integer(I),
                              (service_type =:= Kind
                               orelse
                               service_class =:= Kind) ->
    case lists:keyfind(I, 1, ?MODULE:Kind()) of
        false -> integer_to_binary(I);
        {I, Name} -> Name
    end.

name_to_integer(Kind, Name) when (service_class =:= Kind orelse
                                  service_type =:= Kind),
                                 is_binary(Name) ->
    case lists:keyfind(Name, 2, ?MODULE:Kind()) of
        false -> {error, {unknown, Kind, Name}};
        {I, Name} -> I
    end.
