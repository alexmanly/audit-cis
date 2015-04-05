#
# Cookbook Name:: audit-cis
# Recipe:: centos7-100
#
# Author:: Joshua Timberman <joshua@chef.io>
# Copyright (c) 2015, Chef Software, Inc. <legal@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# `node` is not available in the audit DSL, so let's set a local
# variable to check these attributes as flags
level_two_enabled = AuditCIS.profile_level_two?(node)
ipv6_disabled     = false #AuditCIS.ipv6_disabled?(node)

control_group '1 Install Updates, Patches and Additional Security Software' do
  control '1.1 Filesystem Configuration' do
    context 'Level 1' do
      let(:find_cmd) do
        command <<-EOH.gsub(/^\s+/, '')
          df --local -P | \
          awk {'if (NR!=1) print $6'} | \
          xargs -I '{}' \
          find '{}' -xdev -type d \\( -perm -0002 -a ! -perm -1000 \\) \
          2>/dev/null
        EOH
      end

      it '1.1.1 Create Separate Partition for /tmp' do
        expect(file('/tmp')).to be_mounted
      end

      it '1.1.2 Set nodev option for /tmp Partition' do
        expect(file('/tmp')).to be_mounted.with(options: { nodev: true })
      end

      it '1.1.3 Set nosuid option for /tmp Partition' do
        expect(file('/tmp')).to be_mounted.with(options: { nosuid: true })
      end

      it '1.1.4 Set noexec option for /tmp Partition' do
        expect(file('/tmp')).to be_mounted.with(options: { noexec: true })
      end

      it '1.1.5 Create Separate Partition for /var' do
        expect(file('/var')).to be_mounted
      end

      it '1.1.6 Bind Mount the /var/tmp directory to /tmp' do
        expect(file('/var/tmp')).to be_mounted.with(device: '/tmp')
      end

      it '1.1.7 Create Separate Partition for /var/log' do
        expect(file('/var/log')).to be_mounted
      end

      it '1.1.8 Create Separate Partition for /var/log/audit' do
        expect(file('/var/log/audit')).to be_mounted
      end

      it '1.1.9 Create Separate Partition for /home' do
        expect(file('/home')).to be_mounted
      end

      it '1.1.10 Add nodev Option to /home' do
        expect(file('/home')).to be_mounted.with(options: { nodev: true })
      end

      it '1.1.12 Add noexec Option to Removable Media Partitions' do
        pending <<-EOH.gsub(/^\s+/, '')
          It is difficult to predict all the removable media partitions
          that may exist on the system. Rather than attempt to be clever,
          we recommend implementing a custom audit mode validation on a
          per-site basis.
        EOH
      end

      it '1.1.13 Add nosuid Option to Removable Media Partitions' do
        pending <<-EOH.gsub(/^\s+/, '')
          It is difficult to predict all the removable media partitions
          that may exist on the system. Rather than attempt to be clever,
          we recommend implementing a custom audit mode validation on a
          per-site basis.
        EOH
      end

      it '1.1.14 Add nodev Option to /dev/shm Partition' do
        expect(file('/dev/shm')).to be_mounted
      end

      it '1.1.15 Add nosuid Option to /dev/shm Partition' do
        expect(file('/dev/shm')).to be_mounted.with(options: { nosuid: true })
      end

      it '1.1.16 Add noexec Option to /dev/shm Partition' do
        expect(file('/dev/shm')).to be_mounted.with(options: { noexec: true })
      end

      it '1.1.17 Set Sticky Bit on All World-Writable Directories' do
        expect(find_cmd.stdout).to be_empty
      end
    end

    context 'Level 2' do
      let(:lsmod) { command('/sbin/lsmod') }

      it '1.1.18 Disable Mounting of cramfs Filesystems' do
        expect(lsmod.stdout).to_not match(/cramfs/)
      end

      it '1.1.19 Disable Mounting of freevxfs Filesystems' do
        expect(lsmod.stdout).to_not match(/freevxfs/)
      end

      it '1.1.20 Disable Mounting of jffs2 Filesystems' do
        expect(lsmod.stdout).to_not match(/jffs2/)
      end

      it '1.1.21 Disable Mounting of hfs Filesystems' do
        expect(lsmod.stdout).to_not match(/hfs/)
      end

      it '1.1.22 Disable Mounting of hfsplus Filesystems' do
        expect(lsmod.stdout).to_not match(/hfsplus/)
      end

      it '1.1.23 Disable Mounting of squashfs Filesystems' do
        expect(lsmod.stdout).to_not match(/squashfs/)
      end

      it '1.1.24 Disable Mounting of udf Filesystems' do
        expect(lsmod.stdout).to_not match(/udf/)
      end
    end if level_two_enabled

    control '1.2 Configure Software Updates' do
      context 'Level 1' do
        let(:gpg_fingerprint) do
          command <<-EOH.gsub(/^\s+/, '')
            gpg --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 2>/dev/null | \
            awk -F= '/fingerprint/ {print $2}'
          EOH
        end

        # TODO: (jtimberman) It may be preferable to have this be
        # stored in an attribute that users can change, with this
        # being the default value. The `node` object isn't available
        # in the audit DSL context, so it would have to be assigned
        # to a local variable in this recipe.
        it '1.2.1 Verify CentOS GPG Key is Installed' do
          expect(gpg_fingerprint.stdout).to match(/6341 AB27 53D7 8A78 A7C2  7BB1 24C6 A8A7 F4A8 0EB5/)
        end

        it '1.2.2 Verify that gpgcheck is Globally Activated' do
          expect(file('/etc/yum.conf')).to contain('gpgcheck=1')
        end

        it '1.2.3 Obtain Software Package Updates with yum' do
          # `yum check-update` will return 100 if there are packages
          # to update
          expect(command('yum check-update').exit_status).to be_zero
        end

        it '1.2.4 Verify Package Integrity Using RPM' do
          pending <<-EOH.gsub(/^\s+/, '')
            Not Implemented: Per the note in the CIS Benchmark for
            CentOS 7, there are potential changes to files managed by
            packages to make them more secure to comply with the CIS
            benchmark. As such it is untenable to maintain the complete
            list of all files to check here. It is recommended that
            individual sites implement their own audit mode control for
            rule 1.2.4.
          EOH
        end
      end
    end

    control '1.3 Advanced Intrusion Detection Environment (AIDE)' do
      context 'Level 2' do
        it '1.3.1 Install AIDE' do
          expect(package('aide')).to be_installed
        end

        it '1.3.2 Implement Periodic Execution of File Integrity' do
          expect(cron).to have_entry('0 5 * * * /usr/sbin/aide --check')
        end
      end if level_two_enabled
    end

    control '1.4 Configure SELinux' do
      context 'Level 2' do
        let(:grub_cfg) { file('/boot/grub2/grub.cfg') }
        let(:sestatus) { command('/usr/sbin/sestatus') }
        let(:selinux_config) { file('/etc/selinux/config') }

        it '1.4.1 Enable SELinux in /boot/grub2/grub.cfg' do
          expect(grub_cfg).to_not match(/selinux=0/)
          expect(grub_cfg).to_not match(/enforcing=0/)
        end

        it '1.4.2 Set the SELinux State' do
          expect(selinux_config).to match(/^SELINUX=enforcing/)
          expect(sestatus.stdout).to match(/^SELinux status:\s+enabled/)
          expect(sestatus.stdout).to match(/^Current mode:\s+enforcing/)
          expect(sestatus.stdout).to match(/^Mode from config file:\s+enforcing/)
        end

        it '1.4.3 Set the SELinux Policy' do
          expect(selinux_config).to match(/^SELINUXTYPE=targeted/)
          expect(sestatus.stdout).to contain('Policy from config file: targeted')
        end

        it '1.4.4 Remove SETroubleshoot' do
          expect(package('setroubleshoot')).to_not be_installed
        end if level_two_enabled

        it '1.4.5 Remove MCS Translation Service (mcstrans)' do
          expect(package('mcstrans')).to_not be_installed
        end

        it '1.4.6 Check for Unconfined Daemons' do
          expect(command('ps -eZ | egrep "initrc" | egrep -vw "tr|ps|egrep|bash|awk" | tr ":" " " | awk \'{print $NF }\'').stdout).to be_empty
        end
      end
    end

    control '1.5 Secure Boot Settings' do
      context 'Level 1' do
        let(:grub_cfg) { file('/boot/grub2/grub.cfg') }

        it '1.5.1 Set User/Group Owner on /boot/grub2/grub.cfg' do
          expect(grub_cfg).to be_owned_by('root')
          expect(grub_cfg).to be_grouped_into('root')
        end

        it '1.5.2 Set Permissions on /boot/grub2/grub.cfg' do
          expect(grub_cfg).to be_mode(400)
        end

        it '1.5.3 Set Boot Loader Password' do
          expect(grub_cfg).to match(/^set superusers=/)
          expect(grub_cfg).to match(/^password/)
        end
      end
    end

    control '1.6 Additional Process Hardening' do

      it '1.6.1 Restrict Core Dumps' do
        expect(file('/etc/security/limits.conf')).to match(/\*\s+hard\s+core\s+0/)
        expect(command('/sbin/sysctl fs.suid_dumpable').stdout).to match(/^fs\.suid_dumpable = 0/)
      end

      it '1.6.2 Enable Randomized Virtual Memory Region Placement' do
        expect(command('/sbin/sysctl kernel.randomize_va_space')).to match(/^kernel.randomize_va_space = 2/)
      end
    end

    control '1.7 Use the Latest OS Release' do
      let(:check_update) { command('yum check-update') }

      it 'does not have a pending centos-release package update' do
        expect(check_update.stdout).to_not match(/^centos-release/)
      end

      it 'does not have a pending kernel package update' do
        expect(check_update.stdout).to_not match(/^kernel\./)
      end
    end
  end
