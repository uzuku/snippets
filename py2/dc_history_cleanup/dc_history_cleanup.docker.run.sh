#!/bin/bash

docker run -ti --rm -v $PWD:/home/work/dc_history_cleanup hub.baidubce.com/jpaas-public/pymysql:python-2.7-slim /home/work/dc_history_cleanup/dc_history_cleanup.py
