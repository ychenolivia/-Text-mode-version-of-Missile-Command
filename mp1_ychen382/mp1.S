
# mp1.S - missile-command version
# Good luck, and have fun!

.data
	
    # Constants for accessing the fields of a struct missile, 
    # struct missile is defined in rtc.h and mp1.h

	NEXT 	  = 0
	X	  = 4
	Y	  = 8
	VX	  = 12
	VY	  = 16
	DEST_X	  = 20
	DEST_Y	  = 24
	EXPLODED  = 28
	C	  = 32

    # Character to draw for an explosion - '@'

	EXPLOSION = 64


# Data shared between this file and rtc.c helper functions

# This '.globl' directive makes these symbols visible externally
.globl mp1_missile_list, base_alive, mp1_score

mp1_missile_list:	.long 0x0	# Head of list pointer
base_alive:		.long 0x0	# Array of 3 bytes, plus a padding byte
mp1_score:		.long 0x0	# Player's current score


# Data private to this  file

base_pic:     	    .string "/^^^\\"	# Picture of a live base
dead_base_pic: 	    .string "xxxxx"	# Picture of a dead base
crosshairs_x:		.long 0x0	# X-position of the crosshairs
crosshairs_y:		.long 0x0	# Y-position of the crosshairs
status:		.long 0x0	# for mp1_ioctl_getstatus

.text

# void mp1_poke(void);
# You can use this function to write to video memory.
#
# Interface: Register-based arguments (not C-style)
#    Inputs: %cl  - The byte you wish to write
#            %eax - Offset from the start of video memory that you wish
#                   to write to
#   Outputs: Text-mode video screen is written to at location %eax with
#            the byte in %cl
# Registers: Clobbers EDX
#make %edx a callee saved function
mp1_poke:
		movl    vmem_base_addr(,1),%edx
		movb    %cl,(%edx,%eax,1)
		ret

#   ----------------- Exported functions ---------------------

# void mp1_rtc_tasklet(unsigned long garbage);
# Performs three tasks:
#	(1) updates the list of missiles (implement this in update_missiles,
#           below, and call it from here).
#	(2) Redraw the bases - they may have been overwritten with missiles
#	(3) Redraw the crosshairs - it may have been overwritten with missiles
# Inputs   : none
# Outputs  : none
# Registers: Standard C calling convention

.globl mp1_rtc_tasklet
mp1_rtc_tasklet:
		#setup stack frame
		pushl %ebp
		movl %esp, %ebp

		#callee save
		pushl %ebx
		pushl %esi
		pushl %edi
		
		movl $0, %esi
		movl mp1_missile_list, %ecx  #%ebx points to the head of the list

	    pushl %eax                #caller save
		pushl %ecx
		pushl %edx

		call update_missiles
		movl %eax, %esi
		call second_operation
		call third_operation

		popl %edx                 #restore regs      
		popl %ecx
		popl %eax 
		
		cmpl $0, %esi
		je end
	    pushl %eax                #caller save
		pushl %ecx
		pushl %edx 
		call mp1_notify_user
		popl %edx                 #restore regs      
		popl %ecx
		popl %eax 	
		end:
		popl %edi                 #restore regs 
		popl %esi
		popl %ebx

		leave
		ret


#The function redraws cities.
#Inputs: none
#output: none
second_operation:
	movl base_alive, %ebx
	andl $0x000000ff, %ebx
	cmpl $0, %ebx         #check if the first base is alive
	je draw_first_destroyed_cities #the base is destroyed
	jmp draw_first_alive_cities   #otherwise, the base is alive

	second_base:
	movl base_alive, %ebx
	andl $0x0000ff00, %ebx
	cmpl $0, %ebx        #check if the second base is alive
	je draw_second_destroyed_cities #the base is destroyed
	jmp draw_second_alive_cities   #otherwise, the base is alive

	third_base:
	movl base_alive, %ebx
	andl $0x00ff0000, %ebx
	cmpl $0, %ebx        #check if the third base is alive
	je draw_third_destroyed_cities #the base is destroyed
	jmp draw_third_alive_cities   #otherwise, the base is alive 

	draw_first_destroyed_cities:
		leal dead_base_pic, %esi  #%esi stores dead_base_pic
		movl $18, %edi            

		call draw_cities

		jmp second_base

	draw_second_destroyed_cities:	
		leal dead_base_pic, %esi  #%esi stores dead_base_pic
		movl $38, %edi            

		call draw_cities

		jmp third_base

	draw_third_destroyed_cities:	
		leal dead_base_pic, %esi  #%esi stores dead_base_pic
		movl $58, %edi            

		call draw_cities

		jmp done1

	draw_first_alive_cities:
		leal base_pic, %esi  #%esi stores dead_base_pic
		movl $18, %edi            

		call draw_cities

		jmp second_base

	draw_second_alive_cities:	
		leal base_pic, %esi  #%esi stores dead_base_pic
		movl $38, %edi            

		call draw_cities

		jmp third_base

	draw_third_alive_cities:	
		leal base_pic, %esi  #%esi stores dead_base_pic
		movl $58, %edi            

		call draw_cities
	
	done1:
	ret


