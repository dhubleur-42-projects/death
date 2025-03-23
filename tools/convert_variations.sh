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

if [ ! -f srcs/final_main.s ]; then
	echo "srcs/final_main.s not found"
	exit 1
fi

main()
{
	cd "$PROJECT_FOLDER"
	generate_variation_variables "push_regs"
}

generate_variation_variables()
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

		perl -0777 -pe "s/"$BEGIN_TOKEN":.*"$END_TOKEN":/$BEGIN_TOKEN:\n$FILE_CONTENT\n$END_TOKEN:/s" srcs/main.s > "$WORK_FILE_NAME".s
		$NASM_CMD -I ./includes/ -felf64 -o "$WORK_FILE_NAME".o "$WORK_FILE_NAME".s

		start_offset=$(nm "$WORK_FILE_NAME".o | grep "$BEGIN_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		end_offset=$(nm "$WORK_FILE_NAME".o | grep "$END_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/ibase=16;\U\1/' | bc)
		size=$((end_offset-start_offset))
		
		if [ $VARIATION_SIZE -eq 0 ]; then
			VARIATION_SIZE=$size
		else
			if [ $VARIATION_SIZE -ne $size ]; then
				echo "Variation size mismatch: $VARIATION_NAME"
				exit 1
			fi
		fi

		ld -o "$WORK_FILE_NAME".elf "$WORK_FILE_NAME".o
		start_address=$(nm "$WORK_FILE_NAME".elf | grep "$BEGIN_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/0x\1/')
		stop_address=$(nm "$WORK_FILE_NAME".elf | grep "$END_TOKEN" | cut -d ' ' -f1 | sed -E 's/^0*([^0][0-9a-z]*)$/obase=16;ibase=16;\U\1+1/' | bc | sed 's/^/0x/')

		start_offset=$(objdump -F -d --start-address=$start_address --stop-address=$stop_address "$WORK_FILE_NAME".elf | grep -E "^[0-9a-z].*$BEGIN_TOKEN.*File Offset" | head -n1 | sed -E 's/.*File Offset: 0x([0-9a-z]*).*/ibase=16;\U\1+1/' | bc)
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