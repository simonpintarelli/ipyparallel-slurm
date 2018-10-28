#!/usr/bin/bash -l

remote=daint

profile_dir=$1
if [[ ! -f ${profile_dir}/security/ipcontroller-client.json || ! -f ${profile_dir}/security/ipcontroller-engine.json ]]; then
    echo "Error: directory ${profile_dir}/security must contain the following files:" >&2
    echo "  ipcontroller-client.json" >&2
    echo "  ipcontroller-engine.json" >&2
    exit 1
fi

ipc_file=${profile_dir}/security/ipcontroller-client.json
ipe_file=${profile_dir}/security/ipcontroller-engine.json

port_labels=(registration control mux task iopub notification)

ipc_host=$(grep location $ipc_file | sed -n 's/.*\"location\": \"\(.*\)\".*/\1/ p' )

echo "Setting up ssh forwarding to ${ipc_host} via ${remote}"
for label in ${port_labels[@]};
do
    port=$(grep ${label} ${ipc_file} | sed -n "s/.*\"${label}\": \([0-9]*\).*/\1/ p")
    echo "bind ${label} to localhost:${port}"
    ssh -L ${port}:${ipc_host}:${port} ${remote} -N -f  1> /dev/null 2>&1
done

echo "ipcontroller host: ${ipc_host}"

echo "Ports forwarded over ssh. Now overwrite ${ipc_host} by localhost in: "
echo " ${ipc_file}"
echo " ${ipe_file}"
sed -i 's/\"location\":.*/\"location\": \"localhost\",/' ${ipc_file}
sed -i 's/\"location\":.*/\"location\": \"localhost\",/' ${ipe_file}

jobid=$(echo $1 | sed -n 's/.*profile_job_\([0-9]*\).*/\1/ p')

echo "Connect to ipcluster:"
echo "import ipyparallel as ipp"
echo "c = ipp.Client(profile=job_${jobid})"
echo "view = c[:]"
