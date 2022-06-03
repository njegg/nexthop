run:
	@dosbox \
		-conf UTIL/DOSBOX.CONF\
		-c 'MOUNT C "."' \
	 	-c "C:" \
		-c "DEL NEXTHOP.EXE;" \
		-c "CLS" \
		-c "UTIL\MASM.EXE /z NEXTHOP; > UTIL\MASMLOG.TXT" \
		-c "CLS" \
		-c "TYPE UTIL\MASMLOG.TXT" \
		-c "UTIL\LINK.EXE NEXTHOP.OBJ; > UTIL\LINKLOG.TXT" \
		-c "EXIT" > /dev/null

	@./UTIL/MASM_ERRORS && \
		dosbox \
			-conf UTIL/DOSBOX.CONF\
			-c 'MOUNT C "."' \
			-c "C:" \
			-c "NEXTHOP.EXE" \
			-c "DEL NEXTHOP.OBJ" \
			-c "EXIT"\
			|| echo "There are errors or warnings";cat UTIL/MASMLOG.TXT
	