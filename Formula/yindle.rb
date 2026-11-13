class Yindle < Formula
  desc "Memory-safe CUPS 2.x-compatible print spooler and IPP scheduler in Rust"
  homepage "https://github.com/vindeckyy/yindle"
  url "https://github.com/vindeckyy/yindle/releases/download/v0.1.1/yindle-0.1.1-x86_64-unknown-linux-gnu.tar.gz"
  sha256 "9c64055af60297f9990a356a7e98d3ad4aafb0b07d38ac25bcb8e132d80a1ba8"
  license any_of: ["Apache-2.0", "MIT"]

  depends_on :linux

  def install
    # The release tarball is a system FHS tree; remap it under the brew
    # prefix so it can be evaluated without root or a system-wide install.
    prefix.install Dir["usr/*"]
    etc.install Dir["etc/*"]
    (var/"cups").mkpath
    (var/"cups/spool").mkpath
    (var/"cups/log").mkpath
    (var/"cups/cache").mkpath
    (var/"run/cups").mkpath

    # Point the shipped configs at the brew prefix and run as the
    # installing user on a nonprivileged port.
    inreplace etc/"cups/cups-files.conf" do |s|
      s.gsub! "/etc/cups", "#{etc}/cups"
      s.gsub! "/var/spool/cups", "#{var}/cups/spool"
      s.gsub! "/var/cache/cups", "#{var}/cups/cache"
      s.gsub! "/run/cups", "#{var}/run/cups"
      s.gsub! "/usr/lib/cups", "#{prefix}/lib/cups"
      s.gsub! "/usr/share/cups", "#{prefix}/share/cups"
      s.gsub! "/var/log/cups", "#{var}/cups/log"
      s.gsub! "User lp", "User #{ENV["USER"]}"
      s.gsub! "Group lp", "Group #{ENV["USER"]}"
      s.gsub! "SystemGroup lpadmin", "SystemGroup #{ENV["USER"]}"
    end
    inreplace etc/"cups/cupsd.conf" do |s|
      s.gsub! "Listen localhost:631", "Listen localhost:8631"
      s.gsub! "Listen /run/cups/cups.sock", "Listen #{var}/run/cups/cups.sock"
    end
  end

  def caveats
    <<~EOS
      This tap install runs yindle in user space on port 8631 for
      evaluation. For a system install on port 631, use the .deb or the
      release tarball from #{homepage}/releases.

      Admin ops authorize via SystemGroup, which this formula points at
      your login group - run clients with CUPS_SERVER=#{var}/run/cups/cups.sock
      or ipp://localhost:8631.
    EOS
  end

  service do
    run [opt_sbin/"cupsd", "-f"]
    keep_alive true
    working_dir var
    log_path var/"cups/log/error_log"
    error_log_path var/"cups/log/error_log"
  end

  test do
    system sbin/"cupsd", "-t", "-c", etc/"cups/cupsd.conf"
  end
end
