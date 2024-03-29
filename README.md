<div align="center">
    <img src="./docs/cgi-128.gif" width="128" />
    <h1>CGILua 6</h1>
</div>

<br/>

http://lunarmodules.github.io/cgilua/

## Overview

CGILua is a tool for creating dynamic Web pages and manipulating input data
from Web forms. CGILua allows the separation of logic and data handling from
the generation of pages, making it easy to develop web applications with Lua.

One of advantages of CGILua is its abstraction of the underlying Web server.
CGILua can be used with a variety of Web servers and, for each server, with
different launchers. A launcher is responsible for the interaction of CGILua
and the Web server, for example using ISAPI on IIS or mod_lua on Apache.

CGILua is free software and uses the same license as Lua 5.x (MIT).

You can install CGILua using [LuaRocks](https://luarocks.org):

```
luarocks install cgilua
```

## History

Version 6.0.2 [04/Jul/2020]

* Fix for preventing formatting errors
* Small LDoc corrections

Version 6.0.1 [17/May/2019]

* Bug correction on redirections
* Version variables definition
* Other minor corrections

Version 6.0.0 [05/Nov/2018]

* Adapted CGILua SAPI launcher to explore all WSAPI features
* SAPI layer removed
* Several fixes
* Lua 5.3 compatibility

Version 5.2.1 [22/Apr/2015]

* Uses Lua 5.2

Version 5.1.4 [22/Mar/2010]

* fixed file upload reentrancy
* new launchers for cgilua that do not depend on kepler_init
* Correction on mkurlpath

Version 5.1.3 [9/Mar/2009]

* Strips utf-8 BOM from templates in lp.include
* Fixed reentrancy bug
* Fixed reset of cgilua.urlpath

Version 5.1.2 [19/May/2008]

* Added the cgilua.authentication module
* cgilua.print now separates arguments with tabs, like Lua print
* Now print and write are aliases to cgilua.print and cgilua.put.
* Now strips an eventual #! from top of Lua Pages files
* CGILua can now process sequential requests in the same Lua state
* Better error handling. Wraps error message in valid HTML
* Bug fixed: CGILua was ignoring CGILUA_TMP in Windows
* Corrected the URL handling for the dispatcher (bug found by Ronaldo Sugii)
* Better URL handling for different locales
* Handling multiple values in the generated URL (patch by Matt Campbell)
* Fixed file handle leak in loader.lua
* Fixed bug [#2630] - Including new files (bug found by Bruno Massa)

Version 5.1.1 [21/Nov/2007]

* Changed the security policy for scripts. Now scripts have access to all Lua globals, including the debug and os packages. It is up to the application developer to choose what policy to use
* If you are using Kepler, it is strongly suggested that you replace your previous CGILua config.lua file with the new one installed by Kepler and then merge the differences
* Added the cgilua.dispatcher module
* Added default handlers for a set of MIME types. The default handlers return only the content-type and content-lenght headers for the files.
* Added functions cgilua.splitonfirst and cgilua.splitonlast
* Added functions cgilua.tmpfile and cgilua.tmpname
* Changed the use of "/test" for the session temporary directory checking (bug found by Yuri Takhteyev)
* Corrected the use of cgilua.QUERY in the session handling (bug found by Jim Madsen)
* Better handling of "application/xml" POST content types (patch by Ignacio Burgueño)
* Fixed Bug [#1910] - Bug in byte accounting in post.lua (found by Greg Bell)

Version 5.1.0 [23/Aug/2007]

* Uses Lua 5.1
* Added function cgilua.print (that uses tostring on its parameters)
* Added a generic dispatcher and the concept of CGILua Apps
* Replaced the cgi table used until CGILua 5.0 by two others cgilua.QUERY and cgilua.POST)
* Added fake "package" table to enable the user/programmer to create modules with global visibility
* Bug fix: return of HTTP status code
* Bug fix: close method was recreating the session file
* Correcting how LP handles strings with CR characters (Lua 5.0 would not mind, but Lua 5.1 does)
* Fixed a bug with lighttpd

Version 5.0.1 [20/Sep/2006]

* Uses Compat-5.1 Release 5.
* Caches Lua Pages template strings.
* New configuration examples.
* Improvements in the Session library.
* Removed the debug package from the user scripts environment.
* POST handling bug fixes (related to the text/plain content type).

Version 5.0 [23/Jul/2005]

* CGILua distribution includes now only the Lua files, the launchers have been moved to Kepler.
* The Stable library is now distributed with VEnv.
* Fixed a file upload bug in the CGI and Xavante launchers.
* cgilua.lp.include() now accepts an environment to run the preprocessed file in it.

Version 5.0 beta 2 [23/Dec/2004]

* Distribution bug fix: stable.lua was missing

Version 5.0 beta [15/Dec/2004]

* New ISAPI and Servlet Launchers.
* New Error Handling features.
* New persistent data feature (Stable).
* Uses the package model for Lua 5.1.
* Simpler User Session API.
* Small bug corrections

Version 5.0 alpha 3 [8/Jun/2004]
Version 5.0 alpha [21/Apr/2004]

## Credits

* CGILua 6.0 - CGILua 6.0 is maintained by Tomás Guisasola, including contributions from the
  community, including several commits by Peter Melnichenko and João Dutra Bastos. João worked
  sponsored by the Google Summer of Code program. His project was "Adapt CGILua SAPI launcher
  to explore all WSAPI features".
* CGILua 5.2 - CGILua 5.2 was maintained by Tomás Guisasola with contributions from Fábio
  Mascarenhas, Carla Ourofino and others from the community.
* CGILua 5.1 - CGILua 5.1 was maintained by André Carregal and Tomás Guisasola with contributions
  from Fábio Mascarenhas and others from the Kepler mailing list. 
* CGILua 5.0 - CGILua 5.0 was completely redesigned by Roberto Ierusalimschy, André Carregal and
  Tomás Guisasola as part of the Kepler Project. The implementation is compatible with Lua 5.0
  and was coded by Tomás Guisasola with invaluable contributions by Ana Lúcia de Moura, Fábio
  Mascarenhas and Danilo Tuler. CGILua 5.0 development was sponsored by Fábrica Digital,
  FINEP and CNPq.
* CGILua 4.0 - Ana Lúcia de Moura adapted CGILua 3.2 to Lua 4.0, reimplemented some code and
  added a few improvements but this version was not officially distributed.
* CGILua 3.x - CGILua was born as the evolution of an early system developed by Renato Ferreira
  Borges and André Clínio at TeCGraf. At the time (circa 1995) there were no CGI tools available
  and everything was done with shell scripts! However, the main contribution to CGILua 3 was done
  by Anna Hester, who consolidated the whole tool and developed a consistent distribution with
  versions 3.1 and 3.2 (the number was an effort to follow Lua version numbers).
  This version was widely used on a great variety of systems.