end

control_group '2 OS Services' do
  control '2.1 Remove Legacy Services' do
    it '2.1.1 Remove telnet-server' do
      expect(package('telnet-server')).to_not be_installed
    end

    it '2.1.2 Remove telnet Clients' do
      expect(package('telnet')).to_not be_installed
    end

    it '2.1.3 Remove rsh-server' do
      expect(package('rsh-server')).to_not be_installed
    end

    it '2.1.4 Remove rsh' do
      expect(package('rsh')).to_not be_installed
    end

    it '2.1.5 Remove NIS Client' do
      expect(package('ypbind')).to_not be_installed
    end

    it '2.1.6 Remove NIS Server' do
      expect(package('ypserv')).to_not be_installed
    end

    it '2.1.7 Remove tftp' do
      expect(package('tftp')).to_not be_installed
    end

    it '2.1.8 Remove tftp-server' do
      expect(package('tftp-server')).to_not be_installed
    end

    it '2.1.9 Remove talk' do
      expect(package('talk')).to_not be_installed
    end

    it '2.1.10 Remove talk-server' do
      expect(package('talk-server')).to_not be_installed
    end

    it '2.1.11 Remove xinetd' do
      expect(package('xinetd')).to_not be_installed
    end

    it '2.1.12 Disable chargen-dgram' do
      expect(service('chargen-dgram')).to_not be_running
      expect(service('chargen-dgram')).to_not be_enabled
    end

    it '2.1.13 Disable chargen-stream' do
      expect(service('chargen-stream')).to_not be_running
      expect(service('chargen-stream')).to_not be_enabled
    end

    it '2.1.14 Disable daytime-dgram' do
      expect(service('daytime-dgram')).to_not be_running
      expect(service('daytime-dgram')).to_not be_enabled
    end

    it '2.1.15 Disable daytime-stream' do
      expect(service('daytime-stream')).to_not be_running
      expect(service('daytime-stream')).to_not be_enabled
    end

    it '2.1.16 Disable echo-dgram' do
      expect(service('echo-dgram')).to_not be_running
      expect(service('echo-dgram')).to_not be_enabled
    end

    it '2.1.17 Disable echo-stream' do
      expect(service('echo-stream')).to_not be_running
      expect(service('echo-stream')).to_not be_enabled
    end

    it '2.1.18 Disable tcpmux-server' do
      expect(service('tcpmux-server')).to_not be_running
      expect(service('tcpmux-server')).to_not be_enabled
    end
  end
