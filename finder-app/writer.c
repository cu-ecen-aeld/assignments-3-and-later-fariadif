#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc,char ** argv)
{
	openlog(NULL,LOG_PERROR,LOG_USER);

	if(argc != 3)
	{
		syslog(LOG_ERR,"Invalid arguments");
		return(1);
	}

	FILE * file;
	char * file_name = argv[1];
	char * data = argv[2];
	syslog(LOG_DEBUG,"Writing %s to %s",data,file_name);
	file = fopen(file_name, "w");

	// Check if the file was opened successfully
    	if (file == NULL) {
        	syslog(LOG_ERR,"Failed to create the file.\n");
        	return(1);
    	}

	fputs(data,file);
	fclose(file);
	closelog();
	return 0;
}
