Ansible Role: PHP 72
=========

Ansible role to install PHP version 7.2 on RHEL/CentOS

Requirements
------------

None.

Role Variables
--------------

Additional php extensions are installed when passed in as list items in group_vars and host_vars.
The php_modules_additional takes a list of php extensions to be added in all environments.
```
php_modules_additional:
  - php-pecl-memcache
```

The php_modules-devel variable takes a list of php extensions to be installed in the development environment.
```
php_modules_devel:
  - php-devel
```

Other optional variables include a version number.
```
php_version: "7.2"
```

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: cyberitas.ansible_role_php72 }

License
-------

MIT

Author Information
------------------

Create in 2019 by James Dugger for Cyberitas Technologies, LLC
