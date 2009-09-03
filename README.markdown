CapistranoDbTasks
=================

Add database tasks to capistrano to a Rails project

Currentlty

* It only supports mysql (both side remote and local)
* It has the following tasks: db:local:sync, db:production:rollback, db:production:backup

Commands mysql, mysqldump, bzip2 and unbzip2 must be in your PATH

Feel free to fork and to add more database support or new tasks.

Install
=======

Add it as a plugin
./script/plugin install ./script/plugin install git@github.com:sgruhier/capistrano-db-tasks.git



Example
=======

cap db:local:sync
or
cap production db:local:sync if you are using capistrano-ext to have multistages

Copyright (c) 2009 [Sébastien Gruhier - XILINUS], released under the MIT license