end

control_group '3 Special Purpose Services' do
  control '3.1 Set Daemon umask' do
    it 'sets the umask in system-wide init config' do
      expect(file('/etc/sysconfig/init')).to contain('umask 027')
    end
  end

  control '3.2 Remove the X Window System' do
    it 'disables the graphical.target service' do
      expect(service('graphical.target')).to_not be_running
      expect(service('graphical.target')).to_not be_enabled
      expect(file('/usr/lib/systemd/system/default.target')).to_not be_linked_to('graphical.target')
    end

    it 'does not have the xorg-x11-server-common package installed' do
      expect(package('xorg-x11-server-common')).to_not be_installed
    end
  end

  control '3.3 Disable Avahi Server' do
    it 'disables the avahi-daemon service' do
      expect(service('avahi-daemon')).to_not be_running
      expect(service('avahi-daemon')).to_not be_enabled
    end
  end

  control '3.4 Disable Print Server - CUPS' do
    it 'disables the cups service' do
      expect(service('cups')).to_not be_running
      expect(service('cups')).to_not be_enabled
    end
  end

  control '3.5 Remove DHCP Server' do
    it 'does not have the dhcp package installed' do
      expect(package('dhcp')).to_not be_installed
    end
  end

  control '3.6 Configure Network Time Protocol (NTP)' do
    let(:ntp_conf) { file('/etc/ntp.conf') }

    it 'has the ntp package installed' do
      expect(package('ntp')).to be_installed
    end

    it 'has the restrict parameters in the ntp config' do
      expect(ntp_conf).to match(/restrict default/)
      expect(ntp_conf).to match(/restrict -6 default/)
    end

    it 'has at least one NTP server defined' do
      expect(ntp_conf).to match(/server/)
    end

    it 'is configured to start ntpd as a nonprivileged user' do
      expect(file('/etc/sysconfig/ntpd')).to match(/OPTIONS=.*-u /)
    end
  end

  control '3.7 Remove LDAP' do
    it 'does not have the openldap-servers package installed' do
      expect(package('openldap-servers')).to_not be_installed
    end

    it 'does not have the openldap-clients package installed' do
      expect(package('openldap-clients')).to_not be_installed
    end
  end

  control '3.8 Disable NFS and RPC' do
    it 'disables the nfslock service' do
      expect(service('nfslock')).to_not be_running
      expect(service('nfslock')).to_not be_enabled
    end

    it 'disables the rpcgssd service' do
      expect(service('rpcgssd')).to_not be_running
      expect(service('rpcgssd')).to_not be_enabled
    end

    it 'disables the rpcbind service' do
      expect(service('rpcbind')).to_not be_running
      expect(service('rpcbind')).to_not be_enabled
    end

    it 'disables the rpcidmapd service' do
      expect(service('rpcidmapd')).to_not be_running
      expect(service('rpcidmapd')).to_not be_enabled
    end

    it 'disables the rpcsvcgssd service' do
      expect(service('rpcsvcgssd')).to_not be_running
      expect(service('rpcsvcgssd')).to_not be_enabled
    end
  end

  control '3.9 Remove DNS Server' do
    it 'does not have the bind package installed' do
      expect(package('bind')).to_not be_intalled
    end
  end

  control '3.10 Remove FTP Server' do
    it 'does not have the vsftpd package installed' do
      expect(package('vsftpd')).to_not be_installed
    end
  end

  control '3.11 Remove HTTP Server' do
    it 'does not have the httpd package installed' do
      expect(package('httpd')).to_not be_installed
    end
  end

  control '3.12 Remove Dovecot (IMAP and POP3 services)' do
    it 'does not have the dovecot package installed' do
      expect(package('dovecot')).to_not be_installed
    end
  end

  control '3.13 Remove Samba'  do
    it 'does not have the samba package installed' do
      expect(package('samba')).to_not be_installed
    end
  end

  control '3.14 Remove HTTP Proxy Server' do
    it 'does not have the squid package installed' do
      expect(package('squid')).to_not be_installed
    end
  end

  control '3.15 Remove SNMP Server' do
    it 'does not have the net-snmp package installed' do
      expect(package('net-snmp')).to_not be_installed
    end
  end

  control '3.16 Configure Mail Transfer Agent for Local-Only Mode' do
    it 'listens on port 25 only on the loopback address' do
      expect(port(25)).to be_listening.on('127.0.0.1')
    end
  end
