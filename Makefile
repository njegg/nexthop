run:
	@dosbox \
		-c 'mount c "."' \
	 	-c "c:" \
		-c "del nexthop.exe;" \
		-c "cls" \
		-c "masm.exe /z nexthop; > MASMLOG.TXT" \
		-c "cls" \
		-c "type MASMLOG.TXT" \
		-c "link.exe nexthop.obj; > LINKLOG.TXT" \
		-c "exit"

	@./masm_errors && \
		dosbox \
			-c 'mount c "."' \
			-c "c:" \
			-c "nexthop.exe" \
			-c "del nexthop.obj" \
			-c "exit"\
			||\
		echo;echo "There are errors or warnings:";echo;\
		cat MASMLOG.TXT;
	
	
