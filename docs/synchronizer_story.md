Shadow tracer synchronizer
==========================

I have the synchronizer built and set up. All seems to be working and I can boot into CP/M, no issues.

Returning to the original problem of chasing differences, I get a very early one:

Execution at address 0xb3 of instruction 0xe3 (ex (SP), HL) seems to be writing the incorrect H (or L?) value onto the stack: the reference is 0x7D, the shadow is 0x01. Why?

This boot code is actually documented on https://www.chiark.greenend.org.uk/~jacobn/cpm/pcwboot.html:

                ; Delay loop. B is length of delay.
                ; Clobbers: A. (Preserves carry.)
            delay:
00B1    3E      LD      A,0B3h
00B2    B3
            delaylp:                    ; inner loop controlled by A
00B3    E3      EX      (SP),HL         ; beefy NOPs?
00B4    E3      EX      (SP),HL
00B5    E3      EX      (SP),HL
00B6    E3      EX      (SP),HL
00B7    3D      DEC     A
00B8    20      JR      NZ,delaylp
00B9    F9
00BA    10      DJNZ    delay
00BB    F5
00BC    C9      RET

So, really HL doesn't carry any information, it's purely a delay tactic. Of course the problem goes away almost immediately as the very next instruction blows the incorrect HL value from the shadow core as it is swapped with memory again.

This is the 1st call to 'delay', from address 0x0019. There's no touching of either H or L prior to this, not even in the ROM boot code. So, really HL is whatever we have after reset, and HL is not reset to any particular value after reset. So, unfortunately, this is an expected mismatch, something that we will never be able to get rid of.

One would think that this can be ignored by simply not triggering on the first mismatch but that doesn't seem to be the case. What gives?
Oh, now it works! We need to set the trigger to be edge, otherwise we get a ton of hits one after the other as the match line is held low.

Issue with PUSH AF
------------------

Now we're well into the boot process. We it a PUSH AF at address 0x204a:

We apparently have been here before:

	exx			;2044	d9 	.
	push hl			;2045	e5 	.
	push de			;2046	d5 	.
	push bc			;2047	c5 	.
	exx			;2048	d9 	.
	ex af,af'		;2049	08 	.
	push af			;204a	f5 	.

This is the undocumented F register bits mismatch again, I think within the interrupt handler. Except that mismatch is masked out, so now we hit on 'A' being different: the reference is 0xB3, the shadow is 0xFF. This is almost impossible to explain as a reset mismatch: we're well into the boot process and 'A' is rather commonly used. Of course we're actually saving A' here, not A, which might still be untouched the first time. So we might have to ignore this one as well.

Interrupt timing mismatch
-------------------------

On this particular boot, we had a mismatch in interrupt timing: the T80 got it earlier than the Z80. We also hung during boot this time, which is not ideal: we're not even executing the T80, this should not have happened.

At any rate, at this point the signal integrity over the long long train of extension modules is probably non-ideal.

So, I'll increase the interrupt delay on the T80 and retry.

Sort of. This is not a problem in delaying the interrupt signal, actually. What happens here is that the T80 handles a pending interrupt right after a RETN instruction gets executed, whereas the Z80 ... doesn't seem to be handling the interrupt at all????

This looks awfully familiar. We are returning from the NMI handler, but the Z80 thinks interrupts are disabled, while the T80 doesn't so much.

I've added IntE_FF1 IntE_FF2 to the trace. These are the interrupt enable bits. Of course we can't see inside the Z80, but at least find out what the T80 thinks...

OK, this time around we do see the one cycle (that is MACHINE CYCLE) difference: the T80 interrupts the instruction immediately after the RETN (that is the instruction that got interrupted by the NMI to begin with) which in this case happens to be a 'JR d' instruction. The Z80 executes this instruction (i.e. updates PC in this case) and then takes the interrupt.

The Z80 behavior is probably better - apart from being the the reference - as this delay guarantees some forward progress on the main program. So, how to fix this?

I think the issue here is that the Z80 follows the EI instruction behavior for RETN as well, whereas the T80 doesn't.

									elsif IntE_FF1 = '1' and INT_n='0' and Prefix = "00" and SetEI = '0' then

Is the relevant line: here we delay the handling of the interrupt if SetEI is set, but not for RETN.

Well, good news, it seems: this change apparently fixed the interrupt differences. And in fact, I got no new mismatches either. Good.

Next steps
============

Let's see if we can be more stringent about checking for mismatches. What do we have now enabled?
We only check for data mismatches at the moment. So let's enable control ones as well!

Another interrupt mismatch
----------------------------

This is interesting: I got yet another interrupt mismatch. Fun! This is the EI instruction. Not only that, but this is an example of when the Z80 doesn't take an interrupt at all. I'll save this: ei_with_no_interrupt.

Well, what do you know: the Z80 didn't take the interrupt and the boot froze. So, maybe this is something that shouldn't have happened?

Rerun the test, got the same behavior. Now, boot did not succeed this time either, but it continued quite a bit further after the trigger, so it's not related. Or at least not directly related. Still, not Z80 interrupt, only a T80 one. This is strange to be clear. The instruction stream is:

1F2F     FB               EI
1F30     18               JR 1E
...
1F50     F3               DI

T80: takes interrupt on DI
Z80: doesn't take interrupt on DI

This is weird. The Z80, apparently can't be interrupted on the DI instruction?! That's pretty much impossible. The reason is that the interrupt response cycle doesn't assert MREQ_N, thus (even though the PC is on the address bus and IORQ_N is asserted later), there's no memory transfer and thus, no read from memory. In other words the Z80 doesn't know (can't know) when it decides to handle - or not - an interrupt whether the next instruction is going to be a DI or not. So, the alternative would be that JR delays the enabling of the interrupts even further? That doesn't sound likely either (and I can't seem to find any reference to such behavior either): this would allow for dead-locking the machine by an endless JR loop. Singling JR out would be weird anyway: it doesn't even involve the stack, so preventing interrupts during its execution would make no sense.

It's also pretty unlikely that interrupts are not enabled on the Z80: we just had an EI instruction executed, and both cores agreed on that score.

Another idea is that there's a concurrent NMI happening? Nope, but hold on!!!

What is happening in this case is that the interrupt is getting asserted right before the DI instruction fetch starts. So, the T80 *accepts* this interrupt, whereas the Z80 doesn't (and later it can't because of the DI).

Normally, interrupts are accepted in the last M-cycle of an instruction, so that part is fine, but maybe there's a cycle of delay after all? Implemented an extra cycle of delay in INT_n (inside Z80.vhd) to see if that makes a difference.

THIS IS GOOD NEWS!!!! WITH THIS CHANGE, I MANAGED TO FULLY BOOT WITHOUT ANY TRIGGERS!!!!

Now, booting is not all that stable these days and this was only an instance of 1, but still. Also: I still have the first two inconsistencies that are occasionally trigger.

In fact, it seems that I can catch data corruption that results in a hang now: a data-mismatch usually presages a hang.