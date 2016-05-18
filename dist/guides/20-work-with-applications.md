# work-with-applications(7) -- How to work with your applications

## DESCRIPTION

Applications are installed in a central location within the compute
environment and are available on all compute nodes. This guide
explains how to install and access applications, as well as the use
 of the utilities provided for doing so.

## OVERVIEW

Through the Alces Gridware utility - applications, compilers
and accelerated libraries are easily installed and made
available to your environment for usage with your jobs.

To make application loading as straightforward as possible, whilst
also allowing installation of multiple versions and compilations of
the same application, the system makes use of *environment
modules* (<http://modules.sourceforge.net/>) operated via the `module`
command.

Most applications are command-line based and so can be run in an
interactive terminal or script &mdash; see the "How to run jobs" guide
([run-jobs](run-jobs)). Some applications require an X Window System
and must be executed run within a graphical session under qrsh &mdash;
see the "How to run graphical jobs" guide
([run-graphical-jobs](run-graphical-jobs)).

## ALCES GRIDWARE UTILITY

The `alces gridware` utility provides a simple interface for installing
applications, compilers and accelerated libraries to your environment. 
Only privileged users of an environment are granted access to the Gridware
utility.

To view all of the available Gridware packages: 

    alces gridware list

To search for specific Gridware packages by name: 

    alces gridware search --name python
    base/apps/ipython/2.3.0   base/apps/python/2.7.3    base/apps/python/2.7.5
    base/apps/python/2.7.8    base/apps/python3/3.2.3   base/apps/python3/3.3.3
    base/apps/python3/3.4.0   base/apps/python3/3.4.3   base/libs/biopython/1.61
    base/libs/biopython/1.63

To install an application to your environment, making it 
immediately available for use via the `module` command:

    alces gridware install apps/memtester/4.3.0

## THE MODULE COMMAND

The `module` command sets environment variables and performs tasks
that enable you to run a specific version of the application without
needing to know where it is installed. Each application installed on
the system has its own module; loading it makes the application
available on your `PATH` as well as setting a number of environment
variables named by a simple convention.

There may be multiple versions of an application available. If you
find that new features cause problems you can still load an older
version.

There may also be multiple compilations of an application
available. Examples of multiple compilations include an application
that may be compiled against different MPI environments. Each
compilation may offer significant performance benefits for different
use cases.

## AVAILABLE SOFTWARE

To list the software available within the compute environment, use the
`module avail` command, e.g.:

    [user@login1(cluster) ~]$ module avail apps

    ---  /opt/gridware/bio/el6/etc/modules  ---
      apps/abyss/1.2.6/gcc-4.4.6+openmpi-1.6.3+sparsehash-1.10
      apps/abyss/1.5.1/gcc-4.4.6+openmpi-1.6.3+sparsehash-1.10+boost-1.53.0
      apps/artemis/14.0.17/noarch
      apps/augustus/2.6.1/gcc-4.4.6
      apps/bamtools/2.3.0/gcc-4.4.6
      apps/bedtools/2.20.1/gcc-4.4.6
      apps/bowtie/1.0.0/gcc-4.4.6
      apps/bowtie2/2.1.0/gcc-4.4.6
      apps/bwa/0.7.5a/gcc-4.4.6
      apps/cufflinks/2.0.2/gcc-4.4.6+boost-1.49.0+samtools-0.1.18+eigen-3.0.5
      apps/cutadapt/1.1/gcc-4.4.6+python-2.7.3
      apps/igv/2.1.21/noarch
      apps/ncbiblast/2.2.30/gcc-4.4.6
      apps/picard/1.104/noarch
      apps/samtools/0.1.18/gcc-4.4.6
    ---  /opt/gridware/local/el6/etc/modules  ---
      apps/imb/3.2.3/gcc-4.4.6+openmpi-1.6.3 *default*
      apps/imb/3.2.3/imb-impi
      apps/R/3.1.2/gcc-4.4.6+lapack-3.4.1+blas-1

Each application has a standardised naming convention:
`<category>/<application name>/<application version>/<compilation
options>`.

To load a module into your environment, use the `module load` command,
e.g.:

    [user@login1(cluster) ~]$ module load apps/R
    apps/R/2.15.2/gcc-4.4.6+lapack-3.4.1+blas-1
     | -- libs/gcc/system
     |    * --> OK
     |
     OK

The application will then become available in your command path, e.g.:

    [user@login1(cluster) ~]$ R --help
    Usage: R [options] [< infile] [> outfile]
       or: R CMD command [arguments]

    Start R, a system for statistical computation and graphics, with the
    specified options, or invoke an R tool via the 'R CMD' interface.

    Options:
      -h, --help            Print short help message and exit
    [snip]

Note that when loading a module you don't need to specify the version
or compilation options, this will cause the recommended default
version to be loaded.

## EXPLORING SOFTWARE

Once a module has been loaded, several predefined environment
variables that link to the application installation directories are
available:

 * `$<name>DIR`:

    The directory containing the application, e.g. `$SAMTOOLSDIR`.

 * `$<name>BIN`:

    The directory containing the binaries for the application,
    e.g. `$SAMTOOLSBIN`.  This directory is automatically prepended to
    your `PATH`.

Where applicable, some further variables are defined for convenience:

 * `$<name>DOC`:

   The directory containing any documentation provided for the
   application, e.g. `$SAMTOOLSDOC`.

 * `$<name>LIB`:

   The directory containing development or runtime libraries provided
   by the application, e.g. `$SAMTOOLSLIB`.

 * `$<name>INCLUDE`:

   The directory containing header files provided by the application,
   e.g. `$SAMTOOLSINCLUDE`.

You can use these links to explore the files available with the
installed application. For example:

    [user@login1(cluster) ~]$ cd $SAMTOOLSDIR

    [user@login1(cluster) gcc-4.4.7]$ pwd
    /opt/gridware/depots/c57e463b/el6/pkg/apps/samtools/0.1.19/gcc-4.4.7

    [user@login1(cluster) gcc-4.4.7]$ ls
    bin  doc  examples  include  lib  man

Further environment variables may also be set depending on the
application. To determine what variables will be set when a module is
loaded, use the `module show` command, e.g.:

    [user@login1(cluster) ~]$ module show apps/R

For more information regarding environment modules please refer to the
*environment modules website* (<http://modules.sourceforge.net/>).

For more information on some of the additional application features, please see the [Gridware documentation](http://docs.alces-flight.com/en/latest/apps/apps.html#shared-cluster-applications)

## SEE ALSO

run-jobs, run-graphical-jobs, module(1)

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2015 Alces Software Ltd.
