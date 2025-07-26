#!/bin/bash
#
# ZIPFREAK v1.0 - Advanced ZIP Password Utility
# License: GNU GPLv3 (https://www.gnu.org/licenses/gpl-3.0.html)
# Copyright (C) 2025 B1tZ3r0 - SpeCTeR
#
# Warning: This tool is for legal use only.
# Users assume full responsibility for their actions.



# Color
# Regular Colors
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'

# Bold
BBlack='\033[1;30m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BBlue='\033[1;34m'
BPurple='\033[1;35m'
BCyan='\033[1;36m'
BWhite='\033[1;37m'
RESET='\033[0m'

# Clear screen
clear


# Check dependencies
check_dependencies() {
    local missing=()
    local required=("zip" "unzip" "john" "zip2john")
    
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${BRed}[!] Missing dependencies:${RESET}"
        for dep in "${missing[@]}"; do
            echo -e " - $dep"
        done
        echo -e "\nPlease install them before running this script."
        exit 1
    fi
}

# Password strength checker
check_password_strength() {
    local password="$1"
    local strength=0
    local msg=""
    
    [ ${#password} -ge 8 ] && ((strength++))
    [[ "$password" =~ [A-Z] ]] && ((strength++))
    [[ "$password" =~ [a-z] ]] && ((strength++))
    [[ "$password" =~ [0-9] ]] && ((strength++))
    [[ "$password" =~ [^a-zA-Z0-9] ]] && ((strength++))
    
    case $strength in
        0|1) msg="${BRed}Very Weak${RESET}" ;;
        2) msg="${Red}Weak${RESET}" ;;
        3) msg="${Yellow}Moderate${RESET}" ;;
        4) msg="${Green}Strong${RESET}" ;;
        5) msg="${BGreen}Very Strong${RESET}" ;;
    esac
    
    echo -e "Password Strength: $msg (Length: ${#password} chars)"
    return $strength
}

# Progress bar function
show_progress() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Cleanup function
cleanup() {
    rm -f zip_hash.txt 2>/dev/null
    rm -f john.pot 2>/dev/null
}

show_help() {
    echo -e "${BBlue}ZIPFREAK - ZIP Password Utility${RESET}"
    echo -e "${BGreen}Version: 1.0${RESET}"
    echo -e "${Yellow}Usage: $0 [OPTION]${RESET}"
    echo
    echo -e "${BBlue}Description:${RESET}"
    echo "  A tool for creating and cracking password-protected ZIP archives"
    echo
    echo -e "${BBlue}Features:${RESET}"
    echo "  - Create password-protected ZIP files"
    echo "  - Crack ZIP passwords using multiple methods"
    echo "  - Password strength checking"
    echo "  - Multiple attack modes (dictionary, brute-force, mask)"
    echo
    echo -e "${BBlue}Options:${RESET}"
    echo -e "${BGreen}-h, --help${RESET}      Show this help message"
    echo -e "${BGreen}-v, --version${RESET}   Show version information"
    echo -e "${BGreen}-c, --create${RESET}    Directly enter create mode"
    echo -e "${BGreen}-k, --crack${RESET}     Directly enter crack mode"
    echo
    echo -e "${BBlue}Examples:${RESET}"
    echo "  $0                  # Interactive mode"
    echo "  $0 --create         # Go straight to ZIP creation"
    echo "  $0 --crack file.zip # Attempt to crack file.zip"
    echo
    echo -e "${BRed}Legal Disclaimer:${RESET}"
    echo "  This tool is for educational and authorized testing purposes only."
    echo "  Never use it to attack systems without permission."
    echo
    echo -e "${BBlue}Repository:${RESET}"
    echo "  https://github.com/B1tZ3r0/ZIPFREAK "
    exit 0
}

show_version() {
    echo -e "${BBlue}ZIPFREAK${RESET} - ${BGreen}Version 1.0${RESET}"
    echo "Copyright (C) 2025 B1tZ3r0 - SpeCTeR"
    exit 0
}


