# sudo umount /dev/loop24
# sudo rmmod f2fs
# sudo insmod /home/femu/btrfs-zns/fs/f2fs/f2fs.ko


# sudo dmesg -c
# sudo /home/femu/sungjin1_f2fs_stat
# sudo filebench -f /home/femu/filebench/workloads/fileserver3.f > tmp_app_result
# sudo /home/femu/sungjin1_f2fs_stat
# sudo dmesg -c > ./tmp_kernel_result

RESULT_DIR_PATH=/home/femu/home/femu/FAST_testdata/fb_result/

NORUNTIME=0
EZRESET=1
FAR_LOG=2
FAR_LINEAR=3
FAR_EXP=4

WORKLOAD=fileserver3

for T in 90
do
    for i in 1 2 3
    do
        for SCHEME in $NORUNTIME
        do

            if [ $SCHEME -eq $NORUNTIME ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_NORUNTIME_LSE_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_NORUNTIME_LSE_kernel_${i}.txt
            elif [ $SCHEME -eq $EZRESET ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_EZR_${T}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_EZR_kernel_${T}_${i}.txt
            elif [ $SCHEME -eq $FAR_EXP ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_EXP_${T}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_kernel_EXP_${T}_${i}.txt
            elif [ $SCHEME -eq $FAR_LINEAR ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_LINEAR_${T}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_kernel_LINEAR_${T}_${i}.txt
            elif [ $SCHEME -eq $FAR_LOG ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_LOG_${T}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_kernel_LOG_${T}_${i}.txt
            else  
                echo "error"
            fi
            
            
            
            if [ -f ${RESULT_PATH} ]; then
                echo "already $RESULT_PATH exists"
                sleep 5
                continue
            fi
            
            
            sudo umount /dev/loop24
            sudo mkfs.f2fs -m -c  /dev/nvme0n1 /dev/loop24 -f

            sudo /home/femu/mountfs ${SCHEME} ${T}

            sudo dmesg -c
            sudo /home/femu/sungjin1_f2fs_stat
            sudo filebench -f /home/femu/filebench/workloads/${WORKLOAD}.f > ${RESULT_PATH}
            sudo /home/femu/sungjin1_f2fs_stat
            sudo dmesg -c > ${RESULT_KERNEL_PATH}
        done
    done

done