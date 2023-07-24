#!/bin/sh
#
# ahrStamp.sh - Install AHR service providing ahr_stamp
# Requires Dialog
#

DMMahr="ahr_stamp.c";
DMMahrExe="ahr_stamp";

# Function to generate ahr_stamp C code
generate_ahr_stamp_code() {
    cat << 'EOF' > "${DMMahr}"
#include <stdio.h>
#include <time.h>

// Function to generate the auto-generated timestamp in the format "counter:timestamp"
void ahr_stamp() {
    static int callCounter = 0;
    struct timespec currentTime;
    clock_gettime(CLOCK_REALTIME, &currentTime);

    // Increment the call counter
    callCounter++;

    // Extract individual components of the timestamp
    struct tm timeInfo;
    localtime_r(&currentTime.tv_sec, &timeInfo);

    // Format and print the auto-generated timestamp
    printf("%09d:%04d%02d%02d%02d%02d%02d.%09ld\n",
           callCounter,
           timeInfo.tm_year + 1900,
           timeInfo.tm_mon + 1,
           timeInfo.tm_mday,
           timeInfo.tm_hour,
           timeInfo.tm_min,
           timeInfo.tm_sec,
           currentTime.tv_nsec);
}

int main() {
    // Call the function to generate and print the auto-generated timestamp
    ahr_stamp();

    return 0;
}
EOF
}

# Function to compile and install ahr_stamp
install_ahr_stamp() {
    gcc -o "${DMMahrExe}" "${DMMahr}" -lrt
    cp "${DMMahrExe}" /usr/local/bin/
    chmod +x "/usr/local/bin/${DMMahrExe}"
}

# Function to set up AHR service providing ahr_stamp
setup_ahr_service() {
    cat << EOF | tee /etc/systemd/system/ahr.service > /dev/null
[Unit]
Description=AHR Service providing ahr_stamp

[Service]
ExecStart=/usr/local/bin/${DMMahrExe}
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ahr
    systemctl start ahr
}

# Function to verify installation and service status
verify_installation() {
    # Check if ahr_stamp is in place
    if [ -x "/usr/local/bin/${DMMahrExe}" ]; then
        echo "ahr_stamp executable is installed in /usr/local/bin/${DMMahrExe}"
    else
        echo "ahr_stamp executable is not installed in /usr/local/bin/${DMMahrExe}"
    fi

    # Check if the AHR service is enabled and running
    if systemctl is-active --quiet ahr; then
        echo "AHR service is running."
    else
        echo "AHR service is not running."
    fi

    if systemctl is-enabled --quiet ahr; then
        echo "AHR service is enabled to start on boot."
    else
        echo "AHR service is not enabled to start on boot."
    fi
}

# Main script execution
generate_ahr_stamp_code
install_ahr_stamp
setup_ahr_service
verify_installation

echo "AHR service providing ahr_stamp has been installed and set up."