#The function draws destroyed cities.
#Inputs: %esi: the register stores the five-character array
#        %edi: the register stores the starting index of column
#Output: none
draw_cities:

	#first char
	movl $24, %eax        #%eax=y
	imull $160, %eax           #%eax=80*y*2
    imull $2, %edi             #%edi=x*2
	addl %edi, %eax           #%eax=80*y*2+x*2
	
	movb (%esi), %cl 	

    pushl %eax                #caller-save
	pushl %ecx
	pushl %edx

	call mp1_poke             

	popl %edx                 #restore regs
	popl %ecx
	popl %eax	

	#second char
	addl	$2, %eax
	
	movb 1(%esi), %cl 	

    pushl %eax                #caller-save
	pushl %ecx
	pushl %edx

	call mp1_poke             

	popl %edx                 #restore regs
	popl %ecx
	popl %eax	

	#third char
	addl	$2, %eax
	
	movb 2(%esi), %cl 	

    pushl %eax                #caller-save
	pushl %ecx
	pushl %edx

	call mp1_poke             

	popl %edx                 #restore regs
	popl %ecx
	popl %eax	

	#fourth char
	addl	$2, %eax
	
	movb 3(%esi), %cl 	

    pushl %eax                #caller-save
	pushl %ecx
	pushl %edx

	call mp1_poke             

	popl %edx                 #restore regs
	popl %ecx
	popl %eax	

	#fifth char
	addl	$2, %eax
	
	movb 4(%esi), %cl 	

    pushl %eax                #caller-save
	pushl %ecx
	pushl %edx

	call mp1_poke             

	popl %edx                 #restore regs
	popl %ecx
	popl %eax	

	ret


#The function redraws the crosshairs.
#Inputs: none
#Outputs: none
third_operation:
	movl crosshairs_y, %eax 
	movl crosshairs_x, %ebx 
	imull $160, %eax           #%eax=80*y*2
	imull $2, %ebx             #%ecx=x*2
	addl %ebx, %eax           #%eax=80*y*2+x*2
	movb $0x2B, %cl           #print "+"
	call mp1_poke
	ret




# int mp1_ioctl(unsigned long arg, unsigned int cmd)
# The dispatch function for the MP1 ioctls - should use the cmd argument
# and a jumptable to execute one of the specific ioctls implemented below.
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : unsigned int cmd  - specifies which mp1_ioctl_... function 
#          :                     to execute
# Outputs  : Returns an integer - depends on which ioctl() function is called
# Registers: Standard C calling convention

.globl mp1_ioctl
mp1_ioctl:
	movl 8(%esp), %edi       #%edi: cmd

	cmpl $4, %edi
	jg error
	cmpl $0, %edi
	jl error
	jmp *core_functions(,%edi,4)

	error:
	movl $-1, %eax

	ret

	core_functions:   #jump table
	.long	mp1_ioctl_startgame, mp1_ioctl_addmissile, mp1_ioctl_movexhairs, mp1_ioctl_getstatus, mp1_ioctl_endgame




# ----------------- Functions private to this file -------------------
#The function completes the first operation
#Inputs: ecx: stores the pointer points to the head of the linked list
#Outputs: an integer

update_missiles:
		cmpl	$0, %ecx
		jne	end_check
		movl	%esi, %eax
		ret
	end_check:
		call	current_position
		pushl	%ecx
		movb	$0x20, %cl
		call	mp1_poke
		popl	%ecx
		cmpl	$0, EXPLODED(%ecx)
		jne	position_unchanged		
		movl	VX(%ecx), %edx
		addl	%edx, X(%ecx)
		movl	VY(%ecx), %edx
		addl	%edx, Y(%ecx)
	position_unchanged:
		movl    $128, %ebx
		imull    $512, %ebx
		imull    $80, %ebx
		cmpl	%ebx, X(%ecx)
		jge		erase_missile
		cmpl	$0, X(%ecx)
		jl		erase_missile
		movl    $0, %ebx
		movl    $128, %ebx
		imull    $512, %ebx
		imull    $25, %ebx
		cmpl	%ebx, Y(%ecx)
		jge		erase_missile
		movl    $0, %ebx
		cmpl	$0, Y(%ecx)
		jl		erase_missile
		jmp		second_case


