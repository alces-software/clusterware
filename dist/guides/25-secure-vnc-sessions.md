# secure-vnc-sessions(7) -- How to secure your VNC sessions

## DESCRIPTION

As the VNC protocol does not natively provide support for security
protocols such as SSL, you may wish to take steps to secure access to
your VNC sessions.  This guide explains some approaches you can take
for securing your VNC sessions.

For further information, please refer to the Alces Flight Compute
documentation at <http://docs.alces-flight.com>.

## ALCES FLIGHT ACCESS SERVICE

Delivered over the web, Alces Flight Access provides an easy-access
overview of the interactive sessions your are running across your
clusters.  As well as allowing you to start and terminate sessions,
Alces Flight Access shows you connection details along with an image
of the current state of the session and provides secure, encrypted
access to your interactive sessions directly from within your web
browser.

If you are using an enhanced or enterprise edition of Alces Flight
Compute, please contact us at <support@alces-flight.com> to find out
how to provision an Alces Flight Access appliance.

## CLUSTERWARE VPN

Clusterware may be configured with an OpenVPN service.  Refer to the
`alces about vpn` command to locate the configuration files for your
platform.  You can find OpenVPN downloads and documentation for your
client system at <https://openvpn.net/>.

## OTHER SOLUTIONS

Several third party tools exist to help you secure your VNC
connections.  One option is `ssvnc`, available at
<http://www.karlrunge.com/x11vnc/ssvnc.html>.

Alternatively, you could use an SSH tunnel to access your session.
Refer to online guides for setup instructions,
e.g. <http://www.cl.cam.ac.uk/research/dtg/attarchive/vnc/sshvnc.html>.

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2016 Alces Software Ltd.
