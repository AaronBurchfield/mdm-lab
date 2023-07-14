#!/bin/sh

if [[ ! -f "/depot/ca.pem" ]]; then
  /usr/bin/scepserver ca -init -depot=/depot
fi

/usr/bin/scepserver -depot=/depot -challenge=${SCEP_CHALLENGE} -port=8080 -allowrenew=0
