# sudo umount /dev/loop24
# sudo rmmod f2fs
# sudo insmod /home/femu/btrfs-zns/fs/f2fs/f2fs.ko


# sudo dmesg -c
# sudo /home/femu/sungjin1_f2fs_stat
# sudo filebench -f /home/femu/filebench/workloads/fileserver3.f > tmp_app_result
# sudo /home/femu/sungjin1_f2fs_stat
# sudo dmesg -c > ./tmp_kernel_result

# sudo nano /proc/sys/kernel/randomize_va_space


# sudo rm -rf /mnt/mydisk
# sudo rm -rf my_disk_image.img 
# dd if=/dev/zero of=my_disk_image.img bs=4096 count=524288
# sudo mkfs.ext4 -b 4096 my_disk_image.img
# sudo mkdir /mnt/mydisk

# sudo mount -o loop my_disk_image.img /mnt/mydisk
# sudo umount /mnt/mydisk
# sudo losetup --sector-size 4096 /dev/loop24 my_disk_image.img

RESULT_DIR_PATH=/home/femu/FAST_testdata/fb_result_small

NORUNTIME=0
EZRESET=1
FAR_LOG=2
FAR_LINEAR=3
FAR_EXP=4

WORKLOAD=fileserver3

# 4GB 2097152
# 2GB 1048576
# 1GB 524288
 
LSE=0 # 64
LME2=1 # 128
LME4=2 # 256

DEVICE=$LME4


if [ $DEVICE -eq $LSE ]; then
    RANDOM_SIZE=114688
    DEVICE_STRING=LSE
elif [ $DEVICE -eq $LME2 ]; then
    RANDOM_SIZE=131072
    DEVICE_STRING=LME2
elif [ $DEVICE -eq $LME4 ]; then
    RANDOM_SIZE=196608
    DEVICE_STRING=LME4
else
    echo "which device"
    exit
fi


if lsblk | grep -q "loop24"; then
    echo "loop24 mounted"
else
    sudo rm -rf /mnt/mydisk
    sudo rm -rf my_disk_image.img 
    dd if=/dev/zero of=my_disk_image.img bs=4096 count=$RANDOM_SIZE
    sudo mkfs.ext4 -b 4096 my_disk_image.img
    sudo mkdir /mnt/mydisk

    sudo mount -o loop my_disk_image.img /mnt/mydisk
    sudo umount /mnt/mydisk
    sudo losetup --sector-size 4096 /dev/loop24 my_disk_image.img
fi


for T in 130
do
    for i in 41 42 43
    do
        for SCHEME in $NORUNTIME
        do

            if [ $SCHEME -eq $NORUNTIME ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_NORUNTIME_${DEVICE_STRING}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_NORUNTIME_${DEVICE_STRING}_kernel_${i}.txt
            elif [ $SCHEME -eq $EZRESET ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_EZR_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_EZR_kernel_${i}.txt
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
            
            sleep 1
            while : 
            do
            echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
            echo "0" | sudo tee /proc/sys/kernel/randomize_va_space
            sudo umount /dev/loop24
            sudo mkfs.f2fs -m -c  /dev/nvme0n1 /dev/loop24 -f > tmp1

            sleep 2
            sudo /home/femu/mountfs ${SCHEME} ${T}

            sudo dmesg -c > tmp2
            sudo /home/femu/sungjin1_f2fs_stat
            # sudo filebench -f /home/femu/filebench/workloads/${WORKLOAD}.f > ${RESULT_PATH}
            echo ${RESULT_PATH}
            echo ${RESULT_KERNEL_PATH}
            
            sudo filebench -f /home/femu/filebench/workloads/${WORKLOAD}.f > ${RESULT_DIR_PATH}/tmp

            if grep -q "Shutting down processes" ${RESULT_DIR_PATH}/tmp; then
                sudo /home/femu/sungjin1_f2fs_stat
                sudo dmesg -c > ${RESULT_KERNEL_PATH}
                cat ${RESULT_DIR_PATH}/tmp > ${RESULT_PATH}
                
                cat /home/femu/filebench/workloads/${WORKLOAD}.f >> ${RESULT_PATH}

                rm -rf ${RESULT_DIR_PATH}/tmp
                break
            else
                cat ${RESULT_DIR_PATH}/tmp > ${RESULT_DIR_PATH}/failed
                sleep 5
            fi

            done
        done
    done

done