end

control_group '4 Network Configuration and Firewalls' do
  ::RSpec.configure do |c|
    c.filter_run focus: true
  end

  control '4.1 Modify Network Parameters (Host Only)' do
    it '4.1.1 Disable IP Forwarding' do
      expect(command('/sbin/sysctl net.ipv4.ip_forward').stdout).to match(/^net.ipv4.ip_forward = 0/)
    end

    it '4.1.2 Disable Send Packet Redirects' do
      expect(command('/sbin/sysctl net.ipv4.conf.all.send_redirects').stdout).to match(/^net.ipv4.conf.all.send_redirects = 0/)
      expect(command('/sbin/sysctl net.ipv4.conf.default.send_redirects').stdout).to match(/^net.ipv4.conf.default.send_redirects = 0/)
    end
  end

  control '4.2 Modify Network Parameters (Host and Router)' do
    context 'Level 1' do
      it '4.2.1 Disable Source Routed Packet Acceptance' do
        expect(command('/sbin/sysctl net.ipv4.conf.all.accept_source_route').stdout).to match(/^net.ipv4.conf.all.accept_source_route = 0/)
        expect(command('/sbin/sysctl net.ipv4.conf.default.accept_source_route').stdout).to match(/^net.ipv4.conf.default.accept_source_route = 0/)
      end

      it '4.2.2 Disable ICMP Redirect Acceptance' do
        expect(command('/sbin/sysctl net.ipv4.conf.all.accept_redirects').stdout).to match(/^net.ipv4.conf.all.accept_redirects = 0/)
        expect(command('/sbin/sysctl net.ipv4.conf.default.accept_redirects').stdout).to match(/^net.ipv4.conf.default.accept_redirects = 0/)
      end

      it '4.2.3 Disable Secure ICMP Redirect Acceptance' do
        expect(command('/sbin/sysctl net.ipv4.conf.all.secure_redirects').stdout).to match(/^net.ipv4.conf.all.secure_redirects = 0/)
        expect(command('/sbin/sysctl net.ipv4.conf.default.secure_redirects').stdout).to match(/^net.ipv4.conf.default.secure_redirects = 0/)
      end

      it '4.2.4 Log Suspicious Packets' do
        expect(command('/sbin/sysctl net.ipv4.conf.all.log_martians').stdout).to match(/^net.ipv4.conf.all.log_martians = 1/)
        expect(command('/sbin/sysctl net.ipv4.conf.default.log_martians').stdout).to match(/^net.ipv4.conf.default.log_martians = 1/)
      end

      it '4.2.5 Enable Ignore Broadcast Requests' do
        expect(command('/sbin/sysctl net.ipv4.icmp_echo_ignore_broadcasts').stdout).to match(/^net.ipv4.icmp_echo_ignore_broadcasts = 1/)
      end

      it '4.2.6 Enable Bad Error Message Protection' do
        expect(command('/sbin/sysctl net.ipv4.icmp_ignore_bogus_error_responses').stdout).to match(/^net.ipv4.icmp_ignore_bogus_error_responses = 1/)
      end

      it '4.2.8 Enable TCP SYN Cookies' do
        expect(command('/sbin/sysctl net.ipv4.tcp_syncookies').stdout).to match(/^net.ipv4.tcp_syncookies = 1/)
      end
    end

    context 'Level 2' do
      it '4.2.7 Enable RFC-recommended Source Route Validation' do
        expect(command('/sbin/sysctl net.ipv4.conf.all.rp_filter').stdout).to match(/^net.ipv4.conf.all.rp_filter = 1/)
      end
    end if level_two_enabled
  end

  control '4.3 Wireless Networking' do
    it '4.3.1 Deactivate Wireless Interfaces' do
      expect(command('/sbin/ip link show up').stdout).to_not match(/: wl.*UP/)
    end
  end

  control '4.4 IPv6' do
    context '4.4.1 Configure IPv6' do
      it '4.4.1.1 Disable IPv6 Router Advertisements' do
        expect(command('/sbin/sysctl net.ipv6.conf.all.accept_ra').stdout).to match(/^net.ipv6.conf.all.accept_ra = 0/)
        expect(command('/sbin/sysctl net.ipv6.conf.default.accept_ra').stdout).to match(/^net.ipv6.conf.default.accept_ra = 0/)
      end

      it '4.4.1.2 Disable IPv6 Redirect Acceptance' do
        expect(command('/sbin/sysctl net.ipv6.conf.all.accept_redirects').stdout).to match(/^net.ipv6.conf.all.accept_redirects = 0/)
        expect(command('/sbin/sysctl net.ipv6.conf.default.accept_redirects').stdout).to match(/^net.ipv6.conf.default.accept_redirects = 0/)
      end
    end unless ipv6_disabled

    context '4.4.2 Disable IPv6' do
      it 'Disables IPv6' do
        expect(command('/sbin/sysctl net.ipv6.conf.all.disable_ipv6').stdout).to match(/^net.ipv6.conf.all.disable_ipv6 = 1/)
        expect(command('/sbin/sysctl net.ipv6.conf.default.disable_ipv6').stdout).to match(/^net.ipv6.conf.default.disable_ipv6 = 1/)
      end
    end if ipv6_disabled
  end

  control '4.5 Install TCP Wrappers' do
    it '4.5.1 Install TCP Wrappers' do
      expect(package('tcp_wrappers')).to be_installed
    end

    it '4.5.2 Create /etc/hosts.allow' do
      expect(file('/etc/hosts.allow')).to be_file
    end

    it '4.5.3 Verify Permissions on /etc/hosts.allow' do
      expect(file('/etc/hosts.allow')).to be_mode(644)
    end

    it '4.5.4 Create /etc/hosts.deny' do
      expect(file('/etc/hosts.deny')).to be_file
      expect(file('/etc/hosts.deny')).to contain('ALL: ALL')
    end

    it '4.5.5 Verify Permissions on /etc/hosts.deny' do
      expect(file('/etc/hosts.deny')).to be_mode(644)
    end
  end

  control '4.6 Uncommon Network Protocols' , focus:true do
    let(:lsmod) { command('/sbin/lsmod') }

    it '4.6.1 Disable DCCP' do
      expect(lsmod.stdout).to_not match(/dccp/)
    end

    it '4.6.2 Disable SCTP' do
      expect(lsmod.stdout).to_not match(/sctp/)
    end

    it '4.6.3 Disable RDS' do
      expect(lsmod.stdout).to_not match(/rds/)
    end

    it '4.6.4 Disable TIPC' do
      expect(lsmod.stdout).to_not match(/tipc/)
    end
  end

  control '4.7 Enable firewalld' do
    it 'enables the firewalld service' do
      expect(service('firewalld')).to be_enabled
      expect(service('firewalld')).to be_running
    end
  end
