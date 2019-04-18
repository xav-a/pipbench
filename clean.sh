HANDLER_NAMES=$(cd handlers/ && ls -d */)
for handler in $HANDLER_NAMES; do
    wsk -i action delete $(echo ${handler%/})
done

rm -rf random.dat *.txt handlers/ web/ load_simulator.so graph_resizing/new-graph-* \
        helper_modules/__pycache__
