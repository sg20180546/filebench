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
# sudo rm -rf /home/femu/my_disk_image.img 
# dd if=/dev/zero of=/home/femu/my_disk_image.img bs=4096 count=524288
# sudo mkfs.ext4 -b 4096 /home/femu/my_disk_image.img
# sudo mkdir /mnt/mydisk

# sudo mount -o loop /home/femu/my_disk_image.img /mnt/mydisk
# sudo umount /mnt/mydisk
# sudo losetup --sector-size 4096 /dev/loop24 /home/femu/my_disk_image.img

RESULT_DIR_PATH=/home/femu/FAST_testdata/fb_result_openzone

NORUNTIME=0
EZRESET=1
FAR_LOG=2
FAR_LINEAR=3
FAR_EXP=4


# 4GB 2097152
# 2GB 1048576
# 1GB 524288

LSE=0 # 128
LME2=1 #256
LME4=2 #512

DEVICE=$LSE
DEVICE_NAME=nvme0n1
WORKLOAD=fileserver3_openzone


if [ $DEVICE -eq $LSE ]; then
    RANDOM_SIZE=524288
    DEVICE_STRING=LSE
     RESET_N=80
elif [ $DEVICE -eq $LME2 ]; then
    RANDOM_SIZE=1048576
    DEVICE_STRING=LME2
    RESET_N=320
elif [ $DEVICE -eq $LME4 ]; then
    RANDOM_SIZE=2097152
    DEVICE_STRING=LME4
     RESET_N=160
else
    echo "which device"
    exit
fi


if lsblk | grep -q "loop24"; then
    echo "loop24 mounted"
else
    sudo rm -rf /mnt/mydisk
    sudo rm -rf /home/femu/my_disk_image.img 
    dd if=/dev/zero of=/home/femu/my_disk_image.img bs=4096 count=$RANDOM_SIZE
    sudo mkfs.ext4 -b 4096 /home/femu/my_disk_image.img
    sudo mkdir /mnt/mydisk

    sudo mount -o loop /home/femu/my_disk_image.img /mnt/mydisk
    sudo umount /mnt/mydisk
    sudo losetup --sector-size 4096 /dev/loop24 /home/femu/my_disk_image.img
fi

echo "mq-deadline" | sudo tee /sys/block/${DEVICE_NAME}/queue/scheduler
echo "0" | sudo tee /proc/sys/kernel/randomize_va_space
# sudo /home/femu/zns_utilities/dummy 999 999

T=90



for SCHEME in $NORUNTIME $FAR_EXP
do
    for i in 101
    do
        for O in 1 80
        do

            if [ $SCHEME -eq $NORUNTIME ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_NORUNTIME_${DEVICE_STRING}_${O}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_NORUNTIME_${DEVICE_STRING}_kernel_${O}_${i}.txt
            elif [ $SCHEME -eq $EZRESET ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_EZR_${O}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_EZR_kernel_${i}.txt
            elif [ $SCHEME -eq $FAR_EXP ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_EXP_${T}_${O}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_kernel_EXP_${T}_${O}_${i}.txt
            elif [ $SCHEME -eq $FAR_LINEAR ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_LINEAR_${T}_${O}_${i}.txt
                RESULT_KERNEL_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_kernel_LINEAR_${T}_${O}_${i}.txt
            elif [ $SCHEME -eq $FAR_LOG ]; then
                RESULT_PATH=${RESULT_DIR_PATH}/${WORKLOAD}_ZEUFS_LOG_${T}_${O}_${i}.txt
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
           
            
            sudo umount /dev/loop24
            sudo /home/femu/zone_reset_all 0 ${RESET_N} > /home/femu/tmp1
            sudo mkfs.f2fs -m -c  /dev/${DEVICE_NAME} /dev/loop24 -f > /home/femu/tmp1

            # sleep 10
            sudo /home/femu/mountfs ${SCHEME} ${T} ${O}
            if [ $? -eq 1 ]; then
                echo "COSMOS FAIL"
                exit
            fi

            # sleep 10
            sudo dmesg -c > /home/femu/tmp2
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
                # sudo /home/femu/zns_utilities/dummy 999 999
                rm -rf ${RESULT_DIR_PATH}/tmp
                break
            else
                # sudo /home/femu/zns_utilities/dummy 999 999
                cat ${RESULT_DIR_PATH}/tmp > ${RESULT_DIR_PATH}/failed
                sleep 5
                break
            fi

            done
        done
    done

done