end

control_group '5 Logging and Auditing' do
  control '5.1 Configure rsyslog' do
    it '5.1.1 Install the rsyslog package' do
      expect(package('rsyslog')).to be_installed
    end

    it '5.1.2 Activate the rsyslog Service' do
      expect(service('rsyslog')).to be_enabled
      expect(service('rsyslog')).to be_running
    end

    it '5.1.3 Configure /etc/rsyslog.conf'
    it '5.1.4 Create and Set Permissions on rsyslog Log Files'
    it '5.1.5 Configure rsyslog to Send Logs to a Remote Log Host'
    it '5.1.6 Accept Remote rsyslog Messages Only on Designated Log Hosts'
  end

  # Level 2 applicability profile
  control '5.2 Configure System Accounting (auditd)' do
    context '5.2.1 Configure Data Retention' do
      context 'Level 2' do
        it '5.2.1.1 Configure Audit Log Storage Size'
        it '5.2.1.2 Disable System on Audit Log Full'
        it '5.2.1.3 Keep All Auditing Information'
      end if level_two_enabled
    end

    it '5.2.2 Enable auditd Service'
    it '5.2.3 Enable Auditing for Processes That Start Prior to auditd'
    it '5.2.4 Record Events That Modify Date and Time Information'
    it '5.2.5 Record Events That Modify User/Group Information'
    it '5.2.6 Record Events That Modify the System\'s Network Environment'
    it '5.2.7 Record Events That Modify the System\'s Mandatory Access Controls'
    it '5.2.8 Collect Login and Logout Events'
    it '5.2.9 Collect Session Initiation Information'
    it '5.2.10 Collect Discretionary Access Control Permission Modification Events'
    it '5.2.11 Collect Unsuccessful Unauthorized Access Attempts to Files'
    it '5.2.12 Collect Use of Privileged Commands'
    it '5.2.13 Collect Successful File System Mounts'
    it '5.2.14 Collect File Deletion Events by User'
    it '5.2.15 Collect Changes to System Administration Scope'
    it '5.2.16 Collect System Administrator Actions (sudolog)'
    it '5.2.17 Collect Kernel Module Loading and Unloading'
    it '5.2.18 Make the Audit Configuration Immutable'
  end

  control '5.3 Configure logrotate' do
    # /var/log/messages /var/log/secure /var/log/maillog /var/log/spooler /var/log/boot.log /var/log/cron
    it 'system logs have entries in /etc/logrotate.d/syslog'
  end