current_position:
		pushl	%ebp
		movl	%esp, %ebp
		pushl	%ebx
		pushl	%esi
		pushl	%edi
		pushl	%edx
		movl	Y(%ecx), %edx
		shrl	$16, %edx
		movl	%edx, %eax
		imull	$80, %eax
		movl	X(%ecx), %edx
		shrl 	$16, %edx
		imull   $2, %edx
		addl	%eax, %eax
		popl	%edx
		popl	%edi
		popl	%esi
		popl	%ebx
		leave
		ret
	erase_missile:
		movl    $0, %ebx
		call	remove_the_missle
		jmp		node_complete
#The function erases the missile, update the linked list, and free the memory
#Inputs: %ecx: the pointer points to the current missile
#Outputs: none.
remove_the_missle:
		pushl	%ebp
		movl	%esp, %ebp
		pushl	%ebx
		pushl	%esi
		pushl	%edi
		cmpl	$0, mp1_missile_list
		je		rdy_quit
		movl	mp1_missile_list, %esi
		cmpl	%esi, %ecx
		je		head_remove
	list_backsearch:
		cmpl	(%esi), %ecx
		je		list_backtrack
		cmpl	$0, (%esi)
		je		rdy_quit
		movl	(%esi), %esi
		jmp		list_backsearch
	list_backtrack:
		movl	(%ecx),	%edx
		movl	%edx, (%esi)
		pushl	%eax
		pushl	%edx
		pushl	%ecx
		call	mp1_free
		popl	%ecx
		popl	%edx
		popl	%eax
		movl	%esi, %ecx
		jmp		rdy_quit
	head_remove:
		movl	(%ecx), %ebx
		movl	%ebx, mp1_missile_list
		pushl	%eax
		pushl	%edx
		pushl	%ecx
		call	mp1_free
		popl	%ecx
		popl	%edx
		popl	%eax
		movl	mp1_missile_list, %ecx
	rdy_quit:
		popl	%edi
		popl	%esi
		popl	%ebx
		leave
		ret
	second_case:	
		cmpl	$0, EXPLODED(%ecx)
		jne		is_exploding
		movl	X(%ecx), %edx
		shrl	$16, %edx
		cmpl	%edx, DEST_X(%ecx)
		jne		third_case
		movl	Y(%ecx), %edx
		shrl	$16, %edx
		cmpl	%edx, DEST_Y(%ecx)
		jne		third_case
	is_exploding:
		pushl	%eax
		pushl	%edx		
		pushl	%ecx
		call	missile_explode
		cmpl	$0, %esi
		jne		still_exploding
		movl	%eax, %esi
	still_exploding:
		popl	%ecx
		popl	%edx
		popl	%eax
		call	current_position
		subl	$1, EXPLODED(%ecx)
		jz		stop_exploding
		pushl	%ecx
		movb	$EXPLOSION, %cl
		jmp		draw_explosion
	stop_exploding:
		call	remove_the_missle
		pushl	%ecx
		movb	$0x20,%cl
	draw_explosion:	
		call	mp1_poke
		popl	%ecx
		jmp		node_complete		 
	third_case:
		call	current_position
		pushl	%ecx
		movb	C(%ecx), %cl
		call	mp1_poke
		popl	%ecx
	node_complete:
		cmpl	$0, %ecx
		jne		update_missiles_looping
		movl	%esi, %eax
		ret
	update_missiles_looping:
		movl	(%ecx), %ecx
		jmp		update_missiles 

		
		
#This function is called when the game is about to start.
#inputs: arg(meanngless)
#outputs: none
#Registers: Standard C calling convention
mp1_ioctl_startgame:
	pushl %ebp
	movl %esp, %ebp
	#callee save
	pushl %ebx
	pushl %esi
	pushl %edi
    #initialize variables
	movl $0x00010101, base_alive 

	movl $40, crosshairs_x
	movl $12, crosshairs_y

	popl %edi
	popl %esi
	popl %ebx
	leave
	ret



