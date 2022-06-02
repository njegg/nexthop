run:
	@dosbox \
		-conf DOSBOX.CONF\
		-c 'mount c "."' \
	 	-c "c:" \
		-c "del nexthop.exe;" \
		-c "cls" \
		-c "masm.exe /z nexthop; > MASMLOG.TXT" \
		-c "cls" \
		-c "type MASMLOG.TXT" \
		-c "link.exe nexthop.obj; > LINKLOG.TXT" \
		-c "exit" > /dev/null

	@./MASM_ERRORS && \
		dosbox \
			-conf DOSBOX.CONF\
			-c 'mount c "."' \
			-c "c:" \
			-c "nexthop.exe" \
			-c "del nexthop.obj" \
			-c "exit"\
			|| echo "There are errors or warnings";cat MASMLOG.TXT
	