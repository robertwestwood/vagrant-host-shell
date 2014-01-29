module VagrantPlugins::HostShell
  class Provisioner < Vagrant.plugin('2', :provisioner)
    def provision
      bash_executable = '/bin/bash'
      begin
	require 'win32/registry'
	require 'pathname'
	keyname = 'SOFTWARE\\Wow6432Node\\Cygwin\\setup'
	Win32::Registry::HKEY_LOCAL_MACHINE.open(keyname) do |reg|
	  value = reg['rootdir']
	  cygwin_path = value
	  cygwin_pn = Pathname.new(cygwin_path)
	  bash_executable_pn = cygwin_pn + ('.' + bash_executable + '.exe')
	  bash_executable = bash_executable_pn.to_s
	end
      rescue
      end
      
      
      script = config.inline.is_a?(String) ? [config.inline] : config.inline

      result = script.inject(nil) do |res, cmd|
	if res.nil? || !(config.abort_on_nonzero && !res.exit_code.zero?) 
          res = Vagrant::Util::Subprocess.execute(
            bash_executable,
            '-c',
            cmd,
            :notify => [:stdout, :stderr],
            :workdir => config.cwd
          ) do |io_name, data|
            @machine.env.ui.info "[#{io_name}] #{data}"
	  end
	  res
        end
      end

      if config.abort_on_nonzero && !result.exit_code.zero?      
        raise VagrantPlugins::HostShell::Errors::NonZeroStatusError.new(config.inline, result.exit_code)  
      end

    end
  end
end
