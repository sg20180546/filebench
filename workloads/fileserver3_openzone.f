#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

set mode quit alldone

set $dir=/home/micron/f2fs_mount
set $nfiles=20000
set $meandirwidth=20
set $filesize=cvar(type=cvar-gamma,parameters=mean:268435456;gamma:1.5)
set $nthreads=8
set $iosize=128m
set $readiosize=128m
set $meanappendsize=32m


define fileset name=bigfileset,path=$dir,size=$filesize,entries=$nfiles,dirwidth=$meandirwidth,prealloc=0

define process name=filereader,instances=1
{
  thread name=filewriterthread1,memsize=256m,instances=$nthreads
  {
    flowop createfile name=createfile1,filesetname=bigfileset,fd=1
    flowop writewholefile name=wrtfile1,srcfd=1,fd=1,iosize=$iosize
    flowop fsync name=fsyncfile1,fd=1
    flowop closefile name=closefile1,fd=1


    flowop openfile name=openfile1,filesetname=bigfileset,fd=1
    flowop appendfilerand name=appendfilerand1,iosize=$meanappendsize,fd=1
    flowop closefile name=closefile2,fd=1



    flowop openfile name=openfile2,filesetname=bigfileset,fd=1
    flowop readwholefile name=readfile1,fd=1,iosize=$readiosize
    flowop closefile name=closefile3,fd=1


    flowop deletefile name=deletefile1,filesetname=bigfileset

    flowop statfile name=statfile1,filesetname=bigfileset
    flowop finishoncount name=foc,value=26000
  }
}

echo  "File-server Version 3.0 personality successfully loaded"

psrun
