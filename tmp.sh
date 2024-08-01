            if lsblk | grep -q "nvme0n1"; then
                echo nvme0n1qwerqwe
                # break
            else
                # cat ${RESULT_DIR_PATH}/tmp > ${RESULT_DIR_PATH}/failed
                # sleep 5
                echo none
            fi