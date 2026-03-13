#!/bin/zsh

set -ex

testapp_name="testapp.app"
app_name="Integrator.app"
app_path="/Users/toma/Library/Developer/Xcode/DerivedData/EDR-bqktgmfcjfoattgdaberncaltpal/Build/Products/Debug/$app_name"
testapp_path="/Users/toma/Library/Developer/Xcode/DerivedData/EDR-bqktgmfcjfoattgdaberncaltpal/Build/Products/Debug/$testapp_name"
log_exec_name="log.command"
dbg_exec_name="dbg.command"
shared_host="/tmp/vmshare"
shared_guest="/Volumes/My Shared Files/vmshare"
vm="macOS"
snapshot=$(prlctl snapshot-list "$vm" | tail -1 | awk '{$1=$1};1' | tail -c+2)
atomic_zip="atomic-red-team.zip"

rm -rf "$shared_host"
mkdir "$shared_host"
cp -r "$app_path" "$shared_host"
cp -r "$testapp_path" "$shared_host"
cp /Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver "$shared_host"

pushd /Users/toma/Developer/disertatie/extern/
zip -r "$atomic_zip" atomic-red-team/atomics
cp "$atomic_zip" "$shared_host"
popd

cat <<EOF > "$shared_host/$log_exec_name"
#!/bin/zsh
/usr/bin/log stream --style compact --predicate 'sender BEGINSWITH "Integrator.debug" OR sender BEGINSWITH "com.toma"'
EOF

cat <<EOF > "$shared_host/$dbg_exec_name"
#!/bin/zsh
while true; do
    ps_output=\$(ps aux | grep com.toma | grep -v grep)
    if [ \$? -eq 0 ]; then
        pid=\$(echo "\$ps_output" | awk '{ print \$2 }')
        read -s -k '?Press any key to continue.'
        sudo "$shared_guest/debugserver" 0.0.0.0:5555 --attach="\$pid"
        break
    fi
done
EOF

prlctl snapshot-switch "$vm" --id "$snapshot"
prlctl exec "$vm" --current-user cp -r "'$shared_guest/$app_name'" /Applications
prlctl exec "$vm" --current-user cp -r "'$shared_guest/$testapp_name'" /Applications
prlctl exec "$vm" --current-user cp -r "'$shared_guest/$dbg_exec_name'" /tmp
prlctl exec "$vm" --current-user cp -r "'$shared_guest/$log_exec_name'" /tmp
prlctl exec "$vm" --current-user cp -r "'$shared_guest/$atomic_zip'" /tmp
prlctl exec "$vm" --current-user unzip -d /tmp "/tmp/$atomic_zip"
prlctl exec "$vm" --current-user chmod 700 "/tmp/$dbg_exec_name"
prlctl exec "$vm" --current-user chmod 700 "/tmp/$log_exec_name"
prlctl exec "$vm" --current-user open "/tmp/$dbg_exec_name"
prlctl exec "$vm" --current-user open "/tmp/$log_exec_name"
prlctl exec "$vm" --current-user open "/Applications/$app_name"
