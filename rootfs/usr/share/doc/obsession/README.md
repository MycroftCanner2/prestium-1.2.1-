# What are these programs for?

  * obsession-logout displays a dialog where you can choose if you want
    to quit the session power off, suspend or hibernate the computer.

  * obsession-exit, this is the command line version of obsession-logout.

  * xdg-autostart start automaticaly programs defined in /etc/xdg/autostart
    and ~/.config/autostart (see FreeDesktop specification for autostarted
    programs). Add it to your ~/.openbox/autostart file and manage your
    session with lxsession-edit or other. If you want to set your desktop
    name (e.g. KDE, XFCE, ROX...), add it as a parameter to xdg-autostart
    (e.g. xdg-autostart GNOME). Please refer to this [table](http://standards.freedesktop.org/menu-spec/latest/apb.html) to get
    the name of desktops currently supported by the Freedesktop specification.
    By default, xdg-autostart uses Openbox as desktop name.

# Why?

I'm a big fan of Openbox and LXDE, but I don't need all the features of the
last one. So starting from LXDE project and keeping what is useful (for me)
was a good start to have a very lightweight desktop easy to manage.

# This is so old school!

Yes but it works with ConsoleKit, UPower and systemd.

# xdg-autostart? But Openbox already starts programs automatically!

Yes, it does. Dana have done a god job.

The default Openbox session launches openbox-autostart which launches
openbox-xdg-autostart, a python script. This script requires python-xdg
library to run and, of course, python. The python-xdg dependency is
sometimes missed by packagers, so Openbox may or may not autostart
programs. Xdg-autostart doesn't have this problem.

It was fun to code an autostart program, and it had to be included in
an openbox session managment. You are free to use it or not. If you do
then comment the line calling openbox-xdg-autostart in the
/usr/lib/openbox/openbox-autostart file.

# Configuration

the programs obsession-logout and obsession-exit uses a configuration file
named obsession.conf. This file is automatically created in the .config
directory located in the user home.

The key `screenlock` sets the screen lock command. The key `logout` defines
the logout command. Their respective default values are `xlock -mode blank`
and `openbox --exit`.

