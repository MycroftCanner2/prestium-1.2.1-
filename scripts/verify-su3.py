#!/usr/bin/env python3
"""Prestium 2.0: verify an I2P reseed .su3 file before it goes into the image.

  scripts/verify-su3.py FILE CERTDIR [MAX_AGE_DAYS]

Checks (exit 1 with "ERROR: ..." on the first failure):
  - SU3 magic "I2Psu3", format version 0, file type 0 (zip), content type 3 (reseed data);
  - signer ID is one of the StormyCloud reseed signers and its certificate is in CERTDIR
    (thirdparty/keys/reseed/, the same certificates i2pd ships in certificates/reseed/);
  - signature type 6 (RSA-4096 with SHA-512): the signature over header + version + signer + content
    is checked with openssl against the signer's certificate (I2P signs the raw SHA-512 digest with
    PKCS#1 v1.5 type 1 padding, without a DigestInfo);
  - the version (a Unix timestamp) is at most MAX_AGE_DAYS (default 14) old and not in the future;
  - the zip opens and holds routerInfo-*.dat entries.
Needs: python3, openssl.
"""
import io, os, struct, subprocess, sys, tempfile, time, zipfile, hashlib

SIGNERS = {"admin@stormycloud.org": "admin_at_stormycloud.org.crt",
           "idk@stormycloud.org": "idk_at_stormycloud.org.crt"}
MIN_ROUTERINFOS = 20


def die(msg):
    print("ERROR: su3: " + msg)
    sys.exit(1)


def main():
    if len(sys.argv) < 3:
        die("usage: verify-su3.py FILE CERTDIR [MAX_AGE_DAYS]")
    path, certdir = sys.argv[1], sys.argv[2]
    max_age = float(sys.argv[3]) if len(sys.argv) > 3 else 14.0
    d = open(path, "rb").read()
    if len(d) < 40 or d[:6] != b"I2Psu3":
        die("bad magic (not an SU3 file)")
    if d[7] != 0:
        die("unknown SU3 format version %d" % d[7])
    sigtype, siglen = struct.unpack(">HH", d[8:12])
    verlen, signerlen = d[13], d[15]
    contentlen = struct.unpack(">Q", d[16:24])[0]
    filetype, contenttype = d[25], d[27]
    if filetype != 0:
        die("file type %d, expected 0 (zip)" % filetype)
    if contenttype != 3:
        die("content type %d, expected 3 (reseed)" % contenttype)
    if sigtype != 6 or siglen != 512:
        die("signature type %d/%d bytes, expected 6 (RSA-4096 SHA-512)/512" % (sigtype, siglen))
    if verlen < 16:
        die("version field too short")
    signed_len = 40 + verlen + signerlen + contentlen
    if len(d) != signed_len + siglen:
        die("length mismatch: file %d, header says %d" % (len(d), signed_len + siglen))
    version = d[40:40 + verlen].rstrip(b"\0").decode("ascii", "replace")
    signer = d[40 + verlen:40 + verlen + signerlen].decode("ascii", "replace")
    content = d[40 + verlen + signerlen:signed_len]
    sig = d[signed_len:]
    if signer not in SIGNERS:
        die("unexpected signer %r" % signer)
    cert = os.path.join(certdir, SIGNERS[signer])
    if not os.path.isfile(cert):
        die("no certificate %s" % cert)

    # signature: recover the PKCS#1 v1.5 (type 1) payload and compare with SHA-512(signed part)
    with tempfile.TemporaryDirectory() as t:
        pub, sf = os.path.join(t, "pub.pem"), os.path.join(t, "sig")
        r = subprocess.run(["openssl", "x509", "-in", cert, "-noout", "-pubkey"], capture_output=True)
        if r.returncode:
            die("cannot read certificate %s" % cert)
        open(pub, "wb").write(r.stdout)
        open(sf, "wb").write(sig)
        r = subprocess.run(["openssl", "pkeyutl", "-verifyrecover", "-pubin", "-inkey", pub,
                            "-in", sf, "-pkeyopt", "rsa_padding_mode:pkcs1"], capture_output=True)
        if r.returncode or r.stdout != hashlib.sha512(d[:signed_len]).digest():
            die("BAD SIGNATURE (signer %s)" % signer)
        r = subprocess.run(["openssl", "x509", "-in", cert, "-noout", "-checkend", "0"], capture_output=True)
        if r.returncode:
            die("certificate %s has expired" % cert)

    try:
        ts = int(version)
    except ValueError:
        die("version %r is not a timestamp" % version)
    now = time.time()
    if ts > now + 86400:
        die("version timestamp %d is in the future" % ts)
    age = (now - ts) / 86400
    if age > max_age:
        die("stale: version %s is %.1f days old (limit %g)" % (time.strftime("%Y-%m-%d %H:%M UTC", time.gmtime(ts)), age, max_age))

    try:
        z = zipfile.ZipFile(io.BytesIO(content))
        bad = z.testzip()
    except zipfile.BadZipFile as e:
        die("content is not a valid zip: %s" % e)
    if bad:
        die("corrupt zip entry %s" % bad)
    ri = [n for n in z.namelist() if n.startswith("routerInfo-") and n.endswith(".dat")]
    if len(ri) < MIN_ROUTERINFOS:
        die("only %d routerInfo entries" % len(ri))
    print("OK SU3 signer=%s version=%s (%s, %.1f days old) routerInfos=%d sha256=%s"
          % (signer, version, time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime(ts)), age, len(ri),
             hashlib.sha256(d).hexdigest()))


main()
