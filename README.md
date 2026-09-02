arbtt, the Automatic Rule-Based Time Tracker
============================================

© 2009 Joachim Breitner <mail@joachim-breitner.de>

The Automatic Rule-Based Time Tracker is a desktop daemon that runs in the
background and, every minute, records what windows are open on your
desktop, what their titles are, which one is active. The accompanied
statistics program lets you derive information from this log file, i.e.
what how much of your time have you been spending with e-mail, or what
projects are your largest time wasters. The mapping from the raw window
titles to sensible "tags" is done by a configuration file with an powerful
syntax.

Installation
------------

See <http://arbtt.nomeata.de/#install>

You also need to make sure that `arbtt-capture` is started with your X
session:
- If you use GNOME or KDE, you can copy the file
  `arbtt-capture.desktop` to `~/.config/autostart/`. You might need to put the
  full path to `arbtt-capture` in the `Exec` line there, if you did not do a
  system wide installation.
- If you use macOS, you can use `launchd` for this.
  Create a `.plist` file like the following
  (with the path changed to match where arbtt-capture is located in your system):

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>de.nomeata.arbtt</string>
          <key>Program</key>
          <string>/path/to/arbtt-capture</string>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
      </dict>
  </plist>
  ```
  and place it in `~/Library/LaunchAgents/de.nomeata.arbtt.plist`.
  This will ensure `arbtt-capture` is started whenever you log in.
  To start the service without needing a new login,
  you can run `launchctl load ~/Library/LaunchAgents/de.nomeata.arbtt.plist`.

If you want to record samples at a different rate than one per minute, you
will have to pass the `--sample-rate` parameter to arbtt-capture.

Documentation
------------

Full documentation is now provided in the user manual in the [doc/](doc/)
directory. If you have the docbook xsl toolchain installed, you can
generate the HTML documentation by entering "make" in that directory.
Otherwise, you can use the
[online version of the User’s Guide](http://arbtt.nomeata.de/doc/users_guide/index.html).
Beware that this will also reflect the latest development version.

Development
-----------

You are very welcome to help the development of arbtt. You can find the
latest source at the git repository at
<https://github.com/nomeata/arbtt>.

The issue tracker is hosted on GitHub: <https://github.com/nomeata/arbtt/issues>

User and Developer discussion happens on the arbtt mailing list, `arbtt@lists.nomeata.de`.
To subscribe to the list, visit <http://lists.nomeata.de/mailman/listinfo/arbtt>.

Some of my plans or ideas include:

 * A graphical viewer that allows you to explore the tags in an appealing,
   interactive way. Possibly based on the Charts haskell library.
 * Looking forward and backwards in time when writing rules. (Information
   is already passed to the categorizing function, but not exposed to the
   syntax).
 * `$total_idle` time, which is the maximum idle time until it is reset. This
   would allow the user to catch the idle times more exactly.
 * Rules based on time of day, to create tags for worktime, weekend, late
   at night. (Partially done)
 * Storing the current timezone in the tags, for the previous entry to be
   more to be more useful.
 * Storing the hostname, in case a user has several.
 * Statistics based on time, to visualize trends.
 * Possibly more data sources?

Any help cleaning, documenting or testing the current code is appreciated
as well.

Creating the Windows Installer
------------------------------

The automated Windows build is defined in `.github/workflows/windows.yml`.
It builds 64-bit binaries with GHC and Cabal, obtains PCRE from MSYS2, runs the
test suite, creates an Inno Setup installer, and smoke-tests the installed
programs. The resulting `arbtt-windows-x86_64` workflow artifact contains the
installer.

To build the installer locally, install GHC, Cabal, the 64-bit PCRE 8 development
package, an IANA zoneinfo database, and Inno Setup 6. Then run:

    cabal update
    cabal build all --enable-tests
    cabal test all
    powershell -File scripts/build-windows-installer.ps1 -PcreDll C:\path\to\libpcre-1.dll -TimeZoneDir C:\path\to\share\zoneinfo -Iscc 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'

The installer is written to `dist\installer`. It performs a per-user install,
does not require administrator privileges, and offers optional PATH and startup
integration.
