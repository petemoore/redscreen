.global _start

_start:
  mrs     x0, mpidr_el1          // x0 = Multiprocessor Affinity Register.
  and     x0, x0, #0x3           // x0 = core number.
  cbnz    x0, sleep_core         // Put all cores except core 0 to sleep.
  adr     x10, mbreq             // x10 = memory block pointer for mailbox call.
  mov     w11, 8                 // Mailbox channel 8.
  orr     w2, w10, w11           // Encoded request address + channel number.
  mov     x3, #0xb880            // x3 = lower 16 bits of Mailbox Peripheral Address.
  movk    x3, #0x3f00, lsl #16   // x3 = 0x3f00b880 (Mailbox Peripheral Address)
  1:                             // Wait for mailbox FULL flag to be clear.
    ldr     w4, [x3, 0x18]       // w4 = mailbox status.
    tbnz    w4, #31, 1b          // If FULL flag set (bit 31), try again...
  str     w2, [x3, 0x20]         // Write request address / channel number to mailbox write register.
  2:                             // Wait for mailbox EMPTY flag to be clear.
    ldr     w4, [x3, 0x18]       // w4 = mailbox status.
    tbnz    w4, #30, 2b          // If EMPTY flag set (bit 30), try again...
  ldr     w4, [x3]               // w4 = message request address + channel number.
  cmp     w2, w4                 // See if the message is for us.
  b.ne    2b                     // If not, try again.
  ldr     w5, [x10, #112]        // w5 = allocated framebuffer address
  and     w5, w5, #0x3fffffff    // Clear upper bits beyond addressable memory
  ldr     w6, [x10, #132]        // w6 = pitch (bytes per horizontal line of framebuffer)
  mov     w11, 1024 * 4          // w11 = bytes for pixel data per horizontal line of framebuffer
  sub     w6, w6, w11            // w6 = number of padding bytes at end of horizontal line
  mov     w7, 768                // Number of horizontal lines.
  mov     w8, 0x000000ff         // w8 = RGB encoding for bright red (bright blue in BGR encoding).

  fill_buffer:                   // Fill the entire framebuffer with red points (pixels).
    mov     w9, 1024             // w9 = number of points in horizontal line of framebuffer.
    fill_line:                   // Fill a single row of the framebuffer with red points (pixels).
      str     w8, [x5], 4        // Make current point bright red, and update x5 to next point.
      sub     w9, w9, 1          // Decrease horizontal pixel counter.
      cbnz    w9, fill_line      // Repeat until line complete.
    add     w5, w5, w6           // Update x5 to start of next line.
    sub     w7, w7, 1            // Decrease vertical pixel counter.
    cbnz    w7, fill_buffer      // Repeat until all framebuffer lines complete.

sleep_core:
  wfe                            // Sleep until woken.
  b sleep_core                   // Go back to sleep.

# Memory block for mailbox call
.align 4
mbreq:
  .word 140                      // Buffer size
  .word 0                        // Request/response code
  .word 0x48003                  // Tag 0 - Set Screen Size
  .word 8                        //   value buffer size
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 1024                     //   request: width                response: width
  .word 768                      //   request: height               response: height
  .word 0x48004                  // Tag 1 - Set Virtual Screen Size
  .word 8                        //   value buffer size
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 1024                     //   request: width                response: width
  .word 768                      //   request: height               response: height
  .word 0x48009                  // Tag 2 - Set Virtual Offset
  .word 8                        //   value buffer size
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 0                        //   request: x offset             response: x offset
  .word 0                        //   request: y offset             response: y offset
  .word 0x48005                  // Tag 3 - Set Colour Depth
  .word 4                        //   value buffer size
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
                                 //                   32 bits per pixel => 8 red, 8 green, 8 blue, 8 alpha
                                 //                   See https://en.wikipedia.org/wiki/RGBA_color_space
  .word 32                       //   request: bits per pixel       response: bits per pixel
  .word 0x48006                  // Tag 4 - Set Pixel Order (really is "Colour Order", not "Pixel Order")
  .word 4                        //   value buffer size
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 1                        //   request: 0 => BGR, 1 => RGB   response: 0 => BGR, 1 => RGB
  .word 0x40001                  // Tag 5 - Get (Allocate) Buffer
  .word 8                        //   value buffer size (response > request, so use response size)
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 4096                     //   request: alignment in bytes   response: frame buffer base address
  .word 0                        //   request: padding              response: frame buffer size in bytes
  .word 0x40008                  // Tag 6 - Get Pitch (bytes per line)
  .word 4                        //   value buffer size
  .word 0                        //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
  .word 0                        //   request: padding              response: bytes per line
  .word 0                        // End Tags
