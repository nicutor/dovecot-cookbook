#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
#
# Copyright 2014, Onddo Labs, Sl.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Dovecot) do
  ENABLE_BUILD_OPTIONS = true

  provides 'dovecot', 'dovecot/version'
  provides 'dovecot/build-options' if ENABLE_BUILD_OPTIONS

  def init_dovecot
    dovecot Mash.new
    dovecot['version'] = nil
    dovecot['build-options'] = {} if ENABLE_BUILD_OPTIONS
    dovecot
  end

  def build_option_key(str)
    str.downcase.tr(' ', '-')
  end

  def parse_build_options_hash(build_options)
    Hash[build_options.split(/ +/).map do |value|
      value.index('=').nil? ? [value, true] : value.split('=', 2)
    end]
  end

  def parse_build_options_array(build_options)
    build_options.split(/ +/)
  end

  def collect_version(stdout)
    dovecot['version'] = stdout.split("\n")[0]
  end

  def collect_build_options_line(line)
    case line
    when /^Build options: *(.+)/
      dovecot['build-options']
        .merge!(parse_build_options_hash(Regexp.last_match[1]))
    when /^([^:]+): *(.+)/
      dovecot['build-options'][build_option_key(Regexp.last_match[1])] =
        parse_build_options_array(Regexp.last_match[2])
    end
  end

  def collect_build_options(stdout)
    stdout.each_line { |line| collect_build_options_line(line) }
  end

  collect_data do
    init_dovecot
    so = shell_out('dovecot --version')
    collect_version(so.stdout) if so.exitstatus == 0

    if ENABLE_BUILD_OPTIONS
      so_bo = shell_out('dovecot --build-options')
      collect_build_options(so_bo.stdout) if so_bo.exitstatus == 0
    end
  end
end
