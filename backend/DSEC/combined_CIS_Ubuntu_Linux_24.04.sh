#!/usr/bin/env bash

a__1_1_1_1() {
#!/usr/bin/env bash

{
a_output=()
a_output2=()
a_output3=()
l_dl=""
l_mod_name="cramfs"
l_mod_type="fs"
l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

f_module_chk() {
    l_dl="y"
    a_showconfig=()
    while IFS= read -r l_showconfig; do
        a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

    if ! lsmod | grep "$l_mod_chk_name" &> /dev/null; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
}

for l_mod_base_directory in $l_mod_path; do
    if [ -d "$l_mod_base_directory/${l_mod_name/-//}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-//}")" ]; then
        a_output3+=(" - \"$l_mod_base_directory\"")
        l_mod_chk_name="$l_mod_name"
        [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
        [ "$l_dl" != "y" ] && f_module_chk
    else
        a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
done

[ "${#a_output3[@]}" -gt 0 ] && printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"

if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
fi
}
}

a__1_1_1_10() {
a_output=()
    a_output2=()
    a_modprope_config=()
    a_excluded=()
    a_available_modules=()
    a_ignore=("xfs" "vfat" "ext2" "ext3" "ext4")
    a_cve_exists=(
        "afs" "ceph" "cifs" "exfat" "ext" "fat" "fscache" "fuse" "gfs2" 
        "nfs_common" "nfsd" "smbfs_common"
    )

    f_module_chk() {
        local l_out2=""
        # Mark if module has known CVE
        if grep -Pq -- "\b$l_mod_name\b" <<< "${a_cve_exists[*]}"; then
            l_out2=" <- CVE exists!"
        fi

        # Check blacklist and install lines to verify module disabled status
        if ! grep -Pq -- '\bblacklist\h+'"${l_mod_name}"'\b' <<< "${a_modprope_config[*]}"; then
            a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled$l_out2")
        elif ! grep -Pq -- '\binstall\h+'"${l_mod_name}"'\h+(\/usr)?\/bin\/(false|true)\b' <<< "${a_modprope_config[*]}"; then
            a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled$l_out2")
        fi

        # Check if module is currently loaded
        if lsmod | grep -q "$l_mod_name"; then
            a_output2+=(" - Kernel module: \"$l_mod_name\" is loaded")
        fi
    }

    # Collect available filesystem kernel modules directories (non-empty only)
    while IFS= read -r -d $'\0' l_module_dir; do
        a_available_modules+=("$(basename "$l_module_dir")")
    done < <(find "$(readlink -f /lib/modules/$(uname -r)/kernel/fs)" -mindepth 1 -maxdepth 1 -type d ! -empty -print0)

    # Check current mounts to exclude relevant modules and warn for CVEs
    while IFS= read -r l_exclude; do
        if grep -Pq -- "\b$l_exclude\b" <<< "${a_cve_exists[*]}"; then
            a_output2+=(" - ** WARNING: kernel module: \"$l_exclude\" has a CVE and is currently mounted! **")
        elif grep -Pq -- "\b$l_exclude\b" <<< "${a_available_modules[*]}"; then
            a_output+=(" - Kernel module: \"$l_exclude\" is currently mounted - do NOT unload or disable")
        fi
        # Add to ignore list if not already there
        if ! grep -Pq -- "\b$l_exclude\b" <<< "${a_ignore[*]}"; then
            a_ignore+=("$l_exclude")
        fi
    done < <(findmnt -knD | awk '{print $2}' | sort -u)

    # Get modprobe config blacklist/install entries
    while IFS= read -r l_config; do
        a_modprope_config+=("$l_config")
    done < <(modprobe --showconfig | grep -P '^\h*(blacklist|install)')

    # Check all available filesystem modules
    for l_mod_name in "${a_available_modules[@]}"; do
        # Normalize overlay modules by trimming trailing characters
        [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"

        if grep -Pq -- "\b$l_mod_name\b" <<< "${a_ignore[*]}"; then
            a_excluded+=(" - Kernel module: \"$l_mod_name\"")
        else
            f_module_chk
        fi
    done

    # After processing all modules and filling a_output2 and a_output arrays

    # Check if any output line contains "not fully disabled" AND "<- CVE exists!"
    l_fail=0
    for line in "${a_output2[@]}"; do
        if [[ "$line" == *"not fully disabled"* && "$line" == *"<- CVE exists!"* ]]; then
            l_fail=1
            break
        fi
    done

    if (( l_fail == 1 )); then
        printf '%s\n' "" "-- Audit Result: --" " ** FAIL **" "The following modules have CVE and are not fully disabled:" 
        for line in "${a_output2[@]}"; do
            # Print only lines with CVE not disabled message
            if [[ "$line" == *"not fully disabled"* && "$line" == *"<- CVE exists!"* ]]; then
                printf '%s\n' " $line"
            fi
        done
        # Optionally, print the rest of the messages
        printf '%s\n' "" "-- Other findings --"
        for line in "${a_output2[@]}"; do
            # Print lines without CVE not disabled (optional)
            if ! [[ "$line" == *"not fully disabled"* && "$line" == *"<- CVE exists!"* ]]; then
                printf '%s\n' " $line"
            fi
        done
    else
        printf '%s\n' "" "-- Audit Result: --" " ** PASS **"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "-- Correctly set: --" "${a_output[@]}"
    fi
}

a__1_1_1_2() {
#!/usr/bin/env bash

{
a_output=()
a_output2=()
a_output3=()
l_dl=""
l_mod_name="freevxfs"
l_mod_type="fs"
l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

f_module_chk() {
    l_dl="y"
    a_showconfig=()
    while IFS= read -r l_showconfig; do
        a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

    if ! lsmod | grep "$l_mod_chk_name" &> /dev/null; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
}

for l_mod_base_directory in $l_mod_path; do
    if [ -d "$l_mod_base_directory/${l_mod_name/-//}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-//}")" ]; then
        a_output3+=(" - \"$l_mod_base_directory\"")
        l_mod_chk_name="$l_mod_name"
        [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
        [ "$l_dl" != "y" ] && f_module_chk
    else
        a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
done

[ "${#a_output3[@]}" -gt 0 ] && printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"

if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
fi
}
}

a__1_1_1_3() {
#!/usr/bin/env bash
{
    a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="hfs"
    l_mod_type="fs"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}
}

a__1_1_1_4() {
a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="hfsplus"
    l_mod_type="fs"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}

a__1_1_1_5() {
a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="jffs2"
    l_mod_type="fs"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}

a__1_1_1_6() {
a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="overlayfs"
    l_mod_type="fs"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}

a__1_1_1_7() {
a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="squashfs"
    l_mod_type="fs"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}

a__1_1_1_8() {
a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="udf"
    l_mod_type="fs"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}

a__1_1_1_9() {
a_output=()
    a_output2=()
    a_output3=()
    l_dl=""
    l_mod_name="usb-storage"
    l_mod_type="drivers"
    l_mod_path="$(readlink -f /lib/modules/*/kernel/$l_mod_type | sort -u)"

    f_module_chk() {
        l_dl="y"
        a_showconfig=()
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

        if ! lsmod | grep -q "$l_mod_chk_name"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
        fi

        if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
        fi

        if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    for l_mod_base_directory in $l_mod_path; do
        mod_dir="$l_mod_base_directory/${l_mod_name//-//}"
        if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
            a_output3+=(" - \"$l_mod_base_directory\"")
            l_mod_chk_name="$l_mod_name"
            [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
            [ "$l_dl" != "y" ] && f_module_chk
        else
            a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
        fi
    done

    if [ "${#a_output3[@]}" -gt 0 ]; then
        printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
    fi

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
}

a__1_1_2_1_1() {
output=$(findmnt -kn /tmp)

if [[ -n "$output" ]]; then
    echo "** PASS ** /tmp is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL ** /tmp is not mounted separately"
    return 1
fi
}

a__1_1_2_1_2() {
mount_info=$(findmnt -kn /tmp)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /tmp is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nodev; then
    echo "** PASS ** /tmp is mounted separately with nodev option"
    return 0
else
    echo "** FAIL ** /tmp is mounted separately but missing nodev option"
    return 1
fi
}

a__1_1_2_1_3() {
mount_info=$(findmnt -kn /tmp)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /tmp is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nosuid; then
    echo "** PASS ** /tmp is mounted separately with nosuid option"
    return 0
else
    echo "** FAIL ** /tmp is mounted separately but missing nosuid option"
    return 1
fi
}

a__1_1_2_1_4() {
mount_info=$(findmnt -kn /tmp)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /tmp is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw noexec; then
    echo "** PASS ** /tmp is mounted separately with noexec option"
    return 0
else
    echo "** FAIL ** /tmp is mounted separately but missing noexec option"
    return 1
fi
}

a__1_1_2_2_1() {
output=$(findmnt -kn /dev/shm)

if [[ -n "$output" ]]; then
    echo "** PASS ** /dev/shm is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL **/dev/shm is not mounted separately"
    return 1
fi
}

a__1_1_2_2_2() {
mount_info=$(findmnt -kn /dev/shm)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /dev/shm is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nodev; then
    echo "** PASS ** /dev/shm is mounted separately with nodev option"
    return 0
else
    echo "** FAIL ** /dev/shm is mounted separately but missing nodev option"
    return 1
fi
}

a__1_1_2_2_3() {
mount_info=$(findmnt -kn /dev/shm)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /dev/shm is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nosuid; then
    echo "** PASS ** /dev/shm is mounted separately with nosuid option"
    return 0
else
    echo "** FAIL ** /dev/shm is mounted separately but missing nosuid option"
    return 1
fi
}

a__1_1_2_2_4() {
mount_info=$(findmnt -kn /dev/shm)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /dev/shm is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw noexec; then
    echo "** PASS ** /dev/shm is mounted separately with noexec option"
    return 0
else
    echo "** FAIL ** /dev/shm is mounted separately but missing noexec option"
    return 1
fi
}

a__1_1_2_3_1() {
output=$(findmnt -kn /home)

if [[ -n "$output" ]]; then
    echo "** PASS ** /home is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL **/home is not mounted separately"
    return 1
fi
}

a__1_1_2_3_2() {
mount_info=$(findmnt -kn /home)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /home is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nodev; then
    echo "** PASS ** /home is mounted separately with nodev option"
    return 0
else
    echo "** FAIL ** /home is mounted separately but missing nodev option"
    return 1
fi
}

a__1_1_2_3_3() {
mount_info=$(findmnt -kn /home)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /home is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nosuid; then
    echo "** PASS ** /home is mounted separately with nosuid option"
    return 0
else
    echo "** FAIL ** /home is mounted separately but missing nosuid option"
    return 1
fi
}

a__1_1_2_4_1() {
output=$(findmnt -kn /var)

if [[ -n "$output" ]]; then
    echo "** PASS ** /var is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL **/var is not mounted separately"
    return 1
fi
}

a__1_1_2_4_2() {
mount_info=$(findmnt -kn /var)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nodev; then
    echo "** PASS ** /var is mounted separately with nodev option"
    return 0
else
    echo "** FAIL ** /var is mounted separately but missing nodev option"
    return 1
fi
}

a__1_1_2_4_3() {
mount_info=$(findmnt -kn /var)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nosuid; then
    echo "** PASS ** /var is mounted separately with nosuid option"
    return 0
else
    echo "** FAIL ** /var is mounted separately but missing nosuid option"
    return 1
fi
}

a__1_1_2_5_1() {
output=$(findmnt -kn /var/tmp)

if [[ -n "$output" ]]; then
    echo "** PASS ** /var/tmp is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL **/var/tmp is not mounted separately"
    return 1
fi
}

a__1_1_2_5_2() {
mount_info=$(findmnt -kn /var/tmp)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/tmp is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nodev; then
    echo "** PASS ** /var/tmp is mounted separately with nodev option"
    return 0
else
    echo "** FAIL ** /var/tmp is mounted separately but missing nodev option"
    return 1
fi
}

a__1_1_2_5_3() {
mount_info=$(findmnt -kn /var/tmp)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/tmp is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nosuid; then
    echo "** PASS ** /var/tmp is mounted separately with nosuid option"
    return 0
else
    echo "** FAIL ** /var/tmp is mounted separately but missing nosuid option"
    return 1
fi
}

a__1_1_2_5_4() {
mount_info=$(findmnt -kn /var/tmp)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/tmp is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw noexec; then
    echo "** PASS ** /var/tmp is mounted separately with noexec option"
    return 0
else
    echo "** FAIL ** /var/tmp is mounted separately but missing noexec option"
    return 1
fi
}

a__1_1_2_6_1() {
output=$(findmnt -kn /var/log)

if [[ -n "$output" ]]; then
    echo "** PASS ** /var/log is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL **/var/log is not mounted separately"
    return 1
fi
}

a__1_1_2_6_2() {
mount_info=$(findmnt -kn /var/log)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/log is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nodev; then
    echo "** PASS ** /var/log is mounted separately with nodev option"
    return 0
else
    echo "** FAIL ** /var/log is mounted separately but missing nodev option"
    return 1
fi
}

a__1_1_2_6_3() {
mount_info=$(findmnt -kn /var/log)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/log is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw nosuid; then
    echo "** PASS ** /var/log is mounted separately with nosuid option"
    return 0
else
    echo "** FAIL ** /var/log is mounted separately but missing nosuid option"
    return 1
fi
}

a__1_1_2_6_4() {
mount_info=$(findmnt -kn /var/log)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/log is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw noexec; then
    echo "** PASS ** /var/log is mounted separately with noexec option"
    return 0
else
    echo "** FAIL ** /var/log is mounted separately but missing noexec option"
    return 1
fi
}

a__1_1_2_7_1() {
output=$(findmnt -kn /var/log/audit)

if [[ -n "$output" ]]; then
    echo "** PASS ** /var/log/audit is mounted as a separate filesystem"
    return 0
else
    echo "** FAIL **/var/log/audit is not mounted separately"
    return 1
fi
}

a__1_1_2_7_2() {
mount_info=$(findmnt -kn /var/log/audit)

if [[ -z "$mount_info" ]]; then
    echo "** FAIL ** /var/log/audit is not a separate mount — this audit is not applicable"
    return 0
fi

if echo "$mount_info" | grep -qw noexec; then
    echo "** PASS ** /var/log/audit is mounted separately with noexec option"
    return 0
else
    echo "** FAIL ** /var/log/audit is mounted separately but missing noexec option"
    return 1
fi
}

a__1_3_1_1() {
fail=0

# Check apparmor-utils package
if dpkg-query -s apparmor-utils &>/dev/null; then
    echo "PASS: apparmor-utils is installed"
else
    echo "FAIL: apparmor-utils is NOT installed"
    fail=1
fi

# Check apparmor package
if dpkg-query -s apparmor &>/dev/null; then
    echo "PASS: apparmor is installed"
else
    echo "FAIL: apparmor is NOT installed"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "** PASS ** Both apparmor and apparmor-utils are installed"
else
    echo "** FAIL ** One or both of apparmor and apparmor-utils are missing"
fi
}

a__1_3_1_2() {
#!/usr/bin/env bash

fail=0

# Check if 'linux' lines are missing 'apparmor=1'
if grep "^\s*linux" /boot/grub/grub.cfg | grep -v "apparmor=1" >/dev/null; then
    echo "FAIL: One or more linux lines are missing 'apparmor=1'"
    fail=1
fi

# Check if 'linux' lines are missing 'security=apparmor'
if grep "^\s*linux" /boot/grub/grub.cfg | grep -v "security=apparmor" >/dev/null; then
    echo "FAIL: One or more linux lines are missing 'security=apparmor'"
    fail=1
fi

# Final audit result
if [ "$fail" -eq 0 ]; then
    echo "** PASS ** All linux lines include apparmor kernel parameters"
else
    echo "** FAIL ** Missing apparmor kernel parameters"
fi
}

a__1_3_1_3() {
fail=0

# Get apparmor status output
status_output=$(apparmor_status 2>/dev/null)

# Extract key counts from the output
profiles_unconfined=$(echo "$status_output" | awk '/profiles are in unconfined mode/ {print $1}')
profiles_kill=$(echo "$status_output" | awk '/profiles are in kill mode/ {print $1}')
profiles_prompt=$(echo "$status_output" | awk '/profiles are in prompt mode/ {print $1}')
processes_unconfined=$(echo "$status_output" | awk '/processes are unconfined but have a profile defined/ {print $1}')

# Print and check
if [ "$profiles_unconfined" -gt 0 ]; then
    echo "FAIL: $profiles_unconfined profiles are in unconfined mode"
    fail=1
fi

if [ "$profiles_kill" -gt 0 ]; then
    echo "FAIL: $profiles_kill profiles are in kill mode"
    fail=1
fi

if [ "$profiles_prompt" -gt 0 ]; then
    echo "FAIL: $profiles_prompt profiles are in prompt mode"
    fail=1
fi

if [ "$processes_unconfined" -gt 0 ]; then
    echo "FAIL: $processes_unconfined processes are unconfined but have a profile defined"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "** PASS ** All AppArmor profiles and processes are properly confined (enforce or complain mode)"
else
    echo "** FAIL ** One or more profiles or processes are in unsupported modes"
fi
}

a__1_3_1_4() {
fail=0

# Get AppArmor status output
status_output=$(apparmor_status 2>/dev/null)

# Extract counts
profiles_complain=$(echo "$status_output" | awk '/profiles are in complain mode/ {print $1}')
profiles_unconfined=$(echo "$status_output" | awk '/profiles are in unconfined mode/ {print $1}')
profiles_prompt=$(echo "$status_output" | awk '/profiles are in prompt mode/ {print $1}')
profiles_kill=$(echo "$status_output" | awk '/profiles are in kill mode/ {print $1}')
processes_complain=$(echo "$status_output" | awk '/processes are in complain mode/ {print $1}')
processes_unconfined=$(echo "$status_output" | awk '/processes are unconfined but have a profile defined/ {print $1}')
processes_prompt=$(echo "$status_output" | awk '/processes are in prompt mode/ {print $1}')
processes_kill=$(echo "$status_output" | awk '/processes are in kill mode/ {print $1}')

# Fail if any profile is not in enforce mode
if [ "$profiles_complain" -gt 0 ]; then
    echo "FAIL: $profiles_complain profiles are in complain mode"
    fail=1
fi

if [ "$profiles_unconfined" -gt 0 ]; then
    echo "FAIL: $profiles_unconfined profiles are in unconfined mode"
    fail=1
fi

if [ "$profiles_prompt" -gt 0 ]; then
    echo "FAIL: $profiles_prompt profiles are in prompt mode"
    fail=1
fi

if [ "$profiles_kill" -gt 0 ]; then
    echo "FAIL: $profiles_kill profiles are in kill mode"
    fail=1
fi

# Fail if any process is not in enforce mode
if [ "$processes_complain" -gt 0 ]; then
    echo "FAIL: $processes_complain processes are in complain mode"
    fail=1
fi

if [ "$processes_unconfined" -gt 0 ]; then
    echo "FAIL: $processes_unconfined processes are unconfined but have a profile defined"
    fail=1
fi

if [ "$processes_prompt" -gt 0 ]; then
    echo "FAIL: $processes_prompt processes are in prompt mode"
    fail=1
fi

if [ "$processes_kill" -gt 0 ]; then
    echo "FAIL: $processes_kill processes are in kill mode"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "** PASS ** All AppArmor profiles and processes are in enforce mode"
else
    echo "** FAIL ** One or more profiles or processes are not enforcing"
fi
}

a__1_4_1() {
# Check if 'set superusers' line exists in /boot/grub/grub.cfg
if ! grep -q '^set superusers' /boot/grub/grub.cfg; then
  echo '** FAIL **: No superusers set in grub.cfg'
  echo '** FAIL **'
  exit 1
fi

# Check if 'password_pbkdf2' line exists in /boot/grub/grub.cfg
if ! grep -q '^password_pbkdf2' /boot/grub/grub.cfg; then
  echo '** FAIL **: No password_pbkdf2 set in grub.cfg'
  echo '** FAIL **'
  exit 1
fi

echo '** PASS **'
}

a__1_4_2() {
file="/boot/grub/grub.cfg"

perm=$(stat -Lc '%a' "$file")
uid=$(stat -Lc '%u' "$file")
gid=$(stat -Lc '%g' "$file")

perm_num=$((8#$perm))

if [[ "$uid" -eq 0 && "$gid" -eq 0 && $perm_num -le 0600 ]]; then
    echo "** PASS **"
    exit 0
fi

echo "** FAIL **"
exit 1
}

a__1_5_1() {
a_output=()
    a_output2=()
    a_parlist=(kernel.randomize_va_space=2)
    l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
        else
            a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration and should have a value of: \"$l_value_out\"")
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out["$l_kpar"]="$l_file"
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out["$l_kpar"]="$l_ufwscf"
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"

                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
                else
                    a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_value_out\"")
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(" - \"$l_parameter_name\" is not set in an included file" "** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **")
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"
        f_kernel_parameter_chk
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__1_5_2() {
#!/bin/bash

a_output=()
a_output2=()
a_parlist=("kernel.yama.ptrace_scope=(1|2|3)")

l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

f_kernel_parameter_chk() {
    # Check running configuration
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"
    
    if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
        a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
        a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration"
                    " and should have a value of: \"$l_value_out\"")
    fi

    # Check durable setting (files)
    unset A_out
    declare -A A_out

    while read -r l_out; do
        if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
            else
                l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                [ "$l_kpar" = "$l_parameter_name" ] && A_out["$l_kpar"]="$l_file"
            fi
        fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

    # Account for systems with UFW (not covered by systemd-sysctl --cat-config)
    if [ -n "$l_ufwscf" ]; then
        l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
        l_kpar="${l_kpar//\//.}"
        [ "$l_kpar" = "$l_parameter_name" ] && A_out["$l_kpar"]="$l_ufwscf"
    fi

    # Assess output from files and generate output
    if (( ${#A_out[@]} > 0 )); then
        while IFS="=" read -r l_fkpname l_file_parameter_value; do
            l_fkpname="${l_fkpname// /}"
            l_file_parameter_value="${l_file_parameter_value// /}"
            
            if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
            else
                a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\""
                            " and should have a value of: \"$l_value_out\"")
            fi
        done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
        a_output2+=(" - \"$l_parameter_name\" is not set in an included file"
                    " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **")
    fi
}

# Process each kernel parameter
while IFS="=" read -r l_parameter_name l_parameter_value; do
    l_parameter_name="${l_parameter_name// /}"
    l_parameter_value="${l_parameter_value// /}"

    l_value_out="${l_parameter_value//-/ through }"
    l_value_out="${l_value_out//|/ or }"
    l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

    f_kernel_parameter_chk
done < <(printf '%s\n' "${a_parlist[@]}")

# Output results
if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
        printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
fi
}

a__1_5_3() {
#!/usr/bin/env bash

a_output=()
a_output2=()

# --- 1. Check hard core dump limit in limits.conf ---
if grep -Psq -- '^\\s*\\*\\s+hard\\s+core\\s+0\\b' /etc/security/limits.conf /etc/security/limits.d/* 2>/dev/null; then
    a_output+=(" - Hard limit for core dumps is correctly set to 0")
else
    a_output2+=(" - Hard limit for core dumps is NOT set to 0 in limits.conf or limits.d")
fi

# --- 2. Check fs.suid_dumpable kernel parameter ---
param_name="fs.suid_dumpable"
expected_val="0"
running_val=$(sysctl -n "$param_name" 2>/dev/null)

if [ "$running_val" = "$expected_val" ]; then
    a_output+=(" - $param_name is correctly set to $expected_val in running configuration")
else
    a_output2+=(" - $param_name is set to $running_val (expected: $expected_val) in running configuration")
fi

# Check if it's configured persistently
config_file_match=$(grep -Phs "^\s*${param_name}\s*=\s*${expected_val}\b" /etc/sysctl.conf /etc/sysctl.d/*.conf 2>/dev/null)

if [ -n "$config_file_match" ]; then
    a_output+=(" - $param_name is correctly set to $expected_val in sysctl configuration")
else
    a_output2+=(" - $param_name is NOT correctly set to $expected_val in any sysctl configuration file")
fi

# --- 3. Check if systemd-coredump is installed ---
if systemctl list-unit-files | grep -q '^systemd-coredump'; then
    a_output2+=(" - systemd-coredump is installed. This may override core dump restrictions unless properly configured")
else
    a_output+=(" - systemd-coredump is not installed")
fi

# --- Final Output ---
if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" "- Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__1_5_4() {
output=$(dpkg-query -s prelink &>/dev/null && echo "prelink is installed")

if [[ -n "$output" ]]; then
    echo "** FAIL ** Prelink is installed"
    return 0
else
    echo "** PASS ** prelink is not installed"
    return 1
fi
}

a__1_5_5() {
# Check if apport is enabled in /etc/default/apport
if dpkg-query -s apport &> /dev/null && grep -Psi -- '^\\h*enabled\\h*=\\h*[^0]\\b' /etc/default/apport; then
    echo "** FAIL ** Apport is enabled in /etc/default/apport"
    exit 1
fi

# Check if apport service is active
if systemctl is-active apport.service | grep '^active' &> /dev/null; then
    echo "** FAIL ** Apport service is active"
    exit 1
fi

echo "** PASS ** Apport is disabled and inactive"
}

a__1_6_1() {
# Extract OS ID for dynamic matching
os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')

# Check for dynamic placeholders or OS ID in /etc/motd
if grep -E -i '(\\\\v|\\\\r|\\\\m|\\\\s|'\"$os_id\"')' /etc/motd; then
    echo "** FAIL ** /etc/motd contains dynamic placeholders or OS identifier"
    grep -E -i '(\\\\v|\\\\r|\\\\m|\\\\s|'\"$os_id\"')' /etc/motd
    exit 1
fi

echo "** PASS ** /etc/motd does not contain dynamic system information"
}

a__1_6_2() {
# Fail if this command returns any output
if grep -E -i "(\\\\v|\\\\r|\\\\m|\\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\\"//g'))" /etc/issue | grep -q .; then
    echo "** FAIL ** /etc/issue contains dynamic system information or OS identifier"
    grep -E -i "(\\\\v|\\\\r|\\\\m|\\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\\"//g'))" /etc/issue
    exit 1
fi

echo "** PASS ** /etc/issue contains no dynamic information"
}

a__1_6_3() {
# Run grep and fail if any output is returned
cmd_output=$(grep -E -i "(\\\\v|\\\\r|\\\\m|\\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\\"//g'))" /etc/issue.net)

if [ -n "$cmd_output" ]; then
    echo "** FAIL ** /etc/issue.net contains disallowed dynamic system information"
    echo "$cmd_output"
    exit 1
fi

echo "** PASS ** /etc/issue.net contains no dynamic system information"
}

a__1_6_4() {
# If /etc/motd doesn't exist, that's acceptable (PASS)
[ ! -e /etc/motd ] && {
    echo "** PASS ** /etc/motd does not exist"
    exit 0
}

# Get permission, UID, and GID info
output=$(stat -Lc 'Access: (%#a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/motd 2>/dev/null)

# Extract numeric permission, UID, and GID
perm=$(stat -Lc '%a' /etc/motd)
uid=$(stat -Lc '%u' /etc/motd)
gid=$(stat -Lc '%g' /etc/motd)

# Check if permissions are 644 or more restrictive
if [ "$perm" -gt 644 ]; then
    echo "** FAIL ** /etc/motd has permissions that are too permissive: $perm"
    echo "$output"
    exit 1
fi

# Check ownership
if [ "$uid" -ne 0 ] || [ "$gid" -ne 0 ]; then
    echo "** FAIL ** /etc/motd is not owned by root:root"
    echo "$output"
    exit 1
fi

# All checks passed
echo "** PASS ** /etc/motd has correct permissions and ownership"
echo "$output"
}

a__1_6_5() {
# If /etc/issue doesn't exist, that's acceptable (PASS)
[ ! -e /etc/issue ] && {
    echo "** PASS ** /etc/issue does not exist"
    exit 0
}

# Get permission, UID, and GID info
output=$(stat -Lc 'Access: (%#a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/issue 2>/dev/null)

# Extract numeric permission, UID, and GID
perm=$(stat -Lc '%a' /etc/issue)
uid=$(stat -Lc '%u' /etc/issue)
gid=$(stat -Lc '%g' /etc/issue)

# Check if permissions are 644 or more restrictive
if [ "$perm" -gt 644 ]; then
    echo "** FAIL ** /etc/issue has permissions that are too permissive: $perm"
    echo "$output"
    exit 1
fi

# Check ownership
if [ "$uid" -ne 0 ] || [ "$gid" -ne 0 ]; then
    echo "** FAIL ** /etc/issue is not owned by root:root"
    echo "$output"
    exit 1
fi

# All checks passed
echo "** PASS ** /etc/issue has correct permissions and ownership"
echo "$output"
}

a__1_6_6() {
# If /etc/issue.net doesn't exist, that's acceptable (PASS)
[ ! -e /etc/issue.net ] && {
    echo "** PASS ** /etc/issue.net does not exist"
    exit 0
}

# Get permission, UID, and GID info
output=$(stat -Lc 'Access: (%#a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/issue.net 2>/dev/null)

# Extract numeric permission, UID, and GID
perm=$(stat -Lc '%a' /etc/issue.net)
uid=$(stat -Lc '%u' /etc/issue.net)
gid=$(stat -Lc '%g' /etc/issue.net)

# Check if permissions are 644 or more restrictive
if [ "$perm" -gt 644 ]; then
    echo "** FAIL ** /etc/issue.net has permissions that are too permissive: $perm"
    echo "$output"
    exit 1
fi

# Check ownership
if [ "$uid" -ne 0 ] || [ "$gid" -ne 0 ]; then
    echo "** FAIL ** /etc/issue.net is not owned by root:root"
    echo "$output"
    exit 1
fi

# All checks passed
echo "** PASS ** /etc/issue.net has correct permissions and ownership"
echo "$output"
}

a__1_7_1() {
# Run dpkg-query for gdm3
output=$(dpkg-query -W -f='${binary:Package}\\t${Status}\\t${db:Status-Status}\\n' gdm3 2>&1)

# Expected output when not installed
expected_output="gdm3\tunknown ok not-installed\tnot-installed"

# Compare output
if echo "$output" | grep -q "^$expected_output\$"; then
    echo "** PASS ** gdm3 is not installed"
else
    echo "** FAIL ** gdm3 appears to be installed or partially installed"
    echo "$output"
    exit 1
fi
}

a__1_7_10() {
# Check for [xdmcp] blocks containing Enable=true in relevant config files
found=$(grep -Psil -- '^\\h*\\[xdmcp\\]' /etc/{gdm3,gdm}/{custom,daemon}.conf 2>/dev/null | while IFS= read -r l_file; do
    awk '
        /\[xdmcp\]/ { in_xdmcp = 1; next }
        /^\[/ && !/\\[xdmcp\\]/ { in_xdmcp = 0 }
        in_xdmcp && /^\\s*Enable\\s*=\\s*true/ {
            printf "The file: \\"%s\\" includes: \\"%s\\" in the \\"[xdmcp]\\" block\\n", FILENAME, $0
        }
    ' "$l_file"
done)

if [ -n "$found" ]; then
    echo "** FAIL ** XDMCP is enabled in one or more configuration files"
    echo "$found"
    exit 1
else
    echo "** PASS ** XDMCP is not enabled in any GDM configuration file"
fi
}

a__1_7_2() {
# Check if banner message is enabled
enabled=$(gsettings get org.gnome.login-screen banner-message-enable 2>/dev/null)

if [ "$enabled" != "true" ]; then
    echo "** FAIL ** GNOME login banner is not enabled"
    echo "banner-message-enable = $enabled"
    exit 1
fi

# Check if banner message text is set and not empty
banner_text=$(gsettings get org.gnome.login-screen banner-message-text 2>/dev/null | sed -e "s/^'//" -e "s/'$//")

if [ -z "$banner_text" ]; then
    echo "** FAIL ** GNOME login banner message text is empty"
    exit 1
fi

echo "** PASS ** GNOME login banner is enabled and has message: $banner_text"
}

a__1_7_3() {
# Check if disable-user-list option is enabled
enabled=$(gsettings get org.gnome.login-screen disable-user-list 2>/dev/null)

if [ "$enabled" != "true" ]; then
    echo "** FAIL ** GDM disable-user-list option is not enabled"
    echo "disable-user-list = $enabled"
    exit 1
else
    echo "** PASS ** GDM disable-user-list option is enabled"
    echo "disable-user-list = $enabled"
fi
}

a__1_7_4() {
# Get lock-delay (in seconds)
lock_delay_raw=$(gsettings get org.gnome.desktop.screensaver lock-delay 2>/dev/null)
idle_delay_raw=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)

# Remove 'uint32' and cast to numbers
lock_delay=$(echo "$lock_delay_raw" | awk '{print $2}')
idle_delay=$(echo "$idle_delay_raw" | awk '{print $2}')

# Validate idle-delay: must be non-zero and ≤ 900
if [ -z "$idle_delay" ] || [ "$idle_delay" -eq 0 ] || [ "$idle_delay" -gt 900 ]; then
    echo "** FAIL ** idle-delay is not set properly (current: $idle_delay_raw)"
    exit 1
fi

# Validate lock-delay: must be ≤ 5
if [ -z "$lock_delay" ] || [ "$lock_delay" -gt 5 ]; then
    echo "** FAIL ** lock-delay is not set properly (current: $lock_delay_raw)"
    exit 1
fi

# All good
echo "** PASS ** Screen lock activates after idle: idle-delay = $idle_delay seconds, lock-delay = $lock_delay seconds"
}

a__1_7_5() {
a_output=()
    a_output2=()

    # Function to check if a dconf setting is locked
    f_check_setting() {
        grep -Psrilq -- "^\h*$2\b" /etc/dconf/db/local.d/locks/* &>/dev/null && \
            echo "- \"$3\" is locked" || \
            echo "- \"$3\" is not locked or not set"
    }

    # Declare associative array of settings
    declare -A settings=(
        ["idle-delay"]="/org/gnome/desktop/session/idle-delay"
        ["lock-delay"]="/org/gnome/desktop/screensaver/lock-delay"
    )

    # Loop through each setting and evaluate
    for setting in "${!settings[@]}"; do
        result=$(f_check_setting "$setting" "${settings[$setting]}" "$setting")
        if [[ "$result" == *"is not locked"* || "$result" == *"not set to false"* ]]; then
            a_output2+=("$result")
        else
            a_output+=("$result")
        fi
    done

    # Output results
    printf '%s\n' "" "- Audit Result:"
    if [ "${#a_output2[@]}" -gt 0 ]; then
        printf '%s\n' " ** FAIL **" " - Reason(s) for audit failure:"
        printf '%s\n' "${a_output2[@]}"
        if [ "${#a_output[@]}" -gt 0 ]; then
            printf '%s\n' "" "- Correctly set:"
            printf '%s\n' "${a_output[@]}"
        fi
    else
        printf '%s\n' " ** PASS **"
        printf '%s\n' "${a_output[@]}"
    fi
}

a__1_7_6() {
# Get current settings
automount=$(gsettings get org.gnome.desktop.media-handling automount 2>/dev/null)
automount_open=$(gsettings get org.gnome.desktop.media-handling automount-open 2>/dev/null)

# Check automount
if [ "$automount" != "false" ]; then
    echo "** FAIL ** automount is not disabled (current: $automount)"
    exit 1
fi

# Check automount-open
if [ "$automount_open" != "false" ]; then
    echo "** FAIL ** automount-open is not disabled (current: $automount_open)"
    exit 1
fi

# All good
echo "** PASS ** Automatic mounting and opening of removable media are disabled"
}

a__1_7_7() {
a_output=()
    a_output2=()

    # Function to check if a dconf setting is locked and set to false
    check_setting() {
        grep -Psrilq "^\h*$1\s*=\s*false\b" /etc/dconf/db/local.d/locks/* 2>/dev/null && \
            echo "- \"$3\" is locked and set to false" || \
            echo "- \"$3\" is not locked or not set to false"
    }

    # Define settings to check
    declare -A settings=(
        ["automount"]="org/gnome/desktop/media-handling"
        ["automount-open"]="org/gnome/desktop/media-handling"
    )

    # Run checks for each setting
    for setting in "${!settings[@]}"; do
        result=$(check_setting "$setting" "${settings[$setting]}" "$setting")
        if [[ "$result" == *"is not locked"* || "$result" == *"not set to false"* ]]; then
            a_output2+=("$result")
        else
            a_output+=("$result")
        fi
    done

    # Display audit result
    echo ""
    echo "- Audit Result:"
    if [ "${#a_output2[@]}" -gt 0 ]; then
        echo " ** FAIL **"
        echo " - Reason(s) for audit failure:"
        printf '%s\n' "${a_output2[@]}"
        if [ "${#a_output[@]}" -gt 0 ]; then
            echo ""
            echo "- Correctly set:"
            printf '%s\n' "${a_output[@]}"
        fi
    else
        echo " ** PASS **"
        printf '%s\n' "${a_output[@]}"
    fi
}

a__1_7_8() {
# Get current settings
autorun=$(gsettings get org.gnome.desktop.media-handling autorun-never 2>/dev/null)

# Check autorun
if [ "$autorun" != "true" ]; then
    echo "** FAIL ** autorun-never is not enabled (current: $autorun)"
    exit 1
fi

# All good
echo "** PASS ** autorun-never is enabled (current: $autorun)"
}

a__1_7_9() {
# Function to check and report if a specific setting is locked and set to true
    check_setting() {
        local key="$1"
        local path="$2"
        local label="$3"

        if grep -Psrilq "^\h*${key}\h*=\h*true\b" /etc/dconf/db/local.d/locks/* 2>/dev/null; then
            echo "- \"$label\" is locked and set to true"
        else
            echo "- \"$label\" is not locked or not set to true"
        fi
    }

    # Declare associative array of settings
    declare -A settings=(
        ["autorun-never"]="org/gnome/desktop/media-handling"
    )

    l_output=()
    l_output2=()

    # Run check on each setting
    for setting in "${!settings[@]}"; do
        result=$(check_setting "$setting" "${settings[$setting]}" "$setting")
        l_output+=("$result")
        if [[ "$result" == *"is not locked"* || "$result" == *"not set to true"* ]]; then
            l_output2+=("$result")
        fi
    done

    # Report results
    echo "- Audit Result:"
    if [ "${#l_output2[@]}" -ne 0 ]; then
        echo " ** FAIL **"
        echo "- Reason(s) for audit failure:"
        printf '%s\n' "${l_output2[@]}"
    else
        echo " ** PASS **"
        printf '%s\n' "${l_output[@]}"
    fi
}

a__2_1_1() {
# Check if autofs package is installed
    if dpkg-query -s autofs &>/dev/null; then
        echo "- autofs is installed"

        # Check if autofs.service is enabled
        if systemctl is-enabled autofs.service 2>/dev/null | grep -q '^enabled'; then
            echo "** FAIL ** autofs.service is enabled"
            exit 1
        fi

        # Check if autofs.service is active
        if systemctl is-active autofs.service 2>/dev/null | grep -q '^active'; then
            echo "** FAIL ** autofs.service is active"
            exit 1
        fi

        echo "** PASS ** autofs is installed but the service is neither enabled nor active"
    else
        echo "** PASS ** autofs is not installed"
    fi
}

a__2_1_10() {
# Check if ypserv package is installed
if dpkg-query -s ypserv &>/dev/null; then
    echo "- ypserv is installed"

    # Check if ypserv.service is enabled
    if systemctl is-enabled ypserv.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** ypserv.service is enabled"
        exit 1
    fi

    # Check if ypserv.service is active
    if systemctl is-active ypserv.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** ypserv.service is active"
        exit 1
    fi

    echo "** PASS ** ypserv is installed but service is neither enabled nor active"
else
    echo "** PASS ** ypserv is not installed"
fi
}

a__2_1_11() {
# Check if cups package is installed
if dpkg-query -s cups &>/dev/null; then
    echo "- cups is installed"

    # Check if cups.service or cups.socket are enabled
    if systemctl is-enabled cups.service cups.socket 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** cups.service or cups.socket is enabled"
        exit 1
    fi

    # Check if cups.service or cups.socket are active
    if systemctl is-active cups.service cups.socket 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** cups.service or cups.socket is active"
        exit 1
    fi

    echo "** PASS ** cups is installed but services are neither enabled nor active"
else
    echo "** PASS ** cups is not installed"
fi
}

a__2_1_12() {
#!/usr/bin/env bash

# Check if rpcbind package is installed
if dpkg-query -s rpcbind &>/dev/null; then
    echo "- rpcbind is installed"

    # Check if rpcbind.service or rpcbind.socket are enabled
    if systemctl is-enabled rpcbind.service rpcbind.socket 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** rpcbind.service or rpcbind.socket is enabled"
        exit 1
    fi

    # Check if rpcbind.service or rpcbind.socket are active
    if systemctl is-active rpcbind.service rpcbind.socket 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** rpcbind.service or rpcbind.socket is active"
        exit 1
    fi

    echo "** PASS ** rpcbind is installed but services are neither enabled nor active"
else
    echo "** PASS ** rpcbind is not installed"
fi
}

a__2_1_13() {
if dpkg-query -s rsync &>/dev/null; then
    echo "- rsync is installed"

    if systemctl is-enabled rsync.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** rsync.service is enabled"
        exit 1
    fi

    if systemctl is-active rsync.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** rsync.service is active"
        exit 1
    fi

    echo "** PASS ** rsync is installed but rsync.service is neither enabled nor active"
else
    echo "** PASS ** rsync is not installed"
fi
}

a__2_1_4() {
# Check if bind9 package is installed
if dpkg-query -s bind9 &>/dev/null; then
    echo "- bind9 is installed"

    # Check if bind9 service is enabled
    if systemctl is-enabled bind9.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** bind9.service is enabled"
        exit 1
    fi

    # Check if bind9 service is active
    if systemctl is-active bind9.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** bind9.service is active"
        exit 1
    fi

    echo "** PASS ** bind9 is installed but bind9.service is neither enabled nor active"
else
    echo "** PASS ** bind9 is not installed"
fi
}

a__2_1_15() {
#!/usr/bin/env bash

if dpkg-query -s snmpd &>/dev/null; then
    echo "- snmpd is installed"

    if systemctl is-enabled snmpd.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** snmpd.service is enabled"
        exit 1
    fi

    if systemctl is-active snmpd.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** snmpd.service is active"
        exit 1
    fi

    echo "** PASS ** snmpd is installed but snmpd.service is neither enabled nor active"
else
    echo "** PASS ** snmpd is not installed"
fi
}

a__2_1_16() {
if dpkg-query -s tftpd-hpa &>/dev/null; then
    echo "- tftpd-hpa is installed"

    if systemctl is-enabled tftpd-hpa.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** tftpd-hpa.service is enabled"
        exit 1
    fi

    if systemctl is-active tftpd-hpa.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** tftpd-hpa.service is active"
        exit 1
    fi

    echo "** PASS ** tftpd-hpa is installed but service is neither enabled nor active"
else
    echo "** PASS ** tftpd-hpa is not installed"
fi
}

a__2_1_17() {
#!/usr/bin/env bash

if dpkg-query -s squid &>/dev/null; then
    echo "- squid is installed"

    if systemctl is-enabled squid.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** squid.service is enabled"
        exit 1
    fi

    echo "** PASS ** squid is installed but squid.service is not enabled"
else
    echo "** PASS ** squid is not installed"
fi
}

a__2_1_18() {
#!/usr/bin/env bash

# Function to check if package is installed
check_package_installed() {
    local pkg=$1
    if dpkg-query -s "$pkg" &>/dev/null; then
        echo "$pkg is installed"
        return 0
    else
        return 1
    fi
}

# Function to check if any services are enabled
check_services_enabled() {
    local services=("$@")
    if systemctl is-enabled "${services[@]}" 2>/dev/null | grep -q 'enabled'; then
        echo "** FAIL ** One or more services are enabled: ${services[*]}"
        return 1
    fi
    return 0
}

# Function to check if any services are active
check_services_active() {
    local services=("$@")
    if systemctl is-active "${services[@]}" 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** One or more services are active: ${services[*]}"
        return 1
    fi
    return 0
}

main() {
    local fail=0

    # Check apache2 package and services
    if check_package_installed apache2; then
        # Package installed, check services
        if ! check_services_enabled apache2.socket apache2.service nginx.service; then
            fail=1
        fi
        if ! check_services_active apache2.socket apache2.service nginx.service; then
            fail=1
        fi
    fi

    # Check nginx package (again, services checked above if apache2 installed)
    if check_package_installed nginx; then
        # Package installed, check services
        if ! check_services_enabled apache2.socket apache2.service nginx.service; then
            fail=1
        fi
        if ! check_services_active apache2.socket apache2.service nginx.service; then
            fail=1
        fi
    fi

    # If neither apache2 nor nginx installed, nothing to check - pass
    if ! check_package_installed apache2 && ! check_package_installed nginx; then
        echo "** PASS ** apache2 and nginx are not installed"
        exit 0
    fi

    if [ $fail -eq 0 ]; then
        echo "** PASS ** apache2 and nginx packages are installed, but services are neither enabled nor active"
        exit 0
    else
        exit 1
    fi
}

main
}

a__2_1_19() {
#!/usr/bin/env bash

# Audit for xinetd package and service

# Check if xinetd is installed
if dpkg-query -s xinetd &>/dev/null; then
    echo "- xinetd is installed"

    # Check if the service is enabled
    if systemctl is-enabled xinetd.service 2>/dev/null | grep -q 'enabled'; then
        echo "** FAIL ** xinetd.service is enabled"
        exit 1
    fi

    # Check if the service is active
    if systemctl is-active xinetd.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** xinetd.service is active"
        exit 1
    fi

    echo "** PASS ** xinetd is installed but service is neither enabled nor active"
    exit 0
else
    echo "** PASS ** xinetd is not installed"
    exit 0
fi
}

a__2_1_2() {
if dpkg-query -s avahi-daemon &>/dev/null; then
        echo "- avahi-daemon is installed"

        if systemctl is-enabled avahi-daemon.socket avahi-daemon.service 2>/dev/null | grep -q '^enabled'; then
            echo "** FAIL ** avahi-daemon.socket and avahi-daemon.service is enabled"
            exit 1
        fi

        if systemctl is-active avahi-daemon.socket avahi-daemon.service 2>/dev/null | grep -q '^active'; then
            echo "** FAIL ** avahi-daemon.socket and avahi-daemon.service is active"
            exit 1
        fi

        echo "** PASS ** avahi-daemon is installed but service is neither enabled not active"
    else
        echo "** PASS ** avahi-daemon not installed"
    fi
}

a__2_1_20() {
# Audit: Check if X Windows Server (xserver-common) is installed

if dpkg-query -s xserver-common &>/dev/null; then
    echo "** FAIL ** xserver-common is installed"
    exit 1
else
    echo "** PASS ** xserver-common is not installed"
    exit 0
fi
}

a__2_1_21() {
# Audit: Verify MTA is not listening on any non-loopback address

a_output=()
a_output2=()
a_port_list=("25" "465" "587")

# Check if these ports are listening on non-loopback interfaces
for l_port_number in "${a_port_list[@]}"; do
    if ss -plntu | grep -P -- ":$l_port_number\b" | grep -Pvq '\s+(127\.0\.0\.1|\[?::1\]?):'"$l_port_number"'\b'; then
        a_output2+=("- Port \"$l_port_number\" is listening on a non-loopback network interface")
    else
        a_output+=("- Port \"$l_port_number\" is not listening on a non-loopback network interface")
    fi
done

# Detect MTA and check configured interfaces
l_interfaces=""

if command -v postconf &>/dev/null; then
    l_interfaces="$(postconf -n inet_interfaces | awk '{print $2}')"
elif command -v exim &>/dev/null; then
    l_interfaces="$(exim -bP local_interfaces | awk '{print $2}')"
elif command -v sendmail &>/dev/null; then
    l_interfaces="$(grep -i "O DaemonPortOptions=" /etc/mail/sendmail.cf | grep -oP '(?<=Addr=)[^, ]+')"
fi

# Evaluate MTA binding
if [ -n "$l_interfaces" ]; then
    if grep -Pqi '\ball\b' <<< "$l_interfaces"; then
        a_output2+=("- MTA is bound to all network interfaces")
    elif ! grep -Pqi '(inet_interfaces\s*=\s*)?(127\.0\.0\.1|::1|loopback-only)' <<< "$l_interfaces"; then
        a_output2+=("- MTA is bound to a network interface: \"$l_interfaces\"")
    else
        a_output+=("- MTA is not bound to a non-loopback network interface: \"$l_interfaces\"")
    fi
else
    a_output+=("- MTA not detected or in use")
fi

# Display audit results
echo ""
echo "- Audit Result:"
if [ "${#a_output2[@]}" -eq 0 ]; then
    echo " ** PASS **"
    printf '%s\n' "${a_output[@]}"
else
    echo " ** FAIL **"
    echo " * Reasons for audit failure *"
    printf '%s\n' "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
        echo ""
        echo "- Correctly set:"
        printf '%s\n' "${a_output[@]}"
    fi
fi
}

a__2_1_3() {
# Check if isc-dhcp-server package is installed
if dpkg-query -s isc-dhcp-server &>/dev/null; then
    echo "- isc-dhcp-server is installed"

    # Check if either service is enabled
    if systemctl is-enabled isc-dhcp-server.service isc-dhcp-server6.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** isc-dhcp-server.service or isc-dhcp-server6.service is enabled"
        exit 1
    fi

    # Check if either service is active
    if systemctl is-active isc-dhcp-server.service isc-dhcp-server6.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** isc-dhcp-server.service or isc-dhcp-server6.service is active"
        exit 1
    fi

    echo "** PASS ** isc-dhcp-server is installed but services are neither enabled nor active"
else
    echo "** PASS ** isc-dhcp-server is not installed"
fi
}

a__2_1_5() {
#!/usr/bin/env bash

# Check if dnsmasq package is installed
if dpkg-query -s dnsmasq &>/dev/null; then
    echo "- dnsmasq is installed"

    # Check if dnsmasq.service is enabled
    if systemctl is-enabled dnsmasq.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** dnsmasq.service is enabled"
        exit 1
    fi

    # Check if dnsmasq.service is active
    if systemctl is-active dnsmasq.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** dnsmasq.service is active"
        exit 1
    fi

    echo "** PASS ** dnsmasq is installed but service is neither enabled nor active"
else
    echo "** PASS ** dnsmasq is not installed"
fi
}

a__2_1_6() {
# Check if vsftpd package is installed
if dpkg-query -s vsftpd &>/dev/null; then
    echo "- vsftpd is installed"

    # Check if vsftpd.service is enabled
    if systemctl is-enabled vsftpd.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** vsftpd.service is enabled"
        exit 1
    fi

    # Check if vsftpd.service is active
    if systemctl is-active vsftpd.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** vsftpd.service is active"
        exit 1
    fi

    echo "** PASS ** vsftpd is installed but service is neither enabled nor active"
else
    echo "** PASS ** vsftpd is not installed"
fi
}

a__2_1_7() {
#!/usr/bin/env bash

# Check if slapd package is installed
if dpkg-query -s slapd &>/dev/null; then
    echo "- slapd is installed"

    # Check if slapd.service is enabled
    if systemctl is-enabled slapd.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** slapd.service is enabled"
        exit 1
    fi

    # Check if slapd.service is active
    if systemctl is-active slapd.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** slapd.service is active"
        exit 1
    fi

    echo "** PASS ** slapd is installed but service is neither enabled nor active"
else
    echo "** PASS ** slapd is not installed"
fi
}

a__2_1_9() {
#!/usr/bin/env bash

# Check if nfs-kernel-server is installed
if dpkg-query -s nfs-kernel-server &>/dev/null; then
    echo "- nfs-kernel-server is installed"

    # Check if nfs-server.service is enabled
    if systemctl is-enabled nfs-server.service 2>/dev/null | grep -q '^enabled'; then
        echo "** FAIL ** nfs-server.service is enabled"
        exit 1
    fi

    # Check if nfs-server.service is active
    if systemctl is-active nfs-server.service 2>/dev/null | grep -q '^active'; then
        echo "** FAIL ** nfs-server.service is active"
        exit 1
    fi

    echo "** PASS ** nfs-kernel-server is installed but nfs-server.service is neither enabled nor active"
else
    echo "** PASS ** nfs-kernel-server is not installed"
fi
}

a__2_2_1() {
# Audit: Verify that the nis package is not installed

if dpkg-query -s nis &>/dev/null; then
    echo "** FAIL ** nis is installed"
    exit 1
else
    echo "** PASS ** nis is not installed"
    exit 0
fi
}

a__2_2_2() {
if dpkg-query -s rsh-client &>/dev/null; then
    echo "** FAIL ** rsh-client is installed"
    exit 1
else
    echo "** PASS ** rsh-client is not installed"
    exit 0
fi
}

a__2_2_3() {
if dpkg-query -s talk &>/dev/null; then
    echo "** FAIL ** talk is installed"
    exit 1
else
    echo "** PASS ** talk is not installed"
    exit 0
fi
}

a__2_2_4() {
if dpkg-query -l | grep -E 'telnet|inetutils-telnet' &>/dev/null; then
    echo "** FAIL ** telnet client is installed"
    exit 1
else
    echo "** PASS ** telnet client is not installed"
    exit 0
fi
}

a__2_2_5() {
if dpkg-query -s ldap-utls &>/dev/null; then
    echo "** FAIL ** ldap-utls is installed"
    exit 1
else
    echo "** PASS ** ldap-utls is not installed"
    exit 0
fi
}

a__2_2_6() {
if dpkg-query -l | grep -E 'ftp|tnftp' &>/dev/null; then
    echo "** FAIL ** ftp client is installed"
    exit 1
else
    echo "** PASS ** ftp client is not installed"
    exit 0
fi
}

a__2_3_1_1() {
l_output=""
    l_output2=""

    service_status_check() {
        local service="$1"
        local status_output=""

        if systemctl is-enabled "$service" 2>/dev/null | grep -q 'enabled'; then
            status_output+="\n - Daemon: \"$service\" is enabled on the system"
        fi

        if systemctl is-active "$service" 2>/dev/null | grep -q '^active'; then
            status_output+="\n - Daemon: \"$service\" is active on the system"
        fi

        echo -e "$status_output"
    }

    # Check systemd-timesyncd
    service_name="systemd-timesyncd.service"
    timesyncd_status=$(service_status_check "$service_name")

    if [ -n "$timesyncd_status" ]; then
        l_timesyncd="y"
        l_out_tsd="$timesyncd_status"
    else
        l_timesyncd="n"
        l_out_tsd="\n - Daemon: \"$service_name\" is not enabled and not active on the system"
    fi

    # Check chrony
    service_name="chrony.service"
    chrony_status=$(service_status_check "$service_name")

    if [ -n "$chrony_status" ]; then
        l_chrony="y"
        l_out_chrony="$chrony_status"
    else
        l_chrony="n"
        l_out_chrony="\n - Daemon: \"$service_name\" is not enabled and not active on the system"
    fi

    # Determine overall audit result
    l_status="$l_timesyncd$l_chrony"

    case "$l_status" in
        yy)
            l_output2=" - More than one time sync daemon is in use on the system$l_out_tsd$l_out_chrony"
            ;;
        nn)
            l_output2=" - No time sync daemon is in use on the system$l_out_tsd$l_out_chrony"
            ;;
        yn|ny)
            l_output=" - Only one time sync daemon is in use on the system$l_out_tsd$l_out_chrony"
            ;;
        *)
            l_output2=" - Unable to determine time sync daemon(s) status"
            ;;
    esac

    # Output final result
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure *:\n$l_output2\n"
    fi
}

a__2_3_2_1() {
a_output=()
    a_output2=()
    a_parlist=("NTP=[^#\n\r]+" "FallbackNTP=[^#\n\r]+")
    l_systemd_config_file="/etc/systemd/timesyncd.conf"  # Main systemd configuration file

    f_config_file_parameter_chk() {
        unset A_out
        declare -A A_out  # Associative array to hold parameter -> file mappings

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    # Check if current parameter matches expected parameter name
                    grep -Piq -- "^\h*$l_systemd_parameter_name\b" <<< "$l_systemd_parameter" &&
                        A_out+=(["$l_systemd_parameter"]="$l_file")
                fi
            fi
        done < <("$l_systemdanalyze" cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

        if (( ${#A_out[@]} > 0 )); then
            # Loop over found config parameters and values
            while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do
                l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"
                l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"

                if grep -Piq "\b$l_systemd_parameter_value\b" <<< "$l_systemd_file_parameter_value"; then
                    a_output+=(" - \"$l_systemd_parameter_name\" is correctly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
                else
                    a_output2+=(" - \"$l_systemd_parameter_name\" is incorrectly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value matching: \"$l_value_out\"")
                fi
            done < <(grep -Pio -- "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(" - \"$l_systemd_parameter_name\" is not set in an included file *** Note: \"$l_systemd_parameter_name\" may be set in a file that's ignored by load procedure ***")
        fi
    }

    l_systemdanalyze="$(readlink -f /bin/systemd-analyze)"

    while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do
        # Clean up spaces in names and values
        l_systemd_parameter_name="${l_systemd_parameter_name// /}"
        l_systemd_parameter_value="${l_systemd_parameter_value// /}"

        # Prepare human-readable expected value description
        l_value_out="${l_systemd_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        f_config_file_parameter_chk
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        if [ "${#a_output[@]}" -gt 0 ]; then
            printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
        fi
    fi
}

a__2_3_2_2() {
service="systemd-timesyncd.service"
    enabled=$(systemctl is-enabled "$service" 2>/dev/null)
    active=$(systemctl is-active "$service" 2>/dev/null)

    echo "Checking $service..."

    if [[ "$enabled" == "enabled" ]]; then
        echo " - Service is enabled."
    else
        echo " - Service is NOT enabled."
    fi

    if [[ "$active" == "active" ]]; then
        echo " - Service is active."
    else
        echo " - Service is NOT active."
    fi

    if [[ "$enabled" == "enabled" && "$active" == "active" ]]; then
        echo -e "\nAudit Result:\n ** PASS **\n - systemd-timesyncd.service is enabled and active."
    else
        echo -e "\nAudit Result:\n ** FAIL **\n - systemd-timesyncd.service is not properly enabled and/or active."
    fi
}

a__2_3_3_1() {
a_output=()
    a_output2=()
    a_config_files=("/etc/chrony/chrony.conf")

    # Parameters to search
    l_include='(confdir|sourcedir)'   # Include directives
    l_parameter_name='(server|pool)'  # Allowed NTP config parameters
    l_parameter_value='.+'

    # Discover additional config files from confdir/sourcedir
    while IFS= read -r l_conf_loc; do
        l_dir=""
        l_ext=""

        if [ -d "$l_conf_loc" ]; then
            l_dir="$l_conf_loc"
            l_ext="*"
        elif grep -Psq '/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
            l_dir="$(dirname "$l_conf_loc")"
            l_ext="$(basename "$l_conf_loc")"
        fi

        if [[ -n "$l_dir" && -n "$l_ext" ]]; then
            while IFS= read -r -d $'\0' l_file_name; do
                [ -f "$(readlink -f "$l_file_name")" ] &&
                    a_config_files+=("$(readlink -f "$l_file_name")")
            done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)
        fi
    done < <(awk '$1 ~ /^\s*'"$l_include"'$/ { print $2 }' "${a_config_files[@]}" 2>/dev/null)

    # Look for matching parameter lines
    for l_file in "${a_config_files[@]}"; do
        l_parameter_line="$(grep -Psi '^\h*'"$l_parameter_name"'(\h+|\h*:\h*)'"$l_parameter_value"'\b' "$l_file")"

        if [ -n "$l_parameter_line" ]; then
            a_output+=(
                " - Parameter: \"$(tr -d '()' <<< ${l_parameter_name//|/ or })\""
                " Exists in the file: \"$l_file\" as:"
                " $l_parameter_line"
            )
        fi
    done

    # If no matching parameters were found
    if [ "${#a_output[@]}" -eq 0 ]; then
        a_output2+=(
            " - Parameter: \"$(tr -d '()' <<< ${l_parameter_name//|/ or })\""
            " Does not exist in the chrony configuration"
        )
    fi

    # Print audit result
    if [ "${#a_output2[@]}" -eq 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    fi
}

a__2_3_3_2() {
output=""
    output_fail=""

    # Check if chrony service is active/enabled
    if systemctl is-enabled chrony.service >/dev/null 2>&1 || systemctl is-active chrony.service >/dev/null 2>&1; then
        # Run the check for chronyd running under incorrect user
        unauthorized_users=$(ps -eo user:20,comm | awk '$2 == "chronyd" && $1 != "_chrony" { print $1 }' | sort -u)

        if [ -z "$unauthorized_users" ]; then
            output=" - chronyd is running as expected under the _chrony user"
            status="PASS"
        else
            output_fail=" - chronyd is running as the following unexpected user(s): $unauthorized_users"
            status="FAIL"
        fi
    else
        output_fail=" - chrony service is not active or enabled, skipping user check"
        status="FAIL"
    fi

    # Output the result
    echo -e "\n- Audit Result:"
    if [ "$status" == "PASS" ]; then
        echo " ** PASS **"
        echo "$output"
    else
        echo " ** FAIL **"
        echo " - Reason(s) for audit failure:"
        echo "$output_fail"
    fi
}

a__2_3_3_3() {
output=""
    fail_output=""

    service="chrony.service"

    # Check if chrony is in use
    if systemctl list-units --type=service --state=active | grep -q "$service"; then
        # Check if enabled
        if systemctl is-enabled "$service" 2>/dev/null | grep -q '^enabled$'; then
            output+=" - Service is enabled.\n"
        else
            fail_output+=" - $service is not enabled.\n"
        fi

        # Check if active
        if systemctl is-active "$service" 2>/dev/null | grep -q '^active$'; then
            output+=" - Service is active.\n"
        else
            fail_output+=" - $service is not active.\n"
        fi
    else
        fail_output+=" - $service is not in use (not active on the system).\n"
    fi

    echo -e "\n- Audit Result:"
    if [ -z "$fail_output" ]; then
        echo " ** PASS **"
        echo -e "$output"
    else
        echo " ** FAIL **"
        echo -e " - Reason(s) for audit failure:\n$fail_output"
    fi
}

a__2_4_1_1() {
# Check if cron is enabled
enabled_status=$(systemctl list-unit-files | awk '$1~/^crond?\\.service/{print $2}')
if [ "$enabled_status" = "enabled" ]; then
    echo "** PASS ** cron service is enabled"
else
    echo "** FAIL ** cron service is not enabled"
fi

# Check if cron is active
active_status=$(systemctl list-units | awk '$1~/^crond?\\.service/{print $3}')
if [ "$active_status" = "active" ]; then
    echo "** PASS ** cron service is active"
else
    echo "** FAIL ** cron service is not active"
fi
}

a__2_4_1_2() {
file='/etc/crontab'

if [ ! -f "$file" ]; then
    echo "** FAIL **: $file does not exist"
    exit 1
fi

stat_output=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$file")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
uid=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2)
gid=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2)

status="** PASS **"
[[ "$perm" != "600" ]] && status="** FAIL **"
[[ "$uid" != "0" ]] && status="** FAIL **"
[[ "$gid" != "0" ]] && status="** FAIL **"

echo "$status: $stat_output"
}

a__2_4_1_3() {
dir='/etc/cron.hourly/'

if [ ! -d "$dir" ]; then
    echo "** FAIL **: $dir does not exist"
    exit 1
fi

stat_output=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$dir")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
uid=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2)
gid=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2)

status="** PASS **"
[[ "$perm" != "700" ]] && status="** FAIL **"
[[ "$uid" != "0" ]] && status="** FAIL **"
[[ "$gid" != "0" ]] && status="** FAIL **"

echo "$status: $stat_output"
}

a__2_4_1_4() {
dir='/etc/cron.daily/'

if [ ! -d "$dir" ]; then
    echo "** FAIL **: $dir does not exist"
    exit 1
fi

stat_output=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$dir")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
uid=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2)
gid=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2)

status="** PASS **"
[[ "$perm" != "700" ]] && status="** FAIL **"
[[ "$uid" != "0" ]] && status="** FAIL **"
[[ "$gid" != "0" ]] && status="** FAIL **"

echo "$status: $stat_output"
}

a__2_4_1_5() {
dir='/etc/cron.weekly/'

if [ ! -d "$dir" ]; then
    echo "** FAIL **: $dir does not exist"
    exit 1
fi

stat_output=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$dir")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
uid=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2)
gid=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2)

status="** PASS **"
[[ "$perm" != "700" ]] && status="** FAIL **"
[[ "$uid" != "0" ]] && status="** FAIL **"
[[ "$gid" != "0" ]] && status="** FAIL **"

echo "$status: $stat_output"
}

a__2_4_1_6() {
dir='/etc/cron.monthly/'

if [ ! -d "$dir" ]; then
    echo "** FAIL **: $dir does not exist"
    exit 1
fi

stat_output=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$dir")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
uid=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2)
gid=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2)

status="** PASS **"
[[ "$perm" != "700" ]] && status="** FAIL **"
[[ "$uid" != "0" ]] && status="** FAIL **"
[[ "$gid" != "0" ]] && status="** FAIL **"

echo "$status: $stat_output"
}

a__2_4_1_7() {
dir='/etc/cron.d/'

if [ ! -d "$dir" ]; then
    echo "** FAIL **: $dir does not exist"
    exit 1
fi

stat_output=$(stat -Lc 'Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$dir")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
uid=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2)
gid=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2)

status="** PASS **"
[[ "$perm" != "700" ]] && status="** FAIL **"
[[ "$uid" != "0" ]] && status="** FAIL **"
[[ "$gid" != "0" ]] && status="** FAIL **"

echo "$status: $stat_output"
}

a__2_4_1_8() {
cron_allow="/etc/cron.allow"
cron_deny="/etc/cron.deny"

# Check /etc/cron.allow
if [ ! -f "$cron_allow" ]; then
    echo "** FAIL **: $cron_allow does not exist"
    exit 1
fi

# Validate /etc/cron.allow
stat_output=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' "$cron_allow")
perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
owner=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2 | tr -d ')')
group=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2 | tr -d ')')

if [[ "$perm" -gt 640 || "$owner" != "root" || ( "$group" != "root" && "$group" != "crontab" ) ]]; then
    echo "** FAIL **: $cron_allow permissions or ownership incorrect -> $stat_output"
    exit 1
fi

# Check /etc/cron.deny if it exists
if [ -f "$cron_deny" ]; then
    stat_output=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' "$cron_deny")
    perm=$(echo "$stat_output" | awk '{print $2}' | cut -d'(' -f2 | cut -d'/' -f1)
    owner=$(echo "$stat_output" | awk '{print $4}' | cut -d'(' -f2 | tr -d ')')
    group=$(echo "$stat_output" | awk '{print $6}' | cut -d'(' -f2 | tr -d ')')

    if [[ "$perm" -gt 640 || "$owner" != "root" || ( "$group" != "root" && "$group" != "crontab" ) ]]; then
        echo "** FAIL **: $cron_deny permissions or ownership incorrect -> $stat_output"
        exit 1
    fi
fi

echo "** PASS **: cron.allow and cron.deny permissions and ownership are correct"
}

a__3_1_2() {
# Check if bluez package is installed
if dpkg-query -s bluez &>/dev/null; then
    # bluez is installed — check if bluetooth.service is disabled and inactive
    is_enabled=$(systemctl is-enabled bluetooth.service 2>/dev/null)
    is_active=$(systemctl is-active bluetooth.service 2>/dev/null)

    if [[ "$is_enabled" == "enabled" || "$is_active" == "active" ]]; then
        echo "** FAIL **: bluez is installed and bluetooth.service is $is_enabled/$is_active"
        exit 1
    fi
else
    # bluez is not installed — that's OK
    echo "** PASS **: bluez package is not installed"
    exit 0
fi

echo "** PASS **: bluez is installed but bluetooth.service is disabled and inactive"
}

a__3_2_1() {
# Initialize arrays and variables
  a_output=()
  a_output2=()
  a_output3=()
  l_dl=""
  l_mod_name="dccp"
  l_mod_type="net"

  # Find the module path(s)
  l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

  # Function to check module status
  f_module_chk() {
    l_dl="y"
    a_showconfig=()

    # Read modprobe config lines for the module
    while IFS= read -r l_showconfig; do
      a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+' "${l_mod_chk_name//-/_}"'\b')

    # Check if module is loaded
    if ! lsmod | grep -q "$l_mod_chk_name"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    # Check if module is set to not load (install true/false)
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    # Check if module is blacklisted
    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
  }

  # Loop through all found module paths
  for l_mod_base_directory in $l_mod_path; do
    mod_dir="$l_mod_base_directory/${l_mod_name//-//}"

    if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
      a_output3+=(" - \"$l_mod_base_directory\"")
      l_mod_chk_name="$l_mod_name"

      # If module name contains 'overlay', strip last two chars
      [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"

      [ "$l_dl" != "y" ] && f_module_chk
    else
      a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
  done

  # Print results
  if [ "${#a_output3[@]}" -gt 0 ]; then
    printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
  fi

  if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
      printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
  fi
}

a__3_2_2() {
# Initialize arrays and variables
  a_output=()
  a_output2=()
  a_output3=()
  l_dl=""
  l_mod_name="tipc"
  l_mod_type="net"

  # Find the module path(s)
  l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

  # Function to check module status
  f_module_chk() {
    l_dl="y"
    a_showconfig=()

    # Read modprobe config lines relevant to the module
    while IFS= read -r l_showconfig; do
      a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+' "${l_mod_chk_name//-/_}"'\b')

    # Check if the module is loaded
    if ! lsmod | grep -q "$l_mod_chk_name"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    # Check if the module is not loadable (installed as /bin/true or /bin/false)
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    # Check if the module is blacklisted
    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
  }

  # Loop through each found module path
  for l_mod_base_directory in $l_mod_path; do
    mod_dir="$l_mod_base_directory/${l_mod_name//-//}"

    if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
      a_output3+=(" - \"$l_mod_base_directory\"")
      l_mod_chk_name="$l_mod_name"

      # Adjust module name if it's an overlay (optional logic, depending on use)
      [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"

      [ "$l_dl" != "y" ] && f_module_chk
    else
      a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
  done

  # Output results
  if [ "${#a_output3[@]}" -gt 0 ]; then
    printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
  fi

  if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
      printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
  fi
}

a__3_2_3() {
# Initialize arrays and variables
  a_output=()
  a_output2=()
  a_output3=()
  l_dl=""
  l_mod_name="rds"
  l_mod_type="net"

  # Get full path to module directory
  l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

  # Function to check module configuration and status
  f_module_chk() {
    l_dl="y"
    a_showconfig=()

    # Collect modprobe configuration lines for this module
    while IFS= read -r l_showconfig; do
      a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+' "${l_mod_chk_name//-/_}"'\b')

    # Check if module is currently loaded
    if ! lsmod | grep -q "$l_mod_chk_name"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    # Check if module is configured to not be loadable (via /bin/true or /bin/false)
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    # Check if the module is blacklisted
    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
  }

  # Iterate through each kernel module path and verify presence
  for l_mod_base_directory in $l_mod_path; do
    mod_dir="$l_mod_base_directory/${l_mod_name//-//}"

    if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
      a_output3+=(" - \"$l_mod_base_directory\"")
      l_mod_chk_name="$l_mod_name"

      # Optional adjustment for overlay module naming
      [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"

      [ "$l_dl" != "y" ] && f_module_chk
    else
      a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
  done

  # Print module existence info
  if [ "${#a_output3[@]}" -gt 0 ]; then
    printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
  fi

  # Print audit result
  if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
      printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
  fi
}

a__3_2_4() {
# Initialize arrays and variables
  a_output=()
  a_output2=()
  a_output3=()
  l_dl=""
  l_mod_name="sctp"
  l_mod_type="net"

  # Get kernel module path
  l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

  # Function to check the module's status
  f_module_chk() {
    l_dl="y"
    a_showconfig=()

    # Get modprobe config lines related to the module
    while IFS= read -r l_showconfig; do
      a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+' "${l_mod_chk_name//-/_}"'\b')

    # Check if module is loaded
    if ! lsmod | grep -q "$l_mod_chk_name"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    # Check if module is configured as not loadable (/bin/true or /bin/false)
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    # Check if the module is blacklisted
    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
      a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
      a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
  }

  # Iterate over detected module paths
  for l_mod_base_directory in $l_mod_path; do
    mod_dir="$l_mod_base_directory/${l_mod_name//-//}"

    if [ -d "$mod_dir" ] && [ -n "$(ls -A "$mod_dir")" ]; then
      a_output3+=(" - \"$l_mod_base_directory\"")
      l_mod_chk_name="$l_mod_name"

      # Optional: handle overlays if needed
      [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"

      [ "$l_dl" != "y" ] && f_module_chk
    else
      a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
  done

  # Output module presence info
  if [ "${#a_output3[@]}" -gt 0 ]; then
    printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}"
  fi

  # Output audit results
  if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}"
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
      printf '%s\n' "- Correctly set:" "${a_output[@]}"
    fi
  fi
}

a__3_3_1() {
# Initialize variables and arrays
  a_output=()
  a_output2=()
  l_ipv6_disabled=""
  a_parlist=("net.ipv4.ip_forward=0" "net.ipv6.conf.all.forwarding=0")
  l_ufwscf="$(
    [ -f /etc/default/ufw ] && 
    awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
  )"
  l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

  # Check if IPv6 is disabled system-wide
  f_ipv6_chk() {
    l_ipv6_disabled="no"

    # Check via sysfs
    ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable &&
      l_ipv6_disabled="yes"

    # Check via sysctl
    if sysctl net.ipv6.conf.all.disable_ipv6    | grep -Pqs '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
       sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
      l_ipv6_disabled="yes"
    fi
  }

  # Check both runtime and persistent parameter values
  f_kernel_parameter_chk() {
    # Get current running value
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

    # Compare running value
    if grep -Pq "\b$l_parameter_value\b" <<< "$l_running_parameter_value"; then
      a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
      a_output2+=(
        " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration"
        "   and should have a value of: \"$l_value_out\""
      )
    fi

    # Initialize map for matching files
    unset A_out
    declare -A A_out

    # Find persistent setting files via systemd-sysctl
    while read -r l_out; do
      if [[ -n "$l_out" ]]; then
        if [[ $l_out =~ ^\s*# ]]; then
          l_file="${l_out//# /}"
        else
          l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
          [[ "$l_kpar" == "$l_parameter_name" ]] && A_out["$l_kpar"]="$l_file"
        fi
      fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

    # Include UFW file if applicable
    if [[ -n "$l_ufwscf" ]]; then
      l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
      l_kpar="${l_kpar//\//.}"
      [[ "$l_kpar" == "$l_parameter_name" ]] && A_out["$l_kpar"]="$l_ufwscf"
    fi

    # Check persistent values
    if (( ${#A_out[@]} > 0 )); then
      while IFS="=" read -r l_fkpname l_file_parameter_value; do
        l_fkpname="${l_fkpname// /}"
        l_file_parameter_value="${l_file_parameter_value// /}"
        if grep -Pq "\b$l_parameter_value\b" <<< "$l_file_parameter_value"; then
          a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\"")
        else
          a_output2+=(
            " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\""
            "   and should have a value of: \"$l_value_out\""
          )
        fi
      done < <(grep -Po "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
      a_output2+=(
        " - \"$l_parameter_name\" is not set in an included file"
        "   ** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure **"
      )
    fi
  }

  # Process each parameter
  while IFS="=" read -r l_parameter_name l_parameter_value; do
    l_parameter_name="${l_parameter_name// /}"
    l_parameter_value="${l_parameter_value// /}"
    l_value_out="${l_parameter_value//-/ through }"
    l_value_out="${l_value_out//|/ or }"
    l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

    # IPv6-specific logic
    if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
      [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
      if [ "$l_ipv6_disabled" == "yes" ]; then
        a_output+=(" - IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
      else
        f_kernel_parameter_chk
      fi
    else
      f_kernel_parameter_chk
    fi
  done < <(printf '%s\n' "${a_parlist[@]}")

  # Print audit results
  if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
  fi
}

a__3_3_10() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""

    a_parlist=("net.ipv4.tcp_syncookies=1")

    l_ufwscf="$(
        [ -f /etc/default/ufw ] &&
        awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
    )"

    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable &&
            l_ipv6_disabled="yes"

        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
            l_ipv6_disabled="yes"
        fi
    }

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(
                " - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\""
                "   in the running configuration"
            )
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\""
                "   in the running configuration"
                "   and should have a value of: \"$l_value_out\""
            )
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"

                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                    )
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                        "   and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(
                    " - IPv6 is disabled on the system,"
                    "   \"$l_parameter_name\" is not applicable"
                )
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__3_3_11() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""

    a_parlist=("net.ipv6.conf.all.accept_ra=0"
               "net.ipv6.conf.default.accept_ra=0")

    l_ufwscf="$(
        [ -f /etc/default/ufw ] &&
        awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
    )"

    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable &&
            l_ipv6_disabled="yes"

        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
            l_ipv6_disabled="yes"
        fi
    }

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(
                " - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\""
                "   in the running configuration"
            )
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\""
                "   in the running configuration"
                "   and should have a value of: \"$l_value_out\""
            )
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"

                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                    )
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                        "   and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(
                    " - IPv6 is disabled on the system,"
                    "   \"$l_parameter_name\" is not applicable"
                )
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__3_3_2() {
a_output=()
  a_output2=()
  l_ipv6_disabled=""
  a_parlist=(
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.conf.default.send_redirects=0"
  )

  l_ufwscf="$(
    [ -f /etc/default/ufw ] &&
    awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
  )"

  l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

  f_ipv6_chk() {
    l_ipv6_disabled="no"

    ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable &&
      l_ipv6_disabled="yes"

    if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
       sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
      l_ipv6_disabled="yes"
    fi
  }

  f_kernel_parameter_chk() {
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

    if grep -Pq "\b$l_parameter_value\b" <<< "$l_running_parameter_value"; then
      a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
      a_output2+=(
        " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration"
        "   and should have a value of: \"$l_value_out\""
      )
    fi

    unset A_out
    declare -A A_out

    while read -r l_out; do
      if [ -n "$l_out" ]; then
        if [[ $l_out =~ ^\s*# ]]; then
          l_file="${l_out//# /}"
        else
          l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
          [[ "$l_kpar" == "$l_parameter_name" ]] && A_out["$l_kpar"]="$l_file"
        fi
      fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

    if [[ -n "$l_ufwscf" ]]; then
      l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
      l_kpar="${l_kpar//\//.}"
      [[ "$l_kpar" == "$l_parameter_name" ]] && A_out["$l_kpar"]="$l_ufwscf"
    fi

    if (( ${#A_out[@]} > 0 )); then
      while IFS="=" read -r l_fkpname l_file_parameter_value; do
        l_fkpname="${l_fkpname// /}"
        l_file_parameter_value="${l_file_parameter_value// /}"

        if grep -Pq "\b$l_parameter_value\b" <<< "$l_file_parameter_value"; then
          a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\"")
        else
          a_output2+=(
            " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\""
            "   and should have a value of: \"$l_value_out\""
          )
        fi
      done < <(grep -Po "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
      a_output2+=(
        " - \"$l_parameter_name\" is not set in an included file"
        "   ** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure **"
      )
    fi
  }

  while IFS="=" read -r l_parameter_name l_parameter_value; do
    l_parameter_name="${l_parameter_name// /}"
    l_parameter_value="${l_parameter_value// /}"
    l_value_out="${l_parameter_value//-/ through }"
    l_value_out="${l_value_out//|/ or }"
    l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

    if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
      [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
      if [ "$l_ipv6_disabled" == "yes" ]; then
        a_output+=(" - IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
      else
        f_kernel_parameter_chk
      fi
    else
      f_kernel_parameter_chk
    fi
  done < <(printf '%s\n' "${a_parlist[@]}")

  if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
  fi
}

a__3_3_3() {
a_output=()
  a_output2=()
  l_ipv6_disabled=""

  a_parlist=("net.ipv4.icmp_ignore_bogus_error_responses=1")

  l_ufwscf="$(
    [ -f /etc/default/ufw ] &&
    awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
  )"

  l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

  f_ipv6_chk() {
    l_ipv6_disabled="no"
    ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && l_ipv6_disabled="yes"

    if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
       sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
      l_ipv6_disabled="yes"
    fi
  }

  f_kernel_parameter_chk() {
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

    if grep -Pq "\b$l_parameter_value\b" <<< "$l_running_parameter_value"; then
      a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
      a_output2+=(
        " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration"
        "   and should have a value of: \"$l_value_out\""
      )
    fi

    unset A_out
    declare -A A_out

    while read -r l_out; do
      if [ -n "$l_out" ]; then
        if [[ "$l_out" =~ ^\s*# ]]; then
          l_file="${l_out//# /}"
        else
          l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
          [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
        fi
      fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

    if [ -n "$l_ufwscf" ]; then
      l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
      l_kpar="${l_kpar//\//.}"
      [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
    fi

    if (( ${#A_out[@]} > 0 )); then
      while IFS="=" read -r l_fkpname l_file_parameter_value; do
        l_fkpname="${l_fkpname// /}"
        l_file_parameter_value="${l_file_parameter_value// /}"

        if grep -Pq "\b$l_parameter_value\b" <<< "$l_file_parameter_value"; then
          a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\"")
        else
          a_output2+=(
            " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"${A_out[$l_fkpname]}\""
            "   and should have a value of: \"$l_value_out\""
          )
        fi
      done < <(grep -Po "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
      a_output2+=(
        " - \"$l_parameter_name\" is not set in an included file"
        "   ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
      )
    fi
  }

  while IFS="=" read -r l_parameter_name l_parameter_value; do
    l_parameter_name="${l_parameter_name// /}"
    l_parameter_value="${l_parameter_value// /}"
    l_value_out="${l_parameter_value//-/ through }"
    l_value_out="${l_value_out//|/ or }"
    l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

    if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
      [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
      if [ "$l_ipv6_disabled" = "yes" ]; then
        a_output+=(" - IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
      else
        f_kernel_parameter_chk
      fi
    else
      f_kernel_parameter_chk
    fi
  done < <(printf '%s\n' "${a_parlist[@]}")

  if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
  else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
  fi
}

a__3_3_4() {
# Initialize variables
a_output=()
a_output2=()
l_ipv6_disabled=""
a_parlist=("net.ipv4.icmp_echo_ignore_broadcasts=1")
l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

# Function to check if IPv6 is disabled
f_ipv6_chk() {
    l_ipv6_disabled="no"

    ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && l_ipv6_disabled="yes"

    if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' && \
       sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
        l_ipv6_disabled="yes"
    fi
}

# Function to check kernel parameters
f_kernel_parameter_chk() {
    l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

    if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
        a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
    else
        a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration"
                    " and should have a value of: \"$l_value_out\"")
    fi

    unset A_out
    declare -A A_out

    # Check persistent (file-based) configuration
    while read -r l_out; do
        if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
            else
                l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
            fi
        fi
    done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

    # Check UFW-specific configuration
    if [ -n "$l_ufwscf" ]; then
        l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
        l_kpar="${l_kpar//\//.}"
        [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
    fi

    if (( ${#A_out[@]} > 0 )); then
        while IFS="=" read -r l_fkpname l_file_parameter_value; do
            l_fkpname="${l_fkpname// /}"
            l_file_parameter_value="${l_file_parameter_value// /}"

            if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
            else
                a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\""
                            " and should have a value of: \"$l_value_out\"")
            fi
        done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
        a_output2+=(" - \"$l_parameter_name\" is not set in an included file"
                    " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure **")
    fi
}

# Main loop: Process each parameter
while IFS="=" read -r l_parameter_name l_parameter_value; do
    l_parameter_name="${l_parameter_name// /}"
    l_parameter_value="${l_parameter_value// /}"
    l_value_out="${l_parameter_value//-/ through }"
    l_value_out="${l_value_out//|/ or }"
    l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

    if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
        [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
        if [ "$l_ipv6_disabled" = "yes" ]; then
            a_output+=(" - IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
        else
            f_kernel_parameter_chk
        fi
    else
        f_kernel_parameter_chk
    fi
done < <(printf '%s\n' "${a_parlist[@]}")

# Output results
if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__3_3_5() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""
    
    a_parlist=(
        "net.ipv4.conf.all.accept_redirects=0"
        "net.ipv4.conf.default.accept_redirects=0"
        "net.ipv6.conf.all.accept_redirects=0"
        "net.ipv6.conf.default.accept_redirects=0"
    )

    l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    # Function: Check if IPv6 is disabled
    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable && l_ipv6_disabled="yes"
        
        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
            l_ipv6_disabled="yes"
        fi
    }

    # Function: Check parameter in both runtime and persistent config
    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        # Runtime check
        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration"
                " and should have a value of: \"$l_value_out\""
            )
        fi

        # Persistent check
        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        # UFW exception
        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        # Persistent config check
        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"

                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\""
                        " and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    # Main processing loop
    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(" - IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    # Output results
    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__3_3_6() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""
    a_parlist=(
        "net.ipv4.conf.all.secure_redirects=0"
        "net.ipv4.conf.default.secure_redirects=0"
    )

    l_ufwscf="$(
        [ -f /etc/default/ufw ] && 
        awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
    )"

    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable &&
            l_ipv6_disabled="yes"

        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
            l_ipv6_disabled="yes"
        fi
    }

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"
        
        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(
                " - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\""
                "   in the running configuration"
            )
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\""
                "   in the running configuration"
                "   and should have a value of: \"$l_value_out\""
            )
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"
                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                    )
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                        "   and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(
                    " - IPv6 is disabled on the system,"
                    "   \"$l_parameter_name\" is not applicable"
                )
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__3_3_7() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""

    a_parlist=(
        "net.ipv4.conf.all.rp_filter=1"
        "net.ipv4.conf.default.rp_filter=1"
    )

    l_ufwscf="$(
        [ -f /etc/default/ufw ] && 
        awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
    )"

    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable &&
            l_ipv6_disabled="yes"

        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
            l_ipv6_disabled="yes"
        fi
    }

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(
                " - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\""
                "   in the running configuration"
            )
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\""
                "   in the running configuration"
                "   and should have a value of: \"$l_value_out\""
            )
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"
                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                    )
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                        "   and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(
                    " - IPv6 is disabled on the system,"
                    "   \"$l_parameter_name\" is not applicable"
                )
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__3_3_8() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""

    a_parlist=(
        "net.ipv4.conf.all.accept_source_route=0"
        "net.ipv4.conf.default.accept_source_route=0"
        "net.ipv6.conf.all.accept_source_route=0"
        "net.ipv6.conf.default.accept_source_route=0"
    )

    l_ufwscf="$(
        [ -f /etc/default/ufw ] &&
        awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
    )"

    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable &&
            l_ipv6_disabled="yes"

        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
            l_ipv6_disabled="yes"
        fi
    }

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(
                " - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\""
                "   in the running configuration"
            )
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\""
                "   in the running configuration"
                "   and should have a value of: \"$l_value_out\""
            )
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"

                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                    )
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                        "   and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(
                    " - IPv6 is disabled on the system,"
                    "   \"$l_parameter_name\" is not applicable"
                )
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__3_3_9() {
a_output=()
    a_output2=()
    l_ipv6_disabled=""

    a_parlist=(
        "net.ipv4.conf.all.log_martians=1"
        "net.ipv4.conf.default.log_martians=1"
    )

    l_ufwscf="$(
        [ -f /etc/default/ufw ] &&
        awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw
    )"

    f_ipv6_chk() {
        l_ipv6_disabled="no"
        ! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable &&
            l_ipv6_disabled="yes"

        if sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" &&
           sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
            l_ipv6_disabled="yes"
        fi
    }

    f_kernel_parameter_chk() {
        l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)"

        if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
            a_output+=(
                " - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\""
                "   in the running configuration"
            )
        else
            a_output2+=(
                " - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\""
                "   in the running configuration"
                "   and should have a value of: \"$l_value_out\""
            )
        fi

        unset A_out
        declare -A A_out

        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                    l_file="${l_out//# /}"
                else
                    l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                    [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <("$l_systemdsysctl" --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*/[^#\n\r\h]+\.conf\b)')

        if [ -n "$l_ufwscf" ]; then
            l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi

        if (( ${#A_out[@]} > 0 )); then
            while IFS="=" read -r l_fkpname l_file_parameter_value; do
                l_fkpname="${l_fkpname// /}"
                l_file_parameter_value="${l_file_parameter_value// /}"

                if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                    )
                else
                    a_output2+=(
                        " - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\""
                        "   in \"$(printf '%s' "${A_out[@]}")\""
                        "   and should have a value of: \"$l_value_out\""
                    )
                fi
            done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
        else
            a_output2+=(
                " - \"$l_parameter_name\" is not set in an included file"
                " ** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure **"
            )
        fi
    }

    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
            [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
            if [ "$l_ipv6_disabled" = "yes" ]; then
                a_output+=(
                    " - IPv6 is disabled on the system,"
                    "   \"$l_parameter_name\" is not applicable"
                )
            else
                f_kernel_parameter_chk
            fi
        else
            f_kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}

a__4_1_1() {
active_firewall=()
    firewalls=("ufw" "nftables" "iptables")

    # Determine which firewall is active and enabled
    for firewall in "${firewalls[@]}"; do
        case "$firewall" in
            nftables) cmd="nft" ;;
            *)        cmd="$firewall" ;;
        esac

        if command -v "$cmd" &>/dev/null && \
           systemctl is-enabled --quiet "$firewall" && \
           systemctl is-active --quiet "$firewall"; then
            active_firewall+=("$firewall")
        fi
    done

    # Display audit results
    if [ ${#active_firewall[@]} -eq 1 ]; then
        printf '%s\n' "" "Audit Results:" " ** PASS **" \
               " - A single firewall is in use: ${active_firewall[0]}" \
               "   Follow recommendations for '${active_firewall[0]}' only."
    elif [ ${#active_firewall[@]} -eq 0 ]; then
        printf '%s\n' "" "Audit Results:" " ** FAIL **" \
               " - No firewall is in use or firewall status could not be determined."
    else
        printf '%s\n' "" "Audit Results:" " ** FAIL **" \
               " - Multiple firewalls are active: ${active_firewall[*]}" \
               "   Only one firewall should be active to avoid conflict."
    fi
}

a__4_2_1() {
output=""
if dpkg-query -s ufw &>/dev/null; then
  output=" - UFW package is installed"
  printf '%s\n' "" "- Audit Result:" " ** PASS **" "$output" ""
else
  output=" - UFW package is not installed"
  printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "$output" ""
fi
}

a__4_2_2() {
if dpkg-query -s iptables-persistent &>/dev/null; then
    echo ""
    echo "- Audit Result:"
    echo " ** FAIL **"
    echo " - Reason(s) for audit failure:"
    echo " - iptables-persistent package is installed"
    echo ""
else
    echo ""
    echo "- Audit Result:"
    echo " ** PASS **"
    echo " - iptables-persistent package is not installed"
    echo ""
fi
}

a__4_2_3() {
failures=()

if systemctl is-enabled ufw.service | grep -qv '^enabled$'; then
    failures+=(" - ufw.service is not enabled")
fi

if systemctl is-active ufw | grep -qv '^active$'; then
    failures+=(" - ufw.service is not active")
fi

if ufw status 2>/dev/null | grep -qv '^Status: active'; then
    failures+=(" - ufw firewall is not active (ufw status)")
fi

if [ "${#failures[@]}" -eq 0 ]; then
    echo ""
    echo "- Audit Result:"
    echo " ** PASS **"
    echo " - ufw service is enabled, running, and firewall is active"
    echo ""
else
    echo ""
    echo "- Audit Result:"
    echo " ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
    echo ""
fi
}

a__4_2_4() {
failures=()

# Check /etc/ufw/before.rules for loopback accept rules
if ! grep -Pq '^\s*#\s*allow all on loopback' /etc/ufw/before.rules; then
    failures+=(" - Missing comment: '# allow all on loopback' in /etc/ufw/before.rules")
fi

if ! grep -Pq '^\s*-A\s+ufw-before-input\s+-i\s+lo\s+-j\s+ACCEPT' /etc/ufw/before.rules; then
    failures+=(" - Missing input accept rule for lo in /etc/ufw/before.rules")
fi

if ! grep -Pq '^\s*-A\s+ufw-before-output\s+-o\s+lo\s+-j\s+ACCEPT' /etc/ufw/before.rules; then
    failures+=(" - Missing output accept rule for lo in /etc/ufw/before.rules")
fi

# Check ufw status verbose for loopback deny rules on other interfaces
ufw_status="$(ufw status verbose 2>/dev/null)"

if ! grep -qE '^\s*Anywhere\s+DENY\s+IN\s+127\.0\.0\.0/8' <<< "$ufw_status"; then
    failures+=(" - Missing 'DENY IN 127.0.0.0/8' in ufw status verbose")
fi

if ! grep -qE '^\s*Anywhere\s+\(v6\)\s+DENY\s+IN\s+::1' <<< "$ufw_status"; then
    failures+=(" - Missing 'DENY IN ::1' in ufw status verbose")
fi

if [ "${#failures[@]}" -eq 0 ]; then
    echo ""
    echo "- Audit Result:"
    echo " ** PASS **"
    echo " - Loopback traffic is correctly accepted and loopback spoofing is denied"
    echo ""
else
    echo ""
    echo "- Audit Result:"
    echo " ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
    echo ""
fi
}

a__4_2_6() {
#!/usr/bin/env bash

# Collect UFW-allowed ports
ufw_ports=()
while read -r port; do
    [ -n "$port" ] && ufw_ports+=("$port")
done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)

# Collect actually open ports (excluding loopback)
open_ports=()
while read -r port; do
    [ -n "$port" ] && open_ports+=("$port")
done < <(ss -tuln | awk '
    $5 !~ /%lo:/ && 
    $5 !~ /127\.0\.0\.1:/ && 
    $5 !~ /\[?::1\]?:/ {
        split($5, a, ":"); print a[2]
    }
' | sort -u)

# Find difference: open ports not covered by UFW
diff_ports=($(printf '%s\n' "${open_ports[@]}" "${ufw_ports[@]}" "${ufw_ports[@]}" | sort | uniq -u))

# Report result
if [[ -n "${diff_ports[*]}" ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo "- The following port(s) don't have a rule in UFW:"
    printf '  - %s\n' "${diff_ports[@]}"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** PASS **"
    echo "- All open ports have a rule in UFW"
fi
}

a__4_2_7() {
output="$(ufw status verbose | grep '^Default:')"
expected_values=("deny" "reject" "disabled")
failures=()

# Extract policy values
incoming="$(awk -F '[(),]' '{print $2}' <<< "$output" | xargs)"
outgoing="$(awk -F '[(),]' '{print $3}' <<< "$output" | xargs)"
routed="$(awk -F '[(),]' '{print $4}' <<< "$output" | xargs)"

check_policy() {
    local direction="$1"
    local value="$2"
    if [[ ! " ${expected_values[*]} " =~ " $value " ]]; then
        failures+=(" - Default policy for $direction is '$value', expected: deny/reject/disabled")
    fi
}

check_policy "incoming" "$incoming"
check_policy "outgoing" "$outgoing"
check_policy "routed" "$routed"

if [[ ${#failures[@]} -eq 0 ]]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo "- Default policies are correctly set: $output"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_3_1() {
if dpkg-query -s nftables &>/dev/null; then
    echo -e "\n- Audit Result:\n ** PASS **\n- nftables is installed\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n- nftables is not installed\n"
fi
}

a__4_3_2() {
failures=()

# Check if UFW is installed
if dpkg-query -s ufw &>/dev/null; then
    # If installed, check if it is inactive and masked
    ufw_status="$(ufw status 2>/dev/null)"
    service_status="$(systemctl is-enabled ufw.service 2>/dev/null)"

    if ! grep -q "^Status: inactive" <<< "$ufw_status"; then
        failures+=(" - UFW is installed and not inactive (status: $ufw_status)")
    fi

    if [ "$service_status" != "masked" ]; then
        failures+=(" - ufw.service is not masked (status: $service_status)")
    fi
else
    echo "- UFW is not installed"
fi

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_3_3() {
#!/usr/bin/env bash

failures=()

# Check for non-header rules in iptables
if iptables -L | awk 'NR>2 && $0 !~ /^Chain/ && NF' | grep -q .; then
    failures+=(" - iptables has active rules")
fi

# Check for non-header rules in ip6tables
if ip6tables -L | awk 'NR>2 && $0 !~ /^Chain/ && NF' | grep -q .; then
    failures+=(" - ip6tables has active rules")
fi

if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n - Audit Passed -\n- No iptables or ip6tables rules found\n"
else
    echo -e "\n - Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__4_3_4() {
failures=()

nft_tables="$(nft list tables 2>/dev/null)"

if grep -qE '^\s*table\s+\S+\s+\S+' <<< "$nft_tables"; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Found nftables table(s):"
    echo "$nft_tables"
else
    failures+=(" - No nftables tables found")
fi

if [ ${#failures[@]} -ne 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_3_5() {
failures=()
nft_ruleset="$(nft list ruleset 2>/dev/null)"

if grep -q 'hook input' <<< "$nft_ruleset"; then
    echo " - INPUT base chain found (hook input)"
else
    failures+=(" - Missing INPUT base chain (hook input)")
fi

if grep -q 'hook forward' <<< "$nft_ruleset"; then
    echo " - FORWARD base chain found (hook forward)"
else
    failures+=(" - Missing FORWARD base chain (hook forward)")
fi

if grep -q 'hook output' <<< "$nft_ruleset"; then
    echo " - OUTPUT base chain found (hook output)"
else
    failures+=(" - Missing OUTPUT base chain (hook output)")
fi

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_3_6() {
failures=()
nft_input_section="$(nft list ruleset 2>/dev/null | awk '/hook input/,/}/')"

# Check for accepting traffic on loopback interface
if grep -q 'iif "lo" accept' <<< "$nft_input_section"; then
    echo " - Loopback interface configured to accept traffic (iif \"lo\" accept)"
else
    failures+=(" - Missing rule to accept traffic on loopback interface (iif \"lo\" accept)")
fi

# Check for dropping IPv4 loopback spoofed traffic
if grep -q 'ip saddr 127.0.0.0/8.*drop' <<< "$nft_input_section"; then
    echo " - IPv4 loopback spoofed traffic is dropped (ip saddr 127.0.0.0/8 ... drop)"
else
    failures+=(" - Missing rule to drop IPv4 loopback spoofed traffic (ip saddr 127.0.0.0/8 ... drop)")
fi

# Check if IPv6 is enabled
if [ -e /proc/sys/net/ipv6/conf/all/disable_ipv6 ]; then
    ipv6_disabled=$(< /proc/sys/net/ipv6/conf/all/disable_ipv6)
    if [ "$ipv6_disabled" -eq 0 ]; then
        if grep -q 'ip6 saddr ::1.*drop' <<< "$nft_input_section"; then
            echo " - IPv6 loopback spoofed traffic is dropped (ip6 saddr ::1 ... drop)"
        else
            failures+=(" - Missing rule to drop IPv6 loopback spoofed traffic (ip6 saddr ::1 ... drop)")
        fi
    else
        echo " - IPv6 is disabled, skipping IPv6 loopback spoof check"
    fi
else
    echo " - Cannot determine IPv6 status, skipping IPv6 loopback spoof check"
fi

# Audit Result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_3_8() {
failures=()
input_line="$(nft list ruleset 2>/dev/null | grep 'hook input')"
forward_line="$(nft list ruleset 2>/dev/null | grep 'hook forward')"
output_line="$(nft list ruleset 2>/dev/null | grep 'hook output')"

# Check INPUT chain
if grep -q 'hook input' <<< "$input_line" && grep -q 'policy drop' <<< "$input_line"; then
    echo " - INPUT chain has 'policy drop'"
else
    failures+=(" - INPUT chain is missing or does not have 'policy drop'")
fi

# Check FORWARD chain
if grep -q 'hook forward' <<< "$forward_line" && grep -q 'policy drop' <<< "$forward_line"; then
    echo " - FORWARD chain has 'policy drop'"
else
    failures+=(" - FORWARD chain is missing or does not have 'policy drop'")
fi

# Check OUTPUT chain
if grep -q 'hook output' <<< "$output_line" && grep -q 'policy drop' <<< "$output_line"; then
    echo " - OUTPUT chain has 'policy drop'"
else
    failures+=(" - OUTPUT chain is missing or does not have 'policy drop'")
fi

# Audit Result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_3_9() {
if systemctl is-enabled nftables 2>/dev/null | grep -q '^enabled$'; then
    echo -e "\n- Audit Result:\n ** PASS **\n - nftables service is enabled"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - nftables service is not enabled"
fi
}

a__4_4_1_1() {
failures=()

if dpkg-query -s iptables &>/dev/null; then
    echo "- iptables is installed"
else
    failures+=(" - iptables is not installed")
fi

if dpkg-query -s iptables-persistent &>/dev/null; then
    echo "- iptables-persistent is installed"
else
    failures+=(" - iptables-persistent is not installed")
fi

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__4_4_1_2() {
# Check if nftables is installed
if dpkg-query -s nftables &>/dev/null; then
    # If installed, check that it is both disabled and inactive
    is_enabled=$(systemctl is-enabled nftables.service 2>/dev/null)
    is_active=$(systemctl is-active nftables.service 2>/dev/null)

    if [[ "$is_enabled" == "enabled" || "$is_active" == "active" ]]; then
        echo -e "\n - Audit Result:\n ** FAIL **"
        echo " - nftables is installed and either enabled or active"
        echo "- End List"
    else
        echo -e "\n - Audit Result:\n ** PASS **"
        echo " - nftables is installed but not enabled or active"
    fi
else
    echo -e "\n - Audit Result:\n ** PASS **"
    echo " - nftables is not installed"
fi
}

a__4_4_1_3() {
if ! dpkg-query -s ufw &>/dev/null; then
    echo -e "\n- Audit Result:\n ** PASS **\n - ufw is not installed\n- End List"
elif [[ "$(ufw status 2>/dev/null)" == "Status: inactive" ]]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - ufw is installed but status is inactive\n- End List"
elif [[ "$(systemctl is-enabled ufw 2>/dev/null)" != "enabled" ]]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - ufw is installed but ufw.service is not enabled\n- End List"
elif [[ "$(systemctl is-active ufw.service 2>/dev/null)" != "active" ]]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - ufw is installed but ufw.service is not active\n- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - ufw is installed, active, and enabled"
    echo "- End List"
fi
}

a__4_4_2_1() {
failures=()

input_policy=$(iptables -L | awk '/^Chain INPUT/ {print $4}')
[[ "$input_policy" != "DROP" && "$input_policy" != "REJECT" ]] && failures+=(" - INPUT chain policy is $input_policy (expected DROP or REJECT)")

forward_policy=$(iptables -L | awk '/^Chain FORWARD/ {print $4}')
[[ "$forward_policy" != "DROP" && "$forward_policy" != "REJECT" ]] && failures+=(" - FORWARD chain policy is $forward_policy (expected DROP or REJECT)")

output_policy=$(iptables -L | awk '/^Chain OUTPUT/ {print $4}')
[[ "$output_policy" != "DROP" && "$output_policy" != "REJECT" ]] && failures+=(" - OUTPUT chain policy is $output_policy (expected DROP or REJECT)")

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - All iptables default policies are set to DROP or REJECT\n- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__4_4_2_2() {
failures=()

# Check for INPUT rule: ACCEPT all on lo
if ! iptables -L INPUT -v -n | grep -qE '\bACCEPT\b.*\blo\b.*0\.0\.0\.0/0\s+0\.0\.0\.0/0'; then
    failures+=(" - Missing: ACCEPT all traffic on loopback interface (INPUT chain)")
fi

# Check for INPUT rule: DROP all traffic to 127.0.0.0/8
if ! iptables -L INPUT -v -n | grep -qE '\bDROP\b.*127\.0\.0\.0/8\s+0\.0\.0\.0/0'; then
    failures+=(" - Missing: DROP traffic to 127.0.0.0/8 on non-loopback interfaces (INPUT chain)")
fi

# Check for OUTPUT rule: ACCEPT all traffic from lo
if ! iptables -L OUTPUT -v -n | grep -qE '\bACCEPT\b.*\blo\b.*0\.0\.0\.0/0\s+0\.0\.0\.0/0'; then
    failures+=(" - Missing: ACCEPT all traffic from loopback interface (OUTPUT chain)")
fi

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - Loopback traffic is properly configured in iptables\n- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__4_4_3_1() {
failures=()

# Step 1: Check if IPv6 is disabled
ipv6_disabled="no"

# Kernel module check
if grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable; then
    ipv6_disabled="yes"
fi

# sysctl check
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
    ipv6_disabled="yes"
fi

if [ "$ipv6_disabled" = "yes" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - IPv6 is disabled on the system\n- End List"
    exit 0
fi

# Step 2: If IPv6 is enabled, check ip6tables default policies
input_policy=$(ip6tables -L | awk '/^Chain INPUT/ {print $4}')
[[ "$input_policy" != "DROP" && "$input_policy" != "REJECT" ]] && failures+=(" - INPUT chain policy is $input_policy (expected DROP or REJECT)")

forward_policy=$(ip6tables -L | awk '/^Chain FORWARD/ {print $4}')
[[ "$forward_policy" != "DROP" && "$forward_policy" != "REJECT" ]] && failures+=(" - FORWARD chain policy is $forward_policy (expected DROP or REJECT)")

output_policy=$(ip6tables -L | awk '/^Chain OUTPUT/ {print $4}')
[[ "$output_policy" != "DROP" && "$output_policy" != "REJECT" ]] && failures+=(" - OUTPUT chain policy is $output_policy (expected DROP or REJECT)")

# Report result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - ip6tables default policies are correctly set\n- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__4_4_3_2() {
failures=()

# Step 1: Check if IPv6 is disabled
ipv6_disabled="no"

if grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable; then
    ipv6_disabled="yes"
fi

if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs '^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b' &&
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs '^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b'; then
    ipv6_disabled="yes"
fi

if [ "$ipv6_disabled" = "yes" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - IPv6 is disabled on the system\n- End List"
    exit 0
fi

# Step 2: Check ip6tables rules if IPv6 is enabled

# Check for ACCEPT on lo in INPUT
if ! ip6tables -L INPUT -v -n | grep -qE '\bACCEPT\b.*\blo\b.*::/0\s+::/0'; then
    failures+=(" - Missing: ACCEPT all traffic on loopback interface (INPUT chain)")
fi

# Check for DROP ::1 in INPUT
if ! ip6tables -L INPUT -v -n | grep -qE '\bDROP\b.*::1\s+::/0'; then
    failures+=(" - Missing: DROP spoofed loopback traffic (::1) from non-loopback interfaces (INPUT chain)")
fi

# Check for ACCEPT on lo in OUTPUT
if ! ip6tables -L OUTPUT -v -n | grep -qE '\bACCEPT\b.*\blo\b.*::/0\s+::/0'; then
    failures+=(" - Missing: ACCEPT all traffic from loopback interface (OUTPUT chain)")
fi

# Final report
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - ip6tables loopback traffic is properly configured\n- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_1() {
a_output=()
    a_output2=()

    perm_mask='0177'
    maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"

    f_sshd_files_chk() {
        while IFS=: read -r l_mode l_user l_group; do
            a_out2=()

            if [ $((l_mode & perm_mask)) -gt 0 ]; then
                a_out2+=(
                    " - Is mode: \"$l_mode\""
                    "   Should be mode: \"$maxperm\" or more restrictive"
                )
            fi

            if [ "$l_user" != "root" ]; then
                a_out2+=(
                    " - Is owned by \"$l_user\""
                    "   Should be owned by \"root\""
                )
            fi

            if [ "$l_group" != "root" ]; then
                a_out2+=(
                    " - Is group owned by \"$l_group\""
                    "   Should be group owned by \"root\""
                )
            fi

            if [ "${#a_out2[@]}" -gt 0 ]; then
                a_output2+=(" - File: \"$l_file\":" "${a_out2[@]}")
            else
                a_output+=(
                    " - File: \"$l_file\":"
                    "   Correct: mode ($l_mode), owner ($l_user), group ($l_group)"
                )
            fi
        done < <(stat -Lc '%#a:%U:%G' "$l_file")
    }

    # Check main sshd config
    if [ -e "/etc/ssh/sshd_config" ]; then
        l_file="/etc/ssh/sshd_config"
        f_sshd_files_chk
    fi

    # Check any files in /etc/ssh/sshd_config.d with bad perms/ownership
    while IFS= read -r -d $'\0' l_file; do
        [ -e "$l_file" ] && f_sshd_files_chk
    done < <(find /etc/ssh/sshd_config.d -type f -name '*.conf' \( -perm /077 -o ! -user root -o ! -group root \) -print0 2>/dev/null)

    if [ "${#a_output2[@]}" -eq 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" "- End List"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        if [ "${#a_output[@]}" -gt 0 ]; then
            printf '%s\n' "" "- Correctly set:" "${a_output[@]}" "- End List"
        else
            echo "- End List"
        fi
    fi
}

a__5_1_10() {
failures=()
users_failed=()

# Check for presence of Match blocks
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

# Function to validate that the setting is exactly 'hostbasedauthentication no'
check_setting() {
    local config="$1"
    [[ "$config" =~ ^hostbasedauthentication[[:space:]]+no$ ]]
}

if [ -z "$match_present" ]; then
    # No Match blocks — check global sshd config
    config=$(sudo sshd -T 2>/dev/null | grep -i '^hostbasedauthentication')
    if check_setting "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - HostbasedAuthentication is set to 'no' globally"
        echo "- End List"
    else
        failures+=(" - HostbasedAuthentication is not set to 'no'")
        [ -n "$config" ] && failures+=("   Actual value: $config") || failures+=("   Directive not found")

        echo -e "\n- Audit Result:\n ** FAIL **"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
else
    # Match blocks present — validate setting for each real user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *false && "$shell" != *nologin ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^hostbasedauthentication')
            if ! check_setting "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have HostbasedAuthentication set to 'no'"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have HostbasedAuthentication set to 'no':"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_11() {
failures=()
users_failed=()

# Detect if Match blocks exist
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

# Function to validate that IgnoreRhosts is set to yes
check_ignorerhosts() {
    local config="$1"
    [[ "$config" =~ ^ignorerhosts[[:space:]]+yes$ ]]
}

if [ -z "$match_present" ]; then
    # No Match blocks — check global config
    config=$(sudo sshd -T 2>/dev/null | grep -i '^ignorerhosts')
    if check_ignorerhosts "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - IgnoreRhosts is set to 'yes' globally"
        echo "- End List"
    else
        failures+=(" - IgnoreRhosts is not set to 'yes'")
        [ -n "$config" ] && failures+=("   Actual value: $config") || failures+=("   Directive not found")

        echo -e "\n- Audit Result:\n ** FAIL **"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
else
    # Match blocks exist — check setting per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *false && "$shell" != *nologin ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^ignorerhosts')
            if ! check_ignorerhosts "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have IgnoreRhosts set to 'yes'"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have IgnoreRhosts set to 'yes':"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_12() {
failures=()

# Define the weak KEX algorithms to check for
weak_kex_regex='kexalgorithms\s+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b'

# Extract the KEX algorithms from sshd effective config
kex_line=$(sudo sshd -T 2>/dev/null | grep -Pi '^kexalgorithms\s+')

# Check for weak algorithms
if echo "$kex_line" | grep -Piq "$weak_kex_regex"; then
    failures+=(" - Weak Key Exchange algorithms found in SSH configuration:")
    failures+=("   $kex_line")
fi

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No weak Key Exchange algorithms are configured"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_13() {
failures=()

# Get the LoginGraceTime setting from the global sshd config
value=$(sudo sshd -T 2>/dev/null | grep -i '^logingracetime' | awk '{print $2}')

# If the setting is missing or not a number (or not in seconds), fail
if [[ -z "$value" ]]; then
    failures+=(" - LoginGraceTime is not set in global SSH configuration")
elif [[ ! "$value" =~ ^[0-9]+$ ]]; then
    failures+=(" - LoginGraceTime is not expressed in seconds: '$value'")
elif (( value < 1 || value > 60 )); then
    failures+=(" - LoginGraceTime is set to $value seconds — must be between 1 and 60")
fi

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - LoginGraceTime is correctly set to ${value} seconds"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_14() {
failures=()
users_failed=()

# Detect if Match blocks are present
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

# Acceptable values
valid_values=("INFO" "VERBOSE")

# Validate a given loglevel string
check_loglevel() {
    local val="$1"
    for level in "${valid_values[@]}"; do
        [[ "$val" =~ ^loglevel[[:space:]]+$level$ ]] && return 0
    done
    return 1
}

if [ -z "$match_present" ]; then
    # No Match blocks — check global sshd config
    config=$(sudo sshd -T 2>/dev/null | grep -i '^loglevel')
    if check_loglevel "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - LogLevel is set correctly: $config"
        echo "- End List"
    else
        failures+=(" - LogLevel is not set to INFO or VERBOSE")
        [ -n "$config" ] && failures+=("   Actual value: $config") || failures+=("   Directive not found")

        echo -e "\n- Audit Result:\n ** FAIL **"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
else
    # Match blocks present — check per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *nologin && "$shell" != *false ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^loglevel')
            if ! check_loglevel "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have LogLevel set to INFO or VERBOSE"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have LogLevel set to INFO or VERBOSE:"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_15() {
failures=()

# Weak MACs as defined in the audit
weak_macs_regex='macs\s+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b'

# Get MACs line from sshd -T
macs_line=$(sudo sshd -T 2>/dev/null | grep -Pi '^macs\s+')

# Check if weak MACs are found
if echo "$macs_line" | grep -Piq "$weak_macs_regex"; then
    failures+=(" - Weak MACs found in SSH configuration:")
    failures+=("   $macs_line")
fi

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No weak MACs are configured"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_16() {
failures=()
users_failed=()

# Detect Match blocks
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

check_maxauthtries() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]] && (( value <= 4 ))
}

if [ -z "$match_present" ]; then
    # No Match blocks — check global setting
    value=$(sudo sshd -T 2>/dev/null | grep -i '^maxauthtries' | awk '{print $2}')

    if check_maxauthtries "$value"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - MaxAuthTries is set to $value (≤ 4) globally"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        if [ -z "$value" ]; then
            echo " - MaxAuthTries not found in SSH configuration"
        else
            echo " - MaxAuthTries is set to $value — must be ≤ 4"
        fi
        echo "- End List"
    fi
else
    # Match blocks exist — validate per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *nologin && "$shell" != *false ]]; then
            value=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^maxauthtries' | awk '{print $2}')
            if ! check_maxauthtries "$value"; then
                users_failed+=("$username ($value)")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have MaxAuthTries set to 4 or less"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users exceed MaxAuthTries > 4:"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_17() {
failures=()
users_failed=()

# Check for insecure hardcoded values in config files
bad_config_lines=$(grep -Psi -- '^\h*MaxSessions\h+\"?(1[1-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

if [ -n "$bad_config_lines" ]; then
    failures+=(" - MaxSessions is set to > 10 in one or more config files:")
    failures+=("$bad_config_lines")
fi

# Check if Match blocks are present
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

check_maxsessions() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]] && (( value <= 10 ))
}

if [ -z "$match_present" ]; then
    # Global config check
    value=$(sudo sshd -T 2>/dev/null | grep -i '^maxsessions' | awk '{print $2}')
    if ! check_maxsessions "$value"; then
        failures+=(" - Global MaxSessions is set to $value (must be ≤ 10)")
    fi
else
    # Per-user check if Match blocks exist
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *nologin && "$shell" != *false ]]; then
            value=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^maxsessions' | awk '{print $2}')
            if ! check_maxsessions "$value"; then
                users_failed+=("$username ($value)")
            fi
        fi
    done < /etc/passwd
fi

# Output
if [ "${#failures[@]}" -eq 0 ] && [ "${#users_failed[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - MaxSessions is properly set (≤ 10) in all applicable configurations"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    [ "${#failures[@]}" -gt 0 ] && printf '%s\n' "${failures[@]}"
    if [ "${#users_failed[@]}" -gt 0 ]; then
        echo " - The following users have MaxSessions set > 10:"
        printf '   %s\n' "${users_failed[@]}"
    fi
    echo "- End List"
fi
}

a__5_1_18() {
failures=()

# Get the MaxStartups line from the global SSH config
value=$(sudo sshd -T 2>/dev/null | awk '$1 ~ /^maxstartups$/ { print $2 }')

# Split the value into parts and compare
if [[ "$value" =~ ^([0-9]+):([0-9]+):([0-9]+)$ ]]; then
    start=${BASH_REMATCH[1]}
    rate=${BASH_REMATCH[2]}
    full=${BASH_REMATCH[3]}

    # Fail if any component is greater than the max allowed
    if (( start > 10 || rate > 30 || full > 60 )); then
        failures+=(" - MaxStartups is set to $value (must be ≤ 10:30:60)")
    fi
else
    failures+=(" - MaxStartups is missing or not in expected format (n:r:f): '$value'")
fi

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - MaxStartups is set to $value (≤ 10:30:60)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_19() {
failures=()
users_failed=()

# Check if Match blocks are present
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

# Function to validate the setting
check_permit_empty_pw() {
    local val="$1"
    [[ "$val" =~ ^permitemptypasswords[[:space:]]+no$ ]]
}

if [ -z "$match_present" ]; then
    # No Match blocks — check global config
    config=$(sudo sshd -T 2>/dev/null | grep -i '^permitemptypasswords')
    if check_permit_empty_pw "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - PermitEmptyPasswords is set to 'no' globally"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - PermitEmptyPasswords is not set to 'no'"
        [ -n "$config" ] && echo "   Actual value: $config" || echo "   Directive not found"
        echo "- End List"
    fi
else
    # Match blocks present — check each real user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *nologin && "$shell" != *false ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^permitemptypasswords')
            if ! check_permit_empty_pw "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have PermitEmptyPasswords set to 'no'"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have PermitEmptyPasswords set to 'no':"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_2() {
a_output=()
    a_output2=()

    # Get possible SSH-related group name (e.g., ssh_keys or _ssh)
    l_ssh_group_name="$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) {print $1}' /etc/group)"

    f_file_chk() {
        while IFS=: read -r l_file_mode l_file_owner l_file_group; do
            a_out2=()

            if [ "$l_file_group" = "$l_ssh_group_name" ]; then
                l_pmask="0137"
            else
                l_pmask="0177"
            fi

            l_maxperm="$(printf '%o' $((0777 & ~$l_pmask)))"

            if [ $((l_file_mode & l_pmask)) -gt 0 ]; then
                a_out2+=(" - Mode: \"$l_file_mode\" should be \"$l_maxperm\" or more restrictive")
            fi

            if [ "$l_file_owner" != "root" ]; then
                a_out2+=(" - Owned by: \"$l_file_owner\" should be owned by \"root\"")
            fi

            if [[ ! "$l_file_group" =~ ($l_ssh_group_name|root) ]]; then
                a_out2+=(" - Group owned by: \"$l_file_group\" should be \"$l_ssh_group_name\" or \"root\"")
            fi

            if [ "${#a_out2[@]}" -gt 0 ]; then
                a_output2+=(" - File: \"$l_file\":" "${a_out2[@]}")
            else
                a_output+=(
                    " - File: \"$l_file\":"
                    "   Correct: mode ($l_file_mode), owner ($l_file_owner), group ($l_file_group)"
                )
            fi
        done < <(stat -Lc '%#a:%U:%G' "$l_file")
    }

    # Scan for files under /etc/ssh that look like OpenSSH private keys
    while IFS= read -r -d $'\0' l_file; do
        if ssh-keygen -lf "$l_file" &>/dev/null; then
            if file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?private\h+key\b'; then
                f_file_chk
            fi
        fi
    done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

    # Final audit result
    if [ "${#a_output2[@]}" -eq 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" "- End List"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        if [ "${#a_output[@]}" -gt 0 ]; then
            printf '%s\n' "" "- Correctly set:" "${a_output[@]}" "- End List"
        else
            echo "- End List"
        fi
    fi
}

a__5_1_20() {
failures=()
users_failed=()

# Check for Match block usage
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

# Validation function
check_permit_root_login() {
    local val="$1"
    [[ "$val" =~ ^permitrootlogin[[:space:]]+no$ ]]
}

if [ -z "$match_present" ]; then
    # Global config check
    config=$(sudo sshd -T 2>/dev/null | grep -i '^permitrootlogin')
    if check_permit_root_login "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - PermitRootLogin is set to 'no' globally"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - PermitRootLogin is not set to 'no'"
        [ -n "$config" ] && echo "   Actual value: $config" || echo "   Directive not found"
        echo "- End List"
    fi
else
    # Check Match block overrides per real user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *nologin && "$shell" != *false ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^permitrootlogin')
            if ! check_permit_root_login "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have PermitRootLogin set to 'no'"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have PermitRootLogin set to 'no':"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_21() {
failures=()

# Get PermitUserEnvironment setting
config=$(sudo sshd -T 2>/dev/null | grep -i '^permituserenvironment')

# Validate the setting
if [[ "$config" =~ ^permituserenvironment[[:space:]]+no$ ]]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - PermitUserEnvironment is set to 'no' globally"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - PermitUserEnvironment is not set to 'no'"
    [ -n "$config" ] && echo "   Actual value: $config" || echo "   Directive not found"
    echo "- End List"
fi
}

a__5_1_22() {
failures=()

# Get the UsePAM value from effective SSH config
config=$(sudo sshd -T 2>/dev/null | grep -i '^usepam')

# Check if it's exactly "usepam yes"
if [[ "$config" =~ ^usepam[[:space:]]+yes$ ]]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - UsePAM is set to 'yes' globally"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - UsePAM is not set to 'yes'"
    [ -n "$config" ] && echo "   Actual value: $config" || echo "   Directive not found"
    echo "- End List"
fi
}

a__5_1_3() {
a_output=()
    a_output2=()

    l_pmask="0133"
    l_maxperm="$(printf '%o' $((0777 & ~$l_pmask)))"

    f_file_chk() {
        while IFS=: read -r l_file_mode l_file_owner l_file_group; do
            a_out2=()

            if [ $((l_file_mode & l_pmask)) -gt 0 ]; then
                a_out2+=(" - Mode: \"$l_file_mode\" should be \"$l_maxperm\" or more restrictive")
            fi

            if [ "$l_file_owner" != "root" ]; then
                a_out2+=(" - Owned by: \"$l_file_owner\" should be owned by \"root\"")
            fi

            if [ "$l_file_group" != "root" ]; then
                a_out2+=(" - Group owned by: \"$l_file_group\" should be \"root\"")
            fi

            if [ "${#a_out2[@]}" -gt 0 ]; then
                a_output2+=(" - File: \"$l_file\":" "${a_out2[@]}")
            else
                a_output+=(
                    " - File: \"$l_file\":"
                    "   Correct: mode ($l_file_mode), owner ($l_file_owner), group ($l_file_group)"
                )
            fi
        done < <(stat -Lc '%#a:%U:%G' "$l_file")
    }

    while IFS= read -r -d $'\0' l_file; do
        if ssh-keygen -lf "$l_file" &>/dev/null; then
            if file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?public\h+key\b'; then
                f_file_chk
            fi
        fi
    done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

    if [ "${#a_output2[@]}" -eq 0 ]; then
        [ "${#a_output[@]}" -eq 0 ] && a_output+=(" - No OpenSSH public keys found")
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" "- End List"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        if [ "${#a_output[@]}" -gt 0 ]; then
            printf '%s\n' "" "- Correctly set:" "${a_output[@]}" "- End List"
        else
            echo "- End List"
        fi
    fi
}

a__5_1_4() {
#!/usr/bin/env bash

failures=()
users_failed=()

# Check if Match blocks exist
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

# Regex to match valid allow/deny directives
policy_regex='^\s*(allow|deny)(users|groups)\s+\S+'

# Function to validate a single sshd config line
validate_policy_line() {
    local config_output="$1"
    echo "$config_output" | grep -Piq "$policy_regex"
}

if [ -z "$match_present" ]; then
    # No Match blocks — global audit
    output=$(sudo sshd -T 2>/dev/null | grep -Pi "$policy_regex")
    if validate_policy_line "$output"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - SSH access policy (AllowUsers/Groups or DenyUsers/Groups) is configured globally:"
        echo "$output"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - No global AllowUsers, AllowGroups, DenyUsers, or DenyGroups configured in sshd_config"
        echo "- End List"
    fi
else
    # Match blocks present — audit per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *false && "$shell" != *nologin ]]; then
            user_output=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -Pi "$policy_regex")
            if ! validate_policy_line "$user_output"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All SSH users have access controls defined via Allow/Deny Users/Groups"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have AllowUsers/Groups or DenyUsers/Groups settings applied via sshd -T:"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_5() {
failures=()
users_failed=()
match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)
banner_regex='^banner\s+/\S+'

# Get OS name for policy content check
os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

# Helper to validate banner line and file content
validate_banner() {
    local banner_line="$1"
    local banner_file
    banner_file=$(awk '{print $2}' <<< "$banner_line")

    if [ ! -f "$banner_file" ]; then
        failures+=(" - Banner file does not exist: $banner_file")
        return 1
    fi

    if grep -Psiq -- '(\\v|\\r|\\m|\\s|\b'"$os_name"'\b)' "$banner_file"; then
        failures+=(" - Banner file $banner_file contains disallowed escape codes or OS name ($os_name)")
        return 1
    fi

    return 0
}

if [ -z "$match_present" ]; then
    # No Match blocks — global check
    banner_line=$(sudo sshd -T 2>/dev/null | grep -Pi "$banner_regex")

    if [ -z "$banner_line" ]; then
        failures+=(" - Global SSH banner is not set")
    else
        validate_banner "$banner_line" || true
    fi
else
    # Match blocks present — check per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *false && "$shell" != *nologin ]]; then
            banner_line=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -Pi "$banner_regex")
            if [ -z "$banner_line" ]; then
                users_failed+=("$username")
            else
                validate_banner "$banner_line" || users_failed+=("$username")
            fi
        fi
    done < /etc/passwd
fi

# Result output
if [ "${#failures[@]}" -eq 0 ] && [ "${#users_failed[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - SSH banner is set and conforms to policy"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    if [ "${#users_failed[@]}" -gt 0 ]; then
        echo " - The following users do NOT have a compliant banner set:"
        printf '   %s\n' "${users_failed[@]}"
    fi
    echo "- End List"
fi
}

a__5_1_6() {
failures=()

# Get ciphers line from sshd config
ciphers_line=$(sudo sshd -T 2>/dev/null | grep -Pi '^ciphers\s+')

# Define weak ciphers to detect
weak_ciphers_regex='(3des|blowfish|cast128|aes(128|192|256)-cbc|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se)\b'

# Check if weak ciphers are in use
if echo "$ciphers_line" | grep -Piq "$weak_ciphers_regex"; then
    failures+=(" - Weak cipher(s) found in sshd configuration:")
    failures+=("   $ciphers_line")
fi

# Special case: check if chacha20-poly1305@openssh.com is present
if echo "$ciphers_line" | grep -q 'chacha20-poly1305@openssh.com'; then
    failures+=(" - chacha20-poly1305@openssh.com is in use — review CVE-2023-48795 and ensure patching is applied")
fi

# Result output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No weak SSH ciphers found in sshd_config"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_7() {
failures=()
users_failed=()

match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

check_alive_settings() {
    local config_output="$1"
    local interval count

    interval=$(awk '/^clientaliveinterval/ {print $2}' <<< "$config_output")
    count=$(awk '/^clientalivecountmax/ {print $2}' <<< "$config_output")

    # Must both exist and be > 0
    if [[ -z "$interval" || -z "$count" || "$interval" -le 0 || "$count" -le 0 ]]; then
        return 1
    fi
    return 0
}

if [ -z "$match_present" ]; then
    config=$(sudo sshd -T 2>/dev/null | grep -Pi '^(clientaliveinterval|clientalivecountmax)')
    if check_alive_settings "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - ClientAliveInterval and ClientAliveCountMax are correctly set:"
        echo "$config"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - One or both values are missing or set to 0:"
        echo "$config"
        echo "- End List"
    fi
else
    # Match blocks — check per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *false && "$shell" != *nologin ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -Pi '^(clientaliveinterval|clientalivecountmax)')
            if ! check_alive_settings "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have ClientAliveInterval and ClientAliveCountMax > 0"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have valid ClientAlive settings:"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_1_8() {
failures=()

# Get the global disableforwarding setting
config=$(sudo sshd -T 2>/dev/null | grep -i '^disableforwarding')

# Check if it's explicitly set to yes
if [[ "$config" =~ ^disableforwarding[[:space:]]+yes$ ]]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - disableforwarding is set to yes globally"
    echo "- End List"
else
    failures+=(" - disableforwarding is not set to 'yes'")
    [ -n "$config" ] && failures+=("   Actual value: $config") || failures+=("   Directive not found")

    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_1_9() {
failures=()
users_failed=()

match_present=$(grep -iE '^match\s' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

check_gssapi_setting() {
    local config="$1"
    [[ "$config" =~ ^gssapiauthentication[[:space:]]+no$ ]]
}

if [ -z "$match_present" ]; then
    # No Match blocks — check global setting
    config=$(sudo sshd -T 2>/dev/null | grep -i '^gssapiauthentication')
    if check_gssapi_setting "$config"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - GSSAPIAuthentication is set to 'no' globally"
        echo "- End List"
    else
        failures+=(" - GSSAPIAuthentication is not set to 'no'")
        [ -n "$config" ] && failures+=("   Actual value: $config") || failures+=("   Directive not found")

        echo -e "\n- Audit Result:\n ** FAIL **"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
else
    # Match blocks exist — check per user
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$shell" != *false && "$shell" != *nologin ]]; then
            config=$(sudo sshd -T -C user="$username" 2>/dev/null | grep -i '^gssapiauthentication')
            if ! check_gssapi_setting "$config"; then
                users_failed+=("$username")
            fi
        fi
    done < /etc/passwd

    if [ "${#users_failed[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All users have GSSAPIAuthentication set to 'no'"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - The following users do NOT have GSSAPIAuthentication set to 'no':"
        printf '   %s\n' "${users_failed[@]}"
        echo "- End List"
    fi
fi
}

a__5_2_1() {
if dpkg-query -s sudo &>/dev/null; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - sudo is installed"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - sudo is NOT installed"
    echo "- End List"
fi
}

a__5_2_2() {
failures=()

# Check for presence of `Defaults use_pty`
if grep -rPi -- '^\s*Defaults\s+([^#\n\r]+,\s*)?use_pty\b' /etc/sudoers* 2>/dev/null | grep -q 'use_pty'; then
    :
else
    failures+=(" - Missing: Defaults use_pty")
fi

# Check that `Defaults !use_pty` is not set
if grep -rPi -- '^\s*Defaults\s+([^#\n\r]+,\s*)?!use_pty\b' /etc/sudoers* 2>/dev/null | grep -q '!use_pty'; then
    failures+=(" - Found: Defaults !use_pty — this disables pseudo-terminal enforcement")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - sudo is configured to require a pseudo-terminal (use_pty)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_2_3() {
#!/usr/bin/env bash

failures=()

# Look for Defaults logfile=<path> in /etc/sudoers or /etc/sudoers.d/*
logfile_line=$(grep -rPsi '^\s*Defaults\s+([^#]+,\s*)?logfile\s*=\s*("|'\''|)[^"'\'']+\2' /etc/sudoers* 2>/dev/null)

# Extract the configured path if found
logfile_path=$(echo "$logfile_line" | grep -Poi 'logfile\s*=\s*("?[^" ]+"?|'\''[^'\'']+'\'')' | awk -F= '{print $2}' | tr -d '"'\'' ')

# Validate
if [ -z "$logfile_path" ]; then
    failures+=(" - No 'Defaults logfile=' setting found in sudoers configuration")
elif [ "$logfile_path" != "/var/log/sudo.log" ]; then
    failures+=(" - 'Defaults logfile=' is set to '$logfile_path', expected: /var/log/sudo.log")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - 'Defaults logfile=\"/var/log/sudo.log\"' is correctly set"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_2_4() {
#!/usr/bin/env bash

failures=()
skipped=false

# --- Check if password authentication is in use ---

# SSH: is password authentication enabled?
ssh_pw_auth=$(sudo sshd -T 2>/dev/null | grep -i '^passwordauthentication' | awk '{print tolower($2)}')

# SSH: is PAM enabled?
ssh_usepam=$(sudo sshd -T 2>/dev/null | grep -i '^usepam' | awk '{print tolower($2)}')

# Any users with valid password hashes?
users_with_passwords=$(awk -F: '($2 !~ /^[!*]/) { print $1 }' /etc/shadow)

# If all show passwords are NOT used
if [[ "$ssh_pw_auth" = "no" && "$ssh_usepam" = "no" && -z "$users_with_passwords" ]]; then
    skipped=true
fi

# --- If password auth is in use, check for NOPASSWD usage ---
if [ "$skipped" = false ]; then
    mapfile -t nopasswd_lines < <(grep -r "^[^#].*NOPASSWD" /etc/sudoers* 2>/dev/null)

    if [ "${#nopasswd_lines[@]}" -gt 0 ]; then
        failures+=(" - Found NOPASSWD entries in sudoers configuration:")
        failures+=("${nopasswd_lines[@]}")
    fi
fi

# --- Output results ---
if [ "$skipped" = true ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Skipped: Password authentication is not used on this system"
    echo "- End List"
elif [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - sudo requires a password for privilege escalation"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_2_5() {
#!/usr/bin/env bash

failures=()

# Look for uncommented lines containing '!authenticate'
unauth_lines=$(grep -r "^[^#].*!authenticate" /etc/sudoers* 2>/dev/null)

if [ -n "$unauth_lines" ]; then
    failures+=(" - Found '!authenticate' in sudoers configuration (disables password prompt):")
    failures+=("$unauth_lines")
fi

# Output audit result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No '!authenticate' entries found — sudo requires re-authentication"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_2_6() {
failures=()

# Step 1: Look for explicit `timestamp_timeout` overrides
timeout_lines=$(grep -roP 'timestamp_timeout=\K-?[0-9]+' /etc/sudoers* 2>/dev/null)

if [ -n "$timeout_lines" ]; then
    # Validate each override found
    while read -r value; do
        if [[ "$value" =~ ^-?[0-9]+$ ]]; then
            if [ "$value" -eq -1 ] || [ "$value" -gt 15 ]; then
                failures+=(" - Found timestamp_timeout=$value in sudoers (must be ≤ 15, not -1)")
            fi
        fi
    done <<< "$timeout_lines"
else
    # Step 2: No override — check if sudo -V reports a compiled default
    default_timeout_line=$(sudo -V | grep -i "Authentication timestamp timeout")

    if [ -n "$default_timeout_line" ]; then
        # Parse timeout value only if the line is found
        default_timeout=$(echo "$default_timeout_line" | awk -F: '{print $2}' | tr -dc '0-9-')
        if [[ "$default_timeout" =~ ^-?[0-9]+$ ]]; then
            if [ "$default_timeout" -eq -1 ] || [ "$default_timeout" -gt 15 ]; then
                failures+=(" - Default timestamp timeout is $default_timeout minutes (must be ≤ 15, not -1)")
            fi
        else
            failures+=(" - Could not parse default timeout from sudo -V output")
        fi
    else
        # sudo -V doesn't report default; don't try to parse
        echo " - Note: sudo -V does not report default timestamp_timeout (likely Ubuntu)."
        echo " - Assuming system default applies. Recommend setting explicitly if unsure."
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - Skipped: timestamp_timeout not overridden and default not reported"
        echo "- End List"
        exit 0
    fi
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - sudo timestamp_timeout is 15 minutes or less"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_1_1() {
failures=()
required_version="1.5.3-5"

# Check if package is installed and get version
pkg_info=$(dpkg-query -s libpam-runtime 2>/dev/null | grep -P '^(Status|Version)\b')

status=$(echo "$pkg_info" | grep '^Status:' | awk '{print $4}')
installed_version=$(echo "$pkg_info" | grep '^Version:' | awk '{print $2}')

# Validate status
if [ "$status" != "installed" ]; then
    failures+=(" - libpam-runtime is not installed properly (Status: $status)")
elif ! dpkg --compare-versions "$installed_version" ge "$required_version"; then
    failures+=(" - Installed version is $installed_version, which is less than required $required_version")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - libpam-runtime version is $installed_version (meets minimum required $required_version)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_1_2() {
#!/usr/bin/env bash

failures=()
required_version="1.5.3-5"

# Get package info (status and version)
pkg_info=$(dpkg-query -s libpam-modules 2>/dev/null | grep -P '^(Status|Version)\b')

status=$(echo "$pkg_info" | grep '^Status:' | awk '{print $4}')
installed_version=$(echo "$pkg_info" | grep '^Version:' | awk '{print $2}')

# Validate
if [ "$status" != "installed" ]; then
    failures+=(" - libpam-modules is not installed properly (Status: $status)")
elif ! dpkg --compare-versions "$installed_version" ge "$required_version"; then
    failures+=(" - Installed version is $installed_version, which is less than required $required_version")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - libpam-modules version is $installed_version (meets minimum required $required_version)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_1_3() {
#!/usr/bin/env bash

failures=()

if dpkg-query -s libpam-pwquality &>/dev/null; then
    status_line=$(dpkg-query -s libpam-pwquality | grep -Pi '^Status:')
    version_line=$(dpkg-query -s libpam-pwquality | grep -Pi '^Version:')

    if ! grep -q 'install ok installed' <<< "$status_line"; then
        failures+=(" - libpam-pwquality is present but not properly installed (Status: $status_line)")
    fi

    echo -e " - Detected:\n   $status_line\n   $version_line"
else
    failures+=(" - libpam-pwquality is NOT installed")
fi

# Final output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - libpam-pwquality is installed and properly registered"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_2_1() {
#!/usr/bin/env bash

failures=()
pam_files=(account session auth password)

for file in "${pam_files[@]}"; do
    path="/etc/pam.d/common-$file"
    if grep -Pq '\bpam_unix\.so\b' "$path"; then
        :
    else
        failures+=(" - Missing pam_unix.so in: $path")
    fi
done

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_unix.so is present in all required PAM configuration files"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_2_2() {
#!/usr/bin/env bash

failures=()

# File paths
auth_file="/etc/pam.d/common-auth"
account_file="/etc/pam.d/common-account"

# Check pam_faillock.so preauth line
if ! grep -Pq '^\s*auth\s+requisite\s+pam_faillock\.so\s+preauth\b' "$auth_file"; then
    failures+=(" - Missing 'auth requisite pam_faillock.so preauth' in $auth_file")
fi

# Check pam_faillock.so authfail line
if ! grep -Pq '^\s*auth\s+\[.*default=die.*\]\s+pam_faillock\.so\s+authfail\b' "$auth_file"; then
    failures+=(" - Missing 'auth [default=die] pam_faillock.so authfail' in $auth_file")
fi

# Check pam_faillock.so in account
if ! grep -Pq '^\s*account\s+required\s+pam_faillock\.so\b' "$account_file"; then
    failures+=(" - Missing 'account required pam_faillock.so' in $account_file")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_faillock.so is properly configured in $auth_file and $account_file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_2_3() {
#!/usr/bin/env bash

failures=()

file="/etc/pam.d/common-password"

# Check for pam_pwquality.so in the common-password file
if grep -Pq '\bpam_pwquality\.so\b' "$file"; then
    :
else
    failures+=(" - pam_pwquality.so not found in $file")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_pwquality.so is present in $file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_2_4() {
#!/usr/bin/env bash

failures=()

file="/etc/pam.d/common-password"

# Check for pam_pwhistory.so presence
if grep -Pq '\bpam_pwhistory\.so\b' "$file"; then
    :
else
    failures+=(" - pam_pwhistory.so not found in $file")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_pwhistory.so is present in $file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_1_1() {
#!/usr/bin/env bash

failures=()

# -------- Check faillock.conf --------
faillock_conf="/etc/security/faillock.conf"
if [ -f "$faillock_conf" ]; then
    if grep -Pq '^\s*deny\s*=\s*[1-5]\b' "$faillock_conf"; then
        :
    else
        failures+=(" - 'deny' setting in $faillock_conf is missing or > 5")
    fi
else
    failures+=(" - $faillock_conf not found")
fi

# -------- Check pam_faillock in common-auth --------
pam_file="/etc/pam.d/common-auth"
if grep -Pq '^\s*auth\s+(requisite|required|sufficient)\s+pam_faillock\.so\s+.*\bdeny\s*=\s*(0|[6-9]|[1-9][0-9]+)\b' "$pam_file"; then
    failures+=(" - pam_faillock.so in $pam_file sets deny > 5, which violates policy")
fi

# -------- Output result --------
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - deny is set to 5 or fewer and complies with local policy"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_1_2() {
#!/usr/bin/env bash

failures=()

# -------- Check /etc/security/faillock.conf --------
faillock_conf="/etc/security/faillock.conf"

if [ -f "$faillock_conf" ]; then
    if grep -Pq '^\s*unlock_time\s*=\s*(0|9[0-9][0-9]|[1-9][0-9]{3,})\b' "$faillock_conf"; then
        :
    else
        failures+=(" - 'unlock_time' in $faillock_conf is missing or set to a value less than 900 (unless 0)")
    fi
else
    failures+=(" - $faillock_conf not found")
fi

# -------- Check pam_faillock.so lines in common-auth --------
pam_file="/etc/pam.d/common-auth"
if grep -Pq '^\s*auth\s+(requisite|required|sufficient)\s+pam_faillock\.so\s+.*\bunlock_time\s*=\s*([1-9]|[1-9][0-9]|[1-8][0-9][0-9])\b' "$pam_file"; then
    failures+=(" - pam_faillock.so in $pam_file sets unlock_time < 900 (and not 0)")
fi

# -------- Output result --------
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - unlock_time is 0 or ≥ 900 seconds in all applicable configurations"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_1_3() {
#!/usr/bin/env bash

failures=()
faillock_conf="/etc/security/faillock.conf"
pam_auth_file="/etc/pam.d/common-auth"

# --- 1. Check presence of even_deny_root or root_unlock_time ---
if grep -Pq '^\s*(even_deny_root|root_unlock_time\s*=\s*\d+)\b' "$faillock_conf"; then
    :
else
    failures+=(" - Neither 'even_deny_root' nor 'root_unlock_time' found in $faillock_conf")
fi

# --- 2. Check if root_unlock_time in faillock.conf is valid (≥ 60 if set) ---
if grep -Pq '^\s*root_unlock_time\s*=\s*([1-9]|[1-5][0-9])\b' "$faillock_conf"; then
    failures+=(" - root_unlock_time in $faillock_conf is set to less than 60 seconds (must be ≥ 60)")
fi

# --- 3. Check pam_faillock.so lines in common-auth for root_unlock_time < 60 ---
if grep -Pq '^\s*auth\s+[^#\n\r]+\s+pam_faillock\.so\s+[^#\n\r]*root_unlock_time\s*=\s*([1-9]|[1-5][0-9])\b' "$pam_auth_file"; then
    failures+=(" - pam_faillock.so in $pam_auth_file sets root_unlock_time < 60 seconds (must be ≥ 60)")
fi

# --- Final Output ---
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - even_deny_root and/or root_unlock_time is correctly configured"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_1() {
#!/usr/bin/env bash

failures=()

# --- 1. Check difok in pwquality.conf and .d/*.conf ---
config_files=("/etc/security/pwquality.conf" /etc/security/pwquality.conf.d/*.conf)

found_valid_difok=false
for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        if grep -Psiq '^\s*difok\s*=\s*([2-9]|[1-9][0-9]+)\b' "$file"; then
            found_valid_difok=true
            break
        fi
    fi
done

if ! $found_valid_difok; then
    failures+=(" - difok not found or set to less than 2 in pwquality configuration files")
fi

# --- 2. Ensure pam_pwquality.so does not override difok < 2 ---
pam_file="/etc/pam.d/common-password"
if grep -Psiq '^\s*password\s+(requisite|required|sufficient)\s+pam_pwquality\.so\s+[^#\n\r]*\bdifok\s*=\s*[01]\b' "$pam_file"; then
    failures+=(" - pam_pwquality.so in $pam_file sets difok < 2, which violates policy")
fi

# --- Final Output ---
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - difok is properly set to 2 or greater and not overridden improperly"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_2() {
#!/usr/bin/env bash

failures=()

# 1. Check for minlen >= 14 in pwquality.conf and related files
config_files=(/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

found_valid_minlen=false
for file in "${config_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Psiq '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' "$file"; then
        found_valid_minlen=true
        break
    fi
done

if ! $found_valid_minlen; then
    failures+=(" - No minlen ≥ 14 found in pwquality config files")
fi

# 2. Ensure pam_pwquality.so does NOT override minlen < 14 in common-password and system-auth
pam_files=(/etc/pam.d/common-password /etc/pam.d/system-auth)

for pam_file in "${pam_files[@]}"; do
    [ -f "$pam_file" ] || continue
    if grep -Psiq '^\s*password\s+(requisite|required|sufficient)\s+pam_pwquality\.so\s+[^#\n\r]*\bminlen\s*=\s*([0-9]|1[0-3])\b' "$pam_file"; then
        failures+=(" - pam_pwquality.so in $pam_file sets minlen < 14 (violates policy)")
    fi
done

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Password minlen is properly set to 14 or more characters"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_4() {
#!/usr/bin/env bash

failures=()

# Step 1: Check for valid maxrepeat value in pwquality config
config_files=(/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)
valid_maxrepeat_found=false

for file in "${config_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Psiq '^\s*maxrepeat\s*=\s*[1-3]\b' "$file"; then
        valid_maxrepeat_found=true
        break
    fi
done

if ! $valid_maxrepeat_found; then
    failures+=(" - No valid maxrepeat (1-3) found in pwquality configuration files")
fi

# Step 2: Ensure pam_pwquality.so does NOT override maxrepeat with invalid value
pam_file="/etc/pam.d/common-password"
if [ -f "$pam_file" ]; then
    if grep -Psiq '^\s*password\s+(requisite|required|sufficient)\s+pam_pwquality\.so\s+[^#\n\r]*\bmaxrepeat\s*=\s*(0|[4-9]|[1-9][0-9]+)\b' "$pam_file"; then
        failures+=(" - pam_pwquality.so in $pam_file overrides maxrepeat with 0 or >3 (violates policy)")
    fi
fi

# Final Result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - maxrepeat is set to a value between 1 and 3 and not overridden improperly"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_5() {
#!/usr/bin/env bash

failures=()

# --- Step 1: Check pwquality configuration files ---
config_files=(/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)
valid_found=false

for file in "${config_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Psiq '^\s*maxsequence\s*=\s*[1-3]\b' "$file"; then
        valid_found=true
        break
    fi
done

if ! $valid_found; then
    failures+=(" - No valid maxsequence (1–3) found in pwquality configuration files")
fi

# --- Step 2: Check for invalid overrides in PAM ---
pam_file="/etc/pam.d/common-password"

if [ -f "$pam_file" ]; then
    if grep -Psiq '^\s*password\s+(requisite|required|sufficient)\s+pam_pwquality\.so\s+[^#\n\r]*\bmaxsequence\s*=\s*(0|[4-9]|[1-9][0-9]+)\b' "$pam_file"; then
        failures+=(" - pam_pwquality.so in $pam_file overrides maxsequence with 0 or >3 (violates policy)")
    fi
fi

# --- Final Result ---
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - maxsequence is set between 1 and 3 and not overridden improperly"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_6() {
#!/usr/bin/env bash

failures=()

# --- 1. Check pwquality config files for dictcheck=0 ---
config_files=(/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

for file in "${config_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Psiq '^\s*dictcheck\s*=\s*0\b' "$file"; then
        failures+=(" - dictcheck=0 found in $file (dictionary check disabled)")
    fi
done

# --- 2. Check pam_pwquality.so in common-password for dictcheck=0 ---
pam_file="/etc/pam.d/common-password"
if [ -f "$pam_file" ]; then
    if grep -Psiq '^\s*password\s+(requisite|required|sufficient)\s+pam_pwquality\.so\s+[^#\n\r]*\bdictcheck\s*=\s*0\b' "$pam_file"; then
        failures+=(" - pam_pwquality.so in $pam_file sets dictcheck=0 (dictionary check disabled)")
    fi
fi

# --- Final Output ---
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - dictcheck is enabled (not set to 0 anywhere)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_7() {
#!/usr/bin/env bash

failures=()

# --- 1. Check pwquality configuration files for enforcing=0 ---
config_files=(/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

for file in "${config_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -PHsiq '^\s*enforcing\s*=\s*0\b' "$file"; then
        failures+=(" - enforcing=0 found in $file (password quality enforcement disabled)")
    fi
done

# --- 2. Check pam_pwquality.so for enforcing=0 ---
pam_file="/etc/pam.d/common-password"
if [ -f "$pam_file" ]; then
    if grep -PHsiq '^\s*password\s+[^#\n\r]+\s+pam_pwquality\.so\s+[^#\n\r]*\benforcing=0\b' "$pam_file"; then
        failures+=(" - pam_pwquality.so in $pam_file sets enforcing=0 (soft enforcement enabled)")
    fi
fi

# --- Final Output ---
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - enforcing is not set to 0 anywhere (password enforcement is active)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_2_8() {
#!/usr/bin/env bash

failures=()

# List of pwquality configuration files
config_files=(/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

found=false
for file in "${config_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Psiq '^\s*enforce_for_root\b' "$file"; then
        found=true
        break
    fi
done

# Evaluate result
if $found; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - enforce_for_root is enabled in a pwquality configuration file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - enforce_for_root is not enabled in any pwquality configuration file"
    echo "- End List"
fi
}

a__5_3_3_3_1() {
#!/usr/bin/env bash

failures=()

pam_file="/etc/pam.d/common-password"

if [ ! -f "$pam_file" ]; then
    failures+=(" - File $pam_file not found")
else
    # Extract remember=N value from pam_pwhistory.so line
    remember_line=$(grep -Pi '^\s*password\s+[^#\n\r]+\s+pam_pwhistory\.so\s+[^#\n\r]*remember=\d+' "$pam_file")

    if [ -n "$remember_line" ]; then
        remember_value=$(echo "$remember_line" | grep -Po 'remember=\K\d+')
        if [ "$remember_value" -lt 24 ]; then
            failures+=(" - remember=$remember_value is set on pam_pwhistory.so (must be ≥ 24)")
        fi
    else
        failures+=(" - pam_pwhistory.so line with remember=N not found in $pam_file")
    fi
fi

# Final output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_pwhistory.so uses remember=$remember_value (≥ 24) in $pam_file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_3_2() {
#!/usr/bin/env bash

failures=()

pam_file="/etc/pam.d/common-password"

if [ -f "$pam_file" ]; then
    # Search for enforce_for_root on a line with pam_pwhistory.so
    if grep -Psiq '^\s*password\s+[^#\n\r]+\s+pam_pwhistory\.so\s+[^#\n\r]*\benforce_for_root\b' "$pam_file"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - enforce_for_root is present on pam_pwhistory.so line"
        echo "- End List"
    else
        failures+=(" - pam_pwhistory.so does not include enforce_for_root in $pam_file")
    fi
else
    failures+=(" - $pam_file not found")
fi

# If there were any failures, print them
if [ "${#failures[@]}" -gt 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_3_3() {
#!/usr/bin/env bash

failures=()

pam_file="/etc/pam.d/common-password"

if [ -f "$pam_file" ]; then
    if grep -Psiq '^\s*password\s+[^#\n\r]+\s+pam_pwhistory\.so\s+[^#\n\r]*\buse_authtok\b' "$pam_file"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - use_authtok is present on pam_pwhistory.so line"
        echo "- End List"
    else
        failures+=(" - pam_pwhistory.so line does not include use_authtok in $pam_file")
    fi
else
    failures+=(" - $pam_file not found")
fi

# Report failures
if [ "${#failures[@]}" -gt 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_4_1() {
#!/usr/bin/env bash

failures=()

pam_files=(
    /etc/pam.d/common-password
    /etc/pam.d/common-auth
    /etc/pam.d/common-account
    /etc/pam.d/common-session
    /etc/pam.d/common-session-noninteractive
)

for file in "${pam_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Pqi '^\s*[^#\n\r]+\s+pam_unix\.so\b' "$file"; then
        if grep -Pqi '^\s*[^#\n\r]+\s+pam_unix\.so\b.*\bnullok\b' "$file"; then
            failures+=(" - nullok found in pam_unix.so line in $file")
        fi
    fi
done

# Result output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_unix.so does not include nullok in any common PAM file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_4_2() {
#!/usr/bin/env bash

failures=()

pam_files=(
    /etc/pam.d/common-password
    /etc/pam.d/common-auth
    /etc/pam.d/common-account
    /etc/pam.d/common-session
    /etc/pam.d/common-session-noninteractive
)

for file in "${pam_files[@]}"; do
    [ -f "$file" ] || continue

    # Check for pam_unix.so line with remember=N
    if grep -Pqi '^\s*[^#\n\r]+\s+pam_unix\.so\b.*\bremember=\d+\b' "$file"; then
        failures+=(" - pam_unix.so in $file uses remember= (should not)")
    fi
done

# Final output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - pam_unix.so does not use remember= in any monitored PAM file"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_4_3() {
#!/usr/bin/env bash

failures=()

pam_file="/etc/pam.d/common-password"

if [ -f "$pam_file" ]; then
    # Search for pam_unix.so line with either sha512 or yescrypt
    if grep -Pqi '^\s*password\s+[^#\n\r]+\s+pam_unix\.so\s+[^#\n\r]*(yescrypt|sha512)\b' "$pam_file"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - pam_unix.so in $pam_file uses a strong hashing algorithm (sha512 or yescrypt)"
        echo "- End List"
    else
        failures+=(" - pam_unix.so in $pam_file does not use a strong hashing algorithm (missing sha512 or yescrypt)")
    fi
else
    failures+=(" - $pam_file not found")
fi

# Final output
if [ "${#failures[@]}" -gt 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_3_3_4_4() {
#!/usr/bin/env bash

failures=()

pam_file="/etc/pam.d/common-password"

if [ -f "$pam_file" ]; then
    if grep -Pqi '^\s*password\s+[^#\n\r]+\s+pam_unix\.so\s+[^#\n\r]*\buse_authtok\b' "$pam_file"; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - pam_unix.so line includes use_authtok in $pam_file"
        echo "- End List"
    else
        failures+=(" - pam_unix.so line is missing use_authtok in $pam_file")
    fi
else
    failures+=(" - $pam_file not found")
fi

# Output result
if [ "${#failures[@]}" -gt 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_1_1() {
#!/usr/bin/env bash

failures=()

# 1. Check PASS_MAX_DAYS in /etc/login.defs
login_defs_value=$(grep -Pi '^\s*PASS_MAX_DAYS\s+\d+\b' /etc/login.defs | awk '{print $2}' | head -n1)

if [[ -z "$login_defs_value" ]]; then
    failures+=(" - PASS_MAX_DAYS not set in /etc/login.defs")
elif [[ "$login_defs_value" -gt 365 ]]; then
    failures+=(" - PASS_MAX_DAYS is set to $login_defs_value in /etc/login.defs (must be ≤ 365)")
fi

# 2. Check shadow file password max age for real users
while IFS=: read -r user pass _ _ max _; do
    if [[ "$pass" =~ ^\$.*\$ ]]; then
        if [[ -z "$max" || "$max" -gt 365 || "$max" -lt 1 ]]; then
            failures+=(" - User: $user has PASS_MAX_DAYS set to '$max' (must be 1–365)")
        fi
    fi
done < /etc/shadow

# Result output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - PASS_MAX_DAYS in /etc/login.defs and /etc/shadow is compliant (1–365)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_1_2() {
#!/usr/bin/env bash

failures=()

# 1. Check /etc/login.defs for PASS_MIN_DAYS > 0
login_defs_min=$(grep -Pi '^\s*PASS_MIN_DAYS\s+\d+\b' /etc/login.defs | awk '{print $2}' | head -n1)

if [ -z "$login_defs_min" ]; then
    failures+=(" - PASS_MIN_DAYS is not set in /etc/login.defs")
elif [ "$login_defs_min" -lt 1 ]; then
    failures+=(" - PASS_MIN_DAYS is set to $login_defs_min in /etc/login.defs (must be > 0)")
fi

# 2. Check each real user in /etc/shadow for min days > 0
while IFS=: read -r user pass _ min _; do
    if [[ "$pass" =~ ^\$.*\$ ]]; then
        if [ -z "$min" ] || [ "$min" -lt 1 ]; then
            failures+=(" - User: $user has PASS_MIN_DAYS = ${min:-unset} (must be > 0)")
        fi
    fi
done < /etc/shadow

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - PASS_MIN_DAYS is properly set in login.defs and for all valid users in /etc/shadow"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_1_3() {
#!/usr/bin/env bash

failures=()

# 1. Check PASS_WARN_AGE in /etc/login.defs
login_defs_warn=$(grep -Pi '^\s*PASS_WARN_AGE\s+\d+\b' /etc/login.defs | awk '{print $2}' | head -n1)

if [ -z "$login_defs_warn" ]; then
    failures+=(" - PASS_WARN_AGE is not set in /etc/login.defs")
elif [ "$login_defs_warn" -lt 7 ]; then
    failures+=(" - PASS_WARN_AGE is set to $login_defs_warn in /etc/login.defs (must be ≥ 7)")
fi

# 2. Check PASS_WARN_AGE for real users in /etc/shadow
while IFS=: read -r user pass _ _ _ warn _; do
    if [[ "$pass" =~ ^\$.*\$ ]]; then
        if [ -z "$warn" ] || [ "$warn" -lt 7 ]; then
            failures+=(" - User: $user has PASS_WARN_AGE = ${warn:-unset} (must be ≥ 7)")
        fi
    fi
done < /etc/shadow

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - PASS_WARN_AGE is compliant in /etc/login.defs and /etc/shadow (≥ 7)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_1_4() {
#!/usr/bin/env bash

failures=()

# Check ENCRYPT_METHOD in login.defs
method=$(grep -Pi '^\s*ENCRYPT_METHOD\s+\S+' /etc/login.defs | awk '{print toupper($2)}' | head -n1)

if [ -z "$method" ]; then
    failures+=(" - ENCRYPT_METHOD not set in /etc/login.defs")
elif [[ "$method" != "SHA512" && "$method" != "YESCRYPT" ]]; then
    failures+=(" - ENCRYPT_METHOD is set to \"$method\" (must be SHA512 or YESCRYPT)")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - ENCRYPT_METHOD is set to $method (strong hash)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_1_5() {
#!/usr/bin/env bash

failures=()

# Step 1: Check system default INACTIVE setting
default_inactive=$(useradd -D | grep -i 'INACTIVE' | awk -F= '{print $2}')

if [ -z "$default_inactive" ]; then
    failures+=(" - INACTIVE not set in useradd defaults")
elif [ "$default_inactive" -gt 45 ]; then
    failures+=(" - Default INACTIVE is $default_inactive (must be ≤ 45)")
fi

# Step 2: Check each real user’s INACTIVE field in /etc/shadow
while IFS=: read -r user pass _ _ _ _ inactive _; do
    if [[ "$pass" =~ ^\$.*\$ ]]; then
        if [ -z "$inactive" ] || [ "$inactive" -gt 45 ] || [ "$inactive" -lt 0 ]; then
            failures+=(" - User: $user has INACTIVE=${inactive:-unset} (must be 0–45)")
        fi
    fi
done < /etc/shadow

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - INACTIVE policy is compliant (≤ 45 days)"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_1_6() {
#!/usr/bin/env bash

failures=()

while IFS= read -r l_user; do
    # Get the raw last change date (skip if 'never')
    last_change_date=$(chage --list "$l_user" | grep '^Last password change' | cut -d: -f2 | grep -v 'never$' | xargs)

    if [ -n "$last_change_date" ]; then
        change_ts=$(date -d "$last_change_date" +%s 2>/dev/null)
        now_ts=$(date +%s)

        if [ "$change_ts" -gt "$now_ts" ]; then
            failures+=(" - User \"$l_user\" has future-dated password change: \"$last_change_date\"")
        fi
    fi
done < <(awk -F: '$2~/^\$.*\$/{print $1}' /etc/shadow)

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No users have future-dated password change entries"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_2_1() {
#!/usr/bin/env bash

failures=()

# Check for all users with UID 0
uid0_users=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd)

while IFS= read -r user; do
    if [ "$user" != "root" ]; then
        failures+=(" - User \"$user\" has UID 0 (only root should have UID 0)")
    fi
done <<< "$uid0_users"

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Only 'root' has UID 0"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_2_2() {
#!/usr/bin/env bash

failures=()

while IFS=: read -r username _ _ gid _; do
    if [ "$gid" -eq 0 ]; then
        case "$username" in
            root) continue ;;
            sync|shutdown|halt|operator) continue ;;
            *) failures+=(" - User \"$username\" has GID 0 (not allowed)") ;;
        esac
    fi
done < /etc/passwd

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Only root (and allowed exceptions) have GID 0"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_2_3() {
#!/usr/bin/env bash

failures=()

# Scan /etc/group for GID 0 entries
while IFS=: read -r groupname _ gid _; do
    if [ "$gid" -eq 0 ] && [ "$groupname" != "root" ]; then
        failures+=(" - Group \"$groupname\" has GID 0 (only 'root' should have GID 0)")
    fi
done < /etc/group

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Only the 'root' group is assigned GID 0"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_2_4() {
#!/usr/bin/env bash

failures=()

status=$(passwd -S root 2>/dev/null | awk '{print $2}')

if [[ "$status" == "P" || "$status" == "L" ]]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - User: \"root\" Password is status: $status"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - User: \"root\" has unexpected password status: $status (expected P or L)"
    echo "- End List"
fi
}

a__5_4_2_5() {
l_output2=""
    l_pmask="0022"
    l_maxperm="$(printf '%o' $((0777 & ~$l_pmask)))"
    l_root_path="$(sudo -Hiu root env | grep '^PATH=' | cut -d= -f2)"

    # Split path into array
    unset a_path_loc
    IFS=":" read -ra a_path_loc <<< "$l_root_path"

    # Check for dangerous patterns in PATH
    [[ "$l_root_path" =~ :: ]] && l_output2+="\n - root's PATH contains an empty directory (::)"
    [[ "$l_root_path" =~ :[[:space:]]*$ ]] && l_output2+="\n - root's PATH contains a trailing colon (:)"
    [[ "$l_root_path" =~ (^|:)\.(:|$) ]] && l_output2+="\n - root's PATH contains current directory (.)"

    # Check ownership and permissions of each directory
    for l_path in "${a_path_loc[@]}"; do
        if [ -d "$l_path" ]; then
            read -r l_fmode l_fown <<< "$(stat -Lc '%#a %U' "$l_path")"

            if [ "$l_fown" != "root" ]; then
                l_output2+="\n - Directory \"$l_path\" is owned by \"$l_fown\" (should be root)"
            fi

            if (( (l_fmode & l_pmask) > 0 )); then
                l_output2+="\n - Directory \"$l_path\" has permissions \"$l_fmode\" (should be $l_maxperm or more restrictive)"
            fi
        else
            l_output2+="\n - \"$l_path\" is not a valid directory"
        fi
    done

    # Output result
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - root's PATH is correctly configured"
        echo
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - Reason(s) for audit failure:$l_output2"
        echo
    fi
}

a__5_4_2_6() {
#!/usr/bin/env bash

failures=()

# Check .bash_profile and .bashrc for weak umask values
while IFS= read -r match; do
    failures+=(" - Weak umask found: $match")
done < <(grep -Psi -- '^\h*umask\h+((0[0-7]{3})|(u=[rwx]{0,3}(,g=[rwx]{0,3})?(,o=[rwx]{0,3})?))' /root/.bash_profile /root/.bashrc 2>/dev/null | \
    awk '
        {
            umask_line = tolower($0);
            if (umask_line ~ /umask\s+0[0-7]{3}/) {
                split(umask_line, a, /umask\s+/); val = a[2];
                if (val ~ /^[0-7]{3}$/ && val > 027) print $0;
            } else if (umask_line ~ /u=/ || umask_line ~ /g=/ || umask_line ~ /o=/) {
                # Check symbolic umask - only allow restrictive combinations
                if (umask_line ~ /o=[rwx]/ || umask_line ~ /g=w/) {
                    print $0;
                }
            }
        }
    ')

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - root's umask setting is 027 or more restrictive in /root/.bash_profile and /root/.bashrc"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__5_4_2_7() {
failures=()

    # Generate a pattern of valid login shells
    l_valid_shells="$(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -E 's,/,\\/,g' | paste -sd '|' -)"
    l_valid_shells="^(${l_valid_shells})$"

    # Get UID_MIN from /etc/login.defs
    uid_min=$(awk '/^\s*UID_MIN/ {print $2}' /etc/login.defs)

    # Audit system accounts
    while IFS=: read -r user _ uid _ _ _ shell; do
        if [[ "$user" =~ ^(root|halt|sync|shutdown|nfsnobody)$ ]]; then
            continue
        fi
        if (( uid < uid_min || uid == 65534 )); then
            if [[ "$shell" =~ $l_valid_shells ]]; then
                failures+=(" - Service account \"$user\" has a valid login shell: $shell")
            fi
        fi
    done < /etc/passwd

    # Output result
    if [ "${#failures[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - No system accounts (except exempted ones) have login shells"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - Reason(s) for audit failure:"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
}

a__5_4_2_8() {
failures=()

    # Build regex of valid login shells (e.g., /bin/bash, /bin/sh)
    valid_shells="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -E 's,/,\\/,g' | paste -sd '|' -))$"

    # Loop through accounts that have an invalid shell
    while IFS=: read -r user _ _ _ _ _ _ shell; do
        if [ "$user" = "root" ]; then
            continue
        fi
        if ! [[ "$shell" =~ $valid_shells ]]; then
            # Check if account is locked
            passwd_status=$(passwd -S "$user" 2>/dev/null)
            if [[ "$passwd_status" =~ ^$user\ ([^L]) ]]; then
                failures+=(" - Account \"$user\" does not have a valid login shell and is not locked")
            fi
        fi
    done < /etc/passwd

    # Output audit result
    if [ "${#failures[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All non-root accounts without a valid shell are locked"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - Reason(s) for audit failure:"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
}

a__5_4_3_1() {
#!/usr/bin/env bash

    failures=()

    if grep -Ps '^\h*([^#\n\r]+)?/nologin\b' /etc/shells > /dev/null; then
        failures+=(" - /etc/shells contains /nologin, which should not be listed as a valid shell")
    fi

    if [ "${#failures[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - /etc/shells does not include /nologin"
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        printf '%s\n' "${failures[@]}"
        echo "- End List"
    fi
}

a__5_4_3_2() {
failures=()
    valid_tmout_file=""
    invalid_tmout_line=""

    # Default global bashrc path (optional, may not exist)
    [ -f /etc/bashrc ] && BRC="/etc/bashrc"

    # Files to scan
    files=(/etc/profile /etc/profile.d/*.sh)
    [ -n "$BRC" ] && files+=("$BRC")

    # Step 1: Look for a secure TMOUT definition (<=900), readonly, and exported
    for f in "${files[@]}"; do
        [ -f "$f" ] || continue

        grep -Pq '^\s*([^#]+\s+)?TMOUT=(900|[1-8][0-9][0-9]|[1-9][0-9]?|[1-9])\b' "$f" || continue
        grep -Pq '^\s*([^#]+;\s*)?readonly\s+TMOUT(\s*;|\s*$)' "$f" || continue
        grep -Pq '^\s*([^#]+;\s*)?export\s+TMOUT(\s*;|\s*$)' "$f" || continue

        valid_tmout_file="$f"
        break
    done

    # Step 2: Look for insecure TMOUT values (too long or zero)
    invalid_tmout_line=$(grep -PHs '^\s*[^#]*TMOUT=(0+|9[0-9][1-9]|9[1-9][0-9]|[1-9][0-9]{3,})\b' "${files[@]}" 2>/dev/null)

    # Step 3: Report findings
    if [ -n "$valid_tmout_file" ] && [ -z "$invalid_tmout_line" ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - TMOUT is securely configured in: \"$valid_tmout_file\""
        echo "- End List"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        [ -z "$valid_tmout_file" ] && echo " - TMOUT is not securely set (or not marked readonly/exported)"
        [ -n "$invalid_tmout_line" ] && echo -e " - TMOUT is insecurely configured in:\n$invalid_tmout_line"
        echo "- End List"
    fi
}

a__5_4_3_3() {
good_output=""
    bad_output=""

    check_umask_in_file() {
        local file="$1"

        # Secure umask: 027, 077, symbolic equivalent like u=rw,g=r,o=
        if grep -Psiq -- '^\s*umask\s+(0?[0-7][2-7]7|u=rw[x]?,g=r,o=)\b' "$file"; then
            good_output+="\n - Secure umask found in \"$file\""
        elif grep -Psiq -- '^\s*umask\s+(([0-7]{3,4})|(u=[rwx]{1,3},)?(g=[wrx]{1,3},)?o=[wrx]{1,3})\b' "$file"; then
            bad_output+="\n - Insecure umask found in \"$file\""
        fi
    }

    # Check all relevant shell profile files
    while IFS= read -r -d '' file; do
        check_umask_in_file "$file"
    done < <(find /etc/profile.d/ -type f -name '*.sh' -print0)

    for f in /etc/profile /etc/bashrc /etc/bash.bashrc /etc/login.defs /etc/default/login; do
        [ -f "$f" ] && check_umask_in_file "$f"
    done

    # Check pam_umask in /etc/pam.d/postlogin
    if [ -f /etc/pam.d/postlogin ]; then
        if grep -Psiq -- '^\s*session\s+[^#\n]+\s+pam_umask\.so\s+[^#\n]*umask=(0?[0-7][2-7]7)\b' /etc/pam.d/postlogin; then
            good_output+="\n - Secure umask set via pam_umask in /etc/pam.d/postlogin"
        elif grep -Psiq -- '^\s*session\s+[^#\n]+\s+pam_umask\.so\s+[^#\n]*umask=([0-7]{3,4})\b' /etc/pam.d/postlogin; then
            bad_output+="\n - Insecure umask set via pam_umask in /etc/pam.d/postlogin"
        fi
    fi

    # If no secure or insecure settings were found, flag it
    if [[ -z "$good_output" && -z "$bad_output" ]]; then
        bad_output+="\n - umask is not explicitly configured"
    fi

    # Final report
    if [ -z "$bad_output" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n - * Correctly configured * :$good_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :$bad_output"
        [ -n "$good_output" ] && echo -e "\n- * Correctly configured * :$good_output\n"
    fi
}

a__6_1_1_1() {
failures=()

# Check if systemd-journald is statically enabled
if systemctl is-enabled systemd-journald.service 2>/dev/null | grep -qv '^static$'; then
    failures+=(" - systemd-journald is not 'static' (unexpected enablement state)")
fi

# Check if systemd-journald is active
if systemctl is-active systemd-journald.service 2>/dev/null | grep -qv '^active$'; then
    failures+=(" - systemd-journald is not running (expected 'active')")
fi

# Output audit result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - systemd-journald is statically enabled and active"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__6_1_1_4() {
l_output=""
    l_output2=""

    # Check the status of rsyslog and journald
    if systemctl is-active --quiet rsyslog; then
        l_output+="\n - rsyslog is in use"
        l_output+="\n - Follow the recommendations in the Configure rsyslog subsection only"
    elif systemctl is-active --quiet systemd-journald; then
        l_output+="\n - journald is in use"
        l_output+="\n - Follow the recommendations in the Configure journald subsection only"
    else
        l_output2+="\n - Unable to determine active system logging service"
        l_output2+="\n - Configure only ONE system logging service: rsyslog OR journald"
    fi

    # Output audit results
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **"
        echo -e "$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo -e " - Reason(s) for audit failure:$l_output2\n"
    fi
}

a__6_1_2_1_1() {
if dpkg-query -s systemd-journal-remote &>/dev/null; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - systemd-journal-remote is installed"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - systemd-journal-remote is not installed"
    echo "- End List"
fi
}

a__6_1_2_1_3() {
#!/usr/bin/env bash

failures=()

if systemctl is-enabled systemd-journal-upload.service 2>/dev/null | grep -qv '^enabled$'; then
    failures+=(" - systemd-journal-upload.service is not enabled")
fi

if systemctl is-active systemd-journal-upload.service 2>/dev/null | grep -qv '^active$'; then
    failures+=(" - systemd-journal-upload.service is not active")
fi

if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - systemd-journal-upload.service is enabled and active"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__6_1_2_1_4() {
#!/usr/bin/env bash

failures=()

# Check if either unit is enabled
enabled_units=$(systemctl is-enabled systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null | grep -P '^enabled')
if [ -n "$enabled_units" ]; then
    failures+=(" - The following unit(s) are enabled but should not be:\n$enabled_units")
fi

# Check if either unit is active
active_units=$(systemctl is-active systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null | grep -P '^active')
if [ -n "$active_units" ]; then
    failures+=(" - The following unit(s) are active but should not be:\n$active_units")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - systemd-journal-remote.service and .socket are neither active nor enabled"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%b\n' "${failures[@]}"
    echo "- End List"
fi
}

a__6_1_2_2() {
a_output=()
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journald.conf"
a_parameters=("ForwardToSyslog=no")

f_config_file_parameter_chk() {
    l_used_parameter_setting=""

    while IFS= read -r l_file; do
        l_file="$(tr -d '# ' <<< "$l_file")"
        l_used_parameter_setting="$(grep -PHs -- '^\s*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
        [ -n "$l_used_parameter_setting" ] && break
    done < <($l_analyze_cmd cat-config "$l_systemd_config_file" | tac | grep -Pio '^\s*#\s*/[^#\n\r\s]+\.conf\b')

    if [ -n "$l_used_parameter_setting" ]; then
        while IFS=: read -r l_file_name l_file_parameter; do
            while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " correctly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                    )
                else
                    a_output2+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " incorrectly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                        " Should be set to: \"$l_value_out\""
                    )
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        a_output2+=(
            " - Parameter: \"$l_parameter_name\" is not set in an included file"
            " *** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure ***"
        )
    fi
}

for l_input_parameter in "${a_parameters[@]}"; do
    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        f_config_file_parameter_chk
    done <<< "$l_input_parameter"
done

if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__6_1_2_3() {
a_output=()
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journald.conf"
a_parameters=("Compress=yes")

f_config_file_parameter_chk() {
    l_used_parameter_setting=""

    while IFS= read -r l_file; do
        l_file="$(tr -d '# ' <<< "$l_file")"
        l_used_parameter_setting="$(grep -PHs -- '^\s*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
        [ -n "$l_used_parameter_setting" ] && break
    done < <($l_analyze_cmd cat-config "$l_systemd_config_file" | tac | grep -Pio '^\s*#\s*/[^#\n\r\s]+\.conf\b')

    if [ -n "$l_used_parameter_setting" ]; then
        while IFS=: read -r l_file_name l_file_parameter; do
            while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " correctly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                    )
                else
                    a_output2+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " incorrectly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                        " Should be set to: \"$l_value_out\""
                    )
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        a_output2+=(
            " - Parameter: \"$l_parameter_name\" is not set in an included file"
            " *** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure ***"
        )
    fi
}

# Process each input parameter for validation
for l_input_parameter in "${a_parameters[@]}"; do
    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        f_config_file_parameter_chk
    done <<< "$l_input_parameter"
done

# Print results
if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" "- Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__6_1_2_4() {
a_output=()
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journald.conf"
a_parameters=("Storage=persistent")

f_config_file_parameter_chk() {
    l_used_parameter_setting=""

    while IFS= read -r l_file; do
        l_file="$(tr -d '# ' <<< "$l_file")"
        l_used_parameter_setting="$(grep -PHs -- '^\s*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
        [ -n "$l_used_parameter_setting" ] && break
    done < <(
        $l_analyze_cmd cat-config "$l_systemd_config_file" |
        tac | grep -Pio '^\s*#\s*/[^#\n\r\s]+\.conf\b'
    )

    if [ -n "$l_used_parameter_setting" ]; then
        while IFS=: read -r l_file_name l_file_parameter; do
            while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " correctly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                    )
                else
                    a_output2+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " incorrectly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                        " Should be set to: \"$l_value_out\""
                    )
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        a_output2+=(
            " - Parameter: \"$l_parameter_name\" is not set in an included file"
            " *** Note: \"$l_parameter_name\" may be set in a file that's ignored by the load procedure ***"
        )
    fi
}

# Iterate through parameters
for l_input_parameter in "${a_parameters[@]}"; do
    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        f_config_file_parameter_chk
    done <<< "$l_input_parameter"
done

# Output result
if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" "- Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__6_1_3_1() {
if dpkg-query -s rsyslog &>/dev/null; then
    echo -e "\n- Audit Result:"
    echo " ** PASS **"
    echo " - rsyslog is installed"
    echo "- End List"
else
    echo -e "\n- Audit Result:"
    echo " ** FAIL **"
    echo " - rsyslog is not installed"
    echo "- End List"
fi
}

a__6_1_3_2() {
#!/usr/bin/env bash

{
failures=()

# Check if rsyslog is active (used for logging)
if systemctl is-active --quiet rsyslog; then
    # Check if rsyslog is enabled
    if ! systemctl is-enabled rsyslog 2>/dev/null | grep -q '^enabled$'; then
        failures+=(" - rsyslog.service is not enabled")
    fi

    # Check if rsyslog is active
    if ! systemctl is-active rsyslog.service 2>/dev/null | grep -q '^active$'; then
        failures+=(" - rsyslog.service is not active")
    fi
else
    failures+=(" - rsyslog does not appear to be in use on the system")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:"
    echo " ** PASS **"
    echo " - rsyslog is in use, and the service is enabled and active"
    echo "- End List"
else
    echo -e "\n- Audit Result:"
    echo " ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}
}

a__6_1_3_3() {
a_output=()
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journald.conf"
a_parameters=("ForwardToSyslog=yes")

f_config_file_parameter_chk() {
    l_used_parameter_setting=""

    while IFS= read -r l_file; do
        l_file="$(tr -d '# ' <<< "$l_file")"
        l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
        [ -n "$l_used_parameter_setting" ] && break
    done < <($l_analyze_cmd cat-config "$l_systemd_config_file" | tac | grep -Pio '^\h*#\h*/[^#\n\r\h]+\.conf\b')

    if [ -n "$l_used_parameter_setting" ]; then
        while IFS=: read -r l_file_name l_file_parameter; do
            while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                    a_output+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " correctly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                    )
                else
                    a_output2+=(
                        " - Parameter: \"${l_file_parameter_name// /}\""
                        " incorrectly set to: \"${l_file_parameter_value// /}\""
                        " in the file: \"$l_file_name\""
                        " Should be set to: \"$l_value_out\""
                    )
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        a_output2+=(
            " - Parameter: \"$l_parameter_name\" is not set in an included file"
            " *** Note: \"$l_parameter_name\" may be set in a file that's ignored by load procedure ***"
        )
    fi
}

for l_input_parameter in "${a_parameters[@]}"; do
    while IFS="=" read -r l_parameter_name l_parameter_value; do
        l_parameter_name="${l_parameter_name// /}"
        l_parameter_value="${l_parameter_value// /}"
        l_value_out="${l_parameter_value//-/ through }"
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"
        f_config_file_parameter_chk
    done <<< "$l_input_parameter"
done

if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__6_1_3_4() {
a_output=()
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_include='\$IncludeConfig'
a_config_files=("rsyslog.conf")
l_parameter_name='\$FileCreateMode'

f_parameter_chk() {
    l_perm_mask="0137"
    l_maxperm="$(printf '%o' $((0777 & ~$l_perm_mask)))"
    l_mode="$(awk '{print $2}' <<< "$l_used_parameter_setting" | xargs)"

    if [ $((l_mode & l_perm_mask)) -gt 0 ]; then
        a_output2+=(
            " - Parameter: \"${l_parameter_name//\\/}\" is incorrectly set to mode: \"$l_mode\""
            " in the file: \"$l_file\""
            " Should be mode: \"$l_maxperm\" or more restrictive"
        )
    else
        a_output+=(
            " - Parameter: \"${l_parameter_name//\\/}\" is correctly set to mode: \"$l_mode\""
            " in the file: \"$l_file\""
            " Should be mode: \"$l_maxperm\" or more restrictive"
        )
    fi
}

# Resolve included config path
while IFS= read -r l_file; do
    l_conf_loc="$(awk '$1~/^\s*'"$l_include"'$/ {print $2}' "$(tr -d '# ' <<< "$l_file")" | tail -n 1)"
    [ -n "$l_conf_loc" ] && break
done < <($l_analyze_cmd cat-config "${a_config_files[*]}" | tac | grep -Pio '^\h*#\h*/[^#\n\r\h]+\.conf\b')

# Handle directory or glob includes
if [ -d "$l_conf_loc" ]; then
    l_dir="$l_conf_loc"
    l_ext="*"
elif grep -Psq '/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
    l_dir="$(dirname "$l_conf_loc")"
    l_ext="$(basename "$l_conf_loc")"
fi

# Add discovered included config files
while read -r -d $'\0' l_file_name; do
    [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

# Search for parameter in all config files
while IFS= read -r l_file; do
    l_file="$(tr -d '# ' <<< "$l_file")"
    l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
    [ -n "$l_used_parameter_setting" ] && break
done < <($l_analyze_cmd cat-config "${a_config_files[@]}" | tac | grep -Pio '^\h*#\h*/[^#\n\r\h]+\.conf\b')

# Evaluate parameter
if [ -n "$l_used_parameter_setting" ]; then
    f_parameter_chk
else
    a_output2+=(
        " - Parameter: \"${l_parameter_name//\\/}\" is not set in a configuration file"
        " *** Note: \"${l_parameter_name//\\/}\" may be set in a file that's ignored by load procedure ***"
    )
fi

# Final report
if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
}

a__6_1_3_7() {
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_include='\$IncludeConfig'
a_config_files=("rsyslog.conf")

# Step 1: Locate the IncludeConfig directive
while IFS= read -r l_file; do
    l_conf_loc="$(awk '$1 ~ /^\s*'"$l_include"'$/ {print $2}' "$(tr -d '# ' <<< "$l_file")" | tail -n 1)"
    [ -n "$l_conf_loc" ] && break
done < <($l_analyze_cmd cat-config "${a_config_files[@]}" | tac | grep -Pio '^\h*#\h*/[^#\n\r\h]+\.conf\b')

# Step 2: Resolve included path into config file paths
if [ -d "$l_conf_loc" ]; then
    l_dir="$l_conf_loc"
    l_ext="*"
elif grep -Psq '/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
    l_dir="$(dirname "$l_conf_loc")"
    l_ext="$(basename "$l_conf_loc")"
fi

# Step 3: Append resolved config files to scan list
while read -r -d $'\0' l_file_name; do
    [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

# Step 4: Check for both obsolete and advanced TCP input declarations
for l_logfile in "${a_config_files[@]}"; do
    for pattern in \
        '^\h*module\(load="?imtcp"?\)' \
        '^\h*input\(type="?imtcp"?\b'; do

        if l_match=$(grep -Psi -- "$pattern" "$l_logfile"); then
            a_output2+=(
                "- Entry to accept incoming logs found:"
                " \"$l_match\""
                " in: \"$l_logfile\""
            )
        fi
    done
done

# Step 5: Output result
if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" " - No entries to accept incoming logs found"
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
fi
}

a__6_1_4_1() {
a_output=()
a_output2=()

f_file_test_chk() {
    a_out2=()
    maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"

    if [ $((l_mode & perm_mask)) -gt 0 ]; then
        a_out2+=(" o Mode: \"$l_mode\" should be \"$maxperm\" or more restrictive")
    fi
    if [[ ! "$l_user" =~ $l_auser ]]; then
        a_out2+=(" o Owned by: \"$l_user\" and should be owned by \"${l_auser//|/ or }\"")
    fi
    if [[ ! "$l_group" =~ $l_agroup ]]; then
        a_out2+=(" o Group owned by: \"$l_group\" and should be group owned by \"${l_agroup//|/ or }\"")
    fi

    [ "${#a_out2[@]}" -gt 0 ] && a_output2+=(" - File: \"$l_fname\" is:" "${a_out2[@]}")
}

while IFS= read -r -d $'\0' l_file; do
    while IFS=: read -r l_fname l_mode l_user l_group; do
        base_dir="$(dirname "$l_fname")"
        base_name="$(basename "$l_fname")"

        if grep -Pq -- '/(apt)\h*$' <<< "$base_dir"; then
            perm_mask='0133'
            l_auser="root"
            l_agroup="(root|adm)"
            f_file_test_chk
        else
            case "$base_name" in
                lastlog | lastlog.* | wtmp | wtmp.* | wtmp-* | btmp | btmp.* | btmp-* | README)
                    perm_mask='0113'
                    l_auser="root"
                    l_agroup="(root|utmp)"
                    f_file_test_chk
                    ;;
                cloud-init.log* | localmessages* | waagent.log*)
                    perm_mask='0133'
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    f_file_test_chk
                    ;;
                secure | secure.* | secure-*)
                    perm_mask='0137'
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    f_file_test_chk
                    ;;
                auth.log | syslog | messages)
                    perm_mask='0137'
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    f_file_test_chk
                    ;;
                SSSD | sssd)
                    perm_mask='0117'
                    l_auser="(root|SSSD)"
                    l_agroup="(root|SSSD)"
                    f_file_test_chk
                    ;;
                gdm | gdm3)
                    perm_mask='0117'
                    l_auser="root"
                    l_agroup="(root|gdm|gdm3)"
                    f_file_test_chk
                    ;;
                *.journal | *.journal~)
                    perm_mask='0137'
                    l_auser="root"
                    l_agroup="(root|systemd-journal)"
                    f_file_test_chk
                    ;;
                *)
                    perm_mask='0137'
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    user_shell="$(awk -F: -v u="$l_user" '$1 == u { print $7 }' /etc/passwd)"
                    if [ "$l_user" = "root" ] || ! grep -Pq -- "^\s*${user_shell}\b" /etc/shells; then
                        [[ ! "$l_user" =~ $l_auser ]] && l_auser="(root|syslog|$l_user)"
                        [[ ! "$l_group" =~ $l_agroup ]] && l_agroup="(root|adm|$l_group)"
                    fi
                    f_file_test_chk
                    ;;
            esac
        fi
    done < <(stat -Lc '%n:%#a:%U:%G' "$l_file")
done < <(find -L /var/log -type f \( -perm /0137 -o ! -user root -o ! -group root \) -print0)

# Output result
if [ "${#a_output2[@]}" -eq 0 ]; then
    a_output+=(" - All files in \"/var/log/\" have appropriate permissions and ownership")
    printf '\n%s\n' "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '\n%s\n' "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}" ""
fi
}

a__6_2_1_1() {
#!/usr/bin/env bash

failures=()

# Check if auditd is installed
if dpkg-query -s auditd &>/dev/null; then
    echo " - auditd is installed"
else
    failures+=(" - auditd is NOT installed")
fi

# Check if audispd-plugins is installed
if dpkg-query -s audispd-plugins &>/dev/null; then
    echo " - audispd-plugins is installed"
else
    failures+=(" - audispd-plugins is NOT installed")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All required audit packages are installed"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_1_2() {
#!/usr/bin/env bash

failures=()

# Check if auditd is enabled
if systemctl is-enabled auditd 2>/dev/null | grep -q '^enabled$'; then
    echo " - auditd service is enabled"
else
    failures+=(" - auditd service is NOT enabled")
fi

# Check if auditd is active
if systemctl is-active auditd 2>/dev/null | grep -q '^active$'; then
    echo " - auditd service is active"
else
    failures+=(" - auditd service is NOT active")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - auditd is enabled and active"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_1_3() {
#!/usr/bin/env bash

failures=()

# Find all grub.cfg files and check linux lines missing audit=1
while IFS= read -r line; do
    failures+=(" - Missing 'audit=1': $line")
done < <(find /boot -type f -name 'grub.cfg' -exec grep -Ph '^\s*linux' {} + | grep -v 'audit=1')

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All GRUB kernel entries include 'audit=1'"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_1_4() {
#!/usr/bin/env bash

failures=()

# Search for grub.cfg files under /boot
grub_files=$(find /boot -type f -name 'grub.cfg' 2>/dev/null)

if [ -z "$grub_files" ]; then
    echo -e "\n- Audit Result:\n ** ERROR **"
    echo " - No grub.cfg file found under /boot — audit cannot be completed."
    echo "- End List"
    exit 0
fi

# Extract linux lines and check for missing audit_backlog_limit=
missing_lines=$(grep -Ph '^\h*linux' $grub_files 2>/dev/null | grep -Pv 'audit_backlog_limit=\d+\b')

if [ -n "$missing_lines" ]; then
    while IFS= read -r line; do
        failures+=(" - Missing audit_backlog_limit= on line: $line")
    done <<< "$missing_lines"
fi

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All kernel boot lines in grub.cfg have audit_backlog_limit set"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
fi
}

a__6_2_2_1() {
#!/usr/bin/env bash

failures=()

# Check if max_log_file is defined and has a numeric value
if ! grep -Pq '^\s*max_log_file\s*=\s*\d+\b' /etc/audit/auditd.conf; then
    failures+=(" - 'max_log_file' is not set or does not have a numeric value in /etc/audit/auditd.conf")
fi

# Output audit results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - 'max_log_file' is properly set in /etc/audit/auditd.conf"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_2_2() {
#!/usr/bin/env bash

failures=()

line=$(grep -Pi '^\h*max_log_file_action\h*=\h*\S+' /etc/audit/auditd.conf 2>/dev/null)

if [ -z "$line" ]; then
    failures+=(" - 'max_log_file_action' is not set in /etc/audit/auditd.conf")
elif ! grep -Piq '^\h*max_log_file_action\h*=\h*keep_logs\b' <<< "$line"; then
    failures+=(" - 'max_log_file_action' is set to: ${line#*=}, expected: keep_logs")
fi

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - max_log_file_action is correctly set to 'keep_logs'"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
echo "- End List"
}

a__6_2_2_3() {
#!/usr/bin/env bash

failures=()

# Check disk_full_action is set to 'halt' or 'single'
if ! grep -Piq '^\s*disk_full_action\s*=\s*(halt|single)\b' /etc/audit/auditd.conf; then
    failures+=(" - 'disk_full_action' is not set to 'halt' or 'single' in /etc/audit/auditd.conf")
fi

# Check disk_error_action is set to 'syslog', 'single', or 'halt'
if ! grep -Piq '^\s*disk_error_action\s*=\s*(syslog|single|halt)\b' /etc/audit/auditd.conf; then
    failures+=(" - 'disk_error_action' is not set to 'syslog', 'single', or 'halt' in /etc/audit/auditd.conf")
fi

# Output audit result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - 'disk_full_action' and 'disk_error_action' are configured correctly"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_2_4() {
#!/usr/bin/env bash

failures=()

# Audit: space_left_action should be email, exec, single, or halt
if ! grep -Pq '^\s*space_left_action\s*=\s*(email|exec|single|halt)\b' /etc/audit/auditd.conf; then
    failures+=(" - 'space_left_action' is not set to one of: email, exec, single, halt")
fi

# Audit: admin_space_left_action should be single or halt
if ! grep -Pq '^\s*admin_space_left_action\s*=\s*(single|halt)\b' /etc/audit/auditd.conf; then
    failures+=(" - 'admin_space_left_action' is not set to 'single' or 'halt'")
fi

# Report result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - 'space_left_action' and 'admin_space_left_action' are set correctly"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_1() {
#!/usr/bin/env bash

failures=()

# Define expected audit rules
expected_rules=(
  "-w /etc/sudoers -p wa -k scope"
  "-w /etc/sudoers.d -p wa -k scope"
)

# Normalize whitespace
normalize_rule() {
  sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//'
}

# Get on-disk rules
ondisk_rules=$(awk '/^ *-w/ && /\/etc\/sudoers/ && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules 2>/dev/null | normalize_rule)

# Get active rules
active_rules=$(auditctl -l 2>/dev/null | awk '/^ *-w/ && /\/etc\/sudoers/ && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' | normalize_rule)

# Function to safely check presence
contains_rule() {
  rule="$1"
  input="$2"
  echo "$input" | grep -Fqx -- "$rule"
}

# Check on-disk rules
for rule in "${expected_rules[@]}"; do
  if ! contains_rule "$rule" "$ondisk_rules"; then
    failures+=(" - On-disk rule missing or incorrect: $rule")
  fi
done

# Check active rules
for rule in "${expected_rules[@]}"; do
  if ! contains_rule "$rule" "$active_rules"; then
    failures+=(" - Active audit rule missing or incorrect: $rule")
  fi
done

# Output
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All required audit rules are present (on-disk and active)"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  echo " - Reason(s) for audit failure:"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_10() {
#!/usr/bin/env bash

failures=()
expected_rules=(
  "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=unset -F key=mounts"
  "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=unset -F key=mounts"
)

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

# On-disk rules
ondisk=$(awk "/^ *-a *always,exit/ \
&&/ -F *arch=b(32|64)/ \
&&(/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) \
&&/ -F *auid>=$UID_MIN/ \
&&/ -S/ && /mount/ \
&&(/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)" /etc/audit/rules.d/*.rules 2>/dev/null)

# Running configuration
runtime=$(auditctl -l | awk "/^ *-a *always,exit/ \
&&/ -F *arch=b(32|64)/ \
&&(/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) \
&&/ -F *auid>=$UID_MIN/ \
&&/ -S/ && /mount/ \
&&(/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)")

# Compare
for rule in "${expected_rules[@]}"; do
  grep -Fq -- "$rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $rule")
  grep -Fq -- "$rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $rule")
done

# Output
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All required mount syscall audit rules are present (on-disk and active)"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_11() {
#!/usr/bin/env bash

failures=()
expected_rules=(
  "-w /var/run/utmp -p wa -k session"
  "-w /var/log/wtmp -p wa -k session"
  "-w /var/log/btmp -p wa -k session"
)

# On-disk audit rule check
ondisk=$(awk '/^ *-w/ \
&&(/\/var\/run\/utmp/ || /\/var\/log\/wtmp/ || /\/var\/log\/btmp/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules 2>/dev/null)

# Active audit rules check
runtime=$(auditctl -l | awk '/^ *-w/ \
&&(/\/var\/run\/utmp/ || /\/var\/log\/wtmp/ || /\/var\/log\/btmp/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)')

# Compare
for rule in "${expected_rules[@]}"; do
  grep -Fq -- "$rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $rule")
  grep -Fq -- "$rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $rule")
done

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All required session tracking file audit rules are present"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_12() {
#!/usr/bin/env bash

failures=()
expected_rules=(
  "-w /var/log/lastlog -p wa -k logins"
  "-w /var/run/faillock -p wa -k logins"
)

# Check on-disk rules
ondisk=$(awk '/^ *-w/ \
&&(/\/var\/log\/lastlog/ || /\/var\/run\/faillock/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules 2>/dev/null)

# Check runtime rules
runtime=$(auditctl -l | awk '/^ *-w/ \
&&(/\/var\/log\/lastlog/ || /\/var\/run\/faillock/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)')

# Compare expected rules with actual output
for rule in "${expected_rules[@]}"; do
  grep -Fq -- "$rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $rule")
  grep -Fq -- "$rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $rule")
done

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - Audit rules for login tracking files are correctly configured"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_13() {
#!/usr/bin/env bash

failures=()

# Get UID_MIN from login.defs
UID_MIN=$(awk '/^\s*UID_MIN/ { print $2 }' /etc/login.defs)

expected_rules=(
  "-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=${UID_MIN} -F auid!=unset -k delete"
  "-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat -F auid>=${UID_MIN} -F auid!=unset -k delete"
)

# Get on-disk audit rules
ondisk=$(grep -P '^\s*-a\s+always,exit' /etc/audit/rules.d/*.rules 2>/dev/null |
         grep -P '\s+-F\s+arch=b(32|64)' |
         grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
         grep -P "\s+-F\s+auid>=${UID_MIN}" |
         grep -P '\s+-S\s+.*(unlink|unlinkat|rename|renameat)' |
         grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Get runtime audit rules
runtime=$(auditctl -l 2>/dev/null |
          grep -P '^\s*-a\s+always,exit' |
          grep -P '\s+-F\s+arch=b(32|64)' |
          grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
          grep -P "\s+-F\s+auid>=${UID_MIN}" |
          grep -P '\s+-S\s+.*(unlink|unlinkat|rename|renameat)' |
          grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Compare expected rules with actual output
for rule in "${expected_rules[@]}"; do
  grep -Fq -- "$rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $rule")
  grep -Fq -- "$rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $rule")
done

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - File deletion syscalls are properly audited"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_14() {
#!/usr/bin/env bash

failures=()

expected_rules=(
  "-w /etc/apparmor/ -p wa -k MAC-policy"
  "-w /etc/apparmor.d/ -p wa -k MAC-policy"
)

# On-disk rules check
ondisk=$(grep -hP '^\s*-w\s+/etc/apparmor(\.d)?/' /etc/audit/rules.d/*.rules 2>/dev/null |
         grep -P '\s+-p\s*wa' |
         grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Running config rules check
runtime=$(auditctl -l 2>/dev/null |
          grep -P '^\s*-w\s+/etc/apparmor(\.d)?/' |
          grep -P '\s+-p\s*wa' |
          grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Compare expected rules
for rule in "${expected_rules[@]}"; do
  grep -Fq -- "$rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $rule")
  grep -Fq -- "$rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $rule")
done

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - AppArmor audit rules are correctly configured"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_15() {
#!/usr/bin/env bash

failures=()

expected="-a always,exit -F path=/usr/bin/chcon -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"

# Get UID_MIN
UID_MIN=$(awk '/^\s*UID_MIN/ { print $2 }' /etc/login.defs)

# On-disk rules check
ondisk=$(grep -P '^\s*-a\s+always,exit' /etc/audit/rules.d/*.rules 2>/dev/null |
         grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
         grep -P "\s+-F\s+auid>=${UID_MIN}" |
         grep -P '\s+-F\s+perm=x' |
         grep -P '\s+-F\s+path=/usr/bin/chcon' |
         grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Running audit config check
runtime=$(auditctl -l 2>/dev/null |
          grep -P '^\s*-a\s+always,exit' |
          grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
          grep -P "\s+-F\s+auid>=${UID_MIN}" |
          grep -P '\s+-F\s+perm=x' |
          grep -P '\s+-F\s+path=/usr/bin/chcon' |
          grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Rule existence validation
grep -Fq -- "$expected" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $expected")
grep -Fq -- "$expected" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $expected")

# Result output
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - Auditing of /usr/bin/chcon execution is correctly configured"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_16() {
#!/usr/bin/env bash

failures=()

expected="-a always,exit -F path=/usr/bin/setfacl -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"

# Extract UID_MIN from login.defs
UID_MIN=$(awk '/^\s*UID_MIN/ { print $2 }' /etc/login.defs)

# On-disk audit rule check
ondisk=$(grep -P '^\s*-a\s+always,exit' /etc/audit/rules.d/*.rules 2>/dev/null |
         grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
         grep -P "\s+-F\s+auid>=${UID_MIN}" |
         grep -P '\s+-F\s+perm=x' |
         grep -P '\s+-F\s+path=/usr/bin/setfacl' |
         grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Runtime audit rule check
runtime=$(auditctl -l 2>/dev/null |
          grep -P '^\s*-a\s+always,exit' |
          grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
          grep -P "\s+-F\s+auid>=${UID_MIN}" |
          grep -P '\s+-F\s+perm=x' |
          grep -P '\s+-F\s+path=/usr/bin/setfacl' |
          grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Validation
grep -Fq -- "$expected" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $expected")
grep -Fq -- "$expected" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $expected")

# Result Output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Auditing of /usr/bin/setfacl execution is correctly configured"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_17() {
#!/usr/bin/env bash

failures=()

expected="-a always,exit -F path=/usr/bin/chacl -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"

# Get UID_MIN from /etc/login.defs
UID_MIN=$(awk '/^\s*UID_MIN/ { print $2 }' /etc/login.defs)

# Check on-disk rules
ondisk=$(grep -P '^\s*-a\s+always,exit' /etc/audit/rules.d/*.rules 2>/dev/null |
         grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
         grep -P "\s+-F\s+auid>=${UID_MIN}" |
         grep -P '\s+-F\s+perm=x' |
         grep -P '\s+-F\s+path=/usr/bin/chacl' |
         grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Check running audit configuration
runtime=$(auditctl -l 2>/dev/null |
          grep -P '^\s*-a\s+always,exit' |
          grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
          grep -P "\s+-F\s+auid>=${UID_MIN}" |
          grep -P '\s+-F\s+perm=x' |
          grep -P '\s+-F\s+path=/usr/bin/chacl' |
          grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Validate expected rule presence
grep -Fq -- "$expected" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $expected")
grep -Fq -- "$expected" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $expected")

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Auditing of /usr/bin/chacl execution is correctly configured"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_18() {
#!/usr/bin/env bash

# Initialize array to store any failures
failures=()

# Define expected audit rule string
expected_rule="-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=1000 -F auid!=unset -k usermod"

# Get UID_MIN from login.defs
UID_MIN=$(awk '/^\s*UID_MIN/ { print $2 }' /etc/login.defs)

# Check on-disk rules
ondisk=$(grep -P '^\s*-a\s+always,exit' /etc/audit/rules.d/*.rules 2>/dev/null |
         grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
         grep -P "\s+-F\s+auid>=${UID_MIN}" |
         grep -P '\s+-F\s+perm=x' |
         grep -P '\s+-F\s+path=/usr/sbin/usermod' |
         grep -P '\s+(-k\s+\S+|\s+key=\S+)')
        
# Check active running configuration
runtime=$(auditctl -l 2>/dev/null |
          grep -P '^\s*-a\s+always,exit' |
          grep -P '\s+-F\s+auid!=(unset|-1|4294967295)' |
          grep -P "\s+-F\s+auid>=${UID_MIN}" |
          grep -P '\s+-F\s+perm=x' |
          grep -P '\s+-F\s+path=/usr/sbin/usermod' |
          grep -P '\s+(-k\s+\S+|\s+key=\S+)')

# Evaluate results
grep -Fq -- "$expected_rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $expected_rule")
grep -Fq -- "$expected_rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $expected_rule")

# Output result
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Auditing of /usr/sbin/usermod execution is correctly configured"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_19() {
#!/usr/bin/env bash
{
failures=()
UID_MIN=$(awk '/^\s*UID_MIN/ { print $2 }' /etc/login.defs)

# --- On-Disk Configuration Checks ---
expected_syscall="-a always,exit -F arch=b64 -S create_module,init_module,delete_module,query_module,finit_module -F auid>=1000 -F auid!=unset -k kernel_modules"
expected_kmod_exec="-a always,exit -F path=/usr/bin/kmod -F perm=x -F auid>=1000 -F auid!=unset -k kernel_modules"

ondisk_syscall=$(awk '
    /^ *-a *always,exit/ &&
    (/arch=b32/ || /arch=b64/) &&
    (/ -F auid!=unset/ || / -F auid!=-1/ || / -F auid!=4294967295/) &&
    / -S/ &&
    (/init_module/ || /finit_module/ || /delete_module/ || /create_module/ || /query_module/) &&
    / -k /
' /etc/audit/rules.d/*.rules 2>/dev/null)

ondisk_kmod=$(awk -v uid_min="$UID_MIN" '
    /^ *-a *always,exit/ &&
    (/ -F auid!=unset/ || / -F auid!=-1/ || / -F auid!=4294967295/) &&
    $0 ~ "-F auid>=" uid_min &&
    / -F perm=x/ &&
    / -F path=\/usr\/bin\/kmod/ &&
    / -k /
' /etc/audit/rules.d/*.rules 2>/dev/null)

grep -Fq -- "$expected_syscall" <<< "$ondisk_syscall" || failures+=(" - On-disk syscall rule missing or incorrect: $expected_syscall")
grep -Fq -- "$expected_kmod_exec" <<< "$ondisk_kmod"   || failures+=(" - On-disk kmod rule missing or incorrect: $expected_kmod_exec")

# --- Runtime Configuration Checks ---
runtime_syscall=$(auditctl -l 2>/dev/null | awk '
    /^ *-a *always,exit/ &&
    (/arch=b32/ || /arch=b64/) &&
    (/ -F auid!=unset/ || / -F auid!=-1/ || / -F auid!=4294967295/) &&
    / -S/ &&
    (/init_module/ || /finit_module/ || /delete_module/ || /create_module/ || /query_module/) &&
    / -k /
')

runtime_kmod=$(auditctl -l 2>/dev/null | awk -v uid_min="$UID_MIN" '
    /^ *-a *always,exit/ &&
    (/ -F auid!=unset/ || / -F auid!=-1/ || / -F auid!=4294967295/) &&
    $0 ~ "-F auid>=" uid_min &&
    / -F perm=x/ &&
    / -F path=\/usr\/bin\/kmod/ &&
    / -k /
')

grep -Fq -- "$expected_syscall" <<< "$runtime_syscall" || failures+=(" - Active syscall rule missing or incorrect: $expected_syscall")
grep -Fq -- "$expected_kmod_exec" <<< "$runtime_kmod"   || failures+=(" - Active kmod rule missing or incorrect: $expected_kmod_exec")

# --- Symlink Audit for KMOD tools ---
symlink_issues=()
kmod_target=$(readlink -f /bin/kmod)
for tool in /usr/sbin/lsmod /usr/sbin/rmmod /usr/sbin/insmod /usr/sbin/modinfo /usr/sbin/modprobe /usr/sbin/depmod; do
    if [ "$(readlink -f "$tool")" != "$kmod_target" ]; then
        symlink_issues+=(" - Symlink issue: \"$tool\" does not point to /bin/kmod")
    fi
done

# --- Final Output ---
if [ ${#failures[@]} -eq 0 ] && [ ${#symlink_issues[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All kernel module syscall auditing and symlinks are properly configured"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}" "${symlink_issues[@]}"
fi
}
}

a__6_2_3_2() {
failures=()

expected_rules=(
  "-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
  "-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
)

# Normalize input lines for safe string matching
normalize() {
  sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

# Capture on-disk rules
ondisk_rules=$(awk '
  /^ *-a *always,exit/ &&
  / -F *arch=b(32|64)/ &&
  (/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) &&
  (/ -C *euid!=uid/ || / -C *uid!=euid/) &&
  / -S *execve/ &&
  (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)
' /etc/audit/rules.d/*.rules 2>/dev/null | normalize)

# Capture active rules
active_rules=$(auditctl -l 2>/dev/null | awk '
  /^ *-a *always,exit/ &&
  / -F *arch=b(32|64)/ &&
  (/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) &&
  (/ -C *euid!=uid/ || / -C *uid!=euid/) &&
  / -S *execve/ &&
  (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)
' | normalize)

# Helper to match expected rules
contains() {
  grep -Fqx -- "$1"
}

# Validate on-disk
for rule in "${expected_rules[@]}"; do
  if ! contains "$rule" <<< "$ondisk_rules"; then
    failures+=(" - On-disk rule missing or incorrect: $rule")
  fi
done

# Validate active
for rule in "${expected_rules[@]}"; do
  if ! contains "$rule" <<< "$active_rules"; then
    failures+=(" - Active audit rule missing or incorrect: $rule")
  fi
done

# Output
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All expected user_emulation audit rules are present"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  echo " - Reason(s) for audit failure:"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_20() {
failures=()

expected="-e 2"
actual=$(grep -Ph -- '^\h*-e\h+2\b' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)

if [ "$actual" = "$expected" ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - Immutable audit flag is correctly set: $actual"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Immutable audit flag is missing or incorrect. Expected: \"$expected\", Found: \"${actual:-None}\""
fi
}

a__6_2_3_3() {
failures=()

# Extract sudo log file location from sudoers
SUDO_LOG_FILE=$(grep -rPi '^\h*Defaults\h+.*logfile=' /etc/sudoers* 2>/dev/null | \
    sed -e 's/.*logfile=//;s/,.*//' -e 's/"//g' | head -n1)

# If not set, audit passes (nothing to check)
if [ -z "$SUDO_LOG_FILE" ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - No sudo logfile defined — audit not applicable"
  exit 0
fi

# Escape for regex
SUDO_LOG_FILE_ESCAPED=$(printf "%s" "$SUDO_LOG_FILE" | sed -e 's|/|\\/|g')

# Check on-disk rules
ondisk_match=$(awk "/^ *-w/ && /${SUDO_LOG_FILE_ESCAPED}/ && / +-p *wa/ && (/ key=| -k )/" \
  /etc/audit/rules.d/*.rules 2>/dev/null)

if ! grep -q "${SUDO_LOG_FILE}" <<< "$ondisk_match"; then
  failures+=(" - On-disk rule missing or incorrect: -w $SUDO_LOG_FILE -p wa -k sudo_log_file")
fi

# Check active rules
active_match=$(auditctl -l 2>/dev/null | awk "/^ *-w/ && /${SUDO_LOG_FILE_ESCAPED}/ && / +-p *wa/ && (/ key=| -k )/")

if ! grep -q "${SUDO_LOG_FILE}" <<< "$active_match"; then
  failures+=(" - Active audit rule missing or incorrect: -w $SUDO_LOG_FILE -p wa -k sudo_log_file")
fi

# Output results
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - Audit rules properly monitor sudo log file: $SUDO_LOG_FILE"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  echo " - Reason(s) for audit failure:"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_4() {
failures=()

# Expected rule patterns
expected_rules=(
  "-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change"
  "-a always,exit -F arch=b32 -S adjtimex,settimeofday -k time-change"
  "-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -k time-change"
  "-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -k time-change"
  "-w /etc/localtime -p wa -k time-change"
)

# Normalize function: strips whitespace, sorts syscalls, strips fields for comparison
normalize_rule() {
  echo "$1" |
    sed -E 's/\s+/ /g; s/-F key=/-k /; s/-F a0=0x0/-a0=0x0/' |
    sed -E 's/-F arch=b32/-arch32/; s/-F arch=b64/-arch64/' |
    sed -E 's/-k key=/-k /; s/-F key=/-k /' |
    sed -E 's/-S ([^ ]+,[^ ]+)/-S \1/' |
    sed -E 's/ -F / /g; s/ -a / /g' |
    tr -s ' ' | tr '[:upper:]' '[:lower:]'
}

# Check rule list (file or live) against expected
check_rules() {
  local rule_source="$1"
  local raw_lines

  if [[ "$rule_source" == "disk" ]]; then
    raw_lines=$(awk '
      /^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ &&
      (/adjtimex/ || /settimeofday/ || /clock_settime/) &&
      (/ key=| -k /)
    ' /etc/audit/rules.d/*.rules 2>/dev/null)

    raw_lines+=$'\n'
    raw_lines+=$(awk '
      /^ *-w/ && /\/etc\/localtime/ && / +-p *wa/ && (/ key=| -k /)
    ' /etc/audit/rules.d/*.rules 2>/dev/null)
  else
    raw_lines=$(auditctl -l 2>/dev/null | awk '
      /^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ &&
      (/adjtimex/ || /settimeofday/ || /clock_settime/) &&
      (/ key=| -k /)
    ')

    raw_lines+=$'\n'
    raw_lines+=$(auditctl -l 2>/dev/null | awk '
      /^ *-w/ && /\/etc\/localtime/ && / +-p *wa/ && (/ key=| -k /)
    ')
  fi

  for expected in "${expected_rules[@]}"; do
    found=0
    norm_expected=$(normalize_rule "$expected")
    while read -r rule; do
      [[ -z "$rule" ]] && continue
      norm_candidate=$(normalize_rule "$rule")
      if [[ "$norm_candidate" == *"$norm_expected"* ]]; then
        found=1
        break
      fi
    done <<< "$raw_lines"

    if [ "$found" -eq 0 ]; then
      if [ "$rule_source" = "disk" ]; then
        failures+=(" - On-disk rule missing or incorrect: $expected")
      else
        failures+=(" - Active audit rule missing or incorrect: $expected")
      fi
    fi
  done
}

# Perform audit
check_rules disk
check_rules live

# Report
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All time-change audit rules are correctly configured."
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  echo " - Reason(s) for audit failure:"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_5() {
failures=()

# Expected audit rules
expected_rules=(
  "-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale"
  "-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale"
  "-w /etc/issue -p wa -k system-locale"
  "-w /etc/issue.net -p wa -k system-locale"
  "-w /etc/hosts -p wa -k system-locale"
  "-w /etc/networks -p wa -k system-locale"
  "-w /etc/network -p wa -k system-locale"
  "-w /etc/netplan -p wa -k system-locale"
)

# Normalize rule for reliable matching
normalize_rule() {
  echo "$1" |
    sed -E 's/\s+/ /g' |
    sed -E 's/-F key=/-k /; s/-F a0=0x0/-a0=0x0/' |
    tr -s ' ' | tr '[:upper:]' '[:lower:]'
}

# Compare expected vs actual rule sets
check_rules() {
  local type="$1"
  local rule_dump

  if [[ "$type" == "disk" ]]; then
    rule_dump=$(awk '
      /^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ &&
      (/sethostname/ || /setdomainname/) && (/ key=| -k /)
    ' /etc/audit/rules.d/*.rules 2>/dev/null)

    rule_dump+=$'\n'
    rule_dump+=$(awk '
      /^ *-w/ && (/\/etc\/issue/ || /\/etc\/issue.net/ || /\/etc\/hosts/ ||
      /\/etc\/network/ || /\/etc\/netplan/ || /\/etc\/networks/) &&
      / +-p *wa/ && (/ key=| -k /)
    ' /etc/audit/rules.d/*.rules 2>/dev/null)

  else
    rule_dump=$(auditctl -l 2>/dev/null | awk '
      /^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ &&
      (/sethostname/ || /setdomainname/) && (/ key=| -k /)
    ')

    rule_dump+=$'\n'
    rule_dump+=$(auditctl -l 2>/dev/null | awk '
      /^ *-w/ && (/\/etc\/issue/ || /\/etc\/issue.net/ || /\/etc\/hosts/ ||
      /\/etc\/network/ || /\/etc\/netplan/ || /\/etc\/networks/) &&
      / +-p *wa/ && (/ key=| -k /)
    ')
  fi

  for expected in "${expected_rules[@]}"; do
    found=0
    norm_expected=$(normalize_rule "$expected")
    while read -r line; do
      [[ -z "$line" ]] && continue
      norm_line=$(normalize_rule "$line")
      if [[ "$norm_line" == *"$norm_expected"* ]]; then
        found=1
        break
      fi
    done <<< "$rule_dump"

    if [ "$found" -eq 0 ]; then
      source_label="On-disk"
      [ "$type" = "live" ] && source_label="Active"
      failures+=(" - $source_label audit rule missing or incorrect: $expected")
    fi
  done
}

# Perform both checks
check_rules disk
check_rules live

# Final report
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All system locale audit rules are correctly configured."
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  echo " - Reason(s) for audit failure:"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_6() {
#!/usr/bin/env bash

# CIS-compliant audit: check for setuid/setgid binaries being audited

failures=()

# Get all local mount points that are NOT mounted with noexec or nosuid
mount_points=$(findmnt -n -l -k -it "$(awk '/nodev/ {print $2}' /proc/filesystems | paste -sd,)" \
  | grep -Pv 'noexec|nosuid' | awk '{print $1}')

# Check each privileged file (setuid/setgid) in those partitions
for part in $mount_points; do
  while IFS= read -r -d '' privileged_file; do
    # Check if it's listed in any rule file
    if ! grep -qr -- "$privileged_file" /etc/audit/rules.d; then
      failures+=(" - On-disk audit rule missing for: $privileged_file")
    fi
  done < <(find "$part" -xdev -perm /6000 -type f -print0 2>/dev/null)
done

# Output audit resultdc
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All setuid/setgid files are covered by on-disk audit rules"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  echo " - Reason(s) for audit failure:"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_7() {
#!/usr/bin/env bash

failures=()
UID_MIN=$(awk '/^\s*UID_MIN/ {print $2}' /etc/login.defs)

# Required syscall rule fragments
archs=("b64" "b32")
exits=("-EACCES" "-EPERM")
syscalls="creat|open|openat|truncate|ftruncate"

# Check On-Disk Configuration
for arch in "${archs[@]}"; do
    for exit_code in "${exits[@]}"; do
        found=$(awk "/^ *-a *always,exit/ \
            && / -F *arch=${arch}/ \
            && (/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) \
            && / -F *auid>=${UID_MIN}/ \
            && / -F *exit=${exit_code}/ \
            && / -S/ && /(${syscalls})/ \
            && (/ key= *[!-~]* *\$| -k *[!-~]* *\$)/" /etc/audit/rules.d/*.rules 2>/dev/null)
        if [ -z "$found" ]; then
            failures+=(" - On-disk rule missing: arch=${arch}, exit=${exit_code}")
        fi
    done
done

# Check Active Audit Rules
if auditctl -s >/dev/null 2>&1; then
    for arch in "${archs[@]}"; do
        for exit_code in "${exits[@]}"; do
            found=$(auditctl -l | awk "/^ *-a *always,exit/ \
                && / -F *arch=${arch}/ \
                && (/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) \
                && / -F *auid>=${UID_MIN}/ \
                && / -F *exit=${exit_code}/ \
                && / -S/ && /(${syscalls})/ \
                && (/ key= *[!-~]* *\$| -k *[!-~]* *\$)/")
            if [ -z "$found" ]; then
                failures+=(" - Active audit rule missing: arch=${arch}, exit=${exit_code}")
            fi
        done
    done
else
    failures+=(" - Could not check active rules: auditctl not available or not running")
fi

# Final Output
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All required audit rules for unsuccessful file accesses are present"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - Reason(s) for audit failure:"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_3_8() {
#!/usr/bin/env bash

failures=()
errors=()

# Step 0: Ensure auditd is installed
if ! dpkg -s auditd &>/dev/null; then
    errors+=(" - ERROR: 'auditd' package is not installed. Audit cannot be completed without it.")
fi

# Proceed only if auditd is present
if [ ${#errors[@]} -eq 0 ]; then
    files_to_check=(
        "/etc/group"
        "/etc/passwd"
        "/etc/gshadow"
        "/etc/shadow"
        "/etc/security/opasswd"
        "/etc/nsswitch.conf"
        "/etc/pam.conf"
        "/etc/pam.d"
    )

    for file in "${files_to_check[@]}"; do
        # Check on-disk rules
        if ! grep -Pr -- "^-w\s+${file//\//\\/}\s+-p\s+wa\s+(-k\s+identity|key=identity)" /etc/audit/rules.d/ &>/dev/null; then
            failures+=(" - On-disk rule missing or incorrect: -w $file -p wa -k identity")
        fi

        # Check active rules
        if ! command -v auditctl &>/dev/null; then
            errors+=(" - ERROR: 'auditctl' command not found (is auditd running?).")
            break
        fi

        if ! auditctl -l | grep -P -- "^-w\s+${file//\//\\/}\s+-p\s+wa\s+(-k\s+identity|key=identity)" &>/dev/null; then
            failures+=(" - Active audit rule missing or incorrect: -w $file -p wa -k identity")
        fi
    done
fi

# Output section
if [ ${#errors[@]} -gt 0 ]; then
    echo -e "\n- Audit Result:\n ** ERROR **"
    printf '%s\n' "${errors[@]}"
    echo "- End List"
elif [ ${#failures[@]} -gt 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
    echo "- End List"
else
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All identity audit rules are present in both on-disk and active configuration"
    echo "- End List"
fi
}

a__6_2_3_9() {
#!/usr/bin/env bash

failures=()
expected=(
  "-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=unset -F key=perm_mod"
  "-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>=1000 -F auid!=unset -F key=perm_mod"
  "-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=unset -F key=perm_mod"
  "-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>=1000 -F auid!=unset -F key=perm_mod"
  "-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=unset -F key=perm_mod"
  "-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=unset -F key=perm_mod"
)

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [ -z "$UID_MIN" ]; then
  echo -e "\n- Audit Result:\n ** ERROR **"
  echo " - Cannot determine UID_MIN from /etc/login.defs"
  exit 1
fi

# Check on-disk rules
ondisk=$(awk "/^ *-a *always,exit/ \
  &&/ -F *arch=b(32|64)/ \
  &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) \
  &&/ -F *auid>=$UID_MIN/ \
  &&(/chmod/||/fchmod/||/fchmodat/||/chown/||/fchown/||/fchownat/||/lchown/||/setxattr/||/lsetxattr/||/fsetxattr/||/removexattr/||/lremovexattr/||/fremovexattr/) \
  &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)" /etc/audit/rules.d/*.rules 2>/dev/null)

# Check running configuration
if ! command -v auditctl &>/dev/null; then
  echo -e "\n- Audit Result:\n ** ERROR **"
  echo " - 'auditctl' not found. Auditd might not be installed."
  exit 1
fi

runtime=$(auditctl -l | awk "/^ *-a *always,exit/ \
  &&/ -F *arch=b(32|64)/ \
  &&(/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) \
  &&/ -F *auid>=$UID_MIN/ \
  &&(/chmod/||/fchmod/||/fchmodat/||/chown/||/fchown/||/fchownat/||/lchown/||/setxattr/||/lsetxattr/||/fsetxattr/||/removexattr/||/lremovexattr/||/fremovexattr/) \
  &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)" 2>/dev/null)

for rule in "${expected[@]}"; do
  grep -Fq -- "$rule" <<< "$ondisk" || failures+=(" - On-disk rule missing or incorrect: $rule")
  grep -Fq -- "$rule" <<< "$runtime" || failures+=(" - Active audit rule missing or incorrect: $rule")
done

# Output
if [ "${#failures[@]}" -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All required syscall audit rules are present (on-disk and runtime)"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__6_2_4_1() {
l_perm_mask="0137"
  audit_conf="/etc/audit/auditd.conf"

  if [ -e "$audit_conf" ]; then
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/ { print $2 }' "$audit_conf" | xargs)")"

    if [ -d "$l_audit_log_directory" ]; then
      l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )"
      a_files=()

      while IFS= read -r -d $'\0' l_file; do
        [ -e "$l_file" ] && a_files+=("$l_file")
      done < <(find "$l_audit_log_directory" -maxdepth 1 -type f -perm "/$l_perm_mask" -print0)

      if (( ${#a_files[@]} > 0 )); then
        echo -e "\n- Audit Result:\n ** FAIL **"
        for l_file in "${a_files[@]}"; do
          l_file_mode="$(stat -Lc '%#a' "$l_file")"
          echo " - File: \"$l_file\" is mode: \"$l_file_mode\" (should be mode: \"$l_maxperm\" or more restrictive)"
        done
      else
        echo -e "\n- Audit Result:\n ** PASS **"
        echo " - All files in \"$l_audit_log_directory\" are mode \"$l_maxperm\" or more restrictive"
      fi
    else
      echo -e "\n- Audit Result:\n ** FAIL **"
      echo " - Log file directory not found: \"$l_audit_log_directory\" (check the log_file setting in \"$audit_conf\")"
    fi
  else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File: \"$audit_conf\" not found."
    echo " - ** Verify auditd is installed **"
  fi
}

a__6_2_4_10() {
failures=()
passes=()
audit_tools=(
  "/sbin/auditctl"
  "/sbin/aureport"
  "/sbin/ausearch"
  "/sbin/autrace"
  "/sbin/auditd"
  "/sbin/augenrules"
)

for tool in "${audit_tools[@]}"; do
  if [ -e "$tool" ]; then
    group=$(stat -Lc '%G' "$tool")
    if [[ "$group" != "root" ]]; then
      failures+=(" - $tool is group-owned by \"$group\" (should be \"root\")")
    else
      passes+=(" - $tool is correctly group-owned by root")
    fi
  else
    failures+=(" - $tool does not exist")
  fi
done

if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  if [ ${#passes[@]} -gt 0 ]; then
    echo -e "\n- Correctly configured:"
    printf '%s\n' "${passes[@]}"
  fi
fi
}

a__6_2_4_2() {
l_output=""
  l_output2=""
  audit_conf="/etc/audit/auditd.conf"

  if [ -e "$audit_conf" ]; then
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/ { print $2 }' "$audit_conf" | xargs)")"

    if [ -d "$l_audit_log_directory" ]; then
      while IFS= read -r -d $'\0' l_file; do
        file_owner="$(stat -Lc '%U' "$l_file")"
        l_output2+="\n - File: \"$l_file\" is owned by user: \"$file_owner\"\n   (should be owned by user: \"root\")\n"
      done < <(find "$l_audit_log_directory" -maxdepth 1 -type f ! -user root -print0)
    else
      l_output2+="\n - Log file directory not set correctly in \"$audit_conf\". Please set a valid log file path."
    fi
  else
    l_output2+="\n - File: \"$audit_conf\" not found.\n   ** Verify auditd is installed **"
  fi

  if [ -z "$l_output2" ]; then
    l_output+="\n - All files in \"$l_audit_log_directory\" are owned by user: \"root\""
    echo -e "\n- Audit Result:\n ** PASS **\n - * Correctly configured *:$l_output"
  else
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure *:$l_output2"
  fi
}

a__6_2_4_3() {
failures=()
audit_conf="/etc/audit/auditd.conf"

# --- Check log_group value ---
if grep -Piqs '^\s*log_group\s*=\s*\S+' "$audit_conf"; then
    if ! grep -Piqs '^\s*log_group\s*=\s*(adm|root)\b' "$audit_conf"; then
        failures+=(" - Invalid log_group value in \"$audit_conf\" (should be 'adm' or 'root')")
    fi
else
    failures+=(" - log_group is not set in \"$audit_conf\"")
fi

# --- Check audit log directory group ownership ---
if [ -f "$audit_conf" ]; then
    log_dir="$(dirname "$(awk -F= '/^\s*log_file/ {print $2}' "$audit_conf" | xargs)")"
    if [ -d "$log_dir" ]; then
        while IFS= read -r -d '' f; do
            failures+=(" - File: \"$f\" is not group-owned by 'adm' or 'root'")
        done < <(find -L "$log_dir" -not -path "$log_dir/lost+found" -type f \
                 \( ! -group root -a ! -group adm \) -print0)
    else
        failures+=(" - Log directory \"$log_dir\" does not exist")
    fi
else
    failures+=(" - \"$audit_conf\" not found")
fi

# --- Output result ---
if [ "${#failures[@]}" -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - log_group is correctly set and all log files are group-owned by adm or root"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_4_4() {
perm_mask="0027"

if [ -e "/etc/audit/auditd.conf" ]; then
    audit_log_dir="$(dirname "$(awk -F= '/^\s*log_file\s*/ {print $2}' /etc/audit/auditd.conf | xargs)")"

    if [ -d "$audit_log_dir" ]; then
        max_perm="$(printf '%o' $(( 0777 & ~$perm_mask )) )"
        dir_mode="$(stat -Lc '%#a' "$audit_log_dir")"

        if [ $(( dir_mode & perm_mask )) -gt 0 ]; then
            echo -e "\n- Audit Result:\n ** FAIL **"
            echo " - Directory: \"$audit_log_dir\" is mode: \"$dir_mode\""
            echo "   (should be mode: \"$max_perm\" or more restrictive)"
        else
            echo -e "\n- Audit Result:\n ** PASS **"
            echo " - Directory: \"$audit_log_dir\" is mode: \"$dir_mode\""
            echo "   (meets or exceeds required restriction of \"$max_perm\")"
        fi
    else
        echo -e "\n- Audit Result:\n ** FAIL **"
        echo " - Log file directory \"$audit_log_dir\" does not exist"
        echo " - Please verify log_file is correctly set in \"/etc/audit/auditd.conf\""
    fi
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"/etc/audit/auditd.conf\" not found"
    echo " - ** Verify auditd is installed **"
fi
}

a__6_2_4_5() {
output="" 
output2=""
perm_mask="0137"
max_perm="$(printf '%o' $((0777 & ~perm_mask)))"

while IFS= read -r -d $'\0' fname; do
    mode=$(stat -Lc '%#a' "$fname")
    if [ $((mode & perm_mask)) -gt 0 ]; then
        output2+="\n - File: \"$fname\" is mode: \"$mode\""
        output2+=" (should be mode: \"$max_perm\" or more restrictive)"
    fi
done < <(find /etc/audit/ -type f \( -name "*.conf" -o -name "*.rules" \) -print0)

if [ -z "$output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All audit configuration files are mode: \"$max_perm\" or more restrictive"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo -e "$output2"
fi
}

a__6_2_4_6() {
failures=()

while IFS= read -r -d $'\0' file; do
    owner=$(stat -Lc '%U' "$file")
    failures+=(" - File: \"$file\" is owned by \"$owner\" (should be owned by \"root\")")
done < <(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -user root -print0)

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All audit configuration files are owned by user: root"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_4_7() {
failures=()

while IFS= read -r -d $'\0' file; do
    group=$(stat -Lc '%G' "$file")
    failures+=(" - File: \"$file\" is group-owned by \"$group\" (should be group-owned by \"root\")")
done < <(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -group root -print0)

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All audit configuration files are group-owned by: root"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__6_2_4_8() {
failures=()
passes=()
perm_mask="0022"
max_perm="$(printf '%o' $((0777 & ~$perm_mask)))"

audit_tools=(
  "/sbin/auditctl"
  "/sbin/aureport"
  "/sbin/ausearch"
  "/sbin/autrace"
  "/sbin/auditd"
  "/sbin/augenrules"
)

for tool in "${audit_tools[@]}"; do
  if [ -e "$tool" ]; then
    mode=$(stat -Lc '%#a' "$tool")
    if [ $((mode & perm_mask)) -gt 0 ]; then
      failures+=(" - Audit tool \"$tool\" has mode: \"$mode\" (should be \"$max_perm\" or more restrictive)")
    else
      passes+=(" - Audit tool \"$tool\" is correctly configured with mode: \"$mode\"")
    fi
  else
    failures+=(" - Audit tool \"$tool\" not found")
  fi
done

if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  if [ ${#passes[@]} -gt 0 ]; then
    echo -e "\n- Correctly configured:"
    printf '%s\n' "${passes[@]}"
  fi
fi
}

a__6_2_4_9() {
failures=()
passes=()
audit_tools=(
  "/sbin/auditctl"
  "/sbin/aureport"
  "/sbin/ausearch"
  "/sbin/autrace"
  "/sbin/auditd"
  "/sbin/augenrules"
)

for tool in "${audit_tools[@]}"; do
  if [ -e "$tool" ]; then
    owner=$(stat -Lc '%U' "$tool")
    if [[ "$owner" != "root" ]]; then
      failures+=(" - $tool is owned by \"$owner\" (should be owned by \"root\")")
    else
      passes+=(" - $tool is correctly owned by root")
    fi
  else
    failures+=(" - $tool does not exist")
  fi
done

if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  if [ ${#passes[@]} -gt 0 ]; then
    echo -e "\n- Correctly configured:"
    printf '%s\n' "${passes[@]}"
  fi
fi
}

a__6_3_1() {
failures=()
passes=()

# Check for aide
if dpkg-query -s aide &>/dev/null; then
  passes+=(" - aide is installed")
else
  failures+=(" - aide package is NOT installed")
fi

# Check for aide-common
if dpkg-query -s aide-common &>/dev/null; then
  passes+=(" - aide-common is installed")
else
  failures+=(" - aide-common package is NOT installed")
fi

# Final output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  if [ ${#passes[@]} -gt 0 ]; then
    echo -e "\n- Correctly configured:"
    printf '%s\n' "${passes[@]}"
  fi
fi
}

a__6_3_2() {
failures=()
passes=()

# Check unit-file state
while IFS=$'\t' read -r unit state; do
  case "$unit" in
    dailyaidecheck.timer)
      if [[ "$state" == "enabled" ]]; then
        passes+=(" - dailyaidecheck.timer is enabled")
      else
        failures+=(" - dailyaidecheck.timer is not enabled (state: $state)")
      fi
      ;;
    dailyaidecheck.service)
      if [[ "$state" == "enabled" || "$state" == "static" ]]; then
        passes+=(" - dailyaidecheck.service is $state")
      else
        failures+=(" - dailyaidecheck.service is not enabled/static (state: $state)")
      fi
      ;;
  esac
done < <(systemctl list-unit-files | awk '$1~/^dailyaidecheck\.(timer|service)$/ {print $1 "\t" $2}')

# Check if the timer is active
if systemctl is-active --quiet dailyaidecheck.timer; then
  passes+=(" - dailyaidecheck.timer is active")
else
  failures+=(" - dailyaidecheck.timer is not active")
fi

# Final Output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  if [ ${#passes[@]} -gt 0 ]; then
    echo -e "\n- Correctly configured:"
    printf '%s\n' "${passes[@]}"
  fi
fi
}

a__6_3_3() {
a_output=()
a_output2=()

l_tool_dir="$(readlink -f /sbin)"
a_items=("p" "i" "n" "u" "g" "s" "b" "acl" "xattrs" "sha512")
l_aide_cmd="$(whereis aide | awk '{print $2}')"
a_audit_files=("auditctl" "auditd" "ausearch" "aureport" "autrace" "augenrules")

# Check if AIDE is installed
if [ -f "$l_aide_cmd" ] && command -v "$l_aide_cmd" &>/dev/null; then
    a_aide_conf_files=($(find -L /etc -type f -name 'aide.conf'))

    f_file_par_chk() {
        a_out2=()
        for l_item in "${a_items[@]}"; do
            ! grep -Psiq -- '(\h+|\+)'$l_item'(\h+|\+)' <<< "$l_out" && \
            a_out2+=(" - Missing the \"$l_item\" option")
        done

        if [ "${#a_out2[@]}" -gt 0 ]; then
            a_output2+=(" - Audit tool file: \"$l_file\"" "${a_out2[@]}")
        else
            a_output+=(" - Audit tool file: \"$l_file\" includes: \"${a_items[*]}\"")
        fi
    }

    for l_file in "${a_audit_files[@]}"; do
        if [ -f "$l_tool_dir/$l_file" ]; then
            l_out="$("$l_aide_cmd" --config "${a_aide_conf_files[@]}" -p f:"$l_tool_dir/$l_file")"
            f_file_par_chk
        else
            a_output+=(" - Audit tool file \"$l_file\" doesn't exist")
        fi
    done
else
    a_output2+=(" - The command \"aide\" was not found" " Please install AIDE")
fi

# Print audit result
if [ "${#a_output2[@]}" -eq 0 ]; then
    printf '\n%s\n' "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '\n%s\n' "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    if [ "${#a_output[@]}" -gt 0 ]; then
        printf '\n%s\n' "- Correctly set:" "${a_output[@]}" ""
    fi
fi
}

a__7_1_1() {
failures=()

# Get file metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' /etc/passwd)"

# Check permissions (644 = 0644 octal)
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check user ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

# Check group ownership
if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - /etc/passwd is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_10() {
failures=()
files=("/etc/security/opasswd" "/etc/security/opasswd.old")

for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$file")"

        (( mode > 600 )) && failures+=(" - $file has permission $mode ($perms), should be 600 or more restrictive")
        [[ "$uid" -ne 0 || "$user" != "root" ]] && failures+=(" - $file is owned by UID=$uid ($user), should be root")
        [[ "$gid" -ne 0 || "$group" != "root" ]] && failures+=(" - $file is group-owned by GID=$gid ($group), should be root")
    fi
done

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - All relevant files (if present) are securely configured"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_11() {
failures=()
passes=()

# Sticky bit mask
sticky_mask="01000"

# Excluded path patterns
excluded_paths=(
  -path "/run/user/*" -o
  -path "/proc/*" -o
  -path "*/containerd/*" -o
  -path "*/kubelet/pods/*" -o
  -path "*/kubelet/plugins/*" -o
  -path "/sys/*" -o
  -path "/snap/*"
)

# Build exclusion expression for find
exclude_expr=()
for ((i=0; i<${#excluded_paths[@]}; i+=2)); do
  exclude_expr+=( \( "${excluded_paths[@]:i:2}" \) -prune -o )
done

# Scan world-writable files and directories (one pass)
ww_files=()
ww_dirs_no_sticky=()

# Search root and mounted filesystems excluding excluded paths
while IFS= read -r mount; do
  while IFS= read -r -d $'\0' path; do
    [ ! -e "$path" ] && continue
    if [ -f "$path" ]; then
      ww_files+=("$path")
    elif [ -d "$path" ]; then
      mode=$(stat -Lc '%#a' "$path")
      (( (mode & 01000) == 0 )) && ww_dirs_no_sticky+=("$path")
    fi
  done < <(find "$mount" -xdev "${exclude_expr[@]}" \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)
done < <(findmnt -n -l -k -t ext4,xfs,btrfs -o TARGET | grep -vE '^/(run|proc|sys|snap)')

# Report world-writable files
if [ ${#ww_files[@]} -eq 0 ]; then
  passes+=(" - No world-writable files found")
else
  failures+=(" - Found ${#ww_files[@]} world-writable files:\n$(printf '   %s\n' "${ww_files[@]}")")
fi

# Report world-writable directories without sticky bit
if [ ${#ww_dirs_no_sticky[@]} -eq 0 ]; then
  passes+=(" - All world-writable directories have the sticky bit set")
else
  failures+=(" - Found ${#ww_dirs_no_sticky[@]} world-writable directories without the sticky bit:\n$(printf '   %s\n' "${ww_dirs_no_sticky[@]}")")
fi

# Final output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  [ ${#passes[@]} -gt 0 ] && {
    echo -e "\n- Correctly Configured:"
    printf '%s\n' "${passes[@]}"
  }
fi
}

a__7_1_12() {
failures=()
passes=()

# Excluded paths
excluded_paths=(
  -path "/run/user/*" -o
  -path "/proc/*" -o
  -path "*/containerd/*" -o
  -path "*/kubelet/pods/*" -o
  -path "*/kubelet/plugins/*" -o
  -path "/sys/fs/cgroup/memory/*" -o
  -path "/var/*/private/*"
)

# Build exclusion expression for find
exclude_expr=()
for ((i=0; i<${#excluded_paths[@]}; i+=2)); do
  exclude_expr+=( \( "${excluded_paths[@]:i:2}" \) -prune -o )
done

# Find all mount points to scan
mount_points=$(findmnt -n -l -k -t ext4,xfs,btrfs -o TARGET | grep -vE '^/run/user/')

# Collect unowned and ungrouped files
nouser_files=()
nogroup_files=()

while IFS= read -r mount; do
  while IFS= read -r -d $'\0' file; do
    [ ! -e "$file" ] && continue
    owner_group=$(stat -Lc '%U:%G' "$file")
    IFS=: read -r user group <<< "$owner_group"
    [[ "$user" == "UNKNOWN" ]] && nouser_files+=("$file")
    [[ "$group" == "UNKNOWN" ]] && nogroup_files+=("$file")
  done < <(find "$mount" -xdev "${exclude_expr[@]}" \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2>/dev/null)
done <<< "$mount_points"

# Evaluate results
if [ ${#nouser_files[@]} -eq 0 ]; then
  passes+=(" - No unowned files or directories found on the local filesystem.")
else
  failures+=(" - Found ${#nouser_files[@]} unowned files/directories:\n$(printf '   %s\n' "${nouser_files[@]}")")
fi

if [ ${#nogroup_files[@]} -eq 0 ]; then
  passes+=(" - No ungrouped files or directories found on the local filesystem.")
else
  failures+=(" - Found ${#nogroup_files[@]} ungrouped files/directories:\n$(printf '   %s\n' "${nogroup_files[@]}")")
fi

# Final Output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
  [ ${#passes[@]} -gt 0 ] && {
    echo -e "\n- Correctly Configured:"
    printf '%s\n' "${passes[@]}"
  }
fi
}

a__7_1_2() {
failures=()

# Check if file exists
if [ ! -e /etc/passwd- ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"/etc/passwd-\" does not exist."
    exit 1
fi

# Get file metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' /etc/passwd-)"

# Check permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check user ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

# Check group ownership
if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - /etc/passwd- is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_3() {
failures=()

# Target file
target_file="/etc/group"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_4() {
failures=()

# Target file
target_file="/etc/group-"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_5() {
failures=()

# Target file
target_file="/etc/shadow"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_6() {
failures=()

# Target file
target_file="/etc/shadow-"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_7() {
failures=()

# Target file
target_file="/etc/gshadow"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_8() {
failures=()

# Target file
target_file="/etc/gshadow-"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_1_9() {
failures=()

# Target file
target_file="/etc/shells"

# Check existence
if [ ! -e "$target_file" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo " - File \"$target_file\" does not exist."
    exit 1
fi

# Gather metadata
read -r mode perms uid user gid group <<< "$(stat -Lc '%a %A %u %U %g %G' "$target_file")"

# Check file permissions
if (( mode > 644 )); then
    failures+=(" - Incorrect permissions: $mode ($perms), should be 644 or more restrictive")
fi

# Check ownership
if [[ "$uid" -ne 0 || "$user" != "root" ]]; then
    failures+=(" - Incorrect owner: UID=$uid ($user), should be root")
fi

if [[ "$gid" -ne 0 || "$group" != "root" ]]; then
    failures+=(" - Incorrect group: GID=$gid ($group), should be root")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - $target_file is securely configured (mode: $mode, owner: $user, group: $group)"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_2_1() {
failures=()
passes=()

# Run audit
bad_users=$(awk -F: '($2 != "x") { print "User: \"" $1 "\" is not set to shadowed passwords." }' /etc/passwd)

# Check and report
if [ -n "$bad_users" ]; then
  failures+=("$bad_users")
else
  passes+=(" - All users in /etc/passwd are using shadowed passwords.")
fi

# Final output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__7_2_10() {
failures=()
warnings=()
max_users=1000

# Build regex of valid shells from /etc/shells
valid_shells_regex="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\/,g;p}' | paste -sd'|' -))$"

# Build user:home pairs for interactive users
declare -a user_homes
while read -r user home; do
    [[ -n "$user" && -n "$home" ]] && user_homes+=("$user:$home")
done < <(awk -v pat="$valid_shells_regex" -F: '$NF ~ pat { print $1 ":" $(NF-1) }' /etc/passwd)

# Warn if excessive users
[ "${#user_homes[@]}" -gt "$max_users" ] && echo -e "\n ** INFO **\n - ${#user_homes[@]} interactive users found.\n - This may take a while."

check_file_security() {
    local file="$1" user="$2" group="$3" mask="$4"
    local mode owner gowner; read -r mode owner gowner < <(stat -Lc '%#a %U %G' "$file")
    local max_mode; max_mode="$(printf '%o' $((0777 & ~$mask)))"
    local issues=()

    (( mode & mask )) && issues+=("   • Insecure permissions: \"$mode\" (should be $max_mode or more restrictive)")
    [[ "$owner" != "$user" ]] && issues+=("   • Incorrect owner: \"$owner\" (expected: \"$user\")")
    [[ "$gowner" != "$group" ]] && issues+=("   • Incorrect group: \"$gowner\" (expected: \"$group\")")

    printf '%s\n' "${issues[@]}"
}

for entry in "${user_homes[@]}"; do
    user="${entry%%:*}"
    home="${entry##*:}"
    group="$(id -gn "$user" 2>/dev/null || echo root)"

    dot_issues=()
    netrc_issues=()
    bash_hist_issues=()
    generic_issues=()
    netrc_warnings=()

    if [ -d "$home" ]; then
        while IFS= read -r -d $'\0' file; do
            fname="$(basename "$file")"
            case "$fname" in
                .forward | .rhost)
                    dot_issues+=("   • Insecure file exists: \"$file\" (should be removed)")
                    ;;
                .netrc)
                    output=$(check_file_security "$file" "$user" "$group" 0177)
                    if [ -n "$output" ]; then
                        netrc_issues+=("$output")
                    else
                        netrc_warnings+=("   • Secure .netrc exists: \"$file\" (review if needed)")
                    fi
                    ;;
                .bash_history)
                    output=$(check_file_security "$file" "$user" "$group" 0177)
                    [ -n "$output" ] && bash_hist_issues+=("$output")
                    ;;
                *)
                    output=$(check_file_security "$file" "$user" "$group" 0133)
                    [ -n "$output" ] && generic_issues+=("$output")
                    ;;
            esac
        done < <(find "$home" -xdev -type f -name '.*' -print0)
    fi

    # Collect findings
    if [[ ${#dot_issues[@]} -gt 0 || ${#netrc_issues[@]} -gt 0 || ${#bash_hist_issues[@]} -gt 0 || ${#generic_issues[@]} -gt 0 ]]; then
        failures+=("")
        failures+=(" User: \"$user\" | Home: \"$home\"")
        failures+=("${dot_issues[@]}" "${netrc_issues[@]}" "${bash_hist_issues[@]}" "${generic_issues[@]}")
    fi

    if [ ${#netrc_warnings[@]} -gt 0 ]; then
        warnings+=("")
        warnings+=(" Advisory: \"$user\" has secure but present .netrc in \"$home\"")
        warnings+=("${netrc_warnings[@]}")
    fi
done

# Final Output
if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n  ** PASS **"
    echo " - All interactive users' dotfiles are secure and correctly configured."
    [ ${#warnings[@]} -gt 0 ] && printf '\n- Advisory:\n%s\n' "${warnings[@]}"
else
    echo -e "\n- Audit Result:\n  ** FAIL **"
    echo " - Some users have insecure hidden dotfiles or ownership issues."
    printf '%s\n' "${failures[@]}"
    [ ${#warnings[@]} -gt 0 ] && printf '\n- Advisory:\n%s\n' "${warnings[@]}"
fi
}

a__7_2_2() {
failures=()
passes=()

# Run audit
empty_passwords=$(awk -F: '($2 == "") { print "- User: \"" $1 "\" does not have a password." }' /etc/shadow)

# Check and report
if [ -n "$empty_passwords" ]; then
  failures+=("$empty_passwords")
else
  passes+=(" - All users in /etc/shadow have passwords set.")
fi

# Final output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  printf '%s\n' "${passes[@]}"
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__7_2_3() {
failures=()
passes=()

# Extract unique GIDs
passwd_gids=($(awk -F: '{print $4}' /etc/passwd | sort -u))
group_gids=($(awk -F: '{print $3}' /etc/group | sort -u))

# Identify GIDs in passwd not in group
for gid in "${passwd_gids[@]}"; do
  if ! printf '%s\n' "${group_gids[@]}" | grep -q "^${gid}$"; then
    while IFS=: read -r user _ _ user_gid _; do
      [ "$user_gid" = "$gid" ] && failures+=(" - User: \"$user\" has GID: \"$gid\" which does not exist in /etc/group")
    done < /etc/passwd
  fi
done

# Output
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - All GIDs in /etc/passwd are valid and exist in /etc/group."
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__7_2_4() {
failures=()

# Check for any unexpected fields in shadow group entry (i.e., shell/home)
extra_info=$(awk -F: '($1=="shadow") {print $NF}' /etc/group)
[ "$extra_info" != "" ] && failures+=(" - 'shadow' group should not have extra fields: '$extra_info'")

# Get shadow GID
shadow_gid=$(getent group shadow | awk -F: '{print $3}')

# Check for users whose primary group is 'shadow'
if [ -n "$shadow_gid" ]; then
  while IFS=: read -r user _ _ user_gid _; do
    [ "$user_gid" = "$shadow_gid" ] && failures+=(" - User: \"$user\" has shadow as primary group (GID $shadow_gid)")
  done < /etc/passwd
else
  failures+=(" - 'shadow' group not found in /etc/group")
fi

# Output result
if [ ${#failures[@]} -eq 0 ]; then
  echo -e "\n- Audit Result:\n ** PASS **"
  echo " - No misuse of 'shadow' group found."
else
  echo -e "\n- Audit Result:\n ** FAIL **"
  printf '%s\n' "${failures[@]}"
fi
}

a__7_2_5() {
failures=()

while read -r count uid; do
    if [ "$count" -gt 1 ]; then
        users=$(awk -F: -v id="$uid" '($3 == id) { print $1 }' /etc/passwd | xargs)
        failures+=(" - Duplicate UID: \"$uid\" Users: \"$users\"")
    fi
done < <(cut -d: -f3 /etc/passwd | sort -n | uniq -c)

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No duplicate UIDs found in /etc/passwd"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_2_6() {
failures=()

while read -r count gid; do
    if [ "$count" -gt 1 ]; then
        groups=$(awk -F: -v n="$gid" '($3 == n) { print $1 }' /etc/group | xargs)
        failures+=(" - Duplicate GID: \"$gid\" Groups: \"$groups\"")
    fi
done < <(cut -d: -f3 /etc/group | sort -n | uniq -c)

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No duplicate GIDs found in /etc/group"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_2_7() {
failures=()

while read -r count user; do
    if [ "$count" -gt 1 ]; then
        matches=$(awk -F: -v n="$user" '($1 == n) { print $1 }' /etc/passwd | xargs)
        failures+=(" - Duplicate username: \"$user\" Entries: \"$matches\"")
    fi
done < <(cut -d: -f1 /etc/passwd | sort | uniq -c)

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No duplicate usernames found in /etc/passwd"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_2_8() {
failures=()

while read -r count group; do
    if [ "$count" -gt 1 ]; then
        matches=$(awk -F: -v n="$group" '($1 == n) { print $1 }' /etc/group | xargs)
        failures+=(" - Duplicate group name: \"$group\" Entries: \"$matches\"")
    fi
done < <(cut -d: -f1 /etc/group | sort | uniq -c)

if [ ${#failures[@]} -eq 0 ]; then
    echo -e "\n- Audit Result:\n ** PASS **"
    echo " - No duplicate group names found in /etc/group"
else
    echo -e "\n- Audit Result:\n ** FAIL **"
    printf '%s\n' "${failures[@]}"
fi
}

a__7_2_9() {
output_pass="" output_fail=""
fail_missing_home="" fail_wrong_owner="" fail_wrong_mode=""
mask="0027"
max_mode=$(printf '%o' $(( 0777 & ~$mask )))

# Build regex of valid login shells from /etc/shells (excluding nologin)
valid_shells_regex="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\/,g;p}' | paste -sd'|' -))$"

# Build array of interactive users with home directories
declare -a interactive_users
while read -r user home; do
    interactive_users+=("$user $home")
done < <(awk -v pat="$valid_shells_regex" -F: '$NF ~ pat { print $1, $(NF-1) }' /etc/passwd)

# Warn if extremely large number of users
[ "${#interactive_users[@]}" -gt 10000 ] && echo -e "\n ** INFO **\n - ${#interactive_users[@]} interactive users found. This may take a while.\n"

# Check each user's home directory
for entry in "${interactive_users[@]}"; do
    user="${entry%% *}"
    home="${entry##* }"
    
    if [ -d "$home" ]; then
        read -r owner mode < <(stat -Lc '%U %a' "$home")
        
        [[ "$owner" != "$user" ]] && fail_wrong_owner+="\n - User \"$user\" home \"$home\" is owned by \"$owner\""

        if (( mode & mask )); then
            fail_wrong_mode+="\n - User \"$user\" home \"$home\" is mode \"$mode\" (should be $max_mode or more restrictive)"
        fi
    else
        fail_missing_home+="\n - User \"$user\" home directory \"$home\" does not exist"
    fi
done

# Assemble result
[[ -z "$fail_missing_home" ]] && output_pass+="\n - All home directories exist" || output_fail+="$fail_missing_home"
[[ -z "$fail_wrong_owner" ]]  && output_pass+="\n - All users own their home directories" || output_fail+="$fail_wrong_owner"
[[ -z "$fail_wrong_mode" ]]   && output_pass+="\n - All home directories are mode $max_mode or more restrictive" || output_fail+="$fail_wrong_mode"

[[ -n "$output_pass" ]] && output_pass="\n - Checked interactive users:$output_pass"

# Final output
if [[ -z "$output_fail" ]]; then
    echo -e "\n- Audit Result:\n ** PASS **$output_pass"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure *:$output_fail"
    [[ -n "$output_pass" ]] && echo -e "\n - * Correctly configured *:$output_pass"
fi
}


run_a__1_1_1_1() {
    output=$(a__1_1_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.1" --arg audit_name "Ensure cramfs kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_10() {
    output=$(a__1_1_1_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.10" --arg audit_name "Ensure unused filesystems kernel modules are not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_2() {
    output=$(a__1_1_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.2" --arg audit_name "Ensure freevxfs kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_3() {
    output=$(a__1_1_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.3" --arg audit_name "Ensure hfs kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_4() {
    output=$(a__1_1_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.4" --arg audit_name "Ensure hfsplus kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_5() {
    output=$(a__1_1_1_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.5" --arg audit_name "Ensure jffs2 kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_6() {
    output=$(a__1_1_1_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.6" --arg audit_name "Ensure overlayfs kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_7() {
    output=$(a__1_1_1_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.7" --arg audit_name "Ensure squashfs kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_8() {
    output=$(a__1_1_1_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.8" --arg audit_name "Ensure udf kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_1_9() {
    output=$(a__1_1_1_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.1.9" --arg audit_name "Ensure usb-storage kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_1_1() {
    output=$(a__1_1_2_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.1.1" --arg audit_name "Ensure /tmp is a separate partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_1_2() {
    output=$(a__1_1_2_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.1.2" --arg audit_name "Ensure nodev option set on /tmp partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_1_3() {
    output=$(a__1_1_2_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.1.3" --arg audit_name "Ensure nosuid option set on /tmp partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_1_4() {
    output=$(a__1_1_2_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.1.4" --arg audit_name "Ensure noexec option set on /tmp partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_2_1() {
    output=$(a__1_1_2_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.2.1" --arg audit_name "Ensure /dev/shm is a separate partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_2_2() {
    output=$(a__1_1_2_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.2.2" --arg audit_name "Ensure nodev option set on /dev/shm partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_2_3() {
    output=$(a__1_1_2_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.2.3" --arg audit_name "Ensure nosuid option set on /dev/shm partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_2_4() {
    output=$(a__1_1_2_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.2.4" --arg audit_name "Ensure noexec option set on /dev/shm partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_3_1() {
    output=$(a__1_1_2_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.3.1" --arg audit_name "Ensure separate partition exists for /home" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_3_2() {
    output=$(a__1_1_2_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.3.2" --arg audit_name "Ensure nodev option set on /home partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_3_3() {
    output=$(a__1_1_2_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.3.3" --arg audit_name "Ensure nosuid option set on /home partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_4_1() {
    output=$(a__1_1_2_4_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.4.1" --arg audit_name "Ensure separate partition exists for /var" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_4_2() {
    output=$(a__1_1_2_4_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.4.2" --arg audit_name "Ensure nodev option set on /var partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_4_3() {
    output=$(a__1_1_2_4_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.4.3" --arg audit_name "Ensure nosuid option set on /var partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_5_1() {
    output=$(a__1_1_2_5_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.5.1" --arg audit_name "Ensure separate partition exists for /var/tmp" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_5_2() {
    output=$(a__1_1_2_5_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.5.2" --arg audit_name "Ensure nodev option set on /var/tmp partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_5_3() {
    output=$(a__1_1_2_5_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.5.3" --arg audit_name "Ensure nosuid option set on /var/tmp partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_5_4() {
    output=$(a__1_1_2_5_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.5.4" --arg audit_name "Ensure noexec option set on /var/tmp partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_6_1() {
    output=$(a__1_1_2_6_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.6.1" --arg audit_name "Ensure separate partition exists for /var/log" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_6_2() {
    output=$(a__1_1_2_6_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.6.2" --arg audit_name "Ensure nodev option set on /var/log partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_6_3() {
    output=$(a__1_1_2_6_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.6.3" --arg audit_name "Ensure nosuid option set on /var/log partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_6_4() {
    output=$(a__1_1_2_6_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.6.4" --arg audit_name "Ensure noexec option set on /var/log partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_7_1() {
    output=$(a__1_1_2_7_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.7.1" --arg audit_name "Ensure separate partition exists for /var/log/audit" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_1_2_7_2() {
    output=$(a__1_1_2_7_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.1.2.7.2" --arg audit_name "Ensure noexec option set on /var/log/audit partition" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_3_1_1() {
    output=$(a__1_3_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.3.1.1" --arg audit_name "Ensure AppArmor is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_3_1_2() {
    output=$(a__1_3_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.3.1.2" --arg audit_name "Ensure AppArmor is enabled in the bootloader configuration" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_3_1_3() {
    output=$(a__1_3_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.3.1.3" --arg audit_name "Ensure all AppArmor profiles are in enforce or complain mode" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_3_1_4() {
    output=$(a__1_3_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.3.1.4" --arg audit_name "Ensure all AppArmor profiles are in enforce mode" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_4_1() {
    output=$(a__1_4_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.4.1" --arg audit_name "Ensure bootloader password is set" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_4_2() {
    output=$(a__1_4_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.4.2" --arg audit_name "Ensure access to bootloader config is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_5_1() {
    output=$(a__1_5_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.5.1" --arg audit_name "Ensure address space layout randomization is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_5_2() {
    output=$(a__1_5_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.5.2" --arg audit_name "Ensure ptrace_scope is restricted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_5_3() {
    output=$(a__1_5_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.5.3" --arg audit_name "Ensure core dumps are restricted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_5_4() {
    output=$(a__1_5_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.5.4" --arg audit_name "Ensure prelink is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_5_5() {
    output=$(a__1_5_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.5.5" --arg audit_name "Ensure Automatic Error Reporting is not enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_6_1() {
    output=$(a__1_6_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.6.1" --arg audit_name "Ensure message of the day is configured properly" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_6_2() {
    output=$(a__1_6_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.6.2" --arg audit_name "Ensure local login warning banner is configured properly" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_6_3() {
    output=$(a__1_6_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.6.3" --arg audit_name "Ensure remote login warning banner is configured properly" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_6_4() {
    output=$(a__1_6_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.6.4" --arg audit_name "Ensure access to /etc/motd is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_6_5() {
    output=$(a__1_6_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.6.5" --arg audit_name "Ensure access to /etc/issue is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_6_6() {
    output=$(a__1_6_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.6.6" --arg audit_name "Ensure access to /etc/issue.net is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_1() {
    output=$(a__1_7_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.1" --arg audit_name "Ensure GDM login banner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_10() {
    output=$(a__1_7_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.10" --arg audit_name "Ensure XDMCP is not enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_2() {
    output=$(a__1_7_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.2" --arg audit_name "Ensure GDM login banner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_3() {
    output=$(a__1_7_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.3" --arg audit_name "Ensure GDM disable-user-list option is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_4() {
    output=$(a__1_7_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.4" --arg audit_name "Ensure GDM screen locks when the user is idle" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_5() {
    output=$(a__1_7_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.5" --arg audit_name "Ensure GDM screen locks cannot be overridden" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_6() {
    output=$(a__1_7_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.6" --arg audit_name "Ensure GDM automatic mounting of removable media is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_7() {
    output=$(a__1_7_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.7" --arg audit_name "Ensure GDM disabling automatic mounting of removable media is not overridden" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_8() {
    output=$(a__1_7_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.8" --arg audit_name "Ensure GDM autorun-never is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__1_7_9() {
    output=$(a__1_7_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "1.7.9" --arg audit_name "Ensure GDM autorun-never is not overridden" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_1() {
    output=$(a__2_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.1" --arg audit_name "Ensure autofs services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_10() {
    output=$(a__2_1_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.10" --arg audit_name "Ensure nis server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_11() {
    output=$(a__2_1_11 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.11" --arg audit_name "Ensure print server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_12() {
    output=$(a__2_1_12 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.12" --arg audit_name "Ensure rpcbind services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_13() {
    output=$(a__2_1_13 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.13" --arg audit_name "Ensure rsync services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_4() {
    output=$(a__2_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.4" --arg audit_name "Ensure dns server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_15() {
    output=$(a__2_1_15 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.15" --arg audit_name "Ensure snmp services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_16() {
    output=$(a__2_1_16 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.16" --arg audit_name "Ensure tftp server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_17() {
    output=$(a__2_1_17 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.17" --arg audit_name "Ensure web proxy server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_18() {
    output=$(a__2_1_18 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.18" --arg audit_name "Ensure web server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_19() {
    output=$(a__2_1_19 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.19" --arg audit_name "Ensure xinetd services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_2() {
    output=$(a__2_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.2" --arg audit_name "Ensure avahi daemon services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_20() {
    output=$(a__2_1_20 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.20" --arg audit_name "Ensure X window server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_21() {
    output=$(a__2_1_21 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.21" --arg audit_name "Ensure mail transfer agent is configured for local-only mode" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_3() {
    output=$(a__2_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.3" --arg audit_name "Ensure dhcp server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_5() {
    output=$(a__2_1_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.5" --arg audit_name "Ensure dnsmasq services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_6() {
    output=$(a__2_1_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.6" --arg audit_name "Ensure ftp server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_7() {
    output=$(a__2_1_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.7" --arg audit_name "Ensure ldap server services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_1_9() {
    output=$(a__2_1_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.1.9" --arg audit_name "Ensure network file system services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_2_1() {
    output=$(a__2_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.2.1" --arg audit_name "Ensure NIS Client is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_2_2() {
    output=$(a__2_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.2.2" --arg audit_name "Ensure rsh client is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_2_3() {
    output=$(a__2_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.2.3" --arg audit_name "Ensure talk client is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_2_4() {
    output=$(a__2_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.2.4" --arg audit_name "Ensure telnet client is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_2_5() {
    output=$(a__2_2_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.2.5" --arg audit_name "Ensure ldap client is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_2_6() {
    output=$(a__2_2_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.2.6" --arg audit_name "Ensure ftp client is not installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_3_1_1() {
    output=$(a__2_3_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.3.1.1" --arg audit_name "Ensure a single time synchronization daemon is in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
    matched=false
    executed_audits=""
    if echo "$output" | grep -Eq "systemd-timesyncd.service"; then
        run_a__2_3_2_1
        executed_audits="$executed_audits 2.3.2.1"
        run_a__2_3_2_2
        executed_audits="$executed_audits 2.3.2.2"
        matched=true
    fi
    if echo "$output" | grep -Eq "chrony.service"; then
        run_a__2_3_3_1
        executed_audits="$executed_audits 2.3.3.1"
        run_a__2_3_3_2
        executed_audits="$executed_audits 2.3.3.2"
        run_a__2_3_3_3
        executed_audits="$executed_audits 2.3.3.3"
        matched=true
    fi
    if [ "$matched" = false ]; then
        if [ "$status" = "FAIL" ] || [ "$status" = "ERROR" ]; then
            jq -n --arg audit_id "2.3.2.1" --arg audit_name "Ensure systemd-timesyncd configured with authorized timeserver" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 2.3.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.2.2" --arg audit_name "Ensure systemd-timesyncd is enabled and running" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 2.3.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.3.1" --arg audit_name "Ensure chrony is configured with authorized timeserver" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 2.3.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.3.2" --arg audit_name "Ensure chrony is running as user _chrony" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 2.3.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.3.3" --arg audit_name "Ensure chrony is enabled and running" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 2.3.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        else
            jq -n --arg audit_id "2.3.2.1" --arg audit_name "Ensure systemd-timesyncd configured with authorized timeserver" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 2.3.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.2.2" --arg audit_name "Ensure systemd-timesyncd is enabled and running" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 2.3.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.3.1" --arg audit_name "Ensure chrony is configured with authorized timeserver" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 2.3.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.3.2" --arg audit_name "Ensure chrony is running as user _chrony" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 2.3.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "2.3.3.3" --arg audit_name "Ensure chrony is enabled and running" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 2.3.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        fi
    fi
}


run_a__2_3_2_1() {
    output=$(a__2_3_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.3.2.1" --arg audit_name "Ensure systemd-timesyncd configured with authorized timeserver" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_3_2_2() {
    output=$(a__2_3_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.3.2.2" --arg audit_name "Ensure systemd-timesyncd is enabled and running" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_3_3_1() {
    output=$(a__2_3_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.3.3.1" --arg audit_name "Ensure chrony is configured with authorized timeserver" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_3_3_2() {
    output=$(a__2_3_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.3.3.2" --arg audit_name "Ensure chrony is running as user _chrony" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_3_3_3() {
    output=$(a__2_3_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.3.3.3" --arg audit_name "Ensure chrony is enabled and running" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_1() {
    output=$(a__2_4_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.1" --arg audit_name "Ensure cron daemon is enabled and active" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_2() {
    output=$(a__2_4_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.2" --arg audit_name "Ensure permissions on /etc/crontab are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_3() {
    output=$(a__2_4_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.3" --arg audit_name "Ensure permissions on /etc/cron.hourly are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_4() {
    output=$(a__2_4_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.4" --arg audit_name "Ensure permissions on /etc/cron.daily are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_5() {
    output=$(a__2_4_1_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.5" --arg audit_name "Ensure permissions on /etc/cron.weekly are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_6() {
    output=$(a__2_4_1_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.6" --arg audit_name "Ensure permissions on /etc/cron.monthly are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_7() {
    output=$(a__2_4_1_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.7" --arg audit_name "Ensure permissions on /etc/cron.d are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__2_4_1_8() {
    output=$(a__2_4_1_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "2.4.1.8" --arg audit_name "Ensure crontab is restricted to authorized users" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_1_2() {
    output=$(a__3_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.1.2" --arg audit_name "Ensure bluetooth services are not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_2_1() {
    output=$(a__3_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.2.1" --arg audit_name "Ensure dccp kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_2_2() {
    output=$(a__3_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.2.2" --arg audit_name "Ensure tipc kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_2_3() {
    output=$(a__3_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.2.3" --arg audit_name "Ensure rds kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_2_4() {
    output=$(a__3_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.2.4" --arg audit_name "Ensure sctp kernel module is not available" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_1() {
    output=$(a__3_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.1" --arg audit_name "Ensure ip forwarding is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_10() {
    output=$(a__3_3_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.10" --arg audit_name "Ensure tcp syn cookies is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_11() {
    output=$(a__3_3_11 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.11" --arg audit_name "Ensure ipv6 router advertisements are not accepted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_2() {
    output=$(a__3_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.2" --arg audit_name "Ensure packet redirect sending is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_3() {
    output=$(a__3_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.3" --arg audit_name "Ensure bogus icmp responses are ignored" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_4() {
    output=$(a__3_3_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.4" --arg audit_name "Ensure broadcast icmp requests are ignored" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_5() {
    output=$(a__3_3_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.5" --arg audit_name "Ensure icmp redirects are not accepted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_6() {
    output=$(a__3_3_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.6" --arg audit_name "Ensure secure icmp redirects are not accepted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_7() {
    output=$(a__3_3_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.7" --arg audit_name "Ensure reverse path filtering is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_8() {
    output=$(a__3_3_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.8" --arg audit_name "Ensure source routed packets are not accepted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__3_3_9() {
    output=$(a__3_3_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "3.3.9" --arg audit_name "Ensure suspicious packets are logged" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_1_1() {
    output=$(a__4_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.1.1" --arg audit_name "Ensure a single firewall configuration utility is in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
    matched=false
    executed_audits=""
    if echo "$output" | grep -Eq "A single firewall is in use: ufw"; then
        run_a__4_2_1
        executed_audits="$executed_audits 4.2.1"
        run_a__4_2_2
        executed_audits="$executed_audits 4.2.2"
        run_a__4_2_3
        executed_audits="$executed_audits 4.2.3"
        run_a__4_2_4
        executed_audits="$executed_audits 4.2.4"
        run_a__4_2_6
        executed_audits="$executed_audits 4.2.6"
        run_a__4_2_7
        executed_audits="$executed_audits 4.2.7"
        matched=true
    fi
    if echo "$output" | grep -Eq "A single firewall is in use: nftables"; then
        run_a__4_3_1
        executed_audits="$executed_audits 4.3.1"
        run_a__4_3_2
        executed_audits="$executed_audits 4.3.2"
        run_a__4_3_3
        executed_audits="$executed_audits 4.3.3"
        run_a__4_3_4
        executed_audits="$executed_audits 4.3.4"
        run_a__4_3_5
        executed_audits="$executed_audits 4.3.5"
        run_a__4_3_5
        executed_audits="$executed_audits 4.3.5"
        run_a__4_3_6
        executed_audits="$executed_audits 4.3.6"
        run_a__4_3_8
        executed_audits="$executed_audits 4.3.8"
        run_a__4_3_9
        executed_audits="$executed_audits 4.3.9"
        matched=true
    fi
    if echo "$output" | grep -Eq "A single firewall is in use: iptables"; then
        run_a__4_4_1_1
        executed_audits="$executed_audits 4.4.1.1"
        run_a__4_4_1_2
        executed_audits="$executed_audits 4.4.1.2"
        run_a__4_4_1_3
        executed_audits="$executed_audits 4.4.1.3"
        run_a__4_4_2_1
        executed_audits="$executed_audits 4.4.2.1"
        run_a__4_4_2_2
        executed_audits="$executed_audits 4.4.2.2"
        run_a__4_4_3_1
        executed_audits="$executed_audits 4.4.3.1"
        run_a__4_4_3_2
        executed_audits="$executed_audits 4.4.3.2"
        matched=true
    fi
    if [ "$matched" = false ]; then
        if [ "$status" = "FAIL" ] || [ "$status" = "ERROR" ]; then
            jq -n --arg audit_id "4.2.1" --arg audit_name "Ensure ufw is installed" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.2" --arg audit_name "Ensure iptables-persistent is not installed with ufw" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.3" --arg audit_name "Ensure ufw service is enabled" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.4" --arg audit_name "Ensure ufw loopback traffic is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.6" --arg audit_name "Ensure ufw firewall rules exist for all open ports" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.7" --arg audit_name "Ensure ufw default deny firewall policy" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.1" --arg audit_name "Ensure nftables is installed" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.2" --arg audit_name "Ensure ufw is uninstalled or disabled with nftables" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.3" --arg audit_name "Ensure iptables are flushed with nftables" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.4" --arg audit_name "Ensure a nftables table exists" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.5" --arg audit_name "Ensure nftables base chains exist" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.5" --arg audit_name "Ensure nftables base chains exist" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.6" --arg audit_name "Ensure nftables loopback traffic is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.8" --arg audit_name "Ensure nftables default deny firewall policy" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.9" --arg audit_name "Ensure nftables service is enabled" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.1.1" --arg audit_name "Ensure iptables packages are installed" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.1.2" --arg audit_name "Ensure nftables is not in use with iptables" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.1.3" --arg audit_name "Ensure ufw is not in use with iptables" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.2.1" --arg audit_name "Ensure iptables default deny firewall policy" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.2.2" --arg audit_name "Ensure iptables loopback traffic is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.3.1" --arg audit_name "Ensure ip6tables default deny firewall policy" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.3.2" --arg audit_name "Ensure ip6tables loopback traffic is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 4.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        else
            jq -n --arg audit_id "4.2.1" --arg audit_name "Ensure ufw is installed" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.2" --arg audit_name "Ensure iptables-persistent is not installed with ufw" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.3" --arg audit_name "Ensure ufw service is enabled" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.4" --arg audit_name "Ensure ufw loopback traffic is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.6" --arg audit_name "Ensure ufw firewall rules exist for all open ports" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.2.7" --arg audit_name "Ensure ufw default deny firewall policy" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.1" --arg audit_name "Ensure nftables is installed" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.2" --arg audit_name "Ensure ufw is uninstalled or disabled with nftables" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.3" --arg audit_name "Ensure iptables are flushed with nftables" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.4" --arg audit_name "Ensure a nftables table exists" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.5" --arg audit_name "Ensure nftables base chains exist" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.5" --arg audit_name "Ensure nftables base chains exist" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.6" --arg audit_name "Ensure nftables loopback traffic is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.8" --arg audit_name "Ensure nftables default deny firewall policy" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.3.9" --arg audit_name "Ensure nftables service is enabled" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.1.1" --arg audit_name "Ensure iptables packages are installed" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.1.2" --arg audit_name "Ensure nftables is not in use with iptables" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.1.3" --arg audit_name "Ensure ufw is not in use with iptables" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.2.1" --arg audit_name "Ensure iptables default deny firewall policy" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.2.2" --arg audit_name "Ensure iptables loopback traffic is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.3.1" --arg audit_name "Ensure ip6tables default deny firewall policy" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "4.4.3.2" --arg audit_name "Ensure ip6tables loopback traffic is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 4.1.1" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        fi
    fi
}


run_a__4_2_1() {
    output=$(a__4_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.2.1" --arg audit_name "Ensure ufw is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_2_2() {
    output=$(a__4_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.2.2" --arg audit_name "Ensure iptables-persistent is not installed with ufw" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_2_3() {
    output=$(a__4_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.2.3" --arg audit_name "Ensure ufw service is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_2_4() {
    output=$(a__4_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.2.4" --arg audit_name "Ensure ufw loopback traffic is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_2_6() {
    output=$(a__4_2_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.2.6" --arg audit_name "Ensure ufw firewall rules exist for all open ports" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_2_7() {
    output=$(a__4_2_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.2.7" --arg audit_name "Ensure ufw default deny firewall policy" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_1() {
    output=$(a__4_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.1" --arg audit_name "Ensure nftables is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_2() {
    output=$(a__4_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.2" --arg audit_name "Ensure ufw is uninstalled or disabled with nftables" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_3() {
    output=$(a__4_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.3" --arg audit_name "Ensure iptables are flushed with nftables" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_4() {
    output=$(a__4_3_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.4" --arg audit_name "Ensure a nftables table exists" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_5() {
    output=$(a__4_3_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.5" --arg audit_name "Ensure nftables base chains exist" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_6() {
    output=$(a__4_3_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.6" --arg audit_name "Ensure nftables loopback traffic is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_8() {
    output=$(a__4_3_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.8" --arg audit_name "Ensure nftables default deny firewall policy" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_3_9() {
    output=$(a__4_3_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.3.9" --arg audit_name "Ensure nftables service is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_1_1() {
    output=$(a__4_4_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.1.1" --arg audit_name "Ensure iptables packages are installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_1_2() {
    output=$(a__4_4_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.1.2" --arg audit_name "Ensure nftables is not in use with iptables" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_1_3() {
    output=$(a__4_4_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.1.3" --arg audit_name "Ensure ufw is not in use with iptables" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_2_1() {
    output=$(a__4_4_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.2.1" --arg audit_name "Ensure iptables default deny firewall policy" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_2_2() {
    output=$(a__4_4_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.2.2" --arg audit_name "Ensure iptables loopback traffic is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_3_1() {
    output=$(a__4_4_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.3.1" --arg audit_name "Ensure ip6tables default deny firewall policy" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__4_4_3_2() {
    output=$(a__4_4_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "4.4.3.2" --arg audit_name "Ensure ip6tables loopback traffic is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_1() {
    output=$(a__5_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.1" --arg audit_name "Ensure permissions on /etc/ssh/sshd_config are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_10() {
    output=$(a__5_1_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.10" --arg audit_name "Ensure sshd HostbasedAuthentication is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_11() {
    output=$(a__5_1_11 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.11" --arg audit_name "Ensure sshd IgnoreRhosts is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_12() {
    output=$(a__5_1_12 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.12" --arg audit_name "Ensure sshd KexAlgorithms is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_13() {
    output=$(a__5_1_13 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.13" --arg audit_name "Ensure sshd LoginGraceTime is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_14() {
    output=$(a__5_1_14 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.14" --arg audit_name "Ensure sshd LogLevel is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_15() {
    output=$(a__5_1_15 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.15" --arg audit_name "Ensure sshd MACs are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_16() {
    output=$(a__5_1_16 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.16" --arg audit_name "Ensure sshd MaxAuthTries is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_17() {
    output=$(a__5_1_17 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.17" --arg audit_name "Ensure sshd MaxSessions is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_18() {
    output=$(a__5_1_18 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.18" --arg audit_name "Ensure sshd MaxStartups is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_19() {
    output=$(a__5_1_19 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.19" --arg audit_name "Ensure sshd PermitEmptyPasswords is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_2() {
    output=$(a__5_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.2" --arg audit_name "Ensure permissions on SSH private host key files are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_20() {
    output=$(a__5_1_20 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.20" --arg audit_name "Ensure sshd PermitRootLogin is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_21() {
    output=$(a__5_1_21 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.21" --arg audit_name "Ensure sshd PermitUserEnvironment is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_22() {
    output=$(a__5_1_22 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.22" --arg audit_name "Ensure sshd UsePAM is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_3() {
    output=$(a__5_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.3" --arg audit_name "Ensure permissions on SSH public host key files are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_4() {
    output=$(a__5_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.4" --arg audit_name "Ensure sshd access is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_5() {
    output=$(a__5_1_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.5" --arg audit_name "Ensure sshd Banner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_6() {
    output=$(a__5_1_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.6" --arg audit_name "Ensure sshd Ciphers are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_7() {
    output=$(a__5_1_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.7" --arg audit_name "Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_8() {
    output=$(a__5_1_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.8" --arg audit_name "Ensure sshd DisableForwarding is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_1_9() {
    output=$(a__5_1_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.1.9" --arg audit_name "Ensure sshd GSSAPIAuthentication is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_2_1() {
    output=$(a__5_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.2.1" --arg audit_name "Ensure sudo is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_2_2() {
    output=$(a__5_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.2.2" --arg audit_name "Ensure sudo commands use pty" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_2_3() {
    output=$(a__5_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.2.3" --arg audit_name "Ensure sudo log file exists" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_2_4() {
    output=$(a__5_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.2.4" --arg audit_name "Ensure users must provide password for privilege escalation" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_2_5() {
    output=$(a__5_2_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.2.5" --arg audit_name "Ensure re-authentication for privilege escalation is not disabled globally" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_2_6() {
    output=$(a__5_2_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.2.6" --arg audit_name "Ensure sudo authentication timeout is configured correctly" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_1_1() {
    output=$(a__5_3_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.1.1" --arg audit_name "Ensure latest version of pam is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_1_2() {
    output=$(a__5_3_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.1.2" --arg audit_name "Ensure libpam-modules is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_1_3() {
    output=$(a__5_3_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.1.3" --arg audit_name "Ensure libpam-pwquality is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_2_1() {
    output=$(a__5_3_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.2.1" --arg audit_name "Ensure pam_unix module is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_2_2() {
    output=$(a__5_3_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.2.2" --arg audit_name "Ensure pam_faillock module is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_2_3() {
    output=$(a__5_3_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.2.3" --arg audit_name "Ensure pam_pwquality module is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_2_4() {
    output=$(a__5_3_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.2.4" --arg audit_name "Ensure pam_pwhistory module is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_1_1() {
    output=$(a__5_3_3_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.1.1" --arg audit_name "" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_1_2() {
    output=$(a__5_3_3_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.1.2" --arg audit_name "Ensure password unlock time is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_1_3() {
    output=$(a__5_3_3_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.1.3" --arg audit_name "Ensure password failed attempts lockout includes root account" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_1() {
    output=$(a__5_3_3_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.1" --arg audit_name "Ensure password number of changed characters is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_2() {
    output=$(a__5_3_3_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.2" --arg audit_name "Ensure minimum password length is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_4() {
    output=$(a__5_3_3_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.4" --arg audit_name "Ensure password same consecutive characters is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_5() {
    output=$(a__5_3_3_2_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.5" --arg audit_name "Ensure password maximum sequential characters is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_6() {
    output=$(a__5_3_3_2_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.6" --arg audit_name "Ensure password dictionary check is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_7() {
    output=$(a__5_3_3_2_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.7" --arg audit_name "Ensure password quality checking is enforced" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_2_8() {
    output=$(a__5_3_3_2_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.2.8" --arg audit_name "Ensure password quality is enforced for the root user" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_3_1() {
    output=$(a__5_3_3_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.3.1" --arg audit_name "Ensure password history remember is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_3_2() {
    output=$(a__5_3_3_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.3.2" --arg audit_name "Ensure password history is enforced for the root user" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_3_3() {
    output=$(a__5_3_3_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.3.3" --arg audit_name "Ensure pam_pwhistory includes use_authtok" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_4_1() {
    output=$(a__5_3_3_4_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.4.1" --arg audit_name "Ensure pam_unix does not include nullok" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_4_2() {
    output=$(a__5_3_3_4_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.4.2" --arg audit_name "Ensure pam_unix does not include remember" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_4_3() {
    output=$(a__5_3_3_4_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.4.3" --arg audit_name "Ensure pam_unix includes a strong password hashing algorithm" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_3_3_4_4() {
    output=$(a__5_3_3_4_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.3.3.4.4" --arg audit_name "Ensure pam_unix includes use_authtok" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_1_1() {
    output=$(a__5_4_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.1.1" --arg audit_name "Ensure password expiration is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_1_2() {
    output=$(a__5_4_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.1.2" --arg audit_name "Ensure minimum password days is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_1_3() {
    output=$(a__5_4_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.1.3" --arg audit_name "Ensure password expiration warning days is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_1_4() {
    output=$(a__5_4_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.1.4" --arg audit_name "Ensure strong password hashing algorithm is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_1_5() {
    output=$(a__5_4_1_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.1.5" --arg audit_name "Ensure inactive password lock is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_1_6() {
    output=$(a__5_4_1_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.1.6" --arg audit_name "Ensure all users last password change date is in the past" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_1() {
    output=$(a__5_4_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.1" --arg audit_name "Ensure root is the only UID 0 account" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_2() {
    output=$(a__5_4_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.2" --arg audit_name "Ensure root is the only GID 0 account" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_3() {
    output=$(a__5_4_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.3" --arg audit_name "Ensure group root is the only GID 0 group" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_4() {
    output=$(a__5_4_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.4" --arg audit_name "Ensure root account access is controlled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_5() {
    output=$(a__5_4_2_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.5" --arg audit_name "Ensure root path integrity" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_6() {
    output=$(a__5_4_2_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.6" --arg audit_name "Ensure root user umask is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_7() {
    output=$(a__5_4_2_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.7" --arg audit_name "Ensure system accounts do not have a valid login shell" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_2_8() {
    output=$(a__5_4_2_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.2.8" --arg audit_name "Ensure accounts without a valid login shell are locked" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_3_1() {
    output=$(a__5_4_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.3.1" --arg audit_name "Ensure nologin is not listed in /etc/shells" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_3_2() {
    output=$(a__5_4_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.3.2" --arg audit_name "Ensure default user shell timeout is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__5_4_3_3() {
    output=$(a__5_4_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "5.4.3.3" --arg audit_name "Ensure default user umask is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_1_1() {
    output=$(a__6_1_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.1.1" --arg audit_name "Ensure journald service is enabled and active" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_1_4() {
    output=$(a__6_1_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.1.4" --arg audit_name "Ensure only one logging system is in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
    matched=false
    executed_audits=""
    if echo "$output" | grep -Eq "rsyslog"; then
        run_a__6_1_3_1
        executed_audits="$executed_audits 6.1.3.1"
        run_a__6_1_3_2
        executed_audits="$executed_audits 6.1.3.2"
        run_a__6_1_3_3
        executed_audits="$executed_audits 6.1.3.3"
        run_a__6_1_3_4
        executed_audits="$executed_audits 6.1.3.4"
        run_a__6_1_3_7
        executed_audits="$executed_audits 6.1.3.7"
        matched=true
    fi
    if echo "$output" | grep -Eq "journald"; then
        run_a__6_1_2_1_1
        executed_audits="$executed_audits 6.1.2.1.1"
        run_a__6_1_2_1_3
        executed_audits="$executed_audits 6.1.2.1.3"
        run_a__6_1_2_1_4
        executed_audits="$executed_audits 6.1.2.1.4"
        run_a__6_1_2_2
        executed_audits="$executed_audits 6.1.2.2"
        run_a__6_1_2_3
        executed_audits="$executed_audits 6.1.2.3"
        run_a__6_1_2_4
        executed_audits="$executed_audits 6.1.2.4"
        matched=true
    fi
    if [ "$matched" = false ]; then
        if [ "$status" = "FAIL" ] || [ "$status" = "ERROR" ]; then
            jq -n --arg audit_id "6.1.2.1.1" --arg audit_name "Ensure systemd-journal-remote is installed" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.1.3" --arg audit_name "Ensure systemd-journal-upload is enabled and active" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.1.4" --arg audit_name "Ensure systemd-journal-remote service is not in use" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.2" --arg audit_name "Ensure journald ForwardToSyslog is disabled" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.3" --arg audit_name "Ensure journald Compress is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.4" --arg audit_name "Ensure journald Storage is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.1" --arg audit_name "Ensure rsyslog is installed" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.2" --arg audit_name "Ensure rsyslog service is enabled and active" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.3" --arg audit_name "Ensure journald is configured to send logs to rsyslog" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.4" --arg audit_name "Ensure rsyslog log file creation mode is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.7" --arg audit_name "Ensure rsyslog is not configured to receive logs from a remote client" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.1.1.4 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        else
            jq -n --arg audit_id "6.1.2.1.1" --arg audit_name "Ensure systemd-journal-remote is installed" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.1.3" --arg audit_name "Ensure systemd-journal-upload is enabled and active" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.1.4" --arg audit_name "Ensure systemd-journal-remote service is not in use" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.2" --arg audit_name "Ensure journald ForwardToSyslog is disabled" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.3" --arg audit_name "Ensure journald Compress is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.2.4" --arg audit_name "Ensure journald Storage is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.1" --arg audit_name "Ensure rsyslog is installed" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.2" --arg audit_name "Ensure rsyslog service is enabled and active" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.3" --arg audit_name "Ensure journald is configured to send logs to rsyslog" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.4" --arg audit_name "Ensure rsyslog log file creation mode is configured" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.1.3.7" --arg audit_name "Ensure rsyslog is not configured to receive logs from a remote client" \
                --arg status "PASS" --arg output "Skipped: not applicable due to 6.1.1.4" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        fi
    fi
}


run_a__6_1_2_1_1() {
    output=$(a__6_1_2_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.2.1.1" --arg audit_name "Ensure systemd-journal-remote is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_2_1_3() {
    output=$(a__6_1_2_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.2.1.3" --arg audit_name "Ensure systemd-journal-upload is enabled and active" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_2_1_4() {
    output=$(a__6_1_2_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.2.1.4" --arg audit_name "Ensure systemd-journal-remote service is not in use" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_2_2() {
    output=$(a__6_1_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.2.2" --arg audit_name "Ensure journald ForwardToSyslog is disabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_2_3() {
    output=$(a__6_1_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.2.3" --arg audit_name "Ensure journald Compress is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_2_4() {
    output=$(a__6_1_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.2.4" --arg audit_name "Ensure journald Storage is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_3_1() {
    output=$(a__6_1_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.3.1" --arg audit_name "Ensure rsyslog is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_3_2() {
    output=$(a__6_1_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.3.2" --arg audit_name "Ensure rsyslog service is enabled and active" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_3_3() {
    output=$(a__6_1_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.3.3" --arg audit_name "Ensure journald is configured to send logs to rsyslog" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_3_4() {
    output=$(a__6_1_3_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.3.4" --arg audit_name "Ensure rsyslog log file creation mode is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_3_7() {
    output=$(a__6_1_3_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.3.7" --arg audit_name "Ensure rsyslog is not configured to receive logs from a remote client" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_1_4_1() {
    output=$(a__6_1_4_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.1.4.1" --arg audit_name "Ensure access to all logfiles has been configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_1_1() {
    output=$(a__6_2_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.1.1" --arg audit_name "Ensure auditd packages are installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
    matched=false
    executed_audits=""
    if echo "$output" | grep -Eq "All required audit packages are installed"; then
        run_a__6_2_1_2
        executed_audits="$executed_audits 6.2.1.2"
        run_a__6_2_1_3
        executed_audits="$executed_audits 6.2.1.3"
        run_a__6_2_1_4
        executed_audits="$executed_audits 6.2.1.4"
        run_a__6_2_2_1
        executed_audits="$executed_audits 6.2.2.1"
        run_a__6_2_2_2
        executed_audits="$executed_audits 6.2.2.2"
        run_a__6_2_2_3
        executed_audits="$executed_audits 6.2.2.3"
        run_a__6_2_2_4
        executed_audits="$executed_audits 6.2.2.4"
        run_a__6_2_3_1
        executed_audits="$executed_audits 6.2.3.1"
        run_a__6_2_3_2
        executed_audits="$executed_audits 6.2.3.2"
        run_a__6_2_3_3
        executed_audits="$executed_audits 6.2.3.3"
        run_a__6_2_3_4
        executed_audits="$executed_audits 6.2.3.4"
        run_a__6_2_3_5
        executed_audits="$executed_audits 6.2.3.5"
        run_a__6_2_3_6
        executed_audits="$executed_audits 6.2.3.6"
        run_a__6_2_3_7
        executed_audits="$executed_audits 6.2.3.7"
        run_a__6_2_3_8
        executed_audits="$executed_audits 6.2.3.8"
        run_a__6_2_3_9
        executed_audits="$executed_audits 6.2.3.9"
        run_a__6_2_3_10
        executed_audits="$executed_audits 6.2.3.10"
        run_a__6_2_3_11
        executed_audits="$executed_audits 6.2.3.11"
        run_a__6_2_3_12
        executed_audits="$executed_audits 6.2.3.12"
        run_a__6_2_3_13
        executed_audits="$executed_audits 6.2.3.13"
        run_a__6_2_3_14
        executed_audits="$executed_audits 6.2.3.14"
        run_a__6_2_3_15
        executed_audits="$executed_audits 6.2.3.15"
        run_a__6_2_3_16
        executed_audits="$executed_audits 6.2.3.16"
        run_a__6_2_3_17
        executed_audits="$executed_audits 6.2.3.17"
        run_a__6_2_3_18
        executed_audits="$executed_audits 6.2.3.18"
        run_a__6_2_3_19
        executed_audits="$executed_audits 6.2.3.19"
        run_a__6_2_3_20
        executed_audits="$executed_audits 6.2.3.20"
        run_a__6_2_4_1
        executed_audits="$executed_audits 6.2.4.1"
        run_a__6_2_4_2
        executed_audits="$executed_audits 6.2.4.2"
        run_a__6_2_4_3
        executed_audits="$executed_audits 6.2.4.3"
        run_a__6_2_4_4
        executed_audits="$executed_audits 6.2.4.4"
        run_a__6_2_4_5
        executed_audits="$executed_audits 6.2.4.5"
        run_a__6_2_4_6
        executed_audits="$executed_audits 6.2.4.6"
        run_a__6_2_4_7
        executed_audits="$executed_audits 6.2.4.7"
        run_a__6_2_4_8
        executed_audits="$executed_audits 6.2.4.8"
        run_a__6_2_4_9
        executed_audits="$executed_audits 6.2.4.9"
        run_a__6_2_4_10
        executed_audits="$executed_audits 6.2.4.10"
        matched=true
    fi
    if [ "$matched" = false ]; then
        if [ "$status" = "FAIL" ] || [ "$status" = "ERROR" ]; then
            jq -n --arg audit_id "6.2.1.2" --arg audit_name "Ensure auditd service is enabled and active" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.1.3" --arg audit_name "Ensure auditing for processes that start prior to auditd is enabled" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.1.4" --arg audit_name "Ensure audit_backlog_limit is sufficient" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.1" --arg audit_name "Ensure audit log storage size is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.2" --arg audit_name "Ensure audit logs are not automatically deleted" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.3" --arg audit_name "Ensure system is disabled when audit logs are full" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.4" --arg audit_name "Ensure system warns when audit logs are low on space" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.1" --arg audit_name "Ensure changes to system administration scope is collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.2" --arg audit_name "Ensure actions as another user are always logged" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.3" --arg audit_name "Ensure events that modify the sudo log file are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.4" --arg audit_name "Ensure events that modify date and time information are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.5" --arg audit_name "Ensure events that modify the system's network environment are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.6" --arg audit_name "Ensure use of privileged commands are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.7" --arg audit_name "Ensure unsuccessful file access attempts are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.8" --arg audit_name "Ensure events that modify user/group information are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.9" --arg audit_name "Ensure discretionary access control permission modification events are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.10" --arg audit_name "Ensure successful file system mounts are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.11" --arg audit_name "Ensure session initiation information is collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.12" --arg audit_name "Ensure login and logout events are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.13" --arg audit_name "Ensure file deletion events by users are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.14" --arg audit_name "Ensure events that modify the system's Mandatory Access Controls are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.15" --arg audit_name "Ensure successful and unsuccessful attempts to use the chcon command are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.16" --arg audit_name "Ensure successful and unsuccessful attempts to use the setfacl command are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.17" --arg audit_name "Ensure successful and unsuccessful attempts to use the chacl command are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.18" --arg audit_name "Ensure successful and unsuccessful attempts to use the usermod command are collected" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.19" --arg audit_name "6.2.3.19" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.20" --arg audit_name "6.2.3.20" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.1" --arg audit_name "Ensure audit log files mode is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.2" --arg audit_name "Ensure audit log files owner is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.3" --arg audit_name "Ensure audit log files group owner is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.4" --arg audit_name "Ensure the audit log file directory mode is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.5" --arg audit_name "Ensure audit configuration files mode is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.6" --arg audit_name "Ensure audit configuration files owner is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.7" --arg audit_name "Ensure audit configuration files group owner is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.8" --arg audit_name "Ensure audit tools mode is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.9" --arg audit_name "Ensure audit tools owner is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.10" --arg audit_name "Ensure audit tools group owner is configured" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.2.1.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        else
            jq -n --arg audit_id "6.2.1.2" --arg audit_name "Ensure auditd service is enabled and active" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.1.3" --arg audit_name "Ensure auditing for processes that start prior to auditd is enabled" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.1.4" --arg audit_name "Ensure audit_backlog_limit is sufficient" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.1" --arg audit_name "Ensure audit log storage size is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.2" --arg audit_name "Ensure audit logs are not automatically deleted" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.3" --arg audit_name "Ensure system is disabled when audit logs are full" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.2.4" --arg audit_name "Ensure system warns when audit logs are low on space" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.1" --arg audit_name "Ensure changes to system administration scope is collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.2" --arg audit_name "Ensure actions as another user are always logged" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.3" --arg audit_name "Ensure events that modify the sudo log file are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.4" --arg audit_name "Ensure events that modify date and time information are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.5" --arg audit_name "Ensure events that modify the system's network environment are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.6" --arg audit_name "Ensure use of privileged commands are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.7" --arg audit_name "Ensure unsuccessful file access attempts are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.8" --arg audit_name "Ensure events that modify user/group information are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.9" --arg audit_name "Ensure discretionary access control permission modification events are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.10" --arg audit_name "Ensure successful file system mounts are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.11" --arg audit_name "Ensure session initiation information is collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.12" --arg audit_name "Ensure login and logout events are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.13" --arg audit_name "Ensure file deletion events by users are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.14" --arg audit_name "Ensure events that modify the system's Mandatory Access Controls are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.15" --arg audit_name "Ensure successful and unsuccessful attempts to use the chcon command are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.16" --arg audit_name "Ensure successful and unsuccessful attempts to use the setfacl command are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.17" --arg audit_name "Ensure successful and unsuccessful attempts to use the chacl command are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.18" --arg audit_name "Ensure successful and unsuccessful attempts to use the usermod command are collected" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.19" --arg audit_name "6.2.3.19" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.3.20" --arg audit_name "6.2.3.20" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.1" --arg audit_name "Ensure audit log files mode is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.2" --arg audit_name "Ensure audit log files owner is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.3" --arg audit_name "Ensure audit log files group owner is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.4" --arg audit_name "Ensure the audit log file directory mode is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.5" --arg audit_name "Ensure audit configuration files mode is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.6" --arg audit_name "Ensure audit configuration files owner is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.7" --arg audit_name "Ensure audit configuration files group owner is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.8" --arg audit_name "Ensure audit tools mode is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.9" --arg audit_name "Ensure audit tools owner is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.2.4.10" --arg audit_name "Ensure audit tools group owner is configured" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.2.1.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        fi
    fi
}


run_a__6_2_1_2() {
    output=$(a__6_2_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.1.2" --arg audit_name "Ensure auditd service is enabled and active" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_1_3() {
    output=$(a__6_2_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.1.3" --arg audit_name "Ensure auditing for processes that start prior to auditd is enabled" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_1_4() {
    output=$(a__6_2_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.1.4" --arg audit_name "Ensure audit_backlog_limit is sufficient" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_2_1() {
    output=$(a__6_2_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.2.1" --arg audit_name "Ensure audit log storage size is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_2_2() {
    output=$(a__6_2_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.2.2" --arg audit_name "Ensure audit logs are not automatically deleted" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_2_3() {
    output=$(a__6_2_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.2.3" --arg audit_name "Ensure system is disabled when audit logs are full" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_2_4() {
    output=$(a__6_2_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.2.4" --arg audit_name "Ensure system warns when audit logs are low on space" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_1() {
    output=$(a__6_2_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.1" --arg audit_name "Ensure changes to system administration scope is collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_10() {
    output=$(a__6_2_3_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.10" --arg audit_name "Ensure successful file system mounts are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_11() {
    output=$(a__6_2_3_11 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.11" --arg audit_name "Ensure session initiation information is collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_12() {
    output=$(a__6_2_3_12 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.12" --arg audit_name "Ensure login and logout events are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_13() {
    output=$(a__6_2_3_13 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.13" --arg audit_name "Ensure file deletion events by users are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_14() {
    output=$(a__6_2_3_14 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.14" --arg audit_name "Ensure events that modify the system's Mandatory Access Controls are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_15() {
    output=$(a__6_2_3_15 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.15" --arg audit_name "Ensure successful and unsuccessful attempts to use the chcon command are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_16() {
    output=$(a__6_2_3_16 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.16" --arg audit_name "Ensure successful and unsuccessful attempts to use the setfacl command are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_17() {
    output=$(a__6_2_3_17 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.17" --arg audit_name "Ensure successful and unsuccessful attempts to use the chacl command are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_18() {
    output=$(a__6_2_3_18 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.18" --arg audit_name "Ensure successful and unsuccessful attempts to use the usermod command are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_19() {
    output=$(a__6_2_3_19 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.19" --arg audit_name "6.2.3.19" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_2() {
    output=$(a__6_2_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.2" --arg audit_name "Ensure actions as another user are always logged" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_20() {
    output=$(a__6_2_3_20 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.20" --arg audit_name "6.2.3.20" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_3() {
    output=$(a__6_2_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.3" --arg audit_name "Ensure events that modify the sudo log file are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_4() {
    output=$(a__6_2_3_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.4" --arg audit_name "Ensure events that modify date and time information are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_5() {
    output=$(a__6_2_3_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.5" --arg audit_name "Ensure events that modify the system's network environment are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_6() {
    output=$(a__6_2_3_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.6" --arg audit_name "Ensure use of privileged commands are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_7() {
    output=$(a__6_2_3_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.7" --arg audit_name "Ensure unsuccessful file access attempts are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_8() {
    output=$(a__6_2_3_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.8" --arg audit_name "Ensure events that modify user/group information are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_3_9() {
    output=$(a__6_2_3_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.3.9" --arg audit_name "Ensure discretionary access control permission modification events are collected" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_1() {
    output=$(a__6_2_4_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.1" --arg audit_name "Ensure audit log files mode is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_10() {
    output=$(a__6_2_4_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.10" --arg audit_name "Ensure audit tools group owner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_2() {
    output=$(a__6_2_4_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.2" --arg audit_name "Ensure audit log files owner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_3() {
    output=$(a__6_2_4_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.3" --arg audit_name "Ensure audit log files group owner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_4() {
    output=$(a__6_2_4_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.4" --arg audit_name "Ensure the audit log file directory mode is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_5() {
    output=$(a__6_2_4_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.5" --arg audit_name "Ensure audit configuration files mode is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_6() {
    output=$(a__6_2_4_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.6" --arg audit_name "Ensure audit configuration files owner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_7() {
    output=$(a__6_2_4_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.7" --arg audit_name "Ensure audit configuration files group owner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_8() {
    output=$(a__6_2_4_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.8" --arg audit_name "Ensure audit tools mode is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_2_4_9() {
    output=$(a__6_2_4_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.2.4.9" --arg audit_name "Ensure audit tools owner is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_3_1() {
    output=$(a__6_3_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.3.1" --arg audit_name "Ensure AIDE is installed" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
    matched=false
    executed_audits=""
    if echo "$output" | grep -Eq "aide is installed"; then
        run_a__6_3_2
        executed_audits="$executed_audits 6.3.2"
        run_a__6_3_3
        executed_audits="$executed_audits 6.3.3"
        matched=true
    fi
    if [ "$matched" = false ]; then
        if [ "$status" = "FAIL" ] || [ "$status" = "ERROR" ]; then
            jq -n --arg audit_id "6.3.2" --arg audit_name "Ensure filesystem integrity is regularly checked" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.3.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.3.3" --arg audit_name "Ensure cryptographic mechanisms are used to protect the integrity of audit tools" \
                --arg status "FAIL" --arg output "Skipped: prerequisite audit 6.3.1 failed" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        else
            jq -n --arg audit_id "6.3.2" --arg audit_name "Ensure filesystem integrity is regularly checked" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.3.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
            jq -n --arg audit_id "6.3.3" --arg audit_name "Ensure cryptographic mechanisms are used to protect the integrity of audit tools" \
                --arg status "FAIL" --arg output "Skipped: audit not applicable because 6.3.1 conditions not met" \
                '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
        fi
    fi
}


run_a__6_3_2() {
    output=$(a__6_3_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.3.2" --arg audit_name "Ensure filesystem integrity is regularly checked" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__6_3_3() {
    output=$(a__6_3_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "6.3.3" --arg audit_name "Ensure cryptographic mechanisms are used to protect the integrity of audit tools" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_1() {
    output=$(a__7_1_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.1" --arg audit_name "Ensure permissions on /etc/passwd are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_10() {
    output=$(a__7_1_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.10" --arg audit_name "Ensure permissions on /etc/security/opasswd are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_11() {
    output=$(a__7_1_11 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.11" --arg audit_name "Ensure world writable files and directories are secured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_12() {
    output=$(a__7_1_12 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.12" --arg audit_name "Ensure no files or directories without an owner and a group exist" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_2() {
    output=$(a__7_1_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.2" --arg audit_name "Ensure permissions on /etc/passwd- are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_3() {
    output=$(a__7_1_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.3" --arg audit_name "Ensure permissions on /etc/group are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_4() {
    output=$(a__7_1_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.4" --arg audit_name "Ensure permissions on /etc/group- are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_5() {
    output=$(a__7_1_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.5" --arg audit_name "Ensure permissions on /etc/shadow are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_6() {
    output=$(a__7_1_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.6" --arg audit_name "Ensure permissions on /etc/shadow- are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_7() {
    output=$(a__7_1_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.7" --arg audit_name "Ensure permissions on /etc/gshadow are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_8() {
    output=$(a__7_1_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.8" --arg audit_name "Ensure permissions on /etc/gshadow- are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_1_9() {
    output=$(a__7_1_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.1.9" --arg audit_name "Ensure permissions on /etc/shells are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_1() {
    output=$(a__7_2_1 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.1" --arg audit_name "Ensure accounts in /etc/passwd use shadowed passwords" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_10() {
    output=$(a__7_2_10 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.10" --arg audit_name "Ensure local interactive user dot files access is configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_2() {
    output=$(a__7_2_2 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.2" --arg audit_name "Ensure /etc/shadow password fields are not empty" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_3() {
    output=$(a__7_2_3 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.3" --arg audit_name "Ensure all groups in /etc/passwd exist in /etc/group" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_4() {
    output=$(a__7_2_4 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.4" --arg audit_name "Ensure shadow group is empty" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_5() {
    output=$(a__7_2_5 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.5" --arg audit_name "Ensure no duplicate UIDs exist" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_6() {
    output=$(a__7_2_6 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.6" --arg audit_name "Ensure no duplicate GIDs exist" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_7() {
    output=$(a__7_2_7 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.7" --arg audit_name "Ensure no duplicate user names exist" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_8() {
    output=$(a__7_2_8 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.8" --arg audit_name "Ensure no duplicate group names exist" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


run_a__7_2_9() {
    output=$(a__7_2_9 2>&1)
    if echo "$output" | grep -q "\*\* ERROR \*\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\*\* PASS \*\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    jq -n --arg audit_id "7.2.9" --arg audit_name "Ensure local interactive user home directories are configured" --arg status "$status" --arg output "$output" \
        '{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}' >> tmp_results.json
}


# Run all root audits and collect JSON output
rm -f tmp_results.json
touch tmp_results.json

run_a__1_1_1_1
run_a__1_1_1_2
run_a__1_1_1_3
run_a__1_1_1_4
run_a__1_1_1_5
run_a__1_1_1_6
run_a__1_1_1_7
run_a__1_1_1_8
run_a__1_1_1_9
run_a__1_1_1_10
run_a__1_1_2_1_1
run_a__1_1_2_1_2
run_a__1_1_2_1_3
run_a__1_1_2_1_4
run_a__1_1_2_2_1
run_a__1_1_2_2_2
run_a__1_1_2_2_3
run_a__1_1_2_2_4
run_a__1_1_2_3_1
run_a__1_1_2_3_2
run_a__1_1_2_3_3
run_a__1_1_2_4_1
run_a__1_1_2_4_2
run_a__1_1_2_4_3
run_a__1_1_2_5_1
run_a__1_1_2_5_2
run_a__1_1_2_5_3
run_a__1_1_2_5_4
run_a__1_1_2_6_1
run_a__1_1_2_6_2
run_a__1_1_2_6_3
run_a__1_1_2_6_4
run_a__1_1_2_7_1
run_a__1_1_2_7_2
run_a__1_3_1_1
run_a__1_3_1_2
run_a__1_3_1_3
run_a__1_3_1_4
run_a__1_4_1
run_a__1_4_2
run_a__1_5_1
run_a__1_5_2
run_a__1_5_3
run_a__1_5_4
run_a__1_5_5
run_a__1_6_1
run_a__1_6_2
run_a__1_6_3
run_a__1_6_4
run_a__1_6_5
run_a__1_6_6
run_a__1_7_1
run_a__1_7_2
run_a__1_7_3
run_a__1_7_4
run_a__1_7_5
run_a__1_7_6
run_a__1_7_7
run_a__1_7_8
run_a__1_7_9
run_a__1_7_10
run_a__2_1_1
run_a__2_1_2
run_a__2_1_3
run_a__2_1_4
run_a__2_1_5
run_a__2_1_6
run_a__2_1_7
run_a__2_1_9
run_a__2_1_10
run_a__2_1_11
run_a__2_1_12
run_a__2_1_13
run_a__2_1_15
run_a__2_1_16
run_a__2_1_17
run_a__2_1_18
run_a__2_1_19
run_a__2_1_20
run_a__2_1_21
run_a__2_2_1
run_a__2_2_2
run_a__2_2_3
run_a__2_2_4
run_a__2_2_5
run_a__2_2_6
run_a__2_3_1_1
run_a__2_4_1_1
run_a__2_4_1_2
run_a__2_4_1_3
run_a__2_4_1_4
run_a__2_4_1_5
run_a__2_4_1_6
run_a__2_4_1_7
run_a__2_4_1_8
run_a__3_1_2
run_a__3_2_1
run_a__3_2_2
run_a__3_2_3
run_a__3_2_4
run_a__3_3_1
run_a__3_3_2
run_a__3_3_3
run_a__3_3_4
run_a__3_3_5
run_a__3_3_6
run_a__3_3_7
run_a__3_3_8
run_a__3_3_9
run_a__3_3_10
run_a__3_3_11
run_a__4_1_1
run_a__5_1_1
run_a__5_1_2
run_a__5_1_3
run_a__5_1_4
run_a__5_1_5
run_a__5_1_6
run_a__5_1_7
run_a__5_1_8
run_a__5_1_9
run_a__5_1_10
run_a__5_1_11
run_a__5_1_12
run_a__5_1_13
run_a__5_1_14
run_a__5_1_15
run_a__5_1_16
run_a__5_1_17
run_a__5_1_18
run_a__5_1_19
run_a__5_1_20
run_a__5_1_21
run_a__5_1_22
run_a__5_2_1
run_a__5_2_2
run_a__5_2_3
run_a__5_2_4
run_a__5_2_5
run_a__5_2_6
run_a__5_3_1_1
run_a__5_3_1_2
run_a__5_3_1_3
run_a__5_3_2_1
run_a__5_3_2_2
run_a__5_3_2_3
run_a__5_3_2_4
run_a__5_3_3_1_1
run_a__5_3_3_1_2
run_a__5_3_3_1_3
run_a__5_3_3_2_1
run_a__5_3_3_2_2
run_a__5_3_3_2_4
run_a__5_3_3_2_5
run_a__5_3_3_2_6
run_a__5_3_3_2_7
run_a__5_3_3_2_8
run_a__5_3_3_3_1
run_a__5_3_3_3_2
run_a__5_3_3_3_3
run_a__5_3_3_4_1
run_a__5_3_3_4_2
run_a__5_3_3_4_3
run_a__5_3_3_4_4
run_a__5_4_1_1
run_a__5_4_1_2
run_a__5_4_1_3
run_a__5_4_1_4
run_a__5_4_1_5
run_a__5_4_1_6
run_a__5_4_2_1
run_a__5_4_2_2
run_a__5_4_2_3
run_a__5_4_2_4
run_a__5_4_2_5
run_a__5_4_2_6
run_a__5_4_2_7
run_a__5_4_2_8
run_a__5_4_3_1
run_a__5_4_3_2
run_a__5_4_3_3
run_a__6_1_1_1
run_a__6_1_1_4
run_a__6_1_4_1
run_a__6_2_1_1
run_a__6_3_1
run_a__7_1_1
run_a__7_1_2
run_a__7_1_3
run_a__7_1_4
run_a__7_1_5
run_a__7_1_6
run_a__7_1_7
run_a__7_1_8
run_a__7_1_9
run_a__7_1_10
run_a__7_1_11
run_a__7_1_12
run_a__7_2_1
run_a__7_2_2
run_a__7_2_3
run_a__7_2_4
run_a__7_2_5
run_a__7_2_6
run_a__7_2_7
run_a__7_2_8
run_a__7_2_9
run_a__7_2_10

# Finalize JSON
jq -s 'sort_by(.audit_id | split(".") | map(try tonumber catch .))' tmp_results.json > /tmp/results_CIS_Ubuntu_Linux_24.04.json
rm -f tmp_results.json
echo "Audit complete. Results saved to results_CIS_Ubuntu_Linux_24.04.json"
