# InSpec test for recipe aig_hardening::rhel_sets

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/
login_defs_umask = attribute('login_defs_umask', default: os.redhat? ? '077' : '027', description: 'Default umask to set in login.defs')
login_defs_passmaxdays = attribute('login_defs_passmaxdays', default: '90', description: 'Default password maxdays to set in login.defs')
login_defs_passmindays = attribute('login_defs_passmindays', default: '7', description: 'Default password mindays to set in login.defs')
login_defs_passminlen = attribute('login_defs_passwminlen', default: '8', description: 'Default password minlen (length) to set in login.defs')
login_defs_passwarnage = attribute('login_defs_passwarnage', default: '14', description: 'Default password warnage (days) to set in login.defs')

control 'Sets 1846-1847' do
  impact 1.0
  title 'Verify permsissions of /etc/at.allow'

  only_if('File does not exist') do
    file('/etc/at.allow').exist?
  end

  describe file('/etc/at.allow') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0400' }
  end
end

control 'Sets 1852-1853' do
  impact 1.0
  title 'Verify correct folder permssions in /etc/cron'

  %w(d daily hourly monthly weekly).each do |dir|
    describe directory("/etc/cron.#{dir}") do
      it { should be_owned_by 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '0700' }
    end
  end
end

control 'Sets 1854-1855' do
  impact 1.0
  title 'Verify permssions on /etc/cron.allow'

  describe file('/etc/cron.allow') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0400' }
  end
end

control 'Sets 1857-1858' do
  impact 1.0
  title 'Verify permssions on Crontab'

  describe file('/etc/crontab') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0400' }
  end
end

control 'Sets 1858-1859' do
  impact 1.0
  title 'verify permssions on CUPS client'

  only_if('File does not exist') do
    file('/etc/cups/client.conf').exist?
  end

  describe file('/etc/cups/client.conf') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'lp' }
    its('mode') { should cmp '0644' }
  end
end

control 'Set 1860-1861' do
  impact 0.7
  title 'AIG Compliance sets 1860-1861'
  desc 'Verify file permssions on cupsd.conf'

  only_if('File does not exist') do
    file('/etc/cups/client.conf').exist?
  end

  describe file('/etc/cups/cupsd.conf') do
    it { should be_owned_by '4' }
    its('group') { should eq '3' }
    its('mode') { should cmp'0600' }
  end
end

control  'Sets 1866-1867' do
  impact 1.0
  title 'AIG Compliance sets 1866-1867'

  describe file('/etc/fstab') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1869-1870' do
  describe file('/etc/ftpusers') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end
end

control 'Sets 1871-1872' do
  describe file('/etc/group') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1873 and 1875' do
  path = case os.release.to_i
         when 7
           '/boot/grub2/grub.cfg'
         when 6
           '/boot/grub/grub.conf'
         end

  describe grub_conf(path) do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end
end

control 'Sets 1876-1877' do
  describe file('/etc/gshadow') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0400' }
  end
end

control 'Sets 1878-1880' do
  describe file('/etc/hosts.allow') do
    its('content') { should match 'sshd:ALL' }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1881-1883' do
  describe file('/etc/hosts.deny') do
    its('content') { should match 'ALL:ALL' }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1884-1886' do
  describe file('/etc/inittab') do
    its('content') { should match 'id:3:initdefault' }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end
end

control 'Sets 1887-1889' do
  only_if('File does not exist') do
    file('/etc/issues.net').exist?
  end

  describe file('/etc/issues.net') do
    its('content') do
      should match 'Notice:  These facilities are solely for the use of authorized employees or agents of the Company, its subsidiaries and
    affiliates. Unauthorized use is prohibited and subject to criminal and civil
    penalties. Subject to applicable law, individuals using this computer system must have no expectation of privacy and are subject to having all of their activities monitored and recorded.'
    end
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1894 & 1899' do
  describe file('/etc/login.defs') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0640' }
  end
end

control 'Sets 1893 & 1895-1898' do
  impact 1.0
  title 'Check login.defs'
  desc 'Check owner and permissions for login.defs. Also check the configured PATH variable and umask in login.defs'
  describe file('/etc/login.defs') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    it { should_not be_executable }
  end
  describe login_defs do
    its('UMASK') { should include(login_defs_umask) }
    its('PASS_MAX_DAYS') { should eq login_defs_passmaxdays }
    its('PASS_MIN_DAYS') { should eq login_defs_passmindays }
    its('PASS_WARN_AGE') { should eq login_defs_passwarnage }
    its('PASS_MIN_LEN') { should eq login_defs_passminlen }
  end
end

control 'Set 1900-1901' do
  impact 1.0
  only_if('File does not exist') do
    directory('/etc/mail/').exist?
  end

  describe file('/etc/mail/sendmail.cf') do
    its('content') { should match 'Port=smtp,Addr=127.0.0.1, Name=MTA\n O SmtpGreetingMessage=mailerready\n' }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1902-1904' do
  impact 1.0

  only_if('File does not exist') do
    file('/etc/motd').exist?
  end

  describe file('/etc/motd') do
    its('content') { should match 'Warning:  These facilities are solely for the use of authorized employees or agents of the Company, its subsidiaries and affiliates. Unauthorized use is   prohibited and subject to criminal and civil penalties.  Subject to applicable law, individuals using this computer system must have no expectation of privacy and are subject to having all of   their activities monitored and recorded.' }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1905-1906' do
  impact 1.0

  describe file('/etc/ntp.conf') do
    its('content') { should match 'restrict default ignore\nrestrict 127.0.0.1' }
  end
end

control 'Sets 1912-1913' do
  describe file('/etc/pam.d/system-auth') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Sets 1915-19116' do
  describe file('/etc/passwd') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Set 1918' do
  describe file('/etc/lilo.conf') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Set 1920' do
  describe file('/etc/securetty') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0400' }
  end
end

control 'Set 1921' do
  describe file('/etc/sysctl.conf') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end
end

# control 'Set 1922' do
# replace_or_add 'SET-1922') do
#   path '/etc/profile'
#   pattern '^TMOUT.*'
#   line 'TMOUT=7200 ; TIMEOUT=7200 ; export TMOUT TIMEOUT; readonly TMOUT TIMEOUT'
# end

control 'Sets 1923-1924' do
  describe file('/etc/rc.d/rc.sysinit') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0700' }
  end
end

control 'Sets 1927-1928' do
  describe file('/etc/shadow') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0400' }
  end
end

control 'Set 1929' do
  describe file('/etc/shosts.equiv') do
    it { should_not exist }
  end
end

control 'Sets 1930-1931' do
  describe file('/etc/ssh/ssh_config') do
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end