#The copy a user space missile to kernel
# Inputs   : an argument
# Outputs  : an integer
# Registers: Standard C calling convention
mp1_ioctl_addmissile:
		pushl	%ebp
		movl	%esp, %ebp
		pushl	%ebx
		pushl	%esi
		pushl	%edi
		movl	8(%ebp), %ecx

		pushl   %eax
		pushl	%ecx
		pushl	%edx
		call	mp1_malloc
		popl	%edx
		popl	%ecx
		popl    %eax

		pushl	$33
		pushl	%ecx
		pushl	%eax
		call	mp1_copy_from_user
		cmpl	$0, %eax
		jne		ssfail
		popl	%eax
		popl	%ecx
		popl	%edx
		movl	mp1_missile_list, %edx
		movl	%edx, NEXT(%eax)
		movl	%eax, mp1_missile_list
		movl	$0, %eax
		jmp		addmissile_end
fail:
		#first pop back
		popl	%eax
		popl	%ecx
		popl	%edx
		#free memory, %eax still holds the allocated memory
		pushl	%eax
		call	mp1_free
		popl	%eax
		#return -1
		movl	$-1, %eax
addmissile_end:
		#prepare to leave
		popl	%edi
		popl	%esi
		popl	%ebx
		leave     
		ret   
		
		
		
		


#The function moves the crosshairs.
#inputs: 32-bit integer
#outputs: an integer
#Registers: Standard C calling convention
mp1_ioctl_movexhairs:
		
		pushl	%ebp
		movl	%esp, %ebp
		pushl	%ebx
		pushl	%esi
		pushl	%edi
		
		movl crosshairs_y, %eax       #%eax=y
		imull $160, %eax           #%eax=80*y*2
		movl crosshairs_x, %ecx       #%ecx=x
		imull $2, %ecx             #%ecx=x*2
		addl %ecx, %eax           #%eax=80*y*2+x*2

		movb	$32, %cl
		call	mp1_poke
		
		movl	8(%ebp), %ecx
		cmpl	$0, %ecx
		je		movexhairs_end
	
		movl	%ecx, %eax
		shll	$16, %eax
		sarl	$16, %eax           #delta x
		sarl	$16, %ecx           #delta y
	
		addl	%eax, crosshairs_x
		cmpl	$0, crosshairs_x
		jl		lowy
		cmpl	$79, crosshairs_x
		jg		highx
		jmp		checky
lowx:
		movl	$0, crosshairs_x
		jmp		checky
highx:
		movl	$79, crosshairs_x

checky:
		addl	%ecx, crosshairs_y
		cmpl	$24, crosshairs_y
		jg		highy
		cmpl	$0, crosshairs_y
		jl		lowy
		jmp		redraw
highy:
		movl	$24, crosshairs_y
		jmp		redraw
lowy:
		movl	$0, crosshairs_y
redraw:
		movl	crosshairs_y, %eax
		imull	$80, %eax
		addl	crosshairs_x, %eax
		addl	%eax, %eax
		movb	$43, %cl
		call	mp1_poke
movexhairs_end:
		movl	$0, %eax
		popl	%edi
		popl	%esi
		popl	%ebx
		leave          
		ret

#This function should copy the current score into the low 16-bits of that integer, and the
#status of the three cities into bits 16, 17, and 18.
#input: 32-bit integer
#output: an integer
mp1_ioctl_getstatus:
		pushl 	%ebp                       #calculate position
		movl 	%esp,%ebp
		pushl	%esi
		pushl	%edi
		pushl	%ebx
		movl	8(%ebp),%ecx		
		
		movl	mp1_score, %edx				
		movl	%edx, status
		
		movl	$0x000000ff, %eax			
		andl	base_alive, %eax
		jz		check_second
		addl	$0x00010000, status
check_second:
		
		movl	$0x0000ff00, %eax			
		andl	base_alive, %eax
		jz		check_third
		addl	$0x00020000, status	
check_third:
	
		movl	$0x00ff0000, %eax			
		andl	base_alive, %eax
		jz		getstatus_end
		addl	$0x00040000, status
getstatus_end:			
		pushl	$4
		pushl	$status
		pushl	%ecx
		call	mp1_copy_to_user
		cmpl	$0, %eax					
		
		add $8, %esp					
		popl	%edx										
		jz	end5					
		movl	$-1, %eax					
end5:	
		popl	%ebx
		popl	%edi
		popl	%esi
		leave
		ret

#The function ends the game
#inputs: none
#outputs: none
#Registers: Standard C calling convention
mp1_ioctl_endgame:  
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx                    #callee save
	pushl %esi
	pushl %edi

	loop2:
		cmpl $0, mp1_missile_list
		je done3
		movl	mp1_missile_list, %eax
		movl	NEXT(%eax), %edx
		movl	%edx, mp1_missile_list
		pushl	%eax
		call	mp1_free
		popl	%eax
		jmp		loop2

	done3:
	popl %edi                     #restore caller
	popl %esi
	popl %ebx
	leave
	ret
