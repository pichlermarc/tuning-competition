FROM mysql:5.7

RUN apt-get update
RUN apt-get install -y perl libdbi-perl libdbd-mysql-perl
ADD course-data/ /var/course-data/
WORKDIR /var/course-data/
RUN chmod +x createDB.pl
RUN chmod +x clientsim.pl
RUN ln -s $(pwd)/createDB.pl /usr/bin/create
RUN ln -s $(pwd)/clientsim.pl /usr/bin/clientsim
