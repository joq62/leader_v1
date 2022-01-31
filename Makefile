all:
#	service
	rm -rf ebin/* *_ebin;
	rm -rf src/*.beam *.beam  test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf appl_specs dbase host host_specs my* sd leader;
#	app
	cp src/*.app ebin;
	erlc -I ../infra/log_server/include -o ebin src/*.erl;
	echo Done
unit_test:
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf appl_specs dbase host host_specs my* sd;
	mkdir test_ebin;
#	common
	erlc -D unit_test -I ../infra/log_server/include -o ebin ../common/src/*.erl;
#	sd
	erlc -D unit_test -I ../infra/log_server/include -o ebin ../sd/src/*.erl;
#	appl_mgr
	cp ../appl_mgr/src/*.app ebin;
	erlc -D unit_test -I ../infra/log_server/include -I ../host/include -o ebin ../appl_mgr/src/*.erl;
#	host
	cp ../host/src/*.app ebin;
	erlc -D unit_test -I ../infra/log_server/include -I ../host/include -o ebin ../host/src/*.erl;
#	leader
	erlc -D unit_test -I ../infra/log_server/include -o ebin src/*.erl;
#	test application
	cp test_src/*.app test_ebin;
	erlc -I ../log_server/include -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin\
	    -setcookie cookie_test\
	    -sname test\
	    -unit_test monitor_node test\
	    -unit_test cluster_id test\
	    -unit_test cookie cookie_test\
	    -run unit_test start_test test_src/test.config