end

control_group '6 System Access, Authentication and Authorization' do
  control '6.1 Configure cron and anacron' do
    it '6.1.1 Enable anacron Daemon' do
      expect(package('cronie-anacron')).to be_installed
    end

    it '6.1.2 Enable crond Daemon' do
      expect(service('crond')).to be_enabled
      expect(service('crond')).to be_running
    end

    it '6.1.3 Set User/Group Owner and Permission on /etc/anacrontab' do
      expect(file('/etc/anacrontab')).to be_owned_by('root')
      expect(file('/etc/anacrontab')).to be_grouped_into('root')
      expect(file('/etc/anacrontab')).to be_mode(600)
    end

    it '6.1.4 Set User/Group Owner and Permission on /etc/crontab' do
      expect(file('/etc/crontab')).to be_owned_by('root')
      expect(file('/etc/crontab')).to be_grouped_into('root')
      expect(file('/etc/crontab')).to be_mode(600)
    end

    it '6.1.5 Set User/Group Owner and Permission on /etc/cron.hourly' do
      expect(file('/etc/cron.hourly')).to be_owned_by('root')
      expect(file('/etc/cron.hourly')).to be_grouped_into('root')
      expect(file('/etc/cron.hourly')).to be_mode(600)
    end

    it '6.1.6 Set User/Group Owner and Permission on /etc/cron.daily' do
      expect(file('/etc/cron.daily')).to be_owned_by('root')
      expect(file('/etc/cron.daily')).to be_grouped_into('root')
      expect(file('/etc/cron.daily')).to be_mode(600)
    end

    it '6.1.7 Set User/Group Owner and Permission on /etc/cron.weekly' do
      expect(file('/etc/cron.weekly')).to be_owned_by('root')
      expect(file('/etc/cron.weekly')).to be_grouped_into('root')
      expect(file('/etc/cron.weekly')).to be_mode(600)
    end

    it '6.1.8 Set User/Group Owner and Permission on /etc/cron.monthly' do
      expect(file('/etc/cron.monthly')).to be_owned_by('root')
      expect(file('/etc/cron.monthly')).to be_grouped_into('root')
      expect(file('/etc/cron.monthly')).to be_mode(600)
    end

    it '6.1.9 Set User/Group Owner and Permission on /etc/cron.d' do
      expect(file('/etc/cron.d')).to be_owned_by('root')
      expect(file('/etc/cron.d')).to be_grouped_into('root')
      expect(file('/etc/cron.d')).to be_mode(600)
    end

    it '6.1.10 Restrict at Daemon'
    it '6.1.11 Restrict at/cron to Authorized Users'
  end

  control '6.2 Configure SSH' do
    let(:sshd_config) { file('/etc/ssh/sshd_config') }

    it '6.2.1 Set SSH Protocol to 2' do
      expect(sshd_config).to match(/^Protocol\s+2/)
    end

    it '6.2.2 Set LogLevel to INFO' do
      expect(sshd_config).to match(/^LogLevel\s+INFO/)
    end

    it '6.2.3 Set Permissions on /etc/ssh/sshd_config' do
      expect(file(sshd_config)).to be_owned_by('root')
      expect(file(sshd_config)).to be_grouped_into('root')
      expect(file(sshd_config)).to be_mode(600)
    end

    it '6.2.4 Disable SSH X11 Forwarding' do
      expect(file(sshd_config)).to match(/^X11Forwarding\s+no/)
    end

    it '6.2.5 Set SSH MaxAuthTries to 4 or Less' do
      expect(file(sshd_config)).to match(/^MaxAuthTries\s+[01234]/)
    end

    it '6.2.6 Set SSH IgnoreRhosts to Yes' do
      expect(file(sshd_config)).to match(/^IgnoreRhosts\s+yes/)
    end

    it '6.2.7 Set SSH HostbasedAuthentication to No' do
      expect(file(sshd_config)).to match(/^HostbasedAuthentication\s+no/)
    end

    it '6.2.8 Disable SSH Root Login' do
      expect(file(sshd_config)).to match(/^PermitRootLogin\s+no/)
    end

    it '6.2.9 Set SSH PermitEmptyPasswords to No' do
      expect(file(sshd_config)).to match(/^PermitEmptyPasswords\s+no/)
    end

    it '6.2.10 Do Not Allow Users to Set Environment Options' do
      expect(file(sshd_config)).to match(/^PermitUserEnvironment\s+no/)
    end

    it '6.2.11 Use Only Approved Cipher in Counter Mode' do
      expect(file(sshd_config)).to match(/^Ciphers\s+aes128-ctr,aes192-ctr,aes256-ctr/)
    end

    # The actual intervals are allowed to be set per site policy,
    # which may differ from the recommended (300 and 0 respectively)
    it '6.2.12 Set Idle Timeout Interval for User Login' do
      expect(file(sshd_config)).to match(/^ClientAliveInterval\s+\d/)
      expect(file(sshd_config)).to match(/^ClientAliveCountMax\s+\d/)
    end

    it '6.2.13 Limit Access via SSH' do
      expect(file(sshd_config)).to match(/^(AllowUsers|AllowGroups|DenyUsers|DenyGroups).+/)
    end

    it '6.2.14 Set SSH Banner' do
      expect(file(sshd_config)).to match(/^Banner\s+\/etc\/issue.*/)
    end
  end

  control '6.3 Configure PAM' do
    it '6.3.1 Upgrade Password Hashing Algorithm to SHA-512'
    it '6.3.2 Set Password Creation Requirement Parameters Using pam_cracklib'
    it '6.3.3 Set Lockout for Failed Password Attempts'
    it '6.3.4 Limit Password Reuse'
    it '6.4 Restrict root Login to System Console'
    it '6.5 Restrict Access to the su Command'
  end
