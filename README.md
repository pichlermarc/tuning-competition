# AAU DBT Tuning Competition Docker Setup #

This repository provides the files to build and run a docker-image that contains the following things:

 - MySQL Server 5.7
 - Perl interpreter
 - Database creation scripts
 - Database benchmarking scripts

 ## How to get started ##

### Step 1: ###

Install [Docker Community Edition](https://docs.docker.com/install/). 
 - Docker Desktop is available for Windows and MacOS. 
 - Docker CE Server is available for CentOS, Debian, Fedora and Ubuntu. 
 - For other distributions there might be community-created packages available.

### Step 2 (Linux Distibutions only) ###

Install `docker-compose`, since it is not included with the Docker CE Server. It allows you to easily build the image and start the container without the need of having to type in all the arguments everytime.

To install `docker-compose`, first install `python3` and `python3-pip` via your system's package manager if you haven't already.

Then use `pip3` to install docker-compose:
`sudo pip3 install docker-compose`

### Step 3: ###

Open a terminal in the root folder of this project and run `docker-compose build`

This step requires an internet connection. It will download all the necessary dependencies and create the docker-image for you.

### Step 4: ###

Make sure that port 3306 is not in use on your host-system. If port 3306 is not in use, continue with Step 5!

If it is in use either shutdown the process that is using it (and continue with Step 5), or remap the port by changing the `docker-compose.yml` of this repository.

To remap a port, open `docker-compose.yml` with an text-editor of your choice. You will find a section that looks like this:

```
ports:
      - '3306:3306'
```

By changing the number on the left, you can remap the port to **any free port** on your system, so if you want to remap it to port 33333 change the block to:

```
ports:
      - '33333:3306'
```

Don't forget to save the file.

### Step 5 ###

Run `docker-compose up`

This will start a docker-container and will automatically map some directories to your hosts filesystem. 
 - `mysql-data/` which contains all the databases
 - `mysql-conf/` which contains the configuration
 - `mysql-init/` which contains a `.sql` files that is run on first startup.
 - `tuning-logs/` which contains the bemchmark-logs created by the scripts.

 ### Step 6 ###

To generate data for your database you need to run `docker exec -it tuning-competition create`

**WARNING: This will fill your database with ~3.3 GB of data and might take some time.** 

If you want to create a smaller database you can run 
- `docker exec -it tuning-competition create small` 

    --or--

- `docker exec -it tuning-competition create tiny`

### Step 7 ###

To run the benchmark, run `docker exec -it tuning-competition clientsim`, if you want to reduce the amount of time the simulation is executed, you can add argument `-r [runtime]` after `clientsim`, where `[runtime]` is supposed to be replaced by the amount of seconds the simulation is supposed to be run.

## Additional infos / FAQ ##

**How can I delete my database and start from scratch?**

You can shutdown the container and remove the `mysql-data/` directory. A new database will be created on startup. Afterwards repeat Steps 5 and 6 and you should be good to go!

**I want to edit my MySQL configuration, where is the file?**

To edit the MySQL configuration, edit `mysql-conf/mysql.cnf` in a text editor of your choice. Restart the container with `docker-compose up` and the settings are loaded.

**Where are the logs that I'm supposed to upload?**

The logs are inside the `tuning-logs` folder. If you accidentally deleted the foler, it will be recreated on `docker-compose up` :)

**I cannot connect to the server.**

If you're trying to connect to `localhost` and you are on a *nix based system, try using `127.0.0.1` instead. The default mysql-client will try to connect via Unix-Sockets if `localhost` is used as the host. Using `127.0.0.1` will default to TCP!

**I get some seriously weird errors...**

Try removing docker from your system install the newest version, as well as the newest version of `docker-compose`, sometimes outdated versions cause problems that are fixed in newer versions. 