# Main menu
main_menu() {
    while true; do
        # Display ASCII
        echo -e "${BRed}"
        cat << "EOF"
             &&&&&&&&&&&&&&&&&&                 
           &                   $x;&&                
          &                    $x;;;&&                    	          @@@@@@@@@@+     
         &                     $x;;;;;&&                               @@@:---------@@@
         &                     $x;;;;;;;&                           #@@--------------=@@					
         &                     $x;;;;;;;;;&           	           @@----------@@@@@---@@			     
         &                      X&&&&&&&&&&&&          	           @%---------@@   @---:@#				   
         &                                  &     		  #@-----------@@@@#----@@ 	  
         &                                   &     		  %@--------------------@@ 		  
       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&   &     	           @:-------------------@@
     &;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;&$  &     		   @@------------------@@ 
     &;;;;;;;;;;      ;  ;;    ;;;;;;;;;;;&  &                   @@=------------------@@ 
     &;;;;;;;;;;;;;  ;;  ;; ;;; :;;;;;;;;;&  &                  @@%-----------------:@@@    
     &;;;;;;;;;;;;: ;;;  ;; ;;; .;;;;;;;;;&  &     	       @@@--------@@@@@@@@@@@@
     &;;;;;;;;;;;; ;;;;  ;;    .;;;;;;;;;;&  &               @@@----@@@@@@@
     &;;;;;;;;;;; :;;;;  ;; ;;;;;;;;;;;;;;&  &     	   +@@------@@ 
     &;;;;;;;;;;      ;  ;; ;;;;;;;;;;;;;;&  &     	  @@--------@@  
     &;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;&&  &          @@:-----@@*** 
       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&   &        @@--------@- 
         &                                   &      @@+----@@@@@@. 
         &                                   &    @@@------@@ 
         &                                   &   @@----@@@@@@ 
         &                                   &  -@-----@ 
          &                                  &  @@----*@ 
           &                               x&   @@@@@@@@ 
             &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                                           
EOF
        echo -e "${RESET}"

        # Main Menu
        echo
        echo -e "${BBlue}Welcome to ZIPFREAK - Choose an option:${RESET}"
        echo -e "${BGreen}1) Create password-protected ZIP${RESET}"
        echo -e "${BRed}2) Crack password-protected ZIP${RESET}"
        echo -e "${BCyan}3) Check password strength${RESET}"
        echo -e "${BYellow}4) Exit${RESET}"
        read -p "Choice [1-4]: " main_choice

        case "$main_choice" in
            1)
                create_zip
                ;;
            2)
                crack_zip
                ;;
            3)
                read -s -p "Enter password to check: " CHECK_PASS
                echo
                check_password_strength "$CHECK_PASS"
                read -n 1 -s -r -p "Press any key to continue..."
                clear
                ;;
            4)
                echo -e "${BYellow}Goodbye!${RESET}"
                cleanup
                exit 0
                ;;
            *)
                echo -e "${Red}[-] Invalid option. Please choose 1-4.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# Create ZIP function
create_zip() {
    echo -e "${BGreen}[*] You chose to create a password-protected ZIP.${RESET}"
    read -e -p "Enter the path of the file to zip and protect (or type 'exit' to return): " FILE
    FILE=$(eval echo "$FILE" | tr -d '\r')
    
    if [[ "$FILE" == "exit" ]]; then
            echo -e "${BRed}[!] Returning to main menu...${RESET}"
            return
    fi

    if [[ ! -f "$FILE" && ! -d "$FILE" ]]; then
        echo -e "${Red}[!] File/directory '$FILE' not found!${RESET}"
        return
    fi

    while true; do
        read -s -p "Enter a password for the zip file: " ZIP_PASS
        echo
        read -s -p "Confirm password: " ZIP_PASS_CONFIRM
        echo
        
        if [[ "$ZIP_PASS" != "$ZIP_PASS_CONFIRM" ]]; then
            echo -e "${Red}[!] Passwords don't match! Try again.${RESET}"
        else
            check_password_strength "$ZIP_PASS"
            if [[ $? -lt 3 ]]; then
                echo -e "${Yellow}[!] Warning: Password is weak. Continue anyway? [y/N]${RESET}"
                read -n 1 weak_choice
                echo
                [[ "$weak_choice" =~ [yY] ]] && break
            else
                break
            fi
        fi
    done

    ZIP_NAME="${FILE}.zip"
    echo -e "${BGreen}[*] Creating password-protected zip file: $ZIP_NAME${RESET}"
    
    # Show progress for large files
    if [[ $(du -k "$FILE" | cut -f1) -gt 1024 ]]; then
        echo -e "${Blue}[*] Processing large file, please wait...${RESET}"
        zip -e -r -q --password "$ZIP_PASS" "$ZIP_NAME" "$FILE" &
        show_progress $!
        wait $!
    else
        zip -e -r --password "$ZIP_PASS" "$ZIP_NAME" "$FILE"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${BGreen}[+] Done! File saved as $ZIP_NAME${RESET}"
        echo -e "${Yellow}[!] Remember to securely store your password.${RESET}"
    else
        echo -e "${Red}[-] Failed to create ZIP file!${RESET}"
    fi
    
    read -n 1 -s -r -p "Press any key to continue..."
    clear
}

