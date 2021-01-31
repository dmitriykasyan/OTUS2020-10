# Домашнее задание PAM

## Задание:

Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис

## Подготовка

Из поставленной задачи и анализа модулей PAM, принимаем решение использовать модуль `pam_exec`. Выполним скрипт проверки группы подключаемого пользователя и текущего дня недели.

## Выполнение работы

Определимся с преременными модуля `PAM`:
<details> <summary> Просмотрим документацию по PAM: apropos pam </summary>

```bash
 root@PAMLab ~# apropos pam
PAM (8)              - Pluggable Authentication Modules for Linux
config-util (5)      - Common PAM configuration file for configuration utilities
fingerprint-auth (5) - Common configuration file for PAMified services
fingerprint-auth-ac (5) - Common configuration files for PAMified services written by authconfig(8)
group.conf (5)       - configuration file for the pam_group module
limits.conf (5)      - configuration file for the pam_limits module
pam (8)              - Pluggable Authentication Modules for Linux
pam.conf (5)         - PAM configuration files
pam.d (5)            - PAM configuration files
pam_access (8)       - PAM module for logdaemon style login access control
pam_console (8)      - determine user owning the system console
pam_console_apply (8) - set or revoke permissions for users at the system console
pam_cracklib (8)     - PAM module to check the password against dictionary words
pam_debug (8)        - PAM module to debug the PAM stack
pam_deny (8)         - The locking-out PAM module
pam_echo (8)         - PAM module for printing text messages
pam_env (8)          - PAM module to set/unset environment variables
pam_env.conf (5)     - the environment variables config files
pam_exec (8)         - PAM module which calls an external command
pam_faildelay (8)    - Change the delay on failure per-application
pam_faillock (8)     - Module counting authentication failures during a specified interval
pam_filter (8)       - PAM filter module
pam_ftp (8)          - PAM module for anonymous access module
pam_group (8)        - PAM module for group access
pam_issue (8)        - PAM module to add issue file to user prompt
pam_keyinit (8)      - Kernel session keyring initialiser module
pam_lastlog (8)      - PAM module to display date of last login and perform inactive account lock out
pam_limits (8)       - PAM module to limit resources
pam_listfile (8)     - deny or allow services based on an arbitrary file
pam_localuser (8)    - require users to be listed in /etc/passwd
pam_loginuid (8)     - Record user's login uid to the process attribute
pam_mail (8)         - Inform about available mail
pam_mkhomedir (8)    - PAM module to create users home directory
pam_motd (8)         - Display the motd file
pam_namespace (8)    - PAM module for configuring namespace for a session
pam_nologin (8)      - Prevent non-root users from login
pam_permit (8)       - The promiscuous module
pam_postgresok (8)   - simple check of real UID and corresponding account name
pam_pwhistory (8)    - PAM module to remember last passwords
pam_pwquality (8)    - PAM module to perform password quality checking
pam_rhosts (8)       - The rhosts PAM module
pam_rootok (8)       - Gain only root access
pam_securetty (8)    - Limit root login to special devices
pam_selinux (8)      - PAM module to set the default security context
pam_sepermit (8)     - PAM module to allow/deny login depending on SELinux enforcement state
pam_shells (8)       - PAM module to check for valid login shell
pam_succeed_if (8)   - test account characteristics
pam_systemd (8)      - Register user sessions in the systemd login manager
pam_tally2 (8)       - The login counter (tallying) module
pam_time (8)         - PAM module for time control access
pam_timestamp (8)    - Authenticate using cached successful authentication attempts
pam_timestamp_check (8) - Check to see if the default timestamp is valid
pam_tty_audit (8)    - Enable or disable TTY auditing for specified users
pam_umask (8)        - PAM module to set the file mode creation mask
pam_unix (8)         - Module for traditional password authentication
pam_userdb (8)       - PAM module to authenticate against a db database
pam_warn (8)         - PAM module which logs all PAM items if called
pam_wheel (8)        - Only permit root access to members of group wheel
pam_xauth (8)        - PAM module to forward xauth keys between users
password-auth (5)    - Common configuration file for PAMified services
password-auth-ac (5) - Common configuration files for PAMified services written by authconfig(8)
postlogin (5)        - Common configuration file for PAMified services
postlogin-ac (5)     - Common configuration files for PAMified services written by authconfig(8)
sepermit.conf (5)    - configuration file for the pam_sepermit module
smartcard-auth (5)   - Common configuration file for PAMified services
smartcard-auth-ac (5) - Common configuration files for PAMified services written by authconfig(8)
system-auth (5)      - Common configuration file for PAMified services
system-auth-ac (5)   - Common configuration files for PAMified services written by authconfig(8)
time.conf (5)        - configuration file for the pam_time module
```

</details>
Перременные PAM описываются страницей pam_env (8)          - PAM module to set/unset environment variables. 

root@PAMLab ~# groups friday| awk -F": " '{print $2}'
friday
root@PAMLab ~# gpasswd -a friday day
Adding user friday to group day
root@PAMLab ~# groups friday
friday : friday day
root@PAMLab ~# groups friday| awk -F": " '{print $2}'
friday day
root@PAMLab ~#
