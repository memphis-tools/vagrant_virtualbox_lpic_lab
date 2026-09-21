[DOVECOT POC]
-------------
# DNSSEC + DANE SMTP Proof of Concept

## Objective

Demonstrate that:

1. DNSSEC protects the DNS records used to locate the SMTP server.
2. The SMTP server publishes a DNSSEC-authenticated TLSA record.
3. The TLS certificate presented by the SMTP server matches that TLSA record.
4. A DANE-capable client can therefore validate the SMTP server using DNSSEC + TLSA.

The test host is:

```text
dovecot.vagrant-dummy-ops.lab
```

The SMTP server resolves to:

```text
192.168.1.206
```

---

## 1. Verify the DNSSEC-protected MX record

Command:

```bash
dig +dnssec MX vagrant-dummy-ops.lab
```

Relevant output:

```text
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 17861
;; flags: qr rd ra ad;
```

The important flag is:

```text
ad
```

`ad` means that the local recursive resolver considers the DNS answer DNSSEC-authenticated.

The answer is:

```text
vagrant-dummy-ops.lab. 86400 IN MX 10 dovecot.vagrant-dummy-ops.lab.
```

and it is accompanied by:

```text
vagrant-dummy-ops.lab. ... IN RRSIG MX 8 2 ...
```

Therefore:

```text
vagrant-dummy-ops.lab
        │
        │ DNSSEC validated
        ▼
MX 10 dovecot.vagrant-dummy-ops.lab
```

---

## 2. Verify the DNSSEC-protected A record

Command:

```bash
dig +dnssec A dovecot.vagrant-dummy-ops.lab
```

Relevant output:

```text
;; flags: qr rd ra ad;
```

The DNS answer is:

```text
dovecot.vagrant-dummy-ops.lab. 86005 IN A 192.168.1.206
```

and it has an RRSIG:

```text
dovecot.vagrant-dummy-ops.lab. 86005 IN RRSIG A 8 3 ...
```

Therefore the hostname-to-IP mapping is also DNSSEC-authenticated:

```text
dovecot.vagrant-dummy-ops.lab
        │
        │ DNSSEC validated
        ▼
192.168.1.206
```

---

## 3. Verify the DNSSEC-protected TLSA record

Command:

```bash
dig +dnssec +multi TLSA \
  _25._tcp.dovecot.vagrant-dummy-ops.lab
```

The important part of the answer is:

```text
_25._tcp.dovecot.vagrant-dummy-ops.lab. 3575 IN TLSA 3 1 1 (
    A7B54A852D1A388DE73B4E91C92523FB60AD
    3D83D4AE535E7F185A60C800E52A )
```

The response also contains:

```text
RRSIG TLSA 8 5 3600 ...
```

and:

```text
;; flags: qr rd ra ad;
```

So the TLSA record itself is DNSSEC-authenticated.

The TLSA fields are:

```text
3 1 1
│ │ │
│ │ └── SHA-256
│ └──── SubjectPublicKeyInfo (SPKI)
└────── DANE-EE
```

The DNSSEC-authenticated assertion is therefore:

```text
SHA-256(SPKI)
=
A7B54A852D1A388DE73B4E91C92523FB60AD3D83D4AE535E7F185A60C800E52A
```

---

## 4. Inspect the certificate presented by SMTP

Command:

```bash
openssl s_client \
  -connect dovecot.vagrant-dummy-ops.lab:25 \
  -starttls smtp \
  -showcerts </dev/null
```

The SMTP server presents:

```text
subject =
C = FR,
L = PARIS,
ST = IDF,
O = DUMMY_OPS_TEAM,
OU = DUMMY_DEV_TEAM,
CN = dovecot.vagrant-dummy-ops.lab
```

The issuer is:

```text
CN = ca.vagrant-dummy-ops.lab
```

The TLS connection is successfully established:

```text
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
```

and OpenSSL reports:

```text
Verification: OK
Verify return code: 0 (ok)
```

This proves that the SMTP server successfully performs STARTTLS and that the certificate chains to a CA trusted by the local OpenSSL configuration.

However, this test alone does **not** prove DANE. OpenSSL here is performing normal certificate/CA verification; it is not demonstrating the TLSA match.

---

## 5. Perform the actual DANE validation

Command:

```bash
gnutls-cli \
  --starttls-proto smtp \
  --dane \
  -p 25 \
  dovecot.vagrant-dummy-ops.lab
```

