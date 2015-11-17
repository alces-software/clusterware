# get-started(7) -- How to get started with your HPC environment

## DESCRIPTION

Welcome to your Linux HPC environment!

With your user account on the compute environment you can run
applications, work with files stored within the filesystems of the
compute environment and submit tasks to the HPC job scheduler. This
guide will help you get started with your HPC compute environment.

## HPC ENVIRONMENT COMPONENTS

An HPC environment is made up of a number of different machines which
are typically used for different purposes. Although these can vary,
most systems have the following types of resources:

  * One or more interactive nodes to provide access to users
  * Compute nodes used for running applications
  * One or more management nodes used to provide services within the
    compute environment

As a user, you will normally access the compute environment from an
interactive node - these may be referred to as login or visualisation
nodes. Access to the compute nodes is usually controlled by the HPC
job scheduler, allowing your administrator to control how, when and by
whom the compute nodes are used. Unless instructed otherwise, you
should not normally access the compute or management nodes directly.

## RUNNING JOBS

Applications to be run on compute nodes are typically packaged by
users into individual jobs, which are then submitted to a queue for
processing. Compute nodes are typically identical, or grouped into
different types depending on their configuration or available
resources. When a new job is submitted, the user needs to provide
information to the scheduler to describe how the job should be run -
this typically includes details of the software application to run,
information about data files for the job, and the resources needed for
the application.

Resource requests typically include the number of nodes and CPU cores
to use, the amount of memory required and the expected runtime of the
job. It is important to make an accurate assessment of the resources
required - requesting too few resources could cause the job to run
slowly or not finish in the allowed time; requesting too many
resources could mean that the job has to wait for a longer time before
enough free nodes are available to allow it to run.

For more information on how to submit jobs to your compute
environment, please see the "How to run jobs" guide
([run-jobs](run-jobs)).

## MANAGING DATA

Your compute environment has a number of different areas that can be
used to store files, each with different performance, capacity, access
and data rentention characteristics. By choosing the right area to
store your files, you can ensure that your jobs will perform best, and
that your data will be protected from automatic deletion.

Common data storage areas for HPC environments include:

 * Local scratch:

   Usually the best-performing storage device with lowest contention,
   local scratch is persistent only while jobs are running, and may be
   cleared automatically between jobs. This is a good location for
   temporary data that does not need to be shared between nodes - data
   stored here should be copied to persistent storage at the end of
   each job.

 * Shared scratch:

   A temporary storage area available to all compute nodes for storage
   of files during jobs. Shared filesystems may have quotas enforced,
   and may be automatically cleared during system maintenance periods
   &mdash; data stored here should be copied to persistent storage at
   the end of each job.

 * Home directories:

   A persistent storage area available to all compute nodes for
   storage of data files used within the compute environment. While
   often not a high-performance filesystem, your home directory can be
   used to store data on a longer-term bais. Shared filesystems may
   have quotas enforced - use of compression utilities is recommended
   to maximise the available capacity. Contact your site administrator
   for confirmation that your home directory is backed up for extra
   security.

 * Archive:

   A long-term, persistent storage area available to interactive nodes
   only. This area should be not be used for providing input data to
   jobs running within the compute environment, as it may not be
   available to compute nodes directly.

When you log in to the compute environment for the first time, the
system may automatically generate links in your home directory to the
different storage areas available on your machine.

## SEE ALSO

run-jobs

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2015 Alces Software Ltd.