# Crack ZIP function
crack_zip() {
    echo -e "${BRed}[*] You chose to crack a password-protected ZIP.${RESET}"

    while true; do
        read -e -p "Enter the path to the ZIP file to crack (or type 'exit' to return): " TARGET_FILE
        TARGET_FILE=$(eval echo "$TARGET_FILE" | tr -d '\r')

        if [[ "$TARGET_FILE" == "exit" ]]; then
            echo -e "${BRed}[!] Returning to main menu...${RESET}"
            return
        fi

        if [[ ! -f "$TARGET_FILE" ]]; then
            echo -e "${BRed}[-] File not found: $TARGET_FILE${RESET}"
            continue
        fi

        if ! unzip -l "$TARGET_FILE" &>/dev/null; then
            echo -e "${Red}[-] The file doesn't appear to be a valid ZIP archive${RESET}"
            continue
        fi

        break
    done

    local CRACKED_PASS=""

    while true; do
        echo
        echo -e "${BRed}Select cracking method for: $TARGET_FILE${RESET}"
        echo -e "${BRed}1) Crack ZIP file (zip2john + john)${RESET}"
        echo -e "${BRed}2) Unzip using cracked password${RESET}"
        echo -e "${BRed}3) Choose another ZIP file${RESET}"
        echo -e "${BRed}4) Return to main menu${RESET}"
        read -p "Choice [1-4]: " choice

        case "$choice" in
            1)
                HASH_FILE="zip_hash.txt"
                echo -e "${BRed}[*] Running zip2john...${RESET}"
                zip2john "$TARGET_FILE" > "$HASH_FILE" 2>/dev/null

                if [[ ! -s "$HASH_FILE" ]]; then
                    echo -e "${BRed}[-] Could not extract hash. Is this a valid ZIP?${RESET}"
                    continue
                fi

                echo -e "${BGreen}[+] Hash extracted successfully${RESET}"

                echo
                echo -e "${BRed}Select attack mode:${RESET}"
                echo -e "${BRed}1) Dictionary attack (recommended first try)${RESET}"
                echo -e "${BRed}2) Brute-force attack (slow but thorough)${RESET}"
                echo -e "${BRed}3) Mask attack (know part of the password)${RESET}"
                read -p "Choice [1-3]: " attack_choice

                case "$attack_choice" in
                    1)
                        echo -e "${BRed}Select wordlist option:${RESET}"
                        echo -e "${BRed}1) Use rockyou.txt${RESET}"
                        echo -e "${BRed}2) Enter path to your own wordlist${RESET}"
                        read -p "Choice [1-2]: " wordlist_choice

                        case "$wordlist_choice" in
                            1)
                                WORDLIST="/usr/share/wordlists/rockyou.txt"
                                if [[ ! -f "$WORDLIST" ]]; then
                                    echo -e "${BRed}[-] Wordlist not found at: $WORDLIST${RESET}"
                                    echo -e "${Yellow}[*] Try 'sudo apt install wordlists' or specify custom wordlist${RESET}"
                                    continue
                                fi
                                ;;
                            2)
                                read -e -p "Enter the path to your wordlist: " WORDLIST
                                WORDLIST=$(eval echo "$WORDLIST" | tr -d '\r')
                                if [[ ! -f "$WORDLIST" ]]; then
                                    echo -e "${BRed}[-] Wordlist not found: $WORDLIST${RESET}"
                                    continue
                                fi
                                ;;
                            *)
                                echo -e "${BRed}[-] Invalid wordlist choice.${RESET}"
                                continue
                                ;;
                        esac

                        echo -e "${BRed}[*] Starting dictionary attack...${RESET}"
                        echo -e "${Yellow}[*] This may take some time depending on wordlist size${RESET}"
                        john --wordlist="$WORDLIST" "$HASH_FILE" &
                        show_progress $!
                        wait $!
                        ;;
                    2)
                        echo -e "${BRed}[*] Starting brute-force attack...${RESET}"
                        echo -e "${Yellow}[!] Warning: This may take a VERY long time!${RESET}"
                        echo -e "${Yellow}[*] Press Ctrl+C to stop when needed${RESET}"
                        john --incremental "$HASH_FILE"
                        ;;
                    3)
                        read -p "Enter mask (e.g., '?l?l?l?d?d' for 3 letters + 2 digits): " MASK
                        echo -e "${BRed}[*] Starting mask attack with pattern: $MASK${RESET}"
                        john --mask="$MASK" "$HASH_FILE"
                        ;;
                    *)
                        echo -e "${BRed}[-] Invalid attack choice.${RESET}"
                        continue
                        ;;
                esac

                echo -e "${BRed}[*] Cracked passwords:${RESET}"
                echo "----------------------------------"
                john --show "$HASH_FILE"
                echo "----------------------------------"

                CRACKED_LINE=$(john --show "$HASH_FILE" | grep -v '^$' | head -n 1)
                CRACKED_PASS=$(echo "$CRACKED_LINE" | cut -d':' -f2 | xargs)
                if [[ -n "$CRACKED_PASS" ]]; then
                    echo -e "${BGreen}[+] Password found: '${CRACKED_PASS}'${RESET}"
                else
                    echo -e "${BRed}[-] No password found. Try another method.${RESET}"
                fi
                ;;

            2)
                if [[ -z "$CRACKED_PASS" ]]; then
                    echo -e "${BRed}[-] No cracked password stored. Run option 1 first.${RESET}"
                else
                    echo -e "${BRed}[*] Attempting to unzip with cracked password...${RESET}"
                    mkdir -p "extracted_$(basename "$TARGET_FILE")"
                    unzip -P "$CRACKED_PASS" "$TARGET_FILE" -d "extracted_$(basename "$TARGET_FILE")" 2>/dev/null
                    if [[ $? -eq 0 ]]; then
                        echo -e "${BGreen}[+] File successfully extracted to extracted_$(basename "$TARGET_FILE")/${RESET}"
                    else
                        echo -e "${BRed}[-] Failed to unzip. Wrong password or damaged ZIP.${RESET}"
                    fi
                fi
                ;;

            3)
                echo -e "${BRed}[*] Switching to another ZIP file...${RESET}"
                crack_zip
                return
                ;;

            4)
                echo -e "${BRed}[!] Returning to main menu...${RESET}"
                cleanup
                return
                ;;

            *)
                echo -e "${BRed}[-] Invalid choice. Select 1-4.${RESET}"
                ;;
        esac
    done
}

# Main execution
check_dependencies
trap cleanup EXIT

# Handle command line arguments
if [[ $# -gt 0 ]]; then
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -v|--version)
                show_version
                ;;
            -c|--create)
                create_zip
                # After creation, show main menu
                main_menu
                exit 0
                ;;
            -k|--crack)
                if [[ -z "$2" ]]; then
                    echo -e "${Red}Error: No ZIP file specified for cracking${RESET}"
                    show_help
                    exit 1
                fi
                TARGET_FILE="$2"
                shift # Skip the filename argument
                crack_zip
                # After cracking, show main menu
                main_menu
                exit 0
                ;;
            *)
                echo -e "${Red}Unknown option: $1${RESET}"
                show_help
                exit 1
                ;;
        esac
        shift
    done
else
    # If no arguments were provided, start the main menu
    main_menu
fi
