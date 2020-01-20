.set SCREEN_WIDTH,     1920
.set SCREEN_HEIGHT,    1200
.set BORDER_LEFT,      96
.set BORDER_RIGHT,     96
.set BORDER_TOP,       128
.set BORDER_BOTTOM,    112

.set MAILBOX_BASE,     0x3f00b880
.set MAILBOX_REQ_ADDR, 0x0
.set MAILBOX_WRITE,    0x20
.set MAILBOX_STATUS,   0x118
.set MAILBOX_EMPTY,    30
.set MAILBOX_FULL,     31

.set STACK,            0x80000

// load a 32-bit immediate using MOV
.macro movl Wn, imm
  movz    \Wn,  \imm & 0xFFFF
  movk    \Wn, (\imm >> 16) & 0xFFFF, lsl 16
.endm

.global _start

_start:
  mrs     x0, mpidr_el1                   // x0 = Multiprocessor Affinity Register.
  and     x0, x0, #0x3                    // x0 = core number.
  cbnz    x0, sleep_core                  // Put all cores except core 0 to sleep.
  mov     sp, STACK
  mov     x29, 0
  adr     x28, sysvars
  bl      uart_init
  bl      init_framebuffer
  ldr     w0, [x28, bordercolour-sysvars]
  bl      paint_border
  ldr     w0, [x28, windowcolour-sysvars]
  bl      paint_window
#  bl      paint_copyright
  b       sleep_core

