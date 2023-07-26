#!/bin/sh

# initialize (device) secret
test -f secret || {
    echo "generating \"secret\""
    dd if=/dev/urandom of=secret bs=32 count=1 2>/dev/null
}

echo "first run"

# create challenge for device, store blinding factor in tmp which name is in b
echo "run 1 create challenge"
echo -n "shitty master password" | ../challenge >c 2>b

# respond to challenge on device using the secret
echo "run 1 respond to challenge"
../respond secret <c >r0

fname=$(cat b)
echo "run 1 derive password from response"
{ cat r0; echo -n "shitty master password"; } | ../derive $fname c >pwd0

echo "second run"
echo "run 2 create challenge"
echo -n "shitty master password" | ../challenge >c 2>b
echo "run 2 respond to challenge"
../respond secret <c >r1
fname=$(cat b)
echo "run 2 derive password from response"
{ cat r1; echo -n "shitty master password"; } | ../derive $fname c >pwd1

rm c b

echo -n "verify blinding factors differ: "
cmp r0 r1 >/dev/null 2>/dev/null && {
    echo "fail the two blinding factors are identical"
    rm pwd0 pwd1
    exit 1
}
echo "ok"
rm r0 r1

echo -n "verify the passwords from the two runs are the same: "
cmp pwd0 pwd1 2>/dev/null >/dev/null || {
    echo "fail, the derived password from the two runs are not the same"
    exit 1
}
echo "ok"
rm pwd1
echo "success two runs produced the same password output"

echo "transforming into ascii passwords"
echo -n "full ascii, max size: " 
../2pass <pwd0
echo -n "no symbols, max size: " 
../2pass uld <pwd0
echo -n "no symbols, 8 chars: " 
../2pass uld 8 <pwd0
echo -n "only digits, 4 chars: " 
../2pass d 4 <pwd0
echo -n "only letters, 16 chars: " 
../2pass ul 16 <pwd0

rm pwd0
rm secret