end

control_group '7 User Accounts and Environment' do
  control '7.1 Set Shadow Password Suite Parameters (/etc/login.defs)' do
    it '7.1.1 Set Password Expiration Days'
    it '7.1.2 Set Password Change Minimum Number of Days'
    it '7.1.3 Set Password Expiring Warning Days'
  end

  control '7.2 Disable System Accounts'
  control '7.3 Set Default Group for root Account'
  control '7.4 Set Default umask for Users'
  control '7.5 Lock Inactive User Accounts'
end

control_group '8 Warning Banners' do
  control '8.1 Set Warning Banner for Standard Login Services'
  control '8.2 Remove OS Information from Login Warning Banners'
  control '8.3 Set GNOME Warning Banner'
end

control_group '9 System Maintenance' do
  let(:passwd)  { file('/etc/passwd')  }
  let(:group)   { file('/etc/group')   }
  let(:shadow)  { file('/etc/shadow')  }
  let(:gshadow) { file('/etc/gshadow') }

  control '9.1 Verify System File Permissions' do
    context 'Level 2' do
      it '9.1.1 Verify System File Permissions'
    end if level_two_enabled

    context 'Level 1' do
      it '9.1.2 Verify Permissions on /etc/passwd' do
        expect(passwd).to be_mode(644)
      end

      it '9.1.3 Verify Permissions on /etc/shadow' do
        expect(shadow).to be_mode(000)
      end

      it '9.1.4 Verify Permissions on /etc/gshadow' do
        expect(gshadow).to be_mode(000)
      end

      it '9.1.5 Verify Permissions on /etc/group' do
        expect(group).to be_mode(644)
      end

      it '9.1.6 Verify User/Group Ownership on /etc/passwd' do
        expect(passwd).to be_owned_by('root')
        expect(passwd).to be_grouped_into('root')
      end

      it '9.1.7 Verify User/Group Ownership on /etc/shadow' do
        expect(shadow).to be_owned_by('root')
        expect(shadow).to be_grouped_into('root')
      end

      it '9.1.8 Verify User/Group Ownership on /etc/gshadow' do
        expect(gshadow).to be_owned_by('root')
        expect(gshadow).to be_grouped_into('root')
      end

      it '9.1.9 Verify User/Group Ownership on /etc/group' do
        expect(group).to be_owned_by('root')
        expect(group).to be_grouped_into('root')
      end

      it '9.1.10 Find World Writable Files'

      it '9.1.11 Find Un-owned Files and Directories'

      it '9.1.12 Find Un-grouped Files and Directories'

      it '9.1.13 Find SUID System Executables'

      it '9.1.14 Find SGID System Executables'
    end
  end

  control '9.2 Review User and Group Settings' do
    it '9.2.1 Ensure Password Fields are Not Empty'

    it '9.2.2 Verify No Legacy "+" Entries Exist in /etc/passwd File' do
      expect(passwd).to_not match(/^\+:/)
    end

    it '9.2.3 Verify No Legacy "+" Entries Exist in /etc/shadow File' do
      expect(shadow).to_not match(/^\+:/)
    end

    it '9.2.4 Verify No Legacy "+" Entries Exist in /etc/group File' do
      expect(group).to_not match(/^\+:/)
    end

    it '9.2.5 Verify No UID 0 Accounts Exist Other Than root'
    it '9.2.6 Ensure root PATH Integrity'
    it '9.2.7 Check Permissions on User Home Directories'
    it '9.2.8 Check User Dot File Permissions'
    it '9.2.9 Check Permissions on User .netrc Files'
    it '9.2.10 Check for Presence of User .rhosts Files'
    it '9.2.11 Check Groups in /etc/passwd'
    it '9.2.12 Check That Users Are Assigned Valid Home Directories'
    it '9.2.13 Check User Home Directory Ownership'
    it '9.2.14 Check for Duplicate UIDs'
    it '9.2.15 Check for Duplicate GIDs'
    it '9.2.16 Check That Reserved UIDs Are Assigned to System Accounts'
    it '9.2.17 Check for Duplicate User Names'
    it '9.2.18 Check for Duplicate Group Names'
    it '9.2.19 Check for Presence of User .netrc Files'
    it '9.2.20 Check for Presence of User .forward Files'
  end
end