GnuTLS connects to:

```text
Connecting to '192.168.1.206:25'...
```

The server presents:

```text
CN=dovecot.vagrant-dummy-ops.lab
```

Most importantly, GnuTLS reports the public-key SHA-256 identifier:

```text
Public Key ID:
    sha256:a7b54a852d1a388de73b4e91c92523fb60ad3d83d4ae535e7f185a60c800e52a
```

Compare this with the DNSSEC-authenticated TLSA record:

```text
A7B54A852D1A388DE73B4E91C92523FB60AD3D83D4AE535E7F185A60C800E52A
```

They are identical.

GnuTLS then reports:

```text
- Status: The certificate is trusted.
```

This is the actual DANE proof.

---

# What has been demonstrated

The complete chain is:

```text
                 DNSSEC
                   │
                   ▼
       vagrant-dummy-ops.lab
                   │
                   │ MX
                   ▼
       dovecot.vagrant-dummy-ops.lab
                   │
                   │ A
                   ▼
             192.168.1.206
                   │
                   │ TLSA
                   ▼
          3 1 1 A7B54A85...
                   │
                   │ DNSSEC authenticated
                   ▼
       Expected SHA-256(SPKI)
                   │
                   │ MATCH
                   ▼
       SMTP certificate public key
                   │
                   ▼
              TLS 1.3
```

In concrete terms:

```text
DNSSEC TLSA value:

a7b54a852d1a388de73b4e91c92523fb60ad3d83d4ae535e7f185a60c800e52a

        ==

GnuTLS certificate SPKI:

a7b54a852d1a388de73b4e91c92523fb60ad3d83d4ae535e7f185a60c800e52a
```

Therefore the DNSSEC-authenticated TLSA assertion matches the public key of the certificate actually presented by the SMTP server.

---

# DNSSEC vs DANE

The demonstration also illustrates the difference between the two technologies.

### DNSSEC

DNSSEC establishes:

> "The DNS information I received is cryptographically authentic."

Your evidence is:

```text
flags: ... ad
```

plus the corresponding:

```text
RRSIG
```

records.

### DANE

DANE uses that authenticated DNS information to establish:

> "The public key presented by this SMTP server corresponds to the key published in DNS."

Your evidence is:

```text
TLSA 3 1 1 A7B54A85...
```

matching:

```text
GnuTLS Public Key ID:
sha256:a7b54a85...
```

---

# Recommended final demonstration

For a live demonstration, run these three commands in sequence:

### Terminal 1 — DNSSEC

```bash
dig +dnssec +multi TLSA \
  _25._tcp.dovecot.vagrant-dummy-ops.lab
```

Point out:

```text
flags: ... ad
```

and:

```text
TLSA 3 1 1 A7B54A85...
RRSIG TLSA ...
```

### Terminal 2 — SMTP TLS

```bash
openssl s_client \
  -connect dovecot.vagrant-dummy-ops.lab:25 \
  -starttls smtp </dev/null
```

Point out:

```text
TLSv1.3
CN = dovecot.vagrant-dummy-ops.lab
Verify return code: 0 (ok)
```

### Terminal 3 — DANE

```bash
gnutls-cli \
  --starttls-proto smtp \
  --dane \
  -p 25 \
  dovecot.vagrant-dummy-ops.lab
```

Point out:

```text
Public Key ID:
sha256:a7b54a852d1a388de73b4e91c92523fb60ad3d83d4ae535e7f185a60c800e52a
```

Then show that it is exactly the same value as the DNSSEC-authenticated TLSA record.

That gives a complete and reproducible proof of:

**DNSSEC → authenticated TLSA → SMTP certificate → DANE validation.**


# About dovecot configuration (try an inbox mail which not needs an existing home dir)

    root@dovecot:~# rm -rf /var/mail/vhosts/boris/
    root@dovecot:~# ls -l /var/mail/vhosts/
    total 0

    root@dovecot:~# ls -l /home
    total 8
    drwx------ 6 ansible ansible 4096 Sep 21 13:54 ansible
    drwxr-xr-x 4 vagrant vagrant 4096 Sep 20 21:18 vagrant

    root@dovecot:~# id boris
    uid=10001(boris) gid=10000(sysadmin) groups=10000(sysadmin)
    root@dovecot:~#

    $ mutt -f imaps://boris@dovecot.vagrant-dummy-ops.lab
