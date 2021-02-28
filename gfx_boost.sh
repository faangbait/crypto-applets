#!/bin/sh

export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1

systemctl start amdgpu-clocks
/home/ss/Binaries/amdmemorytweak/linux/amdmemtweak --CL 20 --RAS 30 --RCDRD 14 --RCDWR 12 --RC 44 --RP 14 --RRDS 3 --RRDL 6 --RTP 5 --FAW 12 --CWL 8 --WTRS 4 --WTRL 9 --WR 14 --REF 17000 --RFC 249
