all:bin/prepare_job_assignment_log bin/prepare_lsf_error_log bin/prepare_sys_log
.PHONY:all,clean,tar
job_ass_l =  ./src/job_assignment_log/
lsf_err_l =  ./src/lsf_error_log/
sys_log_l =  ./src/system_error_log/
lib = ./src/lib/
pjal_objects = $(job_ass_l)main.o $(lib)BasicTools.o \
		$(lib)LSFTermLog.o $(lib)MyDataBaseHandler.o
plel_objects = $(lsf_err_l)main.o $(lib)LSFErrorLog.o \
			   $(lib)BasicTools.o $(lib)MyDataBaseHandler.o $(lib)LogParser.o \
			   $(lib)SIMToolbox.o
psl_objects = $(sys_log_l)main.o $(lib)SystemLog.o \
			  $(lib)BasicTools.o $(lib)MyDataBaseHandler.o $(lib)LogParser.o \
			  $(lib)SIMToolbox.o
dlllib = -pthread -lmongoclient -lboost_thread \
		 -lboost_filesystem -lboost_program_options\
		 -lboost_system 
bin/prepare_job_assignment_log: $(pjal_objects) $(lib)MyBasicTool.h
	g++ $(pjal_objects) $(dlllib) -o bin/prepare_job_assignment_log
	@echo "prepare_job_assignment_log end!!\n"
bin/prepare_lsf_error_log: $(plel_objects)
	g++ $(plel_objects) $(dlllib) -o bin/prepare_lsf_error_log
	@echo "prepare_lsf_error_log!!\n"
bin/prepare_sys_log: $(psl_objects)
	g++ $(psl_objects) $(dlllib) -o bin/prepare_sys_log
test:./test/test.o
	g++ ./test/test.o $(dlllib) -o test.x
clear:
	-rm ./bin/*
	-rm *.gz
	-find . -name '*.o' -type f -print -exec rm -rf {} \;
tar:
	tar cvzf my_project.tar.gz src Makefile sys.config termReason.list *.plx
