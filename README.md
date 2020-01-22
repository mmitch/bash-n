bash-n
======

_bash-n_ is a library to simplify writing
[connected-n](https://github.com/fiduciagad/connected-n) game clients
in bash.

To write a client, `source bash-n-client` in your script and then
implement the methods at the top of `bash-n-client` by redefining the
functions with your own code.

Use `udpwrap.pl` to run a client; see below for details.


demo clients
------------

Some simple demo clients are included:

 - `bash-n-failbot` permanently makes illegal moves
 - `bash-n-slothbot` permanently times out
 - `bash-n-simplebot` plays completely random
 - `bash-n-towerbot` tries to build vertical stacks


UDP communication
-----------------

Two pecularities of the way the game implements the UDP protocol
prevent the usage of the internal bash methods for UDP communication
via `/dev/udp/host/port`:

 - the individual messages have no end-of-packet marker like a line
   ending or a final semicolon, so the raw UDP datagrams need to be
   handled by the client

 - the game server sends from a different port than the one it is
   listening on

To mitigate this, `udpwrap.pl` provides a UDP wrapper written in Perl
that translates between UDP datagrams and a single lines of text with
a proper line terminator in both directions:

```
usage:
  udpwrap.pl <local_port> <server:port> <bot_script>

example:
  udpwrap.pl 5000 localhost:4446 ./bash-n-simplebot
```

This will also work for game clients not using `bash-n-client` and/or
written in another language.  Any game client that talks the game
protocol via stdin/stdout can be wrapped with `udpwrap.pl`, removing
the need to implement the low-level network stuff.


project location
----------------

_bash-n_ has its home at https://github.com/mmitch/bash-n/


copyright
---------

bash-n - bash library for connect-n game clients

Copyright (C) 2019, 2020  Christian Garbs <mitch@cgarbs.de>  
Licensed under GNU GPL v3 or later.

bash-n is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

bash-n is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with bash-n.  If not, see <http://www.gnu.org/licenses/>.