init_framebuffer:
  stp     x29, x30, [sp, #-16]!           // Push frame pointer, procedure link register on stack.
  mov     x29, sp                         // Update frame pointer to new stack location.
  movl     w9, MAILBOX_BASE               // x9 = 0x3f00b880 (Mailbox Peripheral Address)
  1:                                      // Wait for mailbox FULL flag to be clear.
    ldr     w10, [x9, MAILBOX_STATUS]     // w10 = mailbox status.
    tbnz    w10, MAILBOX_FULL, 1b         // If FULL flag set (bit 31), try again...
  adr     x10, mbreq                      // x10 = memory block pointer for mailbox call.
  mov     w11, 8                          // Mailbox channel 8.
  orr     w11, w10, w11                   // w11 = encoded request address + channel number.
  str     w11, [x9, MAILBOX_WRITE]        // Write request address / channel number to mailbox write register.
  2:                                      // Wait for mailbox EMPTY flag to be clear.
    ldr     w12, [x9, MAILBOX_STATUS]     // w12 = mailbox status.
    tbnz    w12, MAILBOX_EMPTY, 2b        // If EMPTY flag set (bit 30), try again...
  ldr     w12, [x9, MAILBOX_REQ_ADDR]     // w12 = message request address + channel number.
  cmp     w11, w12                        // See if the message is for us.
  b.ne    2b                              // If not, try again.
  ldr     w11, [x10, framebuffer-mbreq]   // w11 = allocated framebuffer address
  and     w11, w11, #0x3fffffff           // Clear upper bits beyond addressable memory
  str     w11, [x10, framebuffer-mbreq]   // Store framebuffer address in framebuffer system variable.
  ldp     x29, x30, [sp], #16             // Pop frame pointer, procedure link register off stack.
  ret

# Inputs:
#   w0 = colour to paint border
paint_border:
  stp     x29, x30, [sp, #-16]!           // Push frame pointer, procedure link register on stack.
  mov     x29, sp                         // Update frame pointer to new stack location.
  stp     x19, x20, [sp, #-16]!
  mov     w19, w0
  mov     w0, 0
  mov     w1, 0
  mov     w2, SCREEN_WIDTH
  mov     w3, BORDER_TOP
  mov     w4, w19
  bl      paint_rectangle
  mov     w0, 0
  mov     w1, BORDER_TOP
  mov     w2, BORDER_LEFT
  mov     w3, SCREEN_HEIGHT-BORDER_TOP-BORDER_BOTTOM
  mov     w4, w19
  bl      paint_rectangle
  mov     w0, SCREEN_WIDTH-BORDER_RIGHT
  mov     w1, BORDER_TOP
  mov     w2, BORDER_RIGHT
  mov     w3, SCREEN_HEIGHT-BORDER_TOP-BORDER_BOTTOM
  mov     w4, w19
  bl      paint_rectangle
  mov     w0, 0
  mov     w1, SCREEN_HEIGHT-BORDER_BOTTOM
  mov     w2, SCREEN_WIDTH
  mov     w3, BORDER_BOTTOM
  mov     w4, w19
  bl      paint_rectangle
  ldp     x19, x20, [sp], #0x10
  ldp     x29, x30, [sp], #0x10           // Pop frame pointer, procedure link register off stack.
  ret

# Inputs:
#   w0 = x
#   w1 = y
#   w2 = width (pixels)
#   w3 = height (pixels)
#   w4 = colour
paint_rectangle:
  stp     x29, x30, [sp, #-16]!           // Push frame pointer, procedure link register on stack.
  mov     x29, sp                         // Update frame pointer to new stack location.
  adr     x9, mbreq                       // x9 = address of mailbox request.
  ldr     w10, [x9, framebuffer-mbreq]    // w10 = address of framebuffer
  ldr     w11, [x9, pitch-mbreq]          // w11 = pitch
#  umaddl  x10, w1, w11, x10               // x10 = address of framebuffer + y*pitch
   mul     w12, w1, w11                    // w12 = y*pitch
   add     w10, w10, w12                   // w10 = address of framebuffer + y*pitch
  add     w10, w10, w0, LSL #2            // w10 = address of framebuffer + y*pitch + x*4
  fill_rectangle:                         // Fills entire rectangle
    mov w12, w10                          // w12 = reference to start of line
    mov w13, w2                           // w13 = width of line
    fill_line:                            // Fill a single row of the rectangle with colour.
      str     w4, [x10], 4                // Colour current point, and update x10 to next point.
      sub     w13, w13, 1                 // Decrease horizontal pixel counter.
      cbnz    w13, fill_line              // Repeat until line complete.
    add     w10, w12, w11                 // x10 = start of current line + pitch = start of new line.
    sub     w3, w3, 1                     // Decrease vertical pixel counter.
    cbnz    w3, fill_rectangle            // Repeat until all framebuffer lines complete.
  ldp     x29, x30, [sp], #0x10           // Pop frame pointer, procedure link register off stack.
  ret

# Inputs:
#   w0 = colour to paint border
paint_window:
  stp     x29, x30, [sp, #-16]!           // Push frame pointer, procedure link register on stack.
  mov     x29, sp                         // Update frame pointer to new stack location.
  mov     w4, w0
  mov     w0, BORDER_LEFT
  mov     w1, BORDER_TOP
  mov     w2, SCREEN_WIDTH-BORDER_LEFT-BORDER_RIGHT
  mov     w3, SCREEN_HEIGHT-BORDER_TOP-BORDER_BOTTOM
  bl      paint_rectangle
  ldp     x29, x30, [sp], #0x10           // Pop frame pointer, procedure link register off stack.
  ret

# Inputs:
#   x0 = pointer to string
#   w1 = x
#   w2 = y
#   w3 = ink colour
#   w4 = paper colour
paint_string:
  stp     x29, x30, [sp, #-16]!           // Push frame pointer, procedure link register on stack.
  mov     x29, sp                         // Update frame pointer to new stack location.
  adr     x9, mbreq                       // x9 = address of mailbox request.
  ldr     w10, [x9, framebuffer-mbreq]    // w10 = address of framebuffer
  ldr     w9, [x9, pitch-mbreq]           // w9 = pitch
  adr     x11, chars-32*32                // x11 = theoretical start of character table for char 0
1:
  ldrb w12, [x0], 1                       // w12 = char from string, and update x0 to next char
  cbz w12, 2f                             // if found end marker, jump to end of function and return
  add x13, x11, x12, LSL #5               // x13 = address of character bitmap
  mov w14, BORDER_TOP                     // w14 = BORDER_TOP
  add w14, w14, w2, LSL #4                // w14 = BORDER_TOP + y * 16
  mov w15, BORDER_LEFT                    // w15 = BORDER_LEFT
  add w15, w15, w1, LSL #4                // w15 = BORDER_LEFT + x * 16
  add w15, w10, w15, LSL #2               // w15 = address of framebuffer + 4* (BORDER_LEFT + x * 16)
  umaddl  x14, w9, w14, x15               // w14 = pitch*(BORDER_TOP + y * 16) + address of framebuffer + 4 * (BORDER_LEFT + x*16)
  mov w15, 16                             // w15 = y counter
  paint_char:
    mov w16, w14                          // w16 = leftmost pixel of current row address
    mov w12, 1 << 15                      // w12 = mask for current pixel
    ldrh    w17, [x13], 2                 // w17 = bitmap for current row, and update x13 to next bitmap pattern
    paint_line:                           // Paint a horizontal row of pixels of character
      tst     w17, w12                    // apply pixel mask
      csel    w18, w3, w4, ne             // if pixel set, colour w3 (ink colour) else colour w4 (paper colour)
      str     w18, [x14], 4               // Colour current point, and update x14 to next point.
      lsr     w12, w12, 1                 // Shift bit mask to next pixel
      cbnz    w12, paint_line             // Repeat until line complete.
    add     w14, w16, w9                  // x14 = start of current line + pitch = start of new line.
    sub     w15, w15, 1                   // Decrease vertical pixel counter.
    cbnz    w3, paint_char                // Repeat until all framebuffer lines complete.
  b 1b
2:
  ldp     x29, x30, [sp], #0x10           // Pop frame pointer, procedure link register off stack.
  ret

paint_copyright:
  stp     x29, x30, [sp, #-16]!           // Push frame pointer, procedure link register on stack.
  mov     x29, sp                         // Update frame pointer to new stack location.
  adr x0, msg_copyright
  mov x1, 1
  mov x2, 2
  mov x3, 0x0000cfcf
  mov x4, 0x0000cf00
  bl paint_string
  ldp     x29, x30, [sp], #0x10           // Pop frame pointer, procedure link register off stack.
  ret

  
sleep_core:
  wfe                                     // Sleep until woken.
  b       sleep_core                      // Go back to sleep.

# Memory block for mailbox call
.align 4
mbreq:
  .word 140                               // Buffer size
  .word 0                                 // Request/response code
  .word 0x48003                           // Tag 0 - Set Screen Size
  .word 8                                 //   value buffer size
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word SCREEN_WIDTH                      //   request: width                response: width
  .word SCREEN_HEIGHT                     //   request: height               response: height
  .word 0x48004                           // Tag 1 - Set Virtual Screen Size
  .word 8                                 //   value buffer size
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word SCREEN_WIDTH                      //   request: width                response: width
  .word SCREEN_HEIGHT                     //   request: height               response: height
  .word 0x48009                           // Tag 2 - Set Virtual Offset
  .word 8                                 //   value buffer size
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 0                                 //   request: x offset             response: x offset
  .word 0                                 //   request: y offset             response: y offset
  .word 0x48005                           // Tag 3 - Set Colour Depth
  .word 4                                 //   value buffer size
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
                                          //                   32 bits per pixel => 8 red, 8 green, 8 blue, 8 alpha
                                          //                   See https://en.wikipedia.org/wiki/RGBA_color_space
  .word 32                                //   request: bits per pixel       response: bits per pixel
  .word 0x48006                           // Tag 4 - Set Pixel Order (really is "Colour Order", not "Pixel Order")
  .word 4                                 //   value buffer size
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 0                                 //   request: 0 => BGR, 1 => RGB   response: 0 => BGR, 1 => RGB
  .word 0x40001                           // Tag 5 - Get (Allocate) Buffer
  .word 8                                 //   value buffer size (response > request, so use response size)
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
framebuffer:
  .word 4096                              //   request: alignment in bytes   response: frame buffer base address
  .word 0                                 //   request: padding              response: frame buffer size in bytes
  .word 0x40008                           // Tag 6 - Get Pitch (bytes per line)
  .word 4                                 //   value buffer size
  .word 0                                 //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
pitch:
  .word 0                                 //   request: padding              response: bytes per line
  .word 0                                 // End Tags

sysvars:
  bordercolour: .word 0x00cf0000
  windowcolour: .word 0x00cfcfcf

msg_copyright:
   .asciz "1982, 1986, 1987 Amstrad Plc."
.align